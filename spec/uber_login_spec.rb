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

      context 'sessions have stored tokens' do
        before { UberLogin.configuration.strong_sessions = true }

        it 'saves a token to database' do
          expect_any_instance_of(LoginToken).to receive :save!
          controller.login(user)
        end

        it 'sets session[:ulogin]' do
          controller.login(user)
          expect(session[:ulogin]).to_not be_nil
        end
      end

      context 'sessions do not have stored tokens' do
        before { UberLogin.configuration.strong_sessions = false }

        it 'does not save a token to database' do
          expect_any_instance_of(LoginToken).to_not receive :save!
          controller.login(user)
        end

        it 'does not set session[:ulogin]' do
          controller.login(user)
          expect(session[:ulogin]).to be_nil
        end
      end

      it 'runs the :login callbacks' do
        expect(controller).to receive(:run_callbacks).with(:login)
        controller.login(user)
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
        expect(cookies[:ulogin]).to match(/[a-z0-9_\-]+:[a-z0-9+\/]+/i)
      end

      it 'sets both cookies as persistent' do
        expect(cookies).to receive(:permanent).twice.and_return cookies
        controller.login(user, true)
      end
    end

    context 'only one session is allowed per user' do
      before { UberLogin.configuration.allow_multiple_login = false }

      it 'clears all the other tokens' do
        expect(LoginToken).to receive :destroy_all
        controller.login(user)
      end
    end
  end

  describe '#logout' do
    before { controller.login(user, true) }

    context 'sequence is nil' do
      it 'deletes session[:uid]' do
        controller.logout
        expect(session[:uid]).to be_nil
      end

      it 'deletes session[:ulogin]' do
        controller.logout
        expect(session[:ulogin]).to be_nil
      end

      it 'deletes cookies[:uid]' do
        controller.logout
        expect(cookies[:uid]).to be_nil
      end

      it 'deletes cookies[:ulogin]' do
        controller.logout
        expect(cookies[:ulogin]).to be_nil
      end

      context 'persistent login was made' do
        it 'deletes a LoginToken row' do
          expect {
            controller.logout
          }.to change{ LoginToken.count }.by -1
        end
      end

      it 'runs the :logout callbacks' do
        expect(controller).to receive(:run_callbacks).with(:logout)
        controller.logout
      end
    end

    context 'sequence is equal to current user sequence' do
      it 'deletes session[:uid]' do
        controller.logout(UberLogin::TokenEncoder.sequence(cookies[:ulogin]))
        expect(session[:uid]).to be_nil
      end

      it 'deletes session[:ulogin]' do
        controller.logout(UberLogin::TokenEncoder.sequence(cookies[:ulogin]))
        expect(session[:ulogin]).to be_nil
      end

      it 'deletes cookies[:uid]' do
        controller.logout(UberLogin::TokenEncoder.sequence(cookies[:ulogin]))
        expect(cookies[:uid]).to be_nil
      end

      it 'deletes cookies[:ulogin]' do
        controller.logout(UberLogin::TokenEncoder.sequence(cookies[:ulogin]))
        expect(cookies[:ulogin]).to be_nil
      end

      context 'persistent login was made' do
        it 'deletes a LoginToken row' do
          expect {
            controller.logout(UberLogin::TokenEncoder.sequence(cookies[:ulogin]))
          }.to change{ LoginToken.count }.by -1
        end
      end
    end

    context 'sequence is not nil' do
      it 'does not clear session[:uid]' do
        controller.logout('sequence')
        expect(session[:uid]).to_not be_nil
      end

      it 'does not clear cookies[:uid]' do
        controller.logout('sequence')
        expect(cookies[:uid]).to_not be_nil
      end

      it 'does not clear cookies[:ulogin]' do
        controller.logout('sequence')
        expect(cookies[:ulogin]).to_not be_nil
      end

      it 'deletes a LoginToken row' do
        expect {
          controller.logout('sequence')
        }.to change{ LoginToken.count }.by -1
      end
    end
  end

  describe '#logout_all' do
    before { controller.login(user, true) }

    it 'deletes session[:uid]' do
      controller.logout_all
      expect(session[:uid]).to be_nil
    end

    it 'deletes session[:ulogin]' do
      controller.logout_all
      expect(session[:ulogin]).to be_nil
    end

    it 'deletes cookies[:uid]' do
      controller.logout_all
      expect(cookies[:uid]).to be_nil
    end

    it 'deletes cookies[:ulogin]' do
      controller.logout_all
      expect(cookies[:ulogin]).to be_nil
    end
    it 'deletes any token associated with the user' do
      expect(LoginToken).to receive :destroy_all
      controller.logout_all
    end
  end

  describe '#current_user' do
    context 'session[:uid] is set' do
      before {
        session[:uid] = 100
        session[:ulogin] = 'dead:beef'
      }

      it 'returns an user object with that uid' do
        expect(controller.current_user.id).to eq 100
      end
    end

    context 'session[:uid] is nil' do
      before { session[:uid] = nil }

      context 'cookies[:uid] and cookies[:ulogin] are set' do
        before {
          cookies[:uid] = "100"
          cookies[:ulogin] = "whatever:beef"
        }

        context 'the cookies are valid' do
          before { UberLogin::CookieManager.any_instance.stub(:valid?).and_return true }

          it 'runs the :login callbacks' do
            expect(controller).to receive(:run_callbacks)
            controller.login(user, true)
          end

          it 'returns an user object with that uid' do
            expect(controller.current_user.id).to eq "100"
          end

          it 'deletes the token from the database' do
            expect_any_instance_of(LoginToken).to receive(:destroy)
            controller.current_user
          end

          it 'creates a new token for the next login' do
            expect_any_instance_of(LoginToken).to receive(:save!)
            controller.current_user
          end

          it 'refreshes the cookie' do
            controller.current_user
            expect(cookies[:uid]).to eq "100"
            expect(cookies[:ulogin]).to_not eq "whatever:beef"
          end
        end

        context 'the cookies are not valid' do
          before { UberLogin::CookieManager.any_instance.stub(:valid?).and_return false }

          it 'returns nil' do
            expect(controller.current_user).to be_nil
          end

          it 'clears the cookies for this user' do
            controller.current_user
            expect(cookies[:uid]).to be_nil
            expect(cookies[:ulogin]).to be_nil
          end
        end
      end

      context 'cookies are not set' do
        it 'returns nil' do
          expect(controller.current_user).to be_nil
        end
      end
    end
  end
end
