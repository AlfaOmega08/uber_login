require 'spec_helper'

describe CookieManager do
  let(:cookie_manager) { CookieManager.new({ uid: 100, ulogin: "dead:beef" }, FakeRequest.new) }

  describe '#valid?' do
    context 'User id and sequence combination is found' do
      let(:fake_token) {
        LoginToken.new(
          token: BCrypt::Password.create("beef"),
          ip_address: '192.168.1.1'
        )
      }

      before { LoginToken.stub(:find_by).and_return fake_token }

      it 'always executes token_match' do
        expect(cookie_manager).to receive(:token_match)
        cookie_manager.valid?
      end

      it 'does not run ip_equality by default' do
        expect(cookie_manager).to_not receive(:ip_equality)
        cookie_manager.valid?
      end

      context 'if IP are tied to Tokens' do
        before { UberLogin.configuration.tie_tokens_to_ip = true }

        it 'executes ip_equality' do
          expect(cookie_manager).to receive(:ip_equality)
          cookie_manager.valid?
        end
      end

      it 'does not run expiration by default' do
        expect(cookie_manager).to_not receive(:expiration)
        cookie_manager.valid?
      end

      context 'if Tokens do expire' do
        before { UberLogin.configuration.token_expiration = 86400 }

        it 'executes expiration' do
          expect(cookie_manager).to receive(:expiration)
          cookie_manager.valid?
        end
      end

      context 'all checks return true' do
        before { Array.any_instance.stub(:all?).and_return true }

        it 'returns true' do
          expect(cookie_manager.valid?).to be_true
        end
      end

      context 'any check fails' do
        before { Array.any_instance.stub(:all?).and_return false }

        it 'returns false' do
          expect(cookie_manager.valid?).to be_false
        end
      end
    end

    context 'User id and sequence combination is not found' do
      before { LoginToken.stub(:find_by).and_return nil }

      it 'returns false' do
        expect(cookie_manager.valid?).to be_false
      end
    end
  end

  describe '#token_match' do
    before { UberLogin::TokenEncoder.stub(:token).and_return 'secret' }

    it 'returns true if tokens are matched' do
      row = double(token: BCrypt::Password.create('secret', cost: 1))
      expect(cookie_manager.token_match(row)).to be_true
    end

    it 'returns false if tokens are not matched' do
      row = double(token: BCrypt::Password.create('s3cr3t', cost: 1))
      expect(cookie_manager.token_match(row)).to be_false
    end
  end

  describe '#ip_equality' do
    before { FakeRequest.any_instance.stub(:remote_ip).and_return '10.10.10.10' }

    it 'returns true if IPs are equal' do
      row = double(ip_address: '10.10.10.10')
      expect(cookie_manager.ip_equality(row)).to be_true
    end

    it 'returns false if IPs are different' do
      row = double(ip_address: '192.168.1.1')
      expect(cookie_manager.ip_equality(row)).to be_false
    end
  end

  describe '#expiration' do
    before { UberLogin.configuration.token_expiration = 86400 }

    it 'returns true if less than token_expiration seconds are past' do
      row = double(updated_at: Time.now - 100)
      expect(cookie_manager.expiration(row)).to be_true
    end

    it 'returns false if more than token_expiration seconds are past' do
      row = double(updated_at: Time.now - 86401)
      expect(cookie_manager.expiration(row)).to be_false
    end
  end
end