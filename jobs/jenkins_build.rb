require 'net/http'
require 'json'
require 'time'
require 'action_view'
include ActionView::Helpers::DateHelper

JENKINS_URI = URI.parse(ENV['JENKINS_URL'])

JENKINS_AUTH = {
  'name' => ENV['JENKINS_USER'],
  'password' => ENV['JENKINS_TOKEN']
}

# the key of this mapping must be a unique identifier for your job, the according value must be the name that is specified in jenkins
job_mapping = {
  'JOB' => { :job => 'CLA Public - Integration PRs', :pre_job => nil}
}

def get_number_of_failing_tests(job_name)
  info = get_json_for_job(job_name, 'lastCompletedBuild')
  info['actions'][4]['failCount']
end

def get_completion_percentage(job_name)
  build_info = get_json_for_job(job_name)
  prev_build_info = get_json_for_job(job_name, 'lastCompletedBuild')

  return 0 if not build_info["building"]
  last_duration = (prev_build_info["duration"] / 1000).round(2)
  current_duration = (Time.now.to_f - build_info["timestamp"] / 1000).round(2)
  return 99 if current_duration >= last_duration
  ((current_duration * 100) / last_duration).round(0)
end

def get_json_for_job(job_name, build = 'lastBuild')
  job_name = URI.encode(job_name)
  http = Net::HTTP.new(JENKINS_URI.host, JENKINS_URI.port)
  request = Net::HTTP::Get.new("/job/#{job_name}/#{build}/api/json")
  if JENKINS_AUTH['name']
    request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
  end
  response = http.request(request)
  JSON.parse(response.body)
end

job_mapping.each do |title, jenkins_project|
  current_status = nil
  SCHEDULER.every '3s', :first_in => 0 do |job|
    last_status = current_status
    build_info = get_json_for_job(jenkins_project[:job])
    current_status = build_info["result"]
    if build_info["building"]
      current_status = "BUILDING"
      percent = get_completion_percentage(jenkins_project[:job])
    # elsif jenkins_project[:pre_job]
    #   pre_build_info = get_json_for_job(jenkins_project[:pre_job])
    #   current_status = "PREBUILD" if pre_build_info["building"]
    #   percent = get_completion_percentage(jenkins_project[:pre_job])
    end

    parameters = build_info['actions'][0]['parameters']

    if parameters
      pull_title = parameters.select { |p| p['name'] == 'ghprbPullTitle' }[0]['value']
      commit_author = parameters.select { |p| p['name'] == 'ghprbActualCommitAuthor' }[0]['value']
    end

    send_event(jenkins_project[:job], {
      title: jenkins_project[:job].sub('CLA Public - ', ''),
      currentResult: current_status,
      lastResult: last_status,
      value: percent,
      pull_title: pull_title,
      commit_author: commit_author,
      is_building: current_status == 'BUILDING',
      lastBuiltAgo: time_ago_in_words(Time.at(build_info["timestamp"]/1000))
    })
  end
end
