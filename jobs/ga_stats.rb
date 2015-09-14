require 'google/api_client'
require 'date'

START_DATE = (Time.now - (24*60*60) * 2).strftime( "%Y-%m-%d" ) # day before yesterday
END_DATE = (Time.now - (24*60*60)).strftime( "%Y-%m-%d" ) # yesterday

# Get the Google API client
client = Google::APIClient.new(
  application_name: 'CLA Public Dashboard',
  application_version: '0.01'
)

def add_to_batch(batch, api, metric)
  batch.add({
    api_method: api.data.ga.get,
    parameters: {
      'ids' => "ga:#{GA_VIEW_ID}",
      'start-date' => START_DATE,
      'end-date' => END_DATE,
      'metrics' => "ga:#{metric}",
      'dimensions' => 'ga:date'
    }
  }) do |result|
    yesterday = result.data.rows.last.last.to_f.round(2)
    day_before = result.data.rows.first.last.to_f.round(2)
    change = 'same'

    ratio = yesterday / day_before

    if ratio > 1
      change = 'up'
    elsif ratio < 1
      change = 'down'
    end

    yield({
      value: yesterday,
      prev: day_before,
      change: change
    })
  end
end

# Load your credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(GA_KEY_FILE, 'notasecret')
client.authorization = Signet::OAuth2::Client.new(
  token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
  audience: 'https://accounts.google.com/o/oauth2/token',
  scope: 'https://www.googleapis.com/auth/analytics.readonly',
  issuer: GA_SERVICE_ACCOUNT_EMAIL,
  signing_key: key)

# Start the scheduler
SCHEDULER.every '3h', first_in: 0 do
  client.authorization.fetch_access_token!
  analytics = client.discovered_api('analytics','v3')
  batch = Google::APIClient::BatchRequest.new

  result = {}

  # Sessions
  add_to_batch(batch, analytics, 'sessions') {|r| result[:sessions] = r}
  # Eligible rate
  add_to_batch(batch, analytics, 'goal8ConversionRate') {|r| result[:eligible] = r}
  # Incomplete (skip to contact)
  add_to_batch(batch, analytics, 'goal6ConversionRate') {|r| result[:incomplete] = r}
  # Ineligible (Scope)
  add_to_batch(batch, analytics, 'goal1ConversionRate') {|r| result[:ineligible_scope] = r}
  # Ineligible (Means)
  add_to_batch(batch, analytics, 'goal2ConversionRate') {|r| result[:ineligible_means] = r}
  # Family mediation
  add_to_batch(batch, analytics, 'goal5ConversionRate') {|r| result[:family_mediation] = r}
  # Provisional (need more info)
  add_to_batch(batch, analytics, 'goal7ConversionRate') {|r| result[:provisional] = r}
  # Face-to-face (Scope)
  add_to_batch(batch, analytics, 'goal3ConversionRate') {|r| result[:f2f_scope] = r}
  # Face-to-face (Means)
  add_to_batch(batch, analytics, 'goal4ConversionRate') {|r| result[:f2f_means] = r}

  client.execute(batch)

  send_event('ga_stats', result)
end
