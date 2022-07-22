require "excon"
require "json"

class HookAdapter < Sinatra::Base
  post "/" do
    invoke_http_hook
    204
  end

  private

  def invoke_http_hook(body: "")
    Excon.new(http_hook_uri).request(
      method: :post,
      expects: [200, 204],
      body: body,
      headers: headers
    )
  end

  def http_hook_uri
    URI.parse(ENV["HTTP_ENDPOINT"]).to_s
  end
end