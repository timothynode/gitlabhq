require 'gitlab/oauth/user'

# LDAP extension for User model
#
# * Find or create user from omniauth.auth data
# * Links LDAP account with existing user
# * Auth LDAP user with login and password
#
module Gitlab
  module LDAP
    class User < Gitlab::OAuth::User
      class << self
        def find_by_uid_and_provider(uid, provider)
          # LDAP distinguished name is case-insensitive
          ::User.
            where(provider: [provider, :ldap]).
            where('lower(extern_uid) = ?', uid.downcase).last
        end
      end

      def initialize(auth_hash)
        super
        update_user_attributes
      end

      # instance methods
      def gl_user
        @gl_user ||= find_by_uid_and_provider || find_by_email || build_new_user
      end

      def find_by_uid_and_provider
        self.class.find_by_uid_and_provider(
          auth_hash.uid.downcase, auth_hash.provider)
      end

      def find_by_email
        model.find_by(email: auth_hash.email)
      end

      def update_user_attributes
        gl_user.attributes = {
          extern_uid: auth_hash.uid,
          provider: auth_hash.provider,
          email: auth_hash.email
        }
      end

      def changed?
        gl_user.changed?
      end

      def needs_blocking?
        false
      end

      def allowed?
        Gitlab::LDAP::Access.allowed?(gl_user)
      end
    end
  end
end
