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

      def delete_all(uid)
        LoginToken.find_by(uid: uid).destroy
      end

      def delete_all_but(uid, composite)
        # TODO: How to make this ORM agnostic?
      end
    end
  end
end
