
module UberLogin
  module Storage
    def find(uid, sequence)
      LoginToken.find_by(uid: uid, sequence: sequence)
    end

    def find_composite(uid, composite)
      find(uid, TokenEncoder.sequence(composite))
    end
  end
end
