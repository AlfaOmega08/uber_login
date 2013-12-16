require 'spec_helper'

describe UberLogin do
  let(:user) { double(id: 100) }
  let(:controller) { ApplicationController.new }
  let(:session) { controller.session }
  let(:cookies) { controller.cookies }

  describe '#login' do
    context 'remember is false' do
      it 'sets session[:uid]' do
        controller.login(user)
        expect(session[:uid]).to eq 100
      end
    end

    context 'remember is true' do
      it 'sets session[:uid]' do
        controller.login(user, true)
        expect(session[:uid]).to eq 100
      end

      it 'sets the uid cookie' do
        controller.login(user, true)
        expect(cookies[:uid]).to eq 100
      end

      it 'sets the ulogin cookie' do
        controller.login(user, true)
        expect(cookies[:ulogin]).to match(/[a-z0-9+\/]+:[a-z0-9+\/]+/i)
      end

      it 'sets both cookies as persistent' do
        expect(cookies).to receive(:permanent).twice.and_return cookies
        controller.login(user, true)
      end
    end
  end

  describe '#logout' do
    it 'deletes session[:uid]' do
      controller.login(user)
      controller.logout
      expect(session[:uid]).to be_nil
    end

    context 'persistent login was made' do
      before { controller.login(user, true) }

      it 'deletes session[:uid]' do
        controller.logout
        expect(session[:uid]).to be_nil
      end

      it 'deletes login cookies' do
        controller.logout
        expect(cookies[:uid]).to be_nil
        expect(cookies[:ulogin]).to be_nil
      end

      it 'deletes a LoginToken row' do
        expect {
          controller.logout
        }.to change{ LoginToken.count }.by -1
      end
    end
  end

  describe '#save_to_database' do
    it 'saves the triplet to the database' do
      expect_any_instance_of(LoginToken).to receive(:save!)
      controller.send('save_to_database', '100', 'token', 'sequence')
    end
  end
end
