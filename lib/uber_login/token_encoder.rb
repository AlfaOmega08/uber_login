module UberLogin
  module TokenEncoder
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
  end
end