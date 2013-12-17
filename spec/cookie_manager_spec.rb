require 'spec_helper'

describe UberLogin::CookieManager do
  let(:cookie_manager) { UberLogin::CookieManager.new({ uid: 100, ulogin: "dead:beef" }, FakeRequest.new) }

  describe '#valid?' do
    context 'User id and sequence combination is found' do
      context 'all checks return true' do
        before { UberLogin::TokenValidator.any_instance.stub(:valid?).and_return true }

        it 'returns true' do
          expect(cookie_manager.valid?).to be_true
        end
      end

      context 'any check fails' do
        before { UberLogin::TokenValidator.any_instance.stub(:valid?).and_return false }

        it 'returns false' do
          expect(cookie_manager.valid?).to be_false
        end
      end
    end

    context 'User id and sequence combination is not found' do
      before { UberLogin::Storage.stub(:find).and_return nil }

      it 'returns false' do
        expect(cookie_manager.valid?).to be_false
      end
    end
  end
end