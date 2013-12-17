describe UberLogin::TokenEncoder do
  describe '#generate' do
    it 'returns an array of size 2' do
      expect(UberLogin::TokenEncoder.generate.size).to eq 2
    end
  end

  describe '#encode' do
    it 'retuns a string' do
      expect(UberLogin::TokenEncoder.encode('what', 'ever').class).to eq String
    end

    it 'returns the two arguments separated by colons' do
      expect(UberLogin::TokenEncoder.encode('what', 'ever')).to eq 'what:ever'
    end
  end

  describe '#encode_array' do
    it 'retuns a string' do
      expect(UberLogin::TokenEncoder.encode_array([ 'what', 'ever' ]).class).to eq String
    end

    it 'returns the two arguments separated by colons' do
      expect(UberLogin::TokenEncoder.encode_array([ 'what', 'ever' ])).to eq 'what:ever'
    end
  end

  describe '#decode' do
    it 'returns an array of size 2' do
      expect(UberLogin::TokenEncoder.decode('dead:beef').size).to eq 2
    end

    it 'returns the two elements of the token' do
      expect(UberLogin::TokenEncoder.decode('what:ever')).to eq [ 'what', 'ever' ]
    end
  end

  describe '#sequence' do
    it 'returns the first part of the token' do
      expect(UberLogin::TokenEncoder.sequence('what:ever')).to eq 'what'
    end
  end

  describe '#token' do
    it 'returns the second part of the token' do
      expect(UberLogin::TokenEncoder.token('what:ever')).to eq 'ever'
    end
  end

  describe '#token_hash' do
    it 'returns the second part of the token as a hash' do
      token = UberLogin::TokenEncoder.token('what:ever')
      hash = UberLogin::TokenEncoder.token_hash('what:ever')

      expect(BCrypt::Password.new(hash)).to eq token
    end
  end
end