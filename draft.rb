# frozen_string_literal: true

require 'functions_framework'
require 'json'
require 'google/cloud/firestore'
require 'pushover'

# TODO Refactor
def formatted_reservations(target_date_str, time_notify_str, notify_min_qty, time_list_str, notify_p)
  require 'net/http'
  require 'json'
  require 'time'
  table = {
    'TRAMTIMETRAM-UPTUT-B1' => '8:00am',
    'TRAMTIMETRAM-UPTUT-B2' => '8:30am',
    'TRAMTIMETRAM-UPTUT-C1' => '9:00am',
    'TRAMTIMETRAM-UPTUT-C2' => '9:30am',
    'TRAMTIMETRAM-UPTUT-D1' => '10:00am',
    'TRAMTIMETRAM-UPTUT-D2' => '10:30am',
    'TRAMTIMETRAM-UPTUT-E1' => '11:00am',
  }

  date = Date.parse(target_date_str)
  hash = JSON.parse(Net::HTTP.get(URI.parse("https://www.grousemountain.com/products/894/max_available?date=#{target_date_str}")))

  quantities_by_time =
    table.to_h {|k, v|
      [v, hash[k]['qty_rem']]
    }

  notify_quantities =
    quantities_by_time.select {|k, v|
      Time.parse(k) <= Time.parse(time_notify_str) &&
        notify_min_qty <= v
    }
  if token = ENV['PUSHOVER_DEVICE_TOKEN']
    if notify_quantities.empty?
      # No need to notify
    else
      message_body =
        notify_quantities.map {|k, v| "#{k} #{v}" }.join("\n").inspect
      if notify_p
        Pushover::Message.new(
          token: token,
          user: ENV['PUSHOVER_USER_TOKEN'],
          message: "#{target_date_str}\n#{message_body}"
        ).push
      end
    end
  else
    warn 'Missing PUSHOVER_DEVICE_TOKEN/PUSHOVER_USER_TOKEN'
  end


  header = date.strftime('Date: %F (%a)')
  body =
    quantities_by_time.select {|k, _|
      Time.parse(k) <= Time.parse(time_list_str)
    }.map {|k, v|
      '  %s  %s' % [k, v]
    }
  [header, *body]
end

FunctionsFramework.http 'index' do |request|
  if ENV['CREDENTIALS_JSON']
    firestore = ::Google::Cloud::Firestore.new(
      project_id: 'devs-sandbox',
      credentials: JSON.parse(ENV['CREDENTIALS_JSON']),
    )
  else
    # Use emulator
    ENV['FIRESTORE_EMULATOR_HOST'] = "firestore-emulator:8080"
    firestore = ::Google::Cloud::Firestore.new(
      project_id: 'devs-sandbox',
    )
  end
  col = firestore.col('practice-cloud-functions/draft/reservations')

  target_date_str = request.params['target_date_str'] || '2021-03-23'
  notify_p = request.params['notify'] == '1'

  # Simply skip if it's the past
  if Date.parse(target_date_str) < Date.today
    next "#{target_date_str} is older than today(#{Date.today}). Skipping."
  end

  result = formatted_reservations(target_date_str, '8:30am', 1, '9:30am', notify_p)

  col.add({
    target_date_str: target_date_str,
    result: result,
    created_at: Time.now,
  })

  result.join("\n")
end

FunctionsFramework.http 'test' do |request|
  input = JSON.parse request.body.read rescue {}
  eval(input['s'].to_s)
rescue => e
  [e.class, e.full_message]
end
