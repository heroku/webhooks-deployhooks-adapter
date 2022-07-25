# frozen_string_literal: true

require 'excon'
require 'json'

class HookAdapter < Sinatra::Base
  post '/' do
    invoke_http_hook(body: deployhooks_formated_body) if http_hook_configured
    204
  end

  private

  # Formats webhooks' payload to resemble deployhooks behavior.
  # Notice that webhooks does not inform the URL
  # If the request can not be parsed returns an empty string
  def deployhooks_formated_body
    webhook_payload = JSON.parse(request.body.read)
    deployhook_payload = {
      'app' => webhook_payload.dig('data', 'app', 'name'),
      'user' => webhook_payload.dig('actor', 'email'),
      'url' => '',
      'head' => webhook_payload.dig('data', 'slug', 'commit')&.slice(0, 6),
      'head_long' => webhook_payload.dig('data', 'slug', 'commit'),
      'git_log' => webhook_payload.dig('data', 'slug', 'commit_description')&.strip
    }
    deployhook_payload.to_json
  rescue StandardError => e
    puts "An error occured while parsing the request: #{e}"
    ''
  end

  def invoke_http_hook(body: '')
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    Excon.new(http_hook_uri).request(
      method: :post,
      expects: [200, 204],
      body: body,
      headers: headers
    )
  end

  def http_hook_configured
    !ENV['HTTP_ENDPOINT'].nil?
  end

  def http_hook_uri
    URI.parse(ENV['HTTP_ENDPOINT']).to_s
  end
end
