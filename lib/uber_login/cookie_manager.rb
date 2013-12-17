require 'uber_login/storage'
require 'uber_login/token_encoder'

##
# This class handles the +:uid+ and +:ulogin+ cookies
# It builds and sets the cookies, clears them, checks for their validity.
module UberLogin
  class CookieManager
    def initialize(cookies, request)
      @cookies = cookies
      @request = request
      @validity_checks = [ :token_match ]

      @validity_checks << :ip_equality if UberLogin.configuration.tie_tokens_to_ip
      @validity_checks << :expiration if UberLogin.configuration.token_expiration
    end


    def persistent_login(uid, sequence, token)
      @cookies.permanent[:uid] = uid
      @cookies.permanent[:ulogin] = TokenEncoder.encode(sequence, token)
    end

    ##
    # Clears +:uid+ and +:ulogin+ cookies
    def clear
      @cookies.delete :uid
      @cookies.delete :ulogin
    end

    def valid?
      token_row = Storage.find_composite(@cookies[:uid], @cookies[:ulogin])
      @validity_checks.all? { |check| send(check, token_row) }
    rescue
      false
    end

    # Validity checks

    def token_match(row)
      BCrypt::Password.new(row.token) == TokenEncoder.token(@cookies[:ulogin])
    end

    def ip_equality(row)
      row.ip_address == @request.remote_ip
    end

    def expiration(row)
      row.updated_at >= Time.now - UberLogin.configuration.token_expiration
    end
  end
end