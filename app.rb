# frozen_string_literal: true

require 'functions_framework'

FunctionsFramework.http('hello') do |request|
  "Hello, world!\n"
end

require './draft'
