require 'uber_login/version'
require 'securerandom'
require 'bcrypt'

module UberLogin
  def login(user, remember = false)
    session[:uid] = user.id

    if remember
      sequence, token = generate_sequence_and_token

      cookies.permanent[:uid] = user.id
      cookies.permanent[:ulogin] = build_login_cookie(sequence, token)
      save_to_database(user.id, sequence, token)
    end
  end

  private
  def generate_sequence_and_token
    # 9 and 21 are both multiple of 3, so we do not get base64 padding (==)
    [ SecureRandom.base64(9), SecureRandom.base64(21) ]
  end

  def build_login_cookie(sequence, token)
    "#{sequence}:#{token}"
  end

  def save_to_database(uid, sequence, token)
    token_row = LoginToken.new(
        uid: uid,
        sequence: sequence,
        token: hash_token(token)
    )

    token_row.save!
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
