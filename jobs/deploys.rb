require 'net/http'
require 'json'

JOBS = [
  { label: 'Integration', name: 'CLA Public - Integration', uri: JENKINS_URI },
  { label: 'Demo',        name: 'CLA Deploy Public to DEMO', uri: JENKINS_URI },
  { label: 'Staging',     name: 'CLA Deploy PUBLIC to STAGING', uri: JENKINS_INTERNAL_URI },
  { label: 'Production',  name: 'CLA Deploy PUBLIC to PRODUCTION', uri: JENKINS_INTERNAL_URI }
]
REQUEST_STR = "/api/json?tree=jobs[name,color,number,lastBuild[number,timestamp],healthReport[*]]"

def get_jobs(jobs)
  grouped_jobs = jobs.group_by { |j| j[:uri] }
  results = []
  jenkins_jobs = []

  grouped_jobs.each do |uri, group_jobs|
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(REQUEST_STR)

    if JENKINS_AUTH['name']
      request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
    end

    response = http.request(request)

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
      'success'
    when 'red'
      'failure'
    else
      'unstable'
    end

    result['status'] = status
    results << result
  end

  results
end

SCHEDULER.every '1200s', :first_in => 0 do
  send_event('deploys', { jobs: get_jobs(JOBS) })
end
