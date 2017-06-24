# frozen_string_literal: true

module ProxES
  module Helpers
    module Authentication
      def current_user
        return nil unless env['rack.session'] && env['rack.session']['user_id']
        @users ||= Hash.new { |h, k| h[k] = User[k] }
        @users[env['rack.session']['user_id']]
      end

      def current_user=(user)
        env['rack.session']['user_id'] = user.id
      end

      def authenticate
        authenticated?
      end

      def authenticated?
        current_user.nil?
      end

      def authenticate!
        raise NotAuthenticated unless current_user
        true
      end

      def logout
        env['rack.session'].delete('user_id')
      end

      def check_basic
        auth = Rack::Auth::Basic::Request.new(env)
        return unless auth.provided?
        return unless auth.basic?

        identity = ::ProxES::Identity.find(username: auth.credentials[0])
        identity = ::ProxES::Identity.find(username: URI.unescape(auth.credentials[0])) unless identity
        raise NotAuthenticated unless identity
        self.current_user = identity.user if identity.authenticate(auth.credentials[1])
      end
    end

    class NotAuthenticated < StandardError
    end
  end
end
