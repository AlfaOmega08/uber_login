class CookieManager
  def initialize(cookies, request)
    @cookies = cookies
    @request = request
  end

  ##
  # Clears +:uid+ and +:ulogin+ cookies
  def clear
    @cookies.delete :uid
    @cookies.delete :ulogin
  end

  def valid?
    sequence, token = sequence_and_token
    token_row = LoginToken.find_by(uid: @cookies[:uid], sequence: sequence)

    return false unless token_match(token_row.token, token)

    if UberLogin.configuration.tie_token_to_ip
      if token_row.ip_address != @request.remote_ip
        return false
      end
    end

    if expired?(token_row)
      token_row.destroy
      return false
    end

    true
  rescue
    false
  end

  def hashed_token
    BCrypt::Password.create(token).to_s
  end

  def token_match(hashed, clear)
    BCrypt::Password.new(hashed) == clear
  end

  def persistent_login(uid, sequence, token)
    @cookies.permanent[:uid] = uid
    @cookies.permanent[:ulogin] = ulogin_cookie(sequence, token)
  end

  def ulogin_cookie(sequence, token)
    sequence + ':' + token
  end

  def sequence_and_token
    @cookies[:ulogin].split(':')
  end

  def sequence
    sequence_and_token[0]
  end

  def token
    sequence_and_token[1]
  end

  def expired?(row)
    if UberLogin.configuration.login_token_expiration
      row.updated_at < Time.now - UberLogin.configuration.login_token_expiration
    else
      false
    end
  end
end