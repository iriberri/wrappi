require 'wrappi/response'
module Wrappi
  class Endpoint < Miller.base(
    :verb, :client, :path, :default_params,
    :headers, :follow_redirects, :basic_auth,
    :body_type, :retry_options, :cache,
    default_config: {
      verb: :get,
      client: proc { raise 'client not set' }, # TODO: add proper error
      path: proc { raise 'path not defined' }, # TODO: add proper error
      default_params: {},
      headers: proc { client.headers },
      follow_redirects: true,
      body_type: :json,
      cache: false
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

    # AROUND REQUEST
    def self.around_request(&block)
      @around_request = block
    end
    def around_request
      self.class.instance_variable_get(:@around_request)
    end

    # RETRY
    def self.retry_if(&block)
      @retry_if = block
    end
    def retry_if
      self.class.instance_variable_get(:@retry_if)
    end

    # Cache
    def cache_key
      # TODO: think headers have to be in the key as well
      @cache_key ||= "[#{verb.to_s.upcase}]##{url}#{params_cache_key}"
    end

    def logger
      client.logger
    end

    private

    def params_cache_key
      return if params.empty?
      d = Digest::MD5.hexdigest params.to_json
      "?#{d}"
    end

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
