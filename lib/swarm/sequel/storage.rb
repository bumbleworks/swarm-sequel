require "sequel"
require "swarm"

module Swarm
  module Sequel
    class Storage
      TABLE_NAMES = {
        "ProcessDefinition" => "process_definitions",
        "Process" => "processes",
        "Expression" => "expressions",
        "StoredWorkitem" => "stored_workitems"
      }

      attr_reader :sequel_db
      attr_accessor :trace

      def initialize(sequel_db, table_prefix: "swarm", skip_migrations: false)
        @sequel_db = sequel_db
        @table_prefix = table_prefix
        migrate! unless skip_migrations
      end

      def association_key_for_type(type)
        "#{Swarm::Support.tokenize(type)}_id"
      end

      def load_associations(association_name, owner:, type:, foreign_key: nil)
        type = type.split("::").last
        foreign_key ||= association_key_for_type(type)
        dataset_for_type(type).where(foreign_key => owner.id)
      end

      def migrate!(version: nil)
        ::Sequel.extension :migration

        migration_folder = Swarm::Sequel.root.join("lib", "swarm", "sequel", "migrations")
        options = { table: "#{@table_prefix}_schema_info" }
        options.merge!(target: version.to_i) if version

        ::Sequel::Migrator.run(sequel_db, migration_folder, options)
      end

      def table_name_for_type(type)
        "#{@table_prefix}_#{TABLE_NAMES[type]}"
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
          update_record(table, id, values.merge(:id => id))
        else
          create_record(table, values.merge(:id => id))
        end
      end

      def create_record(table, values)
        dataset_for_type(table).insert(values)
      end

      def update_record(table, id, values)
        model = Swarm::Support.constantize("Swarm::#{table}")
        columns = model.columns
        clear = Hash[columns.zip([nil])]
        dataset_for_type(table).where(:id => id).update(clear.merge(values))
      end

      def delete(key)
        table, id = key.split(":")
        dataset_for_type(table).where(:id => id).delete
      end

      def truncate
        TABLE_NAMES.values.each do |table|
          sequel_db["#{@table_prefix}_#{table}".to_sym].truncate
        end
      end
    end
  end
end
