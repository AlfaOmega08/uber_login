# UberLogin

UberLogin was made to have simpler login and logout controllers. It is very difficult to have a secure authentication
system. And when you can't use Devise, AuthLogic, Clearance, or if you just want to be free of those heavy gems and yet
be safe with your login.

How you register users is not UberLogin problem. Password validation or recovery either (may I suggest
[has_editable_password](https://github.com/AlfaOmega08/has_editable_password)?).

UberLogin exposes only three methods: login, logout and logout_all. Assuming you already authenticated your user,
using email or username, or ID number, password or SMS with two phase authentication, you will now call:

    login(user)

If you want persistent logins ("remember me") just pass *true* as second argument:

    login(user, true) # persistent login

When the user hits the logout button just call:

    logout

If the user has multiple persistent logins on many different machines and you (or he) wants to logout them all:

    logout_all

Also the standard `current_user` method is available.

## Installation

Add this line to your application's Gemfile:

    gem 'uber_login'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install uber_login

Now add this line in `ApplicationController`:

    include UberLogin

To work UberLogin requires a table (or a collection if you came from **MongoDB**). Generate it:

    rails g model add_login_tokens uid:integer, sequence:string, token:string

On MongoDB you probably want uid to be a string.

Adding a composite index on (uid, sequence) will speed things up.

If the login_tokens table has `ip_address`, `os` or `browser` fields UberLogin will automatically fill those fields
on persistent login. These can be used for data analysis or to enforce tokens to came from the same IP/OS/Browser combination
(a nice solution to cookie stealing, but would also prevent legitimate users who often change IP during the day to be disconnected).

Prevent replay attacks by using HTTPS on each and every single page of your application or, at least, set
session_storage to active_record_storage, memcached_storage, or any other kind of non client storage like mongoid_storage.

uber_login will always set any cookie with the httponly flag. If HTTPS is detected cookies are set with the secure flag too.

## Usage

Checkout the [uber_login demo app](https://github.com/AlfaOmega08/uber_login_demo)?) to see uber_login in action.

    class SessionController < ApplicationController
      def create
        user = User.find_by_email(params[:email])
        if user.authenticate(params[:password])
          login(user, params[:remember_me])
        else
          render :new
        end
      end

      def destroy
        logout
        redirect_to root_path
      end
    end

UberLogin is also configurable. Create a `config/initializers/uber_login.rb` file with the following contents:

    UberLogin.configure do |config|
      config.allow_multiple_login = true
      config.token_expiration = nil
      config.tie_tokens_to_ip = false
      config.strong_sessions = true
    end

Those are the default values.

You can `tie_tokens_to_ip` to enhance your security and prevent even legitimate user to log in in some situations
(read the Installation section).

You can set a `token_expiration`. If the tokens are older than that, they're not considered valid anymore.

    config.token_expiration = 1.month

You can set `allow_multiple_login` to false to prevent multiple persistent login. That is... a login from a machine
will clear all other logins on any other machine.

`strong_sessions` will make non persistent sessions to be saved in the database too. On each request the session token
is checked against the database just like the cookies one. It won't refresh it, however. This allows you to do nice
things, like logging out users, just by removing the token from the database. Or having a full list of open sessions of
any kind on any device. Even though this is strongly suggested to be +true+, it might impact performance, issuing a
query on almost each page load. Be sure to index :uid and :sequence together on the +login_tokens+ table.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
