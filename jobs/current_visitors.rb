require 'google/api_client'
require 'date'


# Get the Google API client
client = Google::APIClient.new(
  application_name: 'CLA Public Dashboard',
  application_version: '0.01'
)

visitors = []

# Load your credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(GA_KEY_FILE, 'notasecret')
client.authorization = Signet::OAuth2::Client.new(
  token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
  audience: 'https://accounts.google.com/o/oauth2/token',
  scope: 'https://www.googleapis.com/auth/analytics.readonly',
  issuer: GA_SERVICE_ACCOUNT_EMAIL,
  signing_key: key)

# Start the scheduler
SCHEDULER.every '5s', first_in: 0 do
  client.authorization.fetch_access_token!
  analytics = client.discovered_api('analytics','v3')

  response = client.execute(api_method: analytics.data.realtime.get, parameters: {
    'ids' => "ga:#{GA_VIEW_ID}",
    'metrics' => "rt:activeVisitors",
    'dimensions' => 'rt:browser'
  })

  visitors << { x: Time.now.to_i, y: response.data.totalsForAllResults['rt:activeVisitors'].to_i }
  browsers = response.data.rows.map { |i| { browser: i[0], visitors: i[1] } }

  # Limit history to 100 refreshes
  if visitors.size > 100
    visitors.shift
  end

  send_event('visitor_count_real_time', points: visitors, browsers: browsers)
end
