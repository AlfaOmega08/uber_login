module UberLogin
  class TokenValidator
    def initialize(token, request)
      @token = token
      @request = request
      @validity_checks = [ :token_match ]
      @validity_checks << :ip_equality if UberLogin.configuration.tie_tokens_to_ip
      @validity_checks << :expiration if UberLogin.configuration.token_expiration
    end

    def valid?(row)
      @validity_checks.all? { |check| send(check, row) }
    end

    private
    def token_match(row)
      BCrypt::Password.new(row.token) == @token
    end

    def ip_equality(row)
      row.ip_address == @request.remote_ip
    end

    def expiration(row)
      row.updated_at >= Time.now - UberLogin.configuration.token_expiration
    end
  end
end