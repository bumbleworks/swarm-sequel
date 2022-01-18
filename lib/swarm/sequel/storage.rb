require "sequel"
require "swarm"

module Swarm
  module Sequel
    class Storage
      class UnsupportedTypeError < StandardError; end

      TABLE_PREFIX = "swarm"
      TABLE_NAMES = {
        "ProcessDefinition" => "process_definitions",
        "Process" => "processes",
        "Expression" => "expressions",
        "StoredWorkitem" => "stored_workitems"
      }

      attr_reader :sequel_db
      attr_accessor :trace

      def initialize(sequel_db, skip_migrations: false)
        @sequel_db = sequel_db
        migrate! unless skip_migrations
      end

      def uses_collection_indices?
        false
      end

      def association_key_for_type(type)
        "#{Swarm::Support.tokenize(type)}_id".to_sym
      end

      def add_association(association_name, associated, owner:, class_name:, foreign_key: nil)
        type = class_name.split("::").last
        foreign_key ||= association_key_for_type(type)
        update_record(associated, foreign_key => owner.id)
      end

      def load_associations(association_name, owner:, class_name:, foreign_key: nil)
        type = class_name.split("::").last
        foreign_key ||= association_key_for_type(type)
        dataset_for_type(type).where(foreign_key => owner.id)
      end

      def migrate!(version: nil)
        ::Sequel.extension :migration

        migration_folder = Swarm::Sequel.root.join("lib", "swarm", "sequel", "migrations")
        options = { table: "#{TABLE_PREFIX}_schema_info" }
        options.merge!(target: version.to_i) if version

        ::Sequel::Migrator.run(sequel_db, migration_folder, options)
      end

      def table_name_for_type(type)
        base_name = TABLE_NAMES[type]
        raise UnsupportedTypeError unless base_name
        "#{TABLE_PREFIX}_#{base_name}"
      end

      def dataset_for_type(type)
        sequel_db[table_name_for_type(type).to_sym]
      end

      def ids_for_type(type)
        dataset_for_type(type).select_map(:id)
      end

      def all_of_type(type, subtypes: true)
        if subtypes
          dataset_for_type(type).all
        else
          dataset_for_type(type).where(:type => type)
        end
      end

      def [](key)
        table, id = key.split(":")
        dataset_for_type(table).where(:id => id).first
      end

      def []=(key, values)
        table, id = key.split(":")
        existing_record = dataset_for_type(table).where(:id => id).first
        if existing_record
          update_record(existing_record, values.merge(:id => id))
        else
          create_record(table, values.merge(:id => id))
        end
      end

      def create_record(table, values)
        require "pry"; binding.pry
        dataset_for_type(table).insert(values)
      end

      def update_record(record, values)
        type, id = record.values_at(:type, :id)
        model = Swarm::Support.constantize("Swarm::#{type}")
        new_values = record.merge(values)
        dataset_for_type(model.storage_type).where(:id => id).update(new_values)
      end

      def delete(key)
        table, id = key.split(":")
        dataset_for_type(table).where(:id => id).delete
      end

      def truncate
        TABLE_NAMES.values.each do |table|
          sequel_db["#{TABLE_PREFIX}_#{table}".to_sym].truncate
        end
      end
    end
  end
end
