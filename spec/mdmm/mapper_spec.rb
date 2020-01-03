RSpec.describe Mdmm::Mapper do

  describe '.new' do
    it 'returns Mdmm::Mapper object' do
      s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
      rec = JSON.parse(s)
      mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
      result = Mapper.new(rec, mapping)
      expect(result).to be_instance_of(Mdmm::Mapper)
    end
  end # describe .new

  describe '.to_map' do
    let(:s) { '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}' }
    let(:rec) { JSON.parse(s) }
    let(:mapping) { '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>' }
    let(:result) { Mapper.new(rec, mapping).to_map }

    it 'is an Array' do
      expect(result).to be_instance_of(Array)
    end
    it 'includes all fields from the mapping' do
      expect(result).to include('relfoldertitle')
      expect(result).to include('relfolderlink')
    end
  end # describe .to_map

  describe '.top_level' do
    let(:s) { '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}' }
    let(:rec) { JSON.parse(s) }
    let(:mapping) { '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>' }
    let(:result) { Mapper.new(rec, mapping).top_level }

    it 'equals the top-level mods element of the mapping' do
      expect(result).to eq('relatedItem')
    end
    
  end # describe top_level

end # describe Mdmm::Mapper

RSpec.describe Mdmm::SingleFieldMapper do

  describe '.modselements' do
    context 'when field is single-valued' do
      let(:s) { '{"title":"Folder A"}' }
      let(:rec) { JSON.parse(s) }
      let(:mapping) { '<titleInfo><title usage="primary">%title%</title></titleInfo>' }
      let(:result) { SingleFieldMapper.new(rec, mapping).modselements }
      
      it 'is an Array' do
      expect(result).to be_instance_of(Array)
      end
      it 'has length of 1' do
        expect(result.length).to eq(1)
      end
      it 'contained element is XML element' do
        expect(result[0]).to be_instance_of(Nokogiri::XML::Element)
      end
    end
    context 'when field is multi-valued' do
      let(:s) { '{"coverage":"North;;;East;;;South"}' }
      let(:rec) { JSON.parse(s) }
      let(:mapping) { '<subject displayLabel="Coverage"><temporal>%coverage%</temporal></subject>' }
      let(:result) { SingleFieldMapper.new(rec, mapping).modselements }
      
      it 'is an Array' do
      pp(result)
      expect(result).to be_instance_of(Array)
      end
      it 'has length of 3' do
        expect(result.length).to eq(3)
      end
      it 'contained elements are XML elements' do
        expect(result[0]).to be_instance_of(Nokogiri::XML::Element)
        expect(result[1]).to be_instance_of(Nokogiri::XML::Element)
        expect(result[2]).to be_instance_of(Nokogiri::XML::Element)
      end
      it 'XML element is formed correctly' do
        expect(result[0].name).to eq('subject') 
        expect(result[0]['displayLabel']).to eq('Coverage')
        expect(result[0].children[0].name).to eq('temporal') 
        expect(result[0].children[0].text).to eq('North')
      end
    end
  end #describe modselements
end #describe Mdmm::SingleFieldMapper
