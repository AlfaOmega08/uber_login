module UberLogin
  class Configuration
    def initialize
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