RSpec.describe Swarm::Sequel::Storage do
  let(:sequel_db) { Sequel.sqlite }
  subject { described_class.new(sequel_db) }

  describe ".new" do
    it "runs #migrate! by default immediately" do
      expect_any_instance_of(described_class).to receive(:migrate!)
      subject
    end

    it "skips running #migrate! if requested" do
      expect_any_instance_of(described_class).to receive(:migrate!).never
      described_class.new(sequel_db, skip_migrations: true)
    end
  end

  describe "#migrate!" do
    subject { described_class.new(sequel_db, skip_migrations: true) }
    it "runs sequel migrations from migrations dir" do
      expect(::Sequel::Migrator).to receive(:run).
        with(
          sequel_db,
          Swarm::Sequel.root.join("lib/swarm/sequel/migrations"),
          table: "swarm_schema_info"
        )
      subject.migrate!
    end

    it "runs to specified version" do
      expect(::Sequel::Migrator).to receive(:run).
        with(
          sequel_db,
          Swarm::Sequel.root.join("lib/swarm/sequel/migrations"),
          table: "swarm_schema_info", target: 3
        )
      subject.migrate!(version: "3")
    end
  end

  describe "#association_key_for_type" do
    it "returns tokenized type with _id appended" do
      expect(subject.association_key_for_type("PartyKnuckles")).to eq("party_knuckles_id")
    end
  end

  context "with real data" do
    before(:each) do
      Timecop.freeze
      subject # instantiating runs migrations
      [1, 2, 3].each do |id|
        sequel_db[:swarm_process_definitions].insert(
          :id => id, :type => "ProcessDefinition", :tree => "tree", :name => "foo", :version => "1.0.#{id}"
        )
        sequel_db[:swarm_processes].insert(
          :id => id + 3, :type => "Process", :process_definition_id => "1", :workitem => "work", :root_expression_id => "rid_#{id + 3}"
        )
        sequel_db[:swarm_expressions].insert(
          :id => id + 6, :type => "Expression", :parent_id => "pid_#{id + 6}", :position => id + 10, :workitem => "work", :process_id => id + 3
        )
        sequel_db[:swarm_expressions].insert(
          :id => id + 9, :type => "OtherExpression", :parent_id => "pid_#{id + 9}", :position => id + 10, :workitem => "work", :process_id => "4567"
        )
        sequel_db[:swarm_stored_workitems].insert(
          :id => id + 12, :type => "StoredWorkitem", :expression_id => "expression_#{id + 12}"
        )
      end
    end

    after(:each) do
      Timecop.return
      subject.migrate!(version: 0)
    end

    describe "#load_associations" do
      it "returns all associated objects with given relationship" do
        expect(subject.load_associations(
          "processes",
          owner: double(Swarm::ProcessDefinition, id: "1"),
          type: "Swarm::Process",
          foreign_key: :process_definition_id
        ).all).to eq(sequel_db[:swarm_processes].all)
      end
    end

    describe "#ids_for_type" do
      it "returns all ids for given type" do
        expect(subject.ids_for_type("ProcessDefinition")).to match_array(%w(1 2 3))
        expect(subject.ids_for_type("Process")).to match_array(%w(4 5 6))
        expect(subject.ids_for_type("Expression")).to match_array(%w(7 8 9 10 11 12))
        expect(subject.ids_for_type("StoredWorkitem")).to match_array(%w(13 14 15))
      end
    end

    describe "#all_of_type" do
      it "returns all records for given type" do
        expect(subject.all_of_type("Expression")).to match_array(sequel_db[:swarm_expressions].all)
      end

      it "does not return subtypes if constrained" do
        expect(subject.all_of_type("Expression", subtypes: false)).
          to match_array(sequel_db[:swarm_expressions].where(:type => "Expression"))
      end
    end

    describe "#[]" do
      it "returns record at key" do
        record = sequel_db[:swarm_process_definitions].first(:id => "1")
        expect(subject["ProcessDefinition:1"]).to eq(record)
      end
    end

    describe "#[]=" do
      it "creates record with given values" do
        subject["StoredWorkitem:78"] = { :type => "sw", :expression_id => "cupcake party" }
        expect(subject["StoredWorkitem:78"]).to eq({
          :id => "78", :type => "sw", :expression_id => "cupcake party", :created_at => nil, :updated_at => nil
        })
      end

      it "updates existing record with given values" do
        expect(subject["StoredWorkitem:13"][:expression_id]).to eq("expression_13")
        subject["StoredWorkitem:13"] = { :expression_id => "cupcake party" }
        expect(subject["StoredWorkitem:13"]).to eq({
          :id => "13", :type => "StoredWorkitem", :expression_id => "cupcake party", :created_at => nil, :updated_at => nil
        })
      end
    end

    describe "#truncate" do
      it "clears sequel_db" do
        subject.truncate
        expect(sequel_db[:swarm_process_definitions].count).to eq(0)
        expect(sequel_db[:swarm_processes].count).to eq(0)
        expect(sequel_db[:swarm_expressions].count).to eq(0)
        expect(sequel_db[:swarm_stored_workitems].count).to eq(0)
      end
    end

    describe "#delete" do
      it "deletes key from sequel_db" do
        subject.delete("StoredWorkitem:13")
        expect(subject.ids_for_type("StoredWorkitem")).to eq(%w(14 15))
      end
    end
  end
end