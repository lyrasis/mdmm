RSpec.describe Mdmm::CleanRecord do

  
  # omeka collection
  let(:coll1) { Collection.new(File.expand_path('spec/fixtures/testproject/systemb/bcolla')) }
  let(:rec1) { MigRecord.new(coll1, coll1.migrecs[0])  }
  before do
    stub_const('Mdmm::CONFIG', Mdmm::ConfigReader.new('spec/fixtures/files/nearly_blank_config.yaml'))
  end

  describe ".new" do
    it "returns Mdmm::CleanRecord object" do
      coll1.clean_records
      rec1c = CleanRecord.new(coll1, coll1.cleanrecs[0])
      expect(rec1c).to be_instance_of(Mdmm::CleanRecord)
    end
  end # describe .new

  describe ".map" do
    it "returns Mdmm::RecordMapper object" do
      coll1.clean_records
      rec1c = CleanRecord.new(coll1, coll1.cleanrecs[0])
      expect(rec1c.map).to be_instance_of(Mdmm::RecordMapper)
    end
  end #describe ".clean"

end
