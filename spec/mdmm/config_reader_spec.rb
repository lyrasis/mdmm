RSpec.describe Mdmm::ConfigReader do
  let(:c) { ConfigReader.new('spec/fixtures/files/nearly_blank_config.yaml') }

  describe ".new" do
    it "finds systema as one of two wrk_dirs" do
      pp(c)
    expect(c.wrk_dirs.length).to eq(2)
    expect(c.wrk_dirs[0]).to include('systema')
  end

  context 'when verbatim-set options are specified in config' do
    it 'returns populated array' do
      expect(c.replacements).to be_instance_of(Array)
      expect(c.replacements.length).to eq(2)
    end
  end
  
  context 'when verbatim-set options are unspecified in config' do
    it "returns empty arrays" do
      [c.fieldvalues_file,
       c.prelim_replacements,
       c.splits,
       c.constant_fields,
       c.case_changes,
       c.move_fields,
       c.move_and_replaces,
       c.derive_fields,
       c.extractions,
       c.cross_multival_replacements
      ].each{ |atr|
        expect(atr).to be_instance_of(Array)
        expect(atr).to be_empty
      }
    end
  end
  end

  describe ".set_colls" do
    it "sets colls to array of all coll paths" do
      expect(c.colls).to be_instance_of(Array)
      expect(c.colls.length).to eq(3)
    end
  end

  describe ".get_mappings" do
    
    it "returns hash of mappings data from .csv mappings file" do
      expect(c.mappings).to be_instance_of(Hash)
    end
    it "returned hash has keys for each collection" do
      expect(c.mappings.keys.length).to eq(2)
    end
    it "returned hash value for collection key is array of mapping rows" do
      result = c.mappings['bcolla']
      expect(result).to be_instance_of(Array)
      expect(result.length).to eq(4)
    end
  end
end
