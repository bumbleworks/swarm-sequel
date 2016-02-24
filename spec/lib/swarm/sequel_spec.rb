RSpec.describe Swarm::Sequel do
  it 'has a version number' do
    expect(Swarm::Sequel::VERSION).not_to be nil
  end

  describe ".root" do
    it "returns gem root directory" do
      expect(Swarm::Sequel.root).to eq(
        Pathname(File.expand_path("../../../..", __FILE__))
      )
    end
  end
end
