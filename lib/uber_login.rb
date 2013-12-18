require 'uber_login/version'
require 'uber_login/cookie_manager'
require 'uber_login/configuration'
require 'uber_login/session_manager'
require 'securerandom'
require 'bcrypt'
require 'user_agent'

module UberLogin
  ##
  # Returns the logged in user.
  # If session[+:uid+] is set:
  #  * if strong sessions are enabled, it checks for session[+:ulogin+] and tests its value against the database
  #  * if strong sessions are not enabled, it only returns the corresponding +User+
  #
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
  # If strong sessions are enabled session[+:ulogin+] is set to the same value that cookies[+:ulogin+] would have
  def login(user, remember = false)
    logout_all unless UberLogin.configuration.allow_multiple_login

    if strong_sessions or remember
      composite = generate_and_save_token(user.id)
      cookie_manager.persistent_login(user.id, composite) if remember
    else
      composite = nil
    end

    session_manager.login(user.id, composite)
  end

  ##
  # If sequence is nil it clears the current session and if remember cookies are in place they're cleared
  # and corresponding token removed from the database.
  # If sequence is not nil it only removes the sequence and token from the database.
  def logout(sequence = nil)
    if sequence.nil? or sequence == current_sequence
      delete_from_database if cookies[:uid] or strong_sessions
      session_manager.clear
      cookie_manager.clear
    else
      delete_from_database(sequence)
    end
  end

  ##
  # Deletes all "remember me" session for this user from whatever device
  # he/she has ever used to login.
  def logout_all
    Storage.delete_all session[:uid]
    session_manager.clear
    cookie_manager.clear
  end

  private
  def cookie_manager
    @cookie_manager ||= CookieManager.new(cookies, request)
  end

  def session_manager
    @session_manager ||= SessionManager.new(session, request)
  end

  # See +current_user+
  def current_user_uncached
    if session[:uid]
      logout if strong_sessions and !session_manager.valid?
    else
      login_from_cookies if cookie_manager.login_cookies?
    end

    User.find(session[:uid]) rescue nil
  end

  ##
  # Attempts a login from the +:uid+ and +:ulogin+ cookies.
  def login_from_cookies
    if cookie_manager.valid?
      session[:uid] = cookies[:uid]
      generate_new_token
      session[:ulogin] = cookies[:ulogin]
      session[:uid]
    else
      cookie_manager.clear
      nil
    end
  end

  ##
  # Deletes the current token from the database and creates a new one in place.
  # Sets the user cookies to match the new values
  def generate_new_token
    delete_from_database
    composite = generate_and_save_token(cookies[:uid])
    cookie_manager.persistent_login(cookies[:uid], composite)
  end

  ##
  # Creates a pair of cookies.
  # +:uid+ is set to the user id
  # +:ulogin+ is a composite field made of +:sequence+ and +:token+
  #
  # +:sequence+ is used to choose between all possible user login tokens
  # +:token+ is stored +bcrypt+ed in the database and then compared on login
  def generate_and_save_token(uid)
    sequence, token = TokenEncoder.generate
    save_to_database(uid, sequence, token)
    [ sequence, token ]
  end

  ##
  # Creates a LoginToken based on the +uid+, +sequence+ and hashed +token+
  def save_to_database(uid, sequence, token)
    token_row = Storage.build(uid, TokenEncoder.encode(sequence, token))
    set_user_data token_row

    token_row.save!
  end

  ##
  # Removes a LoginToken with current +uid+ and given +sequence+
  # If +sequence+ is nil it is taken from the cookies.
  #
  # A token might have already been destroyed from another client with the intent of disconnecting
  # the current session.
  def delete_from_database(sequence = nil)
    sequence = sequence || current_sequence
    token = Storage.find(cookies[:uid] || session[:uid], sequence)
    token.destroy if token
  end

  def set_user_data(row)
    user_agent = UserAgent.parse(request.user_agent)

    row.ip_address = request.remote_ip if row.respond_to? :ip_address=
    row.os = (user_agent.os || '') if row.respond_to? :os=
    row.browser = (user_agent.browser || '') + ' ' + user_agent.version if row.respond_to? :browser=
  end

  def strong_sessions
    UberLogin.configuration.strong_sessions
  end

  def current_sequence
    TokenEncoder.sequence(cookies[:ulogin] || session[:ulogin])
  end
end
