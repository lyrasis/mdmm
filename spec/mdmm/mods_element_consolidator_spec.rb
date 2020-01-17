RSpec.describe Mdmm::ModsElementConsolidator do
    before do
      stub_const('Mdmm::CONFIG', Mdmm::ConfigReader.new('spec/fixtures/files/nearly_blank_config.yaml'))
    end

  let(:elements) { [
    '<physicalDescription><form type="original">Color map</form></physicalDescription>',
    '<physicalDescription><internetMediaType>image/jp2</internetMediaType></physicalDescription>',
    '<originInfo><dateIssued qualifier="approximate">circa 1915-1925</dateIssued><dateIssued encoding="w3cdtf" keyDate="yes" point="start" qualifier="approximate">1915</dateIssued><dateIssued encoding="w3cdtf" point="end" qualifier="approximate">1925</dateIssued></originInfo>',
    '<originInfo><publisher>Publisher name</publisher><place>Place name</place></originInfo>',
    '<extension><drs:admin><drs:captureDate>2019-02-07</drs:captureDate></drs:admin></extension>',
    '<extension><dpla:another>some value</dpla:another></extension>',
    '<subject><topic>Cats</topic></subject>',
    '<subject><topic>Goats</topic></subject>',
    '<subject><topic>BIRBS</topic></subject>'
  ].map{ |e| Nokogiri::XML.fragment(e).xpath(".//*").first } }
  let(:result) { Mdmm::ModsElementConsolidator.new(elements).result }
  
  describe '.result' do
    it 'returns Array' do
      expect(result).to be_instance_of(Array)
    end
    it 'consolidates elements properly' do
      expect(result.length).to eq(6)
      top_level_elements = result.map{ |e| e.name }
      expect(top_level_elements.select{ |e| e == 'physicalDescription' }.length).to eq(1)
      expect(top_level_elements.select{ |e| e == 'originInfo' }.length).to eq(1)
      expect(top_level_elements.select{ |e| e == 'extension' }.length).to eq(1)
      expect(top_level_elements.select{ |e| e == 'subject' }.length).to eq(3)
    end
  end # describe .new
end
