require 'net/http'
require 'json'

#constants
NUM_LINES = 9


SCHEDULER.every '30s', :first_in => 0 do

  #Fetch job status info from Jenkins (full job list)
  http = Net::HTTP.new(JENKINS_URI.host, JENKINS_URI.port)
  request = Net::HTTP::Get.new("/job/CLA%20Public%20-%20Integration%20PRs/api/json?tree=builds[number,status,timestamp,id,result,description,actions[parameters[name,value]]]")

  if JENKINS_AUTH['name']
    request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
  end

  response = http.request(request)
  data = response.body
  jsondata = JSON.parse(data)
  statuses = jsondata['builds'][0..NUM_LINES-1]

  send_event('jenkins_history', "statuses" => statuses)

end
