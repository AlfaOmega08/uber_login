module UberLogin
  class Storage
    class << self
      def find(uid, sequence)
        LoginToken.where(uid: uid, sequence: sequence).first
      end

      def find_composite(uid, composite)
        find(uid, TokenEncoder.sequence(composite))
      rescue  # composite might invalid if cookies are tampered
        nil
      end

      def build(uid, composite)
        LoginToken.new(
          uid: uid,
          sequence: TokenEncoder.sequence(composite),
          token: TokenEncoder.token_hash(composite)
        )
      end

      def delete_all(uid)
        LoginToken.destroy_all(uid: uid)
      end

      def delete_all_but(uid, composite)
        # TODO: How to make this ORM agnostic?
      end
    end
  end
end
