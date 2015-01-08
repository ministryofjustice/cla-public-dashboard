# Loading these here as config.ru is loaded after jobs/ in Dashing
# and config/settings.rb before

require 'dotenv'
require 'action_view'
require 'active_support/all'
require 'pry'
include ActionView::Helpers::DateHelper

Dotenv.load
