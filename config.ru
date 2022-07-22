require "./config/environment"

run Rack::URLMap.new("/" => HookAdapter)