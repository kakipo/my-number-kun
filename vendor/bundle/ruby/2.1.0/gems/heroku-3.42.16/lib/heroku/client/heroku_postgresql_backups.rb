class Heroku::Client::HerokuPostgresqlApp

  Version = 11

  include Heroku::Helpers

  def self.headers
    Heroku::Client::HerokuPostgresql.headers
  end

  def initialize(app_name)
    @app_name = app_name
  end

  def transfers
    http_get "#{@app_name}/transfers"
  end

  def transfers_get(id, verbose=false)
    http_get "#{@app_name}/transfers/#{URI.encode(id.to_s)}?verbose=#{verbose}"
  end

  def transfers_delete(id)
    http_delete "#{@app_name}/transfers/#{URI.encode(id.to_s)}"
  end

  def transfers_cancel(id)
    http_post "#{@app_name}/transfers/#{URI.encode(id.to_s)}/actions/cancel"
  end

  def transfers_public_url(id)
    http_post "#{@app_name}/transfers/#{URI.encode(id.to_s)}/actions/public-url"
  end

  def heroku_postgresql_host
    if ENV['SHOGUN']
      "shogun-#{ENV['SHOGUN']}.herokuapp.com"
    else
      determine_host(ENV["HEROKU_POSTGRESQL_HOST"], "postgres-api.heroku.com")
    end
  end

  def heroku_postgresql_resource
    RestClient::Resource.new(
      "https://#{heroku_postgresql_host}/client/v11/apps",
      :user => Heroku::Auth.user,
      :password => Heroku::Auth.password,
      :headers => self.class.headers
      )
  end

  def http_get(path)
    checking_client_version do
      retry_on_exception(RestClient::Exception) do
        response = heroku_postgresql_resource[path].get
        display_heroku_warning response
        sym_keys(json_decode(response.to_s))
      end
    end
  end

  def http_post(path, payload = {})
    checking_client_version do
      response = heroku_postgresql_resource[path].post(json_encode(payload))
      display_heroku_warning response
      sym_keys(json_decode(response.to_s))
    end
  end

  def http_delete(path)
    checking_client_version do
      response = heroku_postgresql_resource[path].delete
      display_heroku_warning response
      sym_keys(json_decode(response.to_s))
    end
  end

  def display_heroku_warning(response)
    warning = response.headers[:x_heroku_warning]
    display warning if warning
    response
  end

  private

  def determine_host(value, default)
    if value.nil?
      default
    else
      "#{value}.herokuapp.com"
    end
  end

  def sym_keys(c)
    if c.is_a?(Array)
      c.map { |e| sym_keys(e) }
    else
      c.inject({}) do |h, (k, v)|
        h[k.to_sym] = v; h
      end
    end
  end

  def checking_client_version
    begin
      yield
    rescue RestClient::BadRequest => e
      if message = json_decode(e.response.to_s)["upgrade_message"]
        abort(message)
      else
        raise e
      end
    end
  end
end
