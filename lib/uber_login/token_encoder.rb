require 'bcrypt'

module UberLogin
  class TokenEncoder
    class << self
      def generate
        # 9 and 21 are both multiple of 3, so we do not get base64 padding (==)
        [ SecureRandom.urlsafe_base64(9), SecureRandom.base64(21) ]
      end

      def encode(sequence, token)
        encode_array [ sequence, token ]
      end

      def encode_array(composite_array)
        composite_array.join(':')
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