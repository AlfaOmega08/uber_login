module UberLogin
  class Configuration
    attr_accessor :allow_multiple_login
    attr_accessor :login_token_expiration

    def initialize
      self.allow_multiple_login = true
      self.login_token_expiration = nil
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