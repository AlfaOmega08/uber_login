require 'uber_login/version'
require 'securerandom'
require 'bcrypt'

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
    session[:uid] = user.id

    if remember
      generate_and_set_cookies(user.id)
    end
  end

  ##
  # Clears session[:uid]
  # If remember cookies were set they're cleared and the token is
  # removed from the database.
  def logout
    session.delete(:uid)
    delete_from_database if cookies[:uid]
    reset_login_cookies
  end

  private
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
    if valid_login_cookies?
      session[:uid] = cookies[:uid]
      generate_new_token
    else
      reset_login_cookies
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

    cookies.permanent[:uid] = uid
    cookies.permanent[:ulogin] = build_login_cookie(sequence, token)
    save_to_database(uid, sequence, token)
  end

  ##
  # Clears +:uid+ and +:ulogin+ cookies
  def reset_login_cookies
    cookies.delete :uid
    cookies.delete :ulogin
  end

  ##
  # Returns true if the cookies are matched with the stored login token
  def valid_login_cookies?
    sequence, token = sequence_and_token_from_cookie
    token_row = LoginToken.find_by(uid: cookies[:uid], sequence: sequence)

    if token_row
      BCrypt::Password.new(token_row.token) == token
    else
      false
    end
  rescue  # ORMs can be configure to throw instead of returning nils
    false
  end

  def generate_sequence_and_token
    # 9 and 21 are both multiple of 3, so we do not get base64 padding (==)
    [ SecureRandom.base64(9), SecureRandom.base64(21) ]
  end

  def build_login_cookie(sequence, token)
    "#{sequence}:#{token}"
  end

  def sequence_and_token_from_cookie
    cookies[:ulogin].split(':')
  end

  def save_to_database(uid, sequence, token)
    token_row = LoginToken.new(
        uid: uid,
        sequence: sequence,
        token: hash_token(token)
    )

    token_row.save!
  end

  def delete_from_database
    sequence = sequence_and_token_from_cookie[0]
    token = LoginToken.find_by(uid: cookies[:uid], sequence: sequence)
    token.destroy
  end

  def class_exists?(class_name)
    klass = Module.const_get(class_name)
    return klass.is_a?(Class)
  rescue NameError
    return false
  end

  def hash_token(token)
    BCrypt::Password.create(token).to_s
  end
end
