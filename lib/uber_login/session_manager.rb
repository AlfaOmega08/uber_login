require 'uber_login/storage'
require 'uber_login/token_encoder'
require 'uber_login/token_validator'

##
# This class handles the +:uid+ and +:ulogin+ session variables
# It builds and sets the session variables, clears them, checks for their validity.
module UberLogin
  class SessionManager
    def initialize(session, request)
      @session = session
      @request = request
    end

    ##
    # Sets the +:uid+ and +:ulogin+ session variables
    def login(uid, composite)
      @session[:uid] = uid
      @session[:ulogin] = TokenEncoder.encode_array(composite) if UberLogin.configuration.strong_sessions
    end

    ##
    # Clears +:uid+ and +:ulogin+ session variables
    def clear
      @session.delete :uid
      @session.delete :ulogin
    end

    ##
    # Returns true if the session is considered valid from TokenEncoder validation rules
    def valid?
      token_row = Storage.find_composite(@session[:uid], @session[:ulogin])
      TokenValidator.new(TokenEncoder.token(@session[:ulogin]), @request).valid?(token_row)
    rescue
      false
    end
  end
end