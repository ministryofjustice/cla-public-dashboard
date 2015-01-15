require 'net/http'
require 'json'

# constants
DSD_JOBNAMES = ["CLA Deploy Public to DEMO", "CLA Public - Integration"]
LOCAL_JOBNAMES = ["CLA Deploy PUBLIC to STAGING", "CLA Deploy PUBLIC to PRODUCTION"]
REQUEST_STR = "/api/json?tree=jobs[name,color,number,lastBuild[number,timestamp],healthReport[*]]"

def get_jobs(uri, jobnames)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(REQUEST_STR)
  if JENKINS_AUTH['name']
    request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
  end
  response = http.request(request)
  jobs = JSON.parse(response.body)["jobs"]
  jobs.select { |job|
    jobnames.include?(job["name"])
  }
end

SCHEDULER.every '120s', :first_in => 0 do
  dsd_jobs = get_jobs(JENKINS_URI, DSD_JOBNAMES)
  local_jobs = get_jobs(JENKINS_INTERNAL_URI, LOCAL_JOBNAMES)

  send_event('deploys', { "jobs" => local_jobs.concat(dsd_jobs) })
end
