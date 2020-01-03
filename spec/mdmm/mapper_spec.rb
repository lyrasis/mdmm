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

RSpec.describe Mdmm::MultiFieldMapper do
  describe '.modselements' do
    context 'when fields are single-valued' do
      let(:s) { '{"recsourceorg":"AbC","sourcesystem":"systemname"}' }
      let(:rec) { JSON.parse(s) }
      let(:mapping) { '<recordInfo><recordContentSource authority="marcorg">%recsourceorg%</recordContentSource><recordOrigin>Mapped from %sourcesystem% to MODS</recordOrigin></recordInfo>' }
      let(:result) { MultiFieldMapper.new(rec, mapping).modselements }
      
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
    context 'when fields are multi-valued' do
      let(:s) { '{"recsourceorg":"AbC;;;DeF","sourcesystem":"systemA;;;systemB"}' }
      let(:rec) { JSON.parse(s) }
      let(:mapping) { '<recordInfo><recordContentSource authority="marcorg">%recsourceorg%</recordContentSource><recordOrigin>Mapped from %sourcesystem% to MODS</recordOrigin></recordInfo>' }
      let(:result) { MultiFieldMapper.new(rec, mapping).modselements }
      
      it 'is an Array' do
        expect(result).to be_instance_of(Array)
      end
      it 'has length of 2' do
        expect(result.length).to eq(2)
      end
      it 'contained elements are XML elements' do
        expect(result[0]).to be_instance_of(Nokogiri::XML::Element)
        expect(result[1]).to be_instance_of(Nokogiri::XML::Element)
      end
      it 'XML element is formed correctly' do
        expect(result[1].name).to eq('recordInfo') 
        expect(result[1].children[0].name).to eq('recordContentSource') 
        expect(result[1].children[0]['authority']).to eq('marcorg')
        expect(result[1].children[0].text).to eq('DeF')
      end
    end
  end #describe modselements
end #describe Mdmm::MultiFieldMapper

RSpec.describe Mdmm::DateFieldMapper do
  let(:s) { '{"date_cleaned":"circa 1915-1925^^^qualifier=approximate;;;1915^^^encoding=w3cdtf^^^keyDate=yes^^^point=start^^^qualifier=approximate;;;1925^^^encoding=w3cdtf^^^point=end^^^qualifier=approximate"}' }
  let(:rec) { JSON.parse(s) }
  let(:mapping) { '<originInfo><dateCreated>%date%</dateCreated></originInfo>' }
  let(:result) { DateFieldMapper.new(rec, mapping) }
  
  describe '.field' do
    it 'returns single field from mapping' do
      expect(result.field).to eq('date')
    end
  end

  describe '.vals' do
    it 'returns array of processed fieldvalue hashes' do
      a = [
        {'value' => 'circa 1915-1925',
         'qualifier' => 'approximate'
        },
        {'value' => '1915',
         'encoding' => 'w3cdtf',
         'keyDate' => 'yes',
         'point' => 'start',
         'qualifier' => 'approximate'
        },
        {'value' => '1925',
         'encoding' => 'w3cdtf',
         'point' => 'end',
         'qualifier' => 'approximate'
        }
      ]
      expect(result.vals).to eq(a)
    end
  end
end #describe Mdmm::DateFieldMapper

RSpec.describe Mdmm::OrigininfoDateFieldMapper do
  let(:s) { '{"date_cleaned":"circa 1915-1925^^^qualifier=approximate;;;1915^^^encoding=w3cdtf^^^keyDate=yes^^^point=start^^^qualifier=approximate;;;1925^^^encoding=w3cdtf^^^point=end^^^qualifier=approximate"}' }
  let(:rec) { JSON.parse(s) }
  let(:mapping) { '<originInfo><dateCreated>%date%</dateCreated></originInfo>' }
  let(:result) { OrigininfoDateFieldMapper.new(rec, mapping).modselements }

  describe '.modselements' do
      it 'is an Array' do
      expect(result).to be_instance_of(Array)
      end
      it 'has length of 1' do
        expect(result.length).to eq(1)
      end
      it 'contained element is XML element' do
        expect(result[0]).to be_instance_of(Nokogiri::XML::Element)
      end
      it 'XML element is formed correctly' do
        expect(result[0].name).to eq('originInfo') 
        expect(result[0].children[0].name).to eq('dateCreated')
        expect(result[0].children[0]['qualifier']).to eq('approximate')
        expect(result[0].children[0].text).to eq('circa 1915-1925')
        expect(result[0].children[1]['keyDate']).to eq('yes')
        expect(result[0].children[1]['encoding']).to eq('w3cdtf')
        expect(result[0].children[2]['point']).to eq('end')
      end
  end #describe modselements
end #describe Mdmm::OrigininfoDateFieldMapper

RSpec.describe Mdmm::OtherDateFieldMapper do
  let(:s) { '{"date_cleaned":"circa 1915-1925^^^qualifier=approximate;;;1915^^^encoding=w3cdtf^^^keyDate=yes^^^point=start^^^qualifier=approximate;;;1925^^^encoding=w3cdtf^^^point=end^^^qualifier=approximate"}' }
  let(:rec) { JSON.parse(s) }
  let(:mapping) { '<extension><drs:admin><drs:captureDate>%date%</drs:captureDate></drs:admin></extension>' }
  let(:result) { OtherDateFieldMapper.new(rec, mapping).modselements }

  describe '.modselements' do
      it 'is an Array' do
      expect(result).to be_instance_of(Array)
      end
      it 'has length of 1' do
        expect(result.length).to eq(1)
      end
      it 'contained element is XML element' do
        expect(result[0]).to be_instance_of(Nokogiri::XML::Element)
      end
      it 'XML element is formed correctly' do
        expect(result[0].name).to eq('extension')
        expect(result[0].children[0].name).to eq('drs:admin')
        expect(result[0].children[0].children[0].name).to eq('drs:captureDate')
        expect(result[0].children[0].children[0]['qualifier']).to be_nil
        expect(result[0].children[0].children[0].text).to eq('1915')
      end
  end #describe modselements
end #describe Mdmm::OtherDateFieldMapper

