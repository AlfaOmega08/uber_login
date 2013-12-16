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

  describe '#current_user_uncached' do
    context 'session[:uid] is set' do
      before { session[:uid] = 100 }

      it 'returns an user object with that uid' do
        expect(controller.send(:current_user_uncached).id).to eq 100
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
          before { controller.stub(:valid_login_cookies?).and_return true }

          it 'returns an user object with that uid' do
            expect(controller.send(:current_user_uncached).id).to eq "100"
          end

          it 'deletes the token from the database' do
            expect_any_instance_of(LoginToken).to receive(:destroy)
            controller.send(:current_user_uncached)
          end

          it 'creates a new token for the next login' do
            expect_any_instance_of(LoginToken).to receive(:save!)
            controller.send(:current_user_uncached)
          end

          it 'refreshes the cookie' do
            controller.send(:current_user_uncached)
            expect(cookies[:uid]).to eq "100"
            expect(cookies[:ulogin]).to_not eq "whatever:beef"
          end
        end

        context 'the cookies are not valid' do
          before { controller.stub(:valid_login_cookies?).and_return false }

          it 'returns nil' do
            expect(controller.send(:current_user_uncached)).to be_nil
          end

          it 'clears the cookies for this user' do
            controller.send(:current_user_uncached)
            expect(cookies[:uid]).to be_nil
            expect(cookies[:ulogin]).to be_nil
          end
        end
      end

      context 'cookies are not set' do
        it 'returns nil' do
          expect(controller.send(:current_user_uncached)).to be_nil
        end
      end
    end
  end

  describe '#valid_login_cookies?' do
    before {
      cookies[:uid] = 100
      cookies[:ulogin] = "dead:beef"
    }

    context 'User id and sequence combination is not found' do
      before { LoginToken.stub(:find_by).and_return nil }

      it 'returns false' do
        expect(controller.send(:valid_login_cookies?)).to be_false
      end
    end

    context 'User id and sequence combination is found' do
      before { LoginToken.stub(:find_by).and_return LoginToken.new(token: BCrypt::Password.create("beef")) }

      context 'The token is validated' do
        it 'returns true' do
          expect(controller.send(:valid_login_cookies?)).to be_true
        end
      end

      context 'The token is not validated' do
        before { BCrypt::Password.any_instance.stub(:==).and_return false }

        it 'returns false' do
          expect(controller.send(:valid_login_cookies?)).to be_false
        end
      end
    end
  end
end
