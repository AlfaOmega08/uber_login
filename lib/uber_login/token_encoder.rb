require 'bcrypt'

module UberLogin
  class TokenEncoder
    class << self
      def encode(sequence, token)
        sequence + ':' + token
      end

      def decode(composite)
        composite.split(':')
      end

      def sequence(composite)
        decode(composite)[0]
      end

      def token(composite)
        decode(composite)[1]
      end

      def token_hash(composite)
        BCrypt::Password.create(token(composite)).to_s
      end
    end
  end
end