# frozen_string_literal: true
require 'sequel'
require 'bcrypt'
require 'digest/md5'
require 'active_support'
require 'active_support/core_ext/object/blank'

# Why not store this in Elasticsearch?
module ProxES
  class User < Sequel::Model
    one_to_many :identity
    one_to_many :user_roles

    def role?(check)
      user_roles.map(&:role).map(&:to_sym).include? check.to_sym
    end

    def admin?
      (user_roles.map(&:role) & %w(admin super_admin)).any?
    end

    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s[-1] == '?'
        role?(method_sym[0..-2])
      else
        super
      end
    end

    def respond_to_missing?(name, _include_private = false)
      name[-1] == '?'
    end

    def gravatar
      hash = Digest::MD5.hexdigest(email.downcase)
      "https://www.gravatar.com/avatar/#{hash}"
    end

    def validate
      validates_presence :email
      return if email.blank?
      validates_unique :email
      validates_format(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :email)
    end

    def index_prefix
      email
    end
  end
end
