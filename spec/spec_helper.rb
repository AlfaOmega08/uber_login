$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'uber_login'

class FakeCookieJar < Hash
  def permanent
    self
  end
end

class ApplicationController
  include UberLogin

  attr_accessor :session
  attr_accessor :cookies

  def initialize
    @session = {}
    @cookies = FakeCookieJar.new
  end
end

# This is required to be an ActiveRecord like class
# Mongoid and MongoMapper should be just fine and probably others too.
class LoginToken
  attr_accessor :uid, :sequence, :token

  def initialize(attributes)
    attributes.each do |k, v|
      send("#{k}=", v)
    end
  end

  def save!
    true
  end
end