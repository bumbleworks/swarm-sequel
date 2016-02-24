require 'simplecov'
SimpleCov.start do
  add_filter "/migrations/"
end

require "timecop"

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'swarm/sequel'
