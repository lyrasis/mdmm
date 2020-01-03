RSpec.describe Mdmm::Collection do
  let(:c) { Collection.new(File.expand_path('spec/fixtures/testproject/systema/acoll2')) }
  describe ".new" do
    it "returns Mdmm::Collection object" do
      expect(c).to be_instance_of(Mdmm::Collection)
    end

    it "sets name attribute to directory name" do
      expect(c.name).to eq('acoll2')
    end

    it "sets migrecs attribute with array" do
      expect(c.migrecs).to be_instance_of(Array)
    end

    it "migrecs attribute length == number of collection migrecs" do
      expect(c.migrecs.length).to eq(1)
    end
    
    it "migrecs attribute elements are paths to mig record JSON" do
      expect(c.migrecs[0]).to eq(File.expand_path('spec/fixtures/testproject/systema/acoll2/_migrecords/1.json'))
    end

    it "sets cleanrecdir attribute" do
      expect(c.cleanrecdir).to eq(File.expand_path('spec/fixtures/testproject/systema/acoll2/_cleanrecords'))
    end
    
    it "creates cleanrecdir" do
      expect(Dir.exist?(c.cleanrecdir)).to be true
    end
    
    it "sets modsrecdir attribute" do
      expect(c.modsdir).to eq(File.expand_path('spec/fixtures/testproject/systema/acoll2/_mods'))
    end
    
    it "creates modsrecdir" do
      expect(Dir.exist?(c.modsdir)).to be true
    end
  end

end
