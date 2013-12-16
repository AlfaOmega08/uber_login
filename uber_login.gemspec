# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uber_login/version'

Gem::Specification.new do |spec|
  spec.name          = 'uber_login'
  spec.version       = UberLogin::VERSION
  spec.author        = 'Francesco Boffa'
  spec.email         = 'fra.boffa@gmail.com'
  spec.description   = 'Login and logout management with secure "remember me" capabilities'
  spec.summary       = 'Tired of rewriting the login, logout and current_user methods for the millionth time? Scared of all the security concerns of writing your own authentication methods? This gem will solve all of this problems and still leave you the control over your application.'
  spec.homepage      = 'https://github.com/AlfaOmega08/uber_login'
  spec.license       = 'MIT'

  spec.files = Dir.glob("lib/**/*")
  spec.test_files = Dir.glob("spec/**/*")
  spec.require_paths = ["lib"]
end
