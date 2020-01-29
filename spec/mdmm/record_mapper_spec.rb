RSpec.describe Mdmm::RecordMapper do

  before do
    stub_const('Mdmm::CONFIG', Mdmm::ConfigReader.new('spec/fixtures/files/nearly_blank_config.yaml'))
    @coll1 = Collection.new(File.expand_path('spec/fixtures/testproject/systemb/bcolla'))
    @coll1.clean_records
  end

  describe ".new" do
    xit "returns Mdmm::CleanRecord object" do
#      coll1.clean_records
      rec1c = CleanRecord.new(@coll1, @coll1.cleanrecs[0])
      expect(rec1c).to be_instance_of(Mdmm::CleanRecord)
    end
  end # describe .new

end
