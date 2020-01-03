RSpec.describe Mdmm::Record do
  let!(Mdmm::CONFIGPATH) { stub_const('Mdmm::CONFIGPATH', 'spec/fixtures/files/nearly_blank_config.yaml') }

  before do
    stub_const('Mdmm::CONFIG', Mdmm::ConfigReader.new)
  end
  
  # omeka collection
  let(:coll1) { Collection.new(File.expand_path('spec/fixtures/testproject/systemb/bcolla')) }
  let(:rec1) { Record.new(coll1, coll1.migrecs[0])  }
  # cdm collection
  let(:coll2) { Collection.new(File.expand_path('spec/fixtures/testproject/systema/acoll2')) }
  let(:rec2) { Record.new(coll2, coll2.migrecs[0])  }

  describe ".new" do
    it "returns Mdmm::Record object" do
      expect(rec1).to be_instance_of(Mdmm::Record)
    end

    it "coll attribute returns Mdmm::Collection object" do
      expect(rec1.coll).to be_instance_of(Mdmm::Collection)
    end

    it "json attribute returns record as hash from json file" do
      expect(rec1.json).to be_instance_of(Hash)
      expect(rec1.json['title']).to eq('Lilibet')
    end

    it "fields attribute returns array of fieldnames" do
      expect(rec1.fields).to be_instance_of(Array)
      fieldnames = %w[title description publisher date migptr type identifier]
      fieldnames.each{ |fn| expect(rec1.fields.include?(fn)).to be true }
    end

    it "reportfields only includes fields for reporting" do
      expect(rec1.reportfields.include?('migptr')).to be false
    end

    context "in records from Omeka" do
      it "sets id attribute from migptr field" do
        expect(rec1.id).to eq('2')
      end
    end

    context "in records from CDM" do
      it "sets id attribute from dmrecord field" do
        expect(rec2.id).to eq('1')
      end
    end
  end # describe .new

  describe ".has_field?" do
    it "returns true if populated field exists in record" do
      expect(rec1.has_field?('title')).to be true
    end

    it "returns false if field exists but is empty" do
      expect(rec1.has_field?('emptyfield')).to be false
    end

    it "returns false if field does not exist in record" do
      expect(rec1.has_field?('notafield')).to be false
    end
  end #describe ".has_field?"

end
