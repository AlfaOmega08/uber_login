##
# Use this class in app/config/initializers to change configuration parameters.
module UberLogin
  class Configuration
    # Allow the same user to login on many different devices.
    # This is only effective if strong_sessions is +true+. Otherwise it only affects persistent logins.
    # Defaults to +true+
    attr_accessor :allow_multiple_login

    # The validity of a login token (be it a cookie or session token). Tokens whose age is larger than that are
    # considered expired and not valid.
    # Defaults to +nil+ (no expiration)
    attr_accessor :token_expiration

    # A token is considered valid only if brought by the same IP address to which it was assigned.
    # This would provide a very effective solution against Cookie sniffing, unless it would affect legitimate users a
    # lot. 99% of ISPs will change user IP on each connecition. Also mobile devices might change IP many times in a
    # hour. Setting this to true may disconnect many mobile users each minute.
    # Only decently usable in a private network where all IPs are static (or if you're really paranoid).
    # Defaults to +false+
    attr_accessor :tie_tokens_to_ip

    # Non persistent sessions are saved to the database too. On each request the session token is checked against the
    # database just like the cookies one. It won't refresh it, however.
    # This allows you to do nice things, like logging out users, just by removing the token from the database. Or having
    # a full list of open sessions of any kind on any device.
    # Even though this is strongly suggested to be +true+, it might impact performance, issuing a query on almost
    # each page load. Be sure to index :uid and :sequence together on the +login_tokens+ table.
    attr_accessor :strong_sessions

    # If your User model is named something different than User, you can specify your user model here.
    attr_accessor :user_class

    def initialize
      self.allow_multiple_login = true
      self.token_expiration = nil
      self.tie_tokens_to_ip = false
      self.strong_sessions = true
      self.user_class = "User"
    end
  end

  def self.configure
    yield(configuration) if block_given?
  end

  private
  def self.configuration
    @configuration ||= Configuration.new
  end
end