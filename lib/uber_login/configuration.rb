##
# Use this class in app/config/initializers to change configuration parameters.
module UberLogin
  class Configuration
    attr_accessor :allow_multiple_login
    attr_accessor :token_expiration
    attr_accessor :tie_tokens_to_ip

    def initialize
      self.allow_multiple_login = true
      self.token_expiration = nil
      self.tie_tokens_to_ip = false
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