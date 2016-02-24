require "swarm/sequel/version"
require "swarm/sequel/storage"

Sequel.extension :migration

module Swarm
  module Sequel
    def self.root
      Pathname(File.expand_path "../../..", __FILE__)
    end
  end
end
