require 'uber_login/version'
require 'securerandom'
require 'bcrypt'

module UberLogin
  def current_user
    @current_user ||= current_user_uncached
  end

  def current_user_uncached
    login_from_cookies if cookies[:uid] and !session[:uid]
    if session[:uid]
      User.find(session[:uid])
    end
  end

  def login(user, remember = false)
    session[:uid] = user.id

    if remember
      generate_and_set_cookies(user.id)
    end
  end

  def logout
    session.delete(:uid)

    delete_from_database if cookies[:uid]

    reset_login_cookies
  end

  private
  def login_from_cookies
    if valid_login_cookies?
      session[:uid] = cookies[:uid]
      generate_new_token
    else
      reset_login_cookies
    end
  end

  def generate_new_token
    delete_from_database
    generate_and_set_cookies(cookies[:uid])
  end

  def generate_and_set_cookies(uid)
    sequence, token = generate_sequence_and_token

    cookies.permanent[:uid] = uid
    cookies.permanent[:ulogin] = build_login_cookie(sequence, token)
    save_to_database(uid, sequence, token)
  end

  def reset_login_cookies
    cookies.delete :uid
    cookies.delete :ulogin
  end

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
