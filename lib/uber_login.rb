require 'uber_login/version'
require 'uber_login/cookie_manager'
require 'uber_login/configuration'
require 'securerandom'
require 'bcrypt'
require 'user_agent'

module UberLogin
  ##
  # Returns the logged in user.
  # If session[+:uid+] is set it returns that user.
  # If session[+:uid+] is NOT set but cookies[+:uid+] and cookies[+:ulogin+] ARE:
  #  * It dissects +:ulogin+ into Sequence and Token
  #  * Looks for a LoginToken from UID and Sequence
  #  * Test Token against the stored and strong hashed one
  #  * If they match, session[+:uid+] is set and it returns the +User+
  # If none of the previous cases, +nil+ is returned.
  # If the cookie did not match, they are cleared from the user browser.
  #
  # All the checks are runt only once and the result is cached
  def current_user
    @current_user ||= current_user_uncached
  end

  ##
  # Logs in the given +user+
  # If +remember+ is true all the needed cookies are set.
  # session[+:uid+] is set to user.id
  def login(user, remember = false)
    logout_all unless UberLogin.configuration.allow_multiple_login

    session[:uid] = user.id
    generate_and_set_cookies(user.id) if remember
  end

  ##
  # Clears session[:uid]
  # If remember cookies were set they're cleared and the token is
  # removed from the database.
  def logout
    session.delete(:uid)
    delete_from_database if cookies[:uid]
    cookie_manager.clear
  end

  ##
  # Deletes all "remember me" session for this user from whatever device
  # he/she has ever used to login.
  def logout_all
    LoginToken.find_by(uid: session[:uid]).destroy
    session.delete :uid
    cookie_manager.clear
  end

  private
  def cookie_manager
    @cookie_manager ||= CookieManager.new(cookies, request)
  end

  # See +current_user+
  def current_user_uncached
    login_from_cookies if cookies[:uid] and !session[:uid]
    if session[:uid]
      User.find(session[:uid])
    end
  end

  ##
  # Attempts a login from the +:uid+ and +:ulogin+ cookies.
  def login_from_cookies
    if cookie_manager.valid?
      session[:uid] = cookies[:uid]
      generate_new_token
    else
      cookie_manager.clear
    end
  end

  ##
  # Deletes the current token from the database and creates a new one in place.
  # Sets the user cookies to match the new values
  def generate_new_token
    delete_from_database
    generate_and_set_cookies(cookies[:uid])
  end

  ##
  # Creates a pair of cookies.
  # +:uid+ is set to the user id
  # +:ulogin+ is a composite field made of +:sequence+ and +:token+
  #
  # +:sequence+ is used to choose between all possible user login tokens
  # +:token+ is stored +bcrypt+ed in the database and then compared on login
  def generate_and_set_cookies(uid)
    sequence, token = generate_sequence_and_token
    cookie_manager.persistent_login(uid, sequence, token)
    save_to_database
  end

  ##
  # Creates a LoginToken based on the +uid+, +sequence+ and hashed +token+
  def save_to_database
    token_row = LoginToken.new(
        uid: cookies[:uid],
        sequence: cookie_manager.sequence,
        token: cookie_manager.hashed_token
    )

    set_user_data token_row

    token_row.save!
  end

  ##
  # Removes a LoginToken with +uid+ and +sequence+ taken from the cookies
  def delete_from_database
    sequence = cookie_manager.sequence
    token = LoginToken.find_by(uid: cookies[:uid], sequence: sequence)
    token.destroy
  end

  def generate_sequence_and_token
    # 9 and 21 are both multiple of 3, so we do not get base64 padding (==)
    [ SecureRandom.base64(9), SecureRandom.base64(21) ]
  end

  def set_user_data row
    user_agent = UserAgent.parse(request.user_agent)

    row.ip_address = request.remote_ip if row.respond_to? :ip_address=
    row.os = user_agent.os if row.respond_to? :os=
    row.browser = user_agent.browser + ' ' + user_agent.version if row.respond_to? :browser=
  end
end
