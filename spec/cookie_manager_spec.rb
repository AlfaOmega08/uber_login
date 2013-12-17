require 'spec_helper'

describe UberLogin::CookieManager do
  let(:user) { double(id: 100) }
  let(:controller) { ApplicationController.new }
  let(:session) { controller.session }
  let(:cookies) { controller.cookies }
  let(:cookie_manager) { UberLogin::CookieManager.new(cookies, FakeRequest.new) }

  describe '#persistent_login' do
    it 'sets the :uid cookie' do
      cookie_manager.persistent_login(100, [ 'dead', 'beef' ])
      expect(cookies[:uid]).to eq 100
    end

    it 'sets the :ulogin cookie' do
      cookie_manager.persistent_login(100, [ 'dead', 'beef' ])
      expect(cookies[:ulogin]).to eq 'dead:beef'
    end
  end

  describe '#clear' do
    before { controller.login(user, true) }

    it 'deletes the :uid cookie' do
      cookie_manager.clear
      expect(cookies[:uid]).to be_nil
    end

    it 'deletes the :ulogin cookie' do
      cookie_manager.clear
      expect(cookies[:ulogin]).to be_nil
    end
  end

  describe '#valid?' do
    before { controller.login(user, true) }

    context 'User id and sequence combination is found' do
      before { UberLogin::Storage.stub(:find_composite).and_return user }

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