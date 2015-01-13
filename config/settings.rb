# Loading these here as config.ru is loaded after jobs/ in Dashing
# and config/settings.rb before

require 'dotenv'
require 'action_view'
require 'active_support/all'
require 'pry'
include ActionView::Helpers::DateHelper

Dotenv.load

JENKINS_URI = URI.parse(ENV['JENKINS_URL'])
JENKINS_INTERNAL_URI = URI.parse(ENV['JENKINS_INTERNAL_URL'])
JENKINS_AUTH = {
  'name' => ENV['JENKINS_USER'],
  'password' => ENV['JENKINS_TOKEN']
}
