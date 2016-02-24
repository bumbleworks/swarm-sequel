Sequel.migration do
  change do
    create_table(:swarm_process_definitions) do
      String :id, :primary_key => true
      String :type, :null => false

      String :tree, :null => false
      String :name, :null => false
      String :version, :null => false

      column :created_at, 'timestamp with time zone'
      column :updated_at, 'timestamp with time zone'

      index [:name, :version], :unique => true
    end

    create_table(:swarm_processes) do
      String :id, :primary_key => true
      String :type, :null => false

      String :process_definition_id, :null => false, :index => true
      String :workitem, :null => false
      String :root_expression_id
      String :parent_expression_id

      column :created_at, 'timestamp with time zone'
      column :updated_at, 'timestamp with time zone'
    end

    create_table(:swarm_expressions) do
      String :id, :primary_key => true
      String :type, :null => false

      String :parent_id, :null => false, :index => true
      Integer :position, :null => false
      String :workitem, :null => false
      String :process_id, :null => false, :index => true

      column :applied_at, 'timestamp with time zone'
      column :replied_at, 'timestamp with time zone'
      column :created_at, 'timestamp with time zone'
      column :updated_at, 'timestamp with time zone'
    end

    create_table(:swarm_stored_workitems) do
      String :id, :primary_key => true
      String :type, :null => false

      String :expression_id, :null => false, :index => true

      column :created_at, 'timestamp with time zone'
      column :updated_at, 'timestamp with time zone'
    end
  end
end
