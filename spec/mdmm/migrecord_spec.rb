RSpec.describe Mdmm::MigRecord do

  before do
    stub_const('Mdmm::CONFIG', Mdmm::ConfigReader.new('spec/fixtures/files/nearly_blank_config.yaml'))
  end

  # omeka collection
  let(:coll1) { Collection.new(File.expand_path('spec/fixtures/testproject/systemb/bcolla')) }
  let(:rec1) { MigRecord.new(coll1, coll1.migrecs[0])  }
  # cdm collection
  let(:coll2) { Collection.new(File.expand_path('spec/fixtures/testproject/systema/acoll2')) }
  let(:rec2) { MigRecord.new(coll2, coll2.migrecs[0])  }

  describe ".new" do
    it "returns Mdmm::MigRecord object" do
      expect(rec1).to be_instance_of(Mdmm::MigRecord)
    end

    it "cleanfields only includes fields to be cleaned" do
      expect(rec1.cleanfields.include?('migptr')).to be true
      expect(rec1.cleanfields.include?('dontcleanme')).to be false
    end
  end # describe .new

  describe ".clean" do
    it "returns Mdmm::RecordCleaner object" do
      expect(rec1.clean).to be_instance_of(Mdmm::RecordCleaner)
    end
  end #describe ".clean"

end
