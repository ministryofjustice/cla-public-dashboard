require 'net/http'
require 'json'

JOBS = [
  { label: 'Develop',     name: 'cla_public-DEVELOP', uri: JENKINS_URI },
  { label: 'Master',      name: 'cla_public-MASTER', uri: JENKINS_URI },
]

DEPLOYS = [
  { label: 'Staging',     name: 'cla_public-DEPLOY', uri: JENKINS_URI, env: 'staging' },
  { label: 'Production',  name: 'cla_public-DEPLOY', uri: JENKINS_URI, env: 'prod' }
]

REQUEST_STR = "/api/json?tree=jobs[name,color,number,lastBuild[number,timestamp],healthReport[*]]"
DEPLOY_REQUEST_STRING = "/api/json?tree=builds[number,timestamp,result,description,actions[parameters[name,value]]]"

def get_jobs(jobs)
  grouped_jobs = jobs.group_by { |j| j[:uri] }
  results = []
  jenkins_jobs = []

  def get_request(uri, request_str)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(request_str)

    if JENKINS_AUTH['name']
      request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
    end

    http.request(request)
  end

  grouped_jobs.each do |uri, group_jobs|
    response = get_request(uri, REQUEST_STR)

    jenkins_jobs << JSON.parse(response.body)['jobs'].select do |job|
      jobs.map { |j| j[:name] }.include?(job['name'])
    end
  end

  # Include label from JOBS constant and add `status` property
  JOBS.each do |job|
    result = jenkins_jobs.flatten.select { |j| j['name'] == job[:name] }.first
    result['label'] = job[:label]

    status = case result['color']
    when 'blue'
      { type: 'success', icon: 'success' }
    when 'blue_anime'
      { type: 'success', icon: 'building' }
    when 'red'
      { type: 'failure', icon: 'failure' }
    when 'red_anime'
      { type: 'failure', icon: 'building' }
    else
      { type: 'unstable', icon: 'warning' }
    end

    result['status'] = status
    results << result
  end

  deploy_response = get_request(JENKINS_URI, '/job/cla_public-DEPLOY' + DEPLOY_REQUEST_STRING)
  deploys = JSON.parse(deploy_response.body)['builds']

  DEPLOYS.each do |deploy|
    dr = deploys.select { |d| d['actions'].first['parameters'][1]['value'] == deploy[:env] }.first
    result = {}
    result['label'] = deploy[:label]
    result['status'] = { type: dr['result'].to_s.downcase, icon: dr['result'].to_s.downcase }
    result['lastBuild'] = {}
    result['lastBuild']['timestamp'] = dr['timestamp']
    results << result
  end

  results
end

SCHEDULER.every '120s', :first_in => 0 do
  send_event('deploys', { jobs: get_jobs(JOBS) })
end
