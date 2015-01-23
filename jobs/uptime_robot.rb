require 'uptimerobot'

STATUSES = {
  '0' => 'paused',
  '1' => 'not checked yet',
  '2' => 'up',
  '8' => 'seems down',
  '9' => 'down'
}
TYPES = {
  '1' => 'HTTP(s)',
  '2' => 'Keyword',
  '3' => 'Ping',
  '4' => 'Port',
}

client = UptimeRobot::Client.new(apiKey: 'u200741-b3910f5b96a269d52fe51b73')

SCHEDULER.every '5m', first_in: 0 do
  monitors = []

  client.getMonitors['monitors']['monitor'].each do |m|
    monitors << {
      name: m['friendlyname'],
      type: TYPES[m['type']],
      status: STATUSES[m['status']]
    }
  end

  send_event('uptime_robot', { monitors: monitors })
end
