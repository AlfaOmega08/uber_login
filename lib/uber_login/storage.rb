
module UberLogin
  class Storage
    class << self
      def find(uid, sequence)
        LoginToken.find_by(uid: uid, sequence: sequence)
      end

      def find_composite(uid, composite)
        find(uid, TokenEncoder.sequence(composite))
      end

      def build(uid, composite)
        LoginToken.new(
          uid: uid,
          sequence: TokenEncoder.sequence(composite),
          token: TokenEncoder.token_hash(composite)
        )
      end
    end
  end
end
