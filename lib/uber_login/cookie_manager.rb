##
# This class handles the +:uid+ and +:ulogin+ cookies
# It builds and sets the cookies, clears them, checks for their validity.
class CookieManager
  def initialize(cookies, request)
    @cookies = cookies
    @request = request
    @validity_checks = [ :token_match ]

    @validity_checks << :ip_equality if UberLogin.configuration.tie_tokens_to_ip
    @validity_checks << :expiration if UberLogin.configuration.token_expiration
  end

  ##
  # Clears +:uid+ and +:ulogin+ cookies
  def clear
    @cookies.delete :uid
    @cookies.delete :ulogin
  end

  def valid?
    token_row = LoginToken.find_by(uid: @cookies[:uid], sequence: sequence)
    @validity_checks.all? { |check| send(check, token_row) }
  rescue
    false
  end

  def hashed_token
    BCrypt::Password.create(token).to_s
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

  # Validity checks

  def token_match(row)
    BCrypt::Password.new(row.token) == token
  end

  def ip_equality(row)
    row.ip_address == @request.remote_ip
  end

  def expiration(row)
    row.updated_at >= Time.now - UberLogin.configuration.token_expiration
  end
end