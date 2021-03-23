# frozen_string_literal: true

require 'functions_framework'
require './draft'

FunctionsFramework.http('hello') do |request|
  'Hello, world!'
end
