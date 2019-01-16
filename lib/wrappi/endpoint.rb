require 'wrappi/response'
module Wrappi
  class Endpoint < Miller.base(
    :verb, :client, :path, :default_params,
    :headers, :follow_redirects, :basic_auth,
    :body_type, :around_request,
    default_config: {
      verb: :get,
      client: proc { raise 'client not set' }, # TODO: add proper error
      path: proc { raise 'path not defined' }, # TODO: add proper error
      default_params: {},
      headers: proc { client.headers },
      follow_redirects: true,
      body_type: :json
    }
  )
    attr_reader :input_params, :options
    def initialize(input_params = {}, options = {})
      @input_params = input_params
      @options = options
    end

    def self.call(*args)
      new(*args).call
    end

    def url
      _url.to_s
    end

    def url_with_params
      if verb == :get
        _url.tap do |u|
          u.query = URI.encode_www_form(consummated_params) if consummated_params.any?
        end.to_s
      else
        url
      end
    end

    # overridable
    def consummated_params
      params
    end

    def response
      @response ||= Executer.call(self)
    end
    alias_method :call, :response

    def body; response.body end
    def success?; response.success? end
    def status; response.status end

    private

    def _url
      URI.join("#{client.domain}/", path_gen.path) # TODO: remove heading "/" of path
    end

    def params
      path_gen.params
    end

    def processed_params
      client.params.merge(default_params.merge(input_params))
    end

    def path_gen
      @path_gen ||= PathGen.new(path, processed_params)
    end
  end
end
