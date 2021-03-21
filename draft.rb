# frozen_string_literal: true

require 'functions_framework'
require 'json'

def formatted_reservations(date_str, time_want_str)
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

  date = Date.parse(date_str)
  hash = JSON.parse(Net::HTTP.get(URI.parse("https://www.grousemountain.com/products/894/max_available?date=#{date_str}")))

  header = date.strftime('Date: %F (%a)')
  body =
    table.reject {|_, v|
      Time.parse(time_want_str) < Time.parse(v)
    }.map {|k, v|
      hash[k].then { '  %s  %s' % [v, _1['qty_rem']] }
    }
  [header, *body]
end

FunctionsFramework.http 'index' do |request|
  input = JSON.parse request.body.read rescue {}
  date_str = input['date_str'] || '2021-03-22'
  result = formatted_reservations(date_str, '9:30am').join("\n")
  puts result
  result
end

FunctionsFramework.http 'test' do |request|
  input = JSON.parse request.body.read rescue {}
  eval(input['s'].to_s)
rescue => e
  [e.class, e.full_message]
end
