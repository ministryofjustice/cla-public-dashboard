require 'octokit'

Octokit.configure do |c|
  c.auto_paginate = true
  c.login = ENV['GITHUB_LOGIN']
  c.access_token = ENV['GITHUB_OAUTH_TOKEN']
end

PR_FRESHNESS = { new: (10 * 60), old: (10 * 24 * 60 * 60), stale: (30 * 24 * 60 * 60) }

def get_freshness(time)
  time_diff = Time.now - time

  if time_diff < 10.minutes
    :fresh
  elsif time_diff < 7.days
    :normal
  elsif time_diff < 30.days
    :old
  else
    :stale
  end
end

SCHEDULER.every '15m', :first_in => 0 do |job|
  ENV['GITHUB_REPOS'].split(',').each do |name|
    r = Octokit::Client.new.repository(name)
    pulls = Octokit.pulls(name, state: 'open', sort: 'updated', direction: 'down').map { |pull|
      time_since = Time.now.to_i - pull.updated_at.to_i

      {
        number: pull.number,
        title: pull.title,
        user: {
          name: pull.user.login,
          avatar_url: pull.user.avatar_url
        },
        updated_at: time_ago_in_words(pull.updated_at),
        freshness: get_freshness(pull.updated_at)
      }
    }

    send_event(name, {
      pulls: pulls,
      updated_at: time_ago_in_words(r.updated_at)
    })
  end
end
