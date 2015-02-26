require 'google/api_client'
require 'date'

START_DATE = "yesterday"
END_DATE = "yesterday"

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
SCHEDULER.every '3h', first_in: 0 do
  client.authorization.fetch_access_token!
  analytics = client.discovered_api('analytics','v3')
  batch = Google::APIClient::BatchRequest.new

  users = 0
  page_views = 0
  unique_page_views = 0
  eligible_users = 0
  ineligible_users = 0
  face_to_face_users = 0
  contact_users = 0

  base = {
    api_method: analytics.data.ga.get,
    parameters: {
      'ids' => "ga:#{GA_VIEW_ID}",
      'start-date' => START_DATE,
      'end-date' => END_DATE,
      'output' => 'dataTable',
      'metrics' => "ga:users, ga:pageviews, ga:uniquePageviews"
    }
  }

  batch.add(base) do |result|
    users = result.data.totalsForAllResults['ga:users'].to_i
    page_views = result.data.totalsForAllResults['ga:pageviews'].to_i
    unique_page_views = result.data.totalsForAllResults['ga:uniquePageviews'].to_i
  end

  eligible = {
    api_method: analytics.data.ga.get,
    parameters: {
      'ids' => "ga:#{GA_VIEW_ID}",
      'start-date' => START_DATE,
      'end-date' => END_DATE,
      'metrics' => "ga:users",
      'filters' => "ga:pagePath=@eligible"
    }
  }

  batch.add(eligible) do |result|
    eligible_users = result.data.totalsForAllResults['ga:users'].to_i
  end

  ineligible = {
    api_method: analytics.data.ga.get,
    parameters: {
      'ids' => "ga:#{GA_VIEW_ID}",
      'start-date' => START_DATE,
      'end-date' => END_DATE,
      'metrics' => "ga:users",
      'filters' => "ga:pagePath=@help-organisations"
    }
  }

  batch.add(ineligible) do |result|
    ineligible_users = result.data.totalsForAllResults['ga:users'].to_i
  end

  face_to_face = {
    api_method: analytics.data.ga.get,
    parameters: {
      'ids' => "ga:#{GA_VIEW_ID}",
      'start-date' => START_DATE,
      'end-date' => END_DATE,
      'metrics' => "ga:users",
      'filters' => "ga:pagePath=@face-to-face"
    }
  }

  batch.add(face_to_face) do |result|
    face_to_face_users = result.data.totalsForAllResults['ga:users'].to_i
  end

  contact = {
    api_method: analytics.data.ga.get,
    parameters: {
      'ids' => "ga:#{GA_VIEW_ID}",
      'start-date' => START_DATE,
      'end-date' => END_DATE,
      'metrics' => "ga:users",
      'filters' => "ga:pagePath=@contact"
    }
  }

  batch.add(contact) do |result|
    contact_users = result.data.totalsForAllResults['ga:users'].to_i
  end

  client.execute(batch)

  send_event('ga_stats', {
    users: users,
    page_views: page_views,
    unique_page_views: unique_page_views,
    eligible_users: eligible_users,
    ineligible_users: ineligible_users,
    face_to_face_users: face_to_face_users,
    contact_users: contact_users
  })
end
