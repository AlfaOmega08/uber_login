require 'spec_helper'

describe CookieManager do
  let(:cookie_manager) { CookieManager.new({ uid: 100, ulogin: "dead:beef" }, FakeRequest.new) }

  describe '#valid_login_cookies?' do
    context 'User id and sequence combination is found' do
      let(:fake_token) {
        LoginToken.new(
          token: BCrypt::Password.create("beef"),
          ip_address: '192.168.1.1'
        )
      }

      before { LoginToken.stub(:find_by).and_return fake_token }

      context 'The token is validated' do
        context 'no expiration time is configured' do
          it 'returns true' do
            expect(cookie_manager.valid?).to be_true
          end
        end

        context 'the token is expired' do
          before { UberLogin::Configuration.any_instance.stub(:login_token_expiration).and_return 10 }

          it 'returns false' do
            expect(cookie_manager.valid?).to be_false
          end
        end

        context 'the token is not expired' do
          before { UberLogin::Configuration.any_instance.stub(:login_token_expiration).and_return 1000 }

          it 'returns true' do
            expect(cookie_manager.valid?).to be_true
          end
        end

        context 'tokens are tied to IPs' do
          before { UberLogin::Configuration.any_instance.stub(:tie_token_to_ip).and_return true }

          it 'returns true' do
            expect(cookie_manager.valid?).to be_true
          end
        end
      end

      context 'The token is not validated' do
        before { BCrypt::Password.any_instance.stub(:==).and_return false }

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
end