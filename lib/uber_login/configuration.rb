module UberLogin
  class Configuration
    attr_accessor :allow_multiple_login

    def initialize
      self.allow_multiple_login = true
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