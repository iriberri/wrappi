module Wrappi
  class PathGen
    class MissingParamError < StandardError; end
    PATTERN = /:\w+/
    attr_reader :input_path, :input_params
    def initialize(input_path, input_params)
      @input_path = input_path
      @input_params = Fusu::HashWithIndifferentAccess.new(input_params)
      @interpolable = input_path =~ PATTERN
    end

    def compiled_path
      return input_path unless interpolable?
      @compiled_path ||= URI.escape(new_sections.join('/'))
    end
    alias_method :path, :compiled_path

    def processed_params
      return input_params unless interpolable?
      @processed_params ||= input_params.reject{ |k, v| keys_in_params.include?(k.to_sym) }
    end
    alias_method :params, :processed_params

    private

    def interpolable?
      @interpolable
    end

    def new_sections
      sections.map do |section|
        if section =~ PATTERN
          key = section.delete(':')
          raise MissingParamError.new("path: #{input_path} requires param ':#{key}'") unless input_params.key?(key)
          input_params[key]
        else
          section
        end
      end
    end

    def sections
      input_path.split("/")
    end

    def keys_in_params
      interpolations.map do |k|
        k.delete(':').to_sym
      end
    end

    def interpolations
      input_path.scan(PATTERN)
    end
  end
end
