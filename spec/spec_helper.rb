$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'uber_login'

class FakeCookieJar < Hash
  def permanent
    self
  end

  def []=(key, val)
    if val.class == Hash
      super(key, val[:value])
    else
      super(key, val)
    end
  end
end

class FakeRequest
  def remote_ip
    '192.168.1.1'
  end

  def user_agent
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1667.0 Safari/537.36"
  end

  def ssl?
    true
  end
end

class ApplicationController
  include UberLogin

  attr_accessor :session
  attr_accessor :cookies
  attr_accessor :request

  def initialize
    @session = {}
    @cookies = FakeCookieJar.new
    @request = FakeRequest.new
  end
end

# This is required to be an ActiveRecord like class
# Mongoid and MongoMapper should be just fine and probably others too.
class LoginToken
  attr_accessor :uid, :sequence, :token
  attr_accessor :ip_address, :os, :browser

  @@count = 0

  def initialize(attributes = {})
    attributes.each do |k, v|
      send("#{k}=", v)
    end
  end

  def save!
    true
    @@count += 1
  end

  def self.count
    @@count
  end

  def destroy
    @@count -= 1
  end

  def self.find_by(hash)
    new
  end

  def self.destroy_all(hash)

  end

  def updated_at
    Time.now - 100
  end
end

class User
  attr_accessor :id

  def initialize(attributes = {})
    attributes.each do |k, v|
      send("#{k}=", v)
    end
  end

  def self.find(id)
    id ? User.new(id: id) : nil
  end
end