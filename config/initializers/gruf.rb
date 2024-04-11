# frozen_string_literal: true

require 'gruf'
# It's typically best to generate your protobuf files in a separate, centralized repository across your architecture,
# and then generate gems to use internally to load them. For this demo repository, however, we'll just put them in
# lib/ and load them manually here.
proto_dir = File.join(Rails.root, 'lib', 'proto')
$LOAD_PATH.unshift(proto_dir)
require 'app/proto/Products_services_pb'

Gruf.configure do |c|
  c.interceptors.use(::Gruf::Interceptors::Instrumentation::RequestLogging::Interceptor, formatter: :logstash)
  c.error_serializer = Gruf::Serializers::Errors::Json
  c.rpc_server_options    = {
    pool_size: ENV.fetch('GRPC_SERVER_POOL_SIZE', 100).to_i,
    pool_keep_alive: ENV.fetch('GRPC_SERVER_POOL_KEEP_ALIVE', 1).to_i,
    poll_period: ENV.fetch('GRPC_SERVER_POLL_PERIOD', 1).to_i
  }.to_h.symbolize_keys

  unless Rails.env.test? # no need for auth in dev
    token = ::ENV.fetch('GRPC_AUTH_TOKEN', 'austin').to_s.strip
    c.interceptors.use(Gruf::Interceptors::Authentication::Basic, credentials: [{ password: token }]) if token.present?
  end
end
