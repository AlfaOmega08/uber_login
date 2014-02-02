# UberLogin

UberLogin was made to have simpler login and logout logic. It is very difficult to build a strong authentication
system. If you can't use Devise, AuthLogic, Clearance, or you just want to be free of those heavy gems and yet
be safe with your login, this gem is for you.

UberLogin does not take care of user registration, password validation or recovery (may I suggest
[has_editable_password](https://github.com/AlfaOmega08/has_editable_password)?). It does not take care of login throttling
or all the logging related to log in.

UberLogin only exposes three methods: login, logout and logout_all. Assuming you already authenticated your user,
using email or username, or ID number, password or SMS with two phase authentication, retina or finger scansion, you will now call:

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

Checkout the [uber_login demo app](https://github.com/AlfaOmega08/uber_login_demo) to see uber_login in action.

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
any kind on any device. Even though this is strongly suggested to be *true*, it might impact performance, issuing a
query on almost each page load. Be sure to index :uid and :sequence together on the *login_tokens* table.

### Callbacks
UberLogin provides [before after around]_login and [before after around]_logout callbacks. Not all logins come from a
form, where you explicitly call *login*. Some logins come from cookies, and that happens automagically when you call
*current_user*. So using an after_login callback can be useful to store login logs. You can use *persistent_login?* to
see whether the current session is persistent or not.

## Security
On every login the session is reset. This means that the session ID is regenerated and the content of the session is lost.
Keep this in mind when using UberLogin. This is to prevent Session Fixation.

UberLogin works using the triplet [UID, Sequence, Token] to identify the user. These are stored in the session, or in cookies,
and a copy in the database. In particular the Token is hashed with *bcrypt* before being stored in the database. This,
in case of a direct attack to the database, prevents the attacker from having a list of usable login triplets. The Token
is only valid when presented with the corresponding UID and Sequence values. The sequence value is not hashed and it's only
purpose is to differentiate the user between multiple logins.

For example the same user might log in from it's Android Phone, Chrome on a PC and Firefox on another. The three logins
will have different Sequence values.

UberLogin always uses the HttpOnly flag on cookies to prevent XSS attacks on the login cookies. However Session Hijacking
is only truly prevented if you use SSL on each and every request to the website. This is rule #1 for any website having
a login form. Without SSL, not only the attacker can easily read the Session ID or content, but can also intercept the
login data (email/password) when submitted from the login page.

### More security
You can enforce stronger security by using the UberLogin options. However all of that have side effects. Disallowing
multiple logins looks good for offices, where an employee needs only one session at time. On social websites it might be
a disaster. Also in case of a successful attack, the login made by the attacker would disconnect the legitimate user.

Tying IPs to tokens is only viable if you're sure that all of your users have static IP addresses. Otherwise they may
be affected by "random" logouts.

Having "strong sessions" will give you the power to logout sessions other than the current, but it will also add a query
overhead on each request. If you're not interested in this kind of utility, or you see that the overhead is unacceptable
you can simply opt-out strong sessions.

In the future we'll probably add the possibility of tying the login token to the User Agent. The user would be "random
disconnected" only if the browser gets updated. However an attacker would need to guess the exact user agent string
in order to reuse a stolen triplet.

Also, whether you're using HTTPS or not (please, do!), consider not using Session CookieStorage, or at least ensure
that the session is signed and crypted.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
