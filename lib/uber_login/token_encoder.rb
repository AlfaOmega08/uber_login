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
        if composite
          composite.split(':')
        else
          [ nil, nil ]
        end
      end

      def sequence(composite)
        if composite
          decode(composite)[0]
        end
      end

      def token(composite)
        if composite
          decode(composite)[1]
        end
      end

      def token_hash(composite)
        BCrypt::Password.create(token(composite)).to_s
      end
    end
  end
end