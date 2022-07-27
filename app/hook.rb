# frozen_string_literal: true

require 'addressable'
require 'excon'
require 'json'

class HookAdapter < Sinatra::Base
  post '/' do
    verify_authorization!
    verify_message_digest!
    verify_release_finished!

    invoke_http_hook(body: deployhooks_formated_body) if http_hook_configured

    204
  rescue Excon::Error => e
    puts "An error occured while sending the request: #{e}"
    500
  end

  private

  def verify_authorization!
    return unless authorization_enabled

    halt 403 unless Rack::Utils.secure_compare(request.env['Authorization'], ENV['AUTHORIZATION'])
  end

  def authorization_enabled
    !ENV['AUTHORIZATION'].nil?
  end

  def verify_message_digest!
    return unless digest_enabled

    halt 400 unless valid_signature?(request, ENV['WEBHOOK_SECRET'])
  end

  def digest_enabled
    !ENV['WEBHOOK_SECRET'].nil?
  end

  def valid_signature?(request, webhook_secret)
    calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(
      OpenSSL::Digest.new('sha256'),
      webhook_secret,
      request.body.read
    )).strip
    heroku_hmac = request.env['Heroku-Webhook-Hmac-SHA256']

    heroku_hmac && Rack::Utils.secure_compare(calculated_hmac, heroku_hmac)
  end

  def verify_release_finished!
    halt 204 unless release_finished
  end

  def release_finished
    status = webhook_payload.dig('data', 'status')
    action = webhook_payload['action']
    is_current = webhook_payload.dig('data', 'current')
    status.eql?('succeeded') && action.eql?('update') && is_current
  end

  def invoke_http_hook(body: '')
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    Excon.new(http_hook_uri).request(
      method: :post,
      expects: [200, 204],
      body: URI.encode_www_form(body),
      headers: headers
    )
  end

  def http_hook_uri
    uri = URI.parse(ENV['HTTP_ENDPOINT'])
    variable = /{{(\w+)}}/
    uri.to_s.gsub(variable) do |match_string|
      matchdata = match_string.match(variable)
      Addressable::URI.encode_component(deployhooks_formated_body[matchdata[1]], Addressable::URI::CharacterClasses::PATH)
    end
  end

  # Formats webhooks' payload to resemble deployhooks behavior.
  # Notice that webhooks does not inform the URL and prev_head
  # If the request can not be parsed returns an empty string
  def deployhooks_formated_body
    {
      'app' => webhook_payload.dig('data', 'app', 'name'),
      'app_uuid' => webhook_payload.dig('data', 'app', 'id'),
      'user' => webhook_payload.dig('actor', 'email'),
      'url' => '',
      'head' => webhook_payload.dig('data', 'slug', 'commit')&.slice(0, 8),
      'head_long' => webhook_payload.dig('data', 'slug', 'commit'),
      'git_log' => webhook_payload.dig('data', 'slug', 'commit_description')&.strip,
      'prev_head' => '',
      'release' => webhook_payload.dig('data', 'version')
    }
  end

  def http_hook_configured
    !ENV['HTTP_ENDPOINT'].nil?
  end

  attr_reader :webhook_payload

  def webhook_payload
    @webhook_payload ||= parse_body
  end

  def parse_body
    request.body.rewind
    JSON.parse(request.body.read)
  rescue StandardError => e
    puts "An error occured while parsing the request: #{e}"
    {}
  end
end
