# frozen_string_literal: true

require 'excon'
require 'json'

class HookAdapter < Sinatra::Base
  post '/' do
    verify_authorization!
    invoke_http_hook(body: deployhooks_formated_body) if http_hook_configured && release_finished
    204
  rescue Excon::Error => e
    puts "An error occured while sending the request: #{e}"
    500
  end

  private

  attr_reader :webhook_payload

  def webhook_payload
    @webhook_payload ||= parse_body
  end

  def parse_body
    JSON.parse(request.body.read)
  rescue StandardError => e
    puts "An error occured while parsing the request: #{e}"
    {}
  end

  def verify_authorization!
    return unless authorization_enabled

    halt 403 unless Rack::Utils.secure_compare(request.env['Authorization'], ENV['AUTHORIZATION'])
  end

  def authorization_enabled
    !ENV['AUTHORIZATION'].nil?
  end

  def release_finished
    status = webhook_payload.dig('data', 'status')
    action = webhook_payload['action']
    is_current = webhook_payload.dig('data', 'current')
    status.eql?('succeeded') && action.eql?('update') && is_current
  end

  # Formats webhooks' payload to resemble deployhooks behavior.
  # Notice that webhooks does not inform the URL
  # If the request can not be parsed returns an empty string
  def deployhooks_formated_body
    {
      'app' => webhook_payload.dig('data', 'app', 'name'),
      'user' => webhook_payload.dig('actor', 'email'),
      'url' => '',
      'head' => webhook_payload.dig('data', 'slug', 'commit')&.slice(0, 6),
      'head_long' => webhook_payload.dig('data', 'slug', 'commit'),
      'git_log' => webhook_payload.dig('data', 'slug', 'commit_description')&.strip
    }
  end

  def invoke_http_hook(body: '')
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    Excon.new(http_hook_uri).request(
      method: :post,
      expects: [200, 204],
      body: body.to_json,
      headers: headers
    )
  end

  def http_hook_configured
    !ENV['HTTP_ENDPOINT'].nil?
  end

  def http_hook_uri
    uri = URI.parse(ENV['HTTP_ENDPOINT'])
    variable = /{{(\w+)}}/
    uri.to_s.gsub(variable) do |match_string|
      matchdata = match_string.match(variable)
      Addressable::URI.encode_component(deployhooks_formated_body[matchdata[1]], Addressable::URI::CharacterClasses::PATH)
    end
  end
end
