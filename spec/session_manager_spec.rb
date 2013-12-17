require 'spec_helper'

describe UberLogin::SessionManager do
  let(:user) { double(id: 100) }
  let(:controller) { ApplicationController.new }
  let(:session) { controller.session }
  let(:cookies) { controller.cookies }
  let(:session_manager) { UberLogin::SessionManager.new(session, FakeRequest.new) }

  describe '#login' do
    it 'sets the :uid variable' do
      session_manager.login(100, [ 'dead', 'beef' ])
      expect(session[:uid]).to eq 100
    end

    context 'strong_sessions are not enabled' do
      before { UberLogin.configuration.strong_sessions = false }

      it 'does not set the :ulogin cookie' do
        session_manager.login(100, [ 'dead', 'beef' ])
        expect(session[:ulogin]).to be_nil
      end
    end

    context 'strong_sessions are enabled' do
      before { UberLogin.configuration.strong_sessions = true }

      it 'sets the :ulogin cookie' do
        session_manager.login(100, [ 'dead', 'beef' ])
        expect(session[:ulogin]).to_not be_nil
      end
    end
  end

  describe '#clear' do
    before { controller.login(user, true) }

    it 'deletes the :uid variable' do
      session_manager.clear
      expect(session[:uid]).to be_nil
    end

    it 'deletes the :ulogin variable' do
      session_manager.clear
      expect(session[:ulogin]).to be_nil
    end
  end

  describe '#valid?' do
    before { controller.login(user, true) }

    context 'User id and sequence combination is found' do
      before { UberLogin::Storage.stub(:find_composite).and_return user }

      context 'all checks return true' do
        before { UberLogin::TokenValidator.any_instance.stub(:valid?).and_return true }

        it 'returns true' do
          expect(session_manager.valid?).to be_true
        end
      end

      context 'any check fails' do
        before { UberLogin::TokenValidator.any_instance.stub(:valid?).and_return false }

        it 'returns false' do
          expect(session_manager.valid?).to be_false
        end
      end
    end

    context 'User id and sequence combination is not found' do
      before { UberLogin::Storage.stub(:find).and_return nil }

      it 'returns false' do
        expect(session_manager.valid?).to be_false
      end
    end
  end
end