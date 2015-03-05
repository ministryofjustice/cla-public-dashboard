require 'net/http'
require 'json'

#constants
NUM_LINES = 5


SCHEDULER.every '300s', :first_in => 0 do

  #Fetch job status info from Jenkins (full job list)
  http = Net::HTTP.new(JENKINS_URI.host, JENKINS_URI.port)
  request = Net::HTTP::Get.new("/job/CLA%20Public%20-%20Integration%20PRs/api/json?tree=builds[number,timestamp,result,description,actions[parameters[value]]]")

  if JENKINS_AUTH['name']
    request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
  end

  response = http.request(request)
  data = response.body
  jsondata = JSON.parse(data)
  statuses = jsondata['builds'][1..NUM_LINES]

  statuses.map do |item|
    if item['actions'][0]['parameters']
      item['pullNumber'] = item['actions'][0]['parameters'][6]['value']
      item['description'] = item['actions'][0]['parameters'][12]['value']
    else
      item['pullNumber'] = 'N/A'
      item['description'] = 'N/A'
    end
  end

  send_event('jenkins_history', "statuses" => statuses)

end
