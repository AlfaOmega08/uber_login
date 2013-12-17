require 'spec_helper'

describe UberLogin::TokenValidator do
  let(:token_validator) { UberLogin::TokenValidator.new('secret', FakeRequest.new) }
  let(:fake_token) {
    LoginToken.new(
        token: BCrypt::Password.create("beef"),
        ip_address: '192.168.1.1'
    )
  }

  describe '#valid?' do
    it 'always executes token_match' do
      expect(token_validator).to receive(:token_match)
      token_validator.valid?(fake_token)
    end

    it 'does not run ip_equality by default' do
      expect(token_validator).to_not receive(:ip_equality)
      token_validator.valid?(fake_token)
    end

    context 'if IP are tied to tokens' do
      before { UberLogin.configuration.tie_tokens_to_ip = true }
      let(:token_validator) { UberLogin::TokenValidator.new('secret', FakeRequest.new) }

      it 'executes ip_equality' do
        token_validator.stub(:token_match).and_return true
        expect(token_validator).to receive(:ip_equality)
        token_validator.valid?(fake_token)
      end
    end

    it 'does not run expiration by default' do
      expect(token_validator).to_not receive(:expiration)
      token_validator.valid?(fake_token)
    end

    context 'if tokens do expire' do
      before { UberLogin.configuration.token_expiration = 86400 }
      let(:token_validator) { UberLogin::TokenValidator.new('secret', FakeRequest.new) }

      it 'executes expiration' do
        token_validator.stub(:token_match).and_return true
        expect(token_validator).to receive(:expiration)
        token_validator.valid?(fake_token)
      end
    end

    context 'all checks return true' do
      before { Array.any_instance.stub(:all?).and_return true }

      it 'returns true' do
        expect(token_validator.valid?(fake_token)).to be_true
      end
    end

    context 'any check fails' do
      before { Array.any_instance.stub(:all?).and_return false }

      it 'returns false' do
        expect(token_validator.valid?(fake_token)).to be_false
      end
    end
  end
end