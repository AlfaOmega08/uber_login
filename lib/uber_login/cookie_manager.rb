require 'uber_login/storage'
require 'uber_login/token_encoder'
require 'uber_login/token_validator'

##
# This class handles the +:uid+ and +:ulogin+ cookies
# It builds and sets the cookies, clears them, checks for their validity.
module UberLogin
  class CookieManager
    def initialize(cookies, request)
      @cookies = cookies
      @request = request
    end

    ##
    # Sets the +:uid+ and +:ulogin+ cookies for next login
    def persistent_login(uid, composite)
      @cookies.permanent[:uid] = uid
      @cookies.permanent[:ulogin] = TokenEncoder.encode_array composite
    end

    ##
    # Clears +:uid+ and +:ulogin+ cookies
    def clear
      @cookies.delete :uid
      @cookies.delete :ulogin
    end

    ##
    # Returns true if cookies are considered valid from TokenEncoder validation rules
    def valid?
      token_row = Storage.find_composite(@cookies[:uid], @cookies[:ulogin])
      TokenValidator.new(TokenEncoder.token(@cookies[:ulogin]), @request).valid?(token_row)
    rescue
      false
    end

    ##
    # Returns true if the +:uid+ and +:ulogin+ cookies are set
    def login_cookies?
      @cookies[:uid] and @cookies[:ulogin]
    end
  end
end