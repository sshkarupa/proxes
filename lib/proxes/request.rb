# frozen_string_literal: true

require 'rack'

module ProxES
  class Request < Rack::Request
    ID_ENDPOINTS = %w[_create _explain _mlt _percolate _source _termvector _update].freeze
    WRITE_METHODS = %w[POST PUT DELETE].freeze

    def self.from_env(env)
      endpoint = path_endpoint(env['REQUEST_PATH'])
      endpoint_class = endpoint.nil? ? 'index' : endpoint[1..-1]
      begin
        require 'proxes/request/' + endpoint_class.downcase
        Request.const_get(endpoint_class.titlecase).new(env)
      rescue LoadError
        new(env)
      end
    end

    def self.path_endpoint(path)
      return '_root' if ['', nil, '/'].include? path
      path_parts = path[1..-1].split('/')
      return path_parts[-1] if ID_ENDPOINTS.include? path_parts[-1]
      return path_parts[-2] if path_parts[-1] == 'count' && path_parts[-2] == '_percolate'
      return path_parts[-2] if path_parts[-1] == 'scroll' && path_parts[-2] == '_search'
      path_parts.find { |part| part[0] == '_' }
    end

    def initialize(env)
      super
      parse
    end

    def endpoint
      path_parts[0]
    end

    def parse
      path_parts
    end

    def indices?
      false
    end

    private

    def path_parts
      @path_parts ||= path[1..-1].split('/')
    end

    def check_part(val)
      return val if val.nil?
      return [] if [endpoint, '_all'].include?(val) && !WRITE_METHODS.include?(request_method)
      val.split(',')
    end
  end
end
