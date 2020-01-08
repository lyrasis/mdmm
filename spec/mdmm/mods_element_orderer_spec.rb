RSpec.describe Mdmm::ModsElementOrderer do
  
  describe '.result' do
    describe '#order_titles' do
      let(:elements) { [
        '<titleInfo type="alternative"><title>AT</title></titleInfo>',
        '<titleInfo type="main" usage="primary"><title>PT</title></titleInfo>',
        '<titleInfo><title>OT</title></titleInfo>',
      ].map{ |e| Nokogiri::XML.fragment(e).xpath(".//*").first } }
      let(:result) { Mdmm::ModsElementOrderer.new(elements).result }

      it 'returns Array' do
        expect(result).to be_instance_of(Array)
      end
      it 'puts primary title first' do
        expect(result[0].text).to eq('PT')
      end
      it 'puts untyped non-primary titles next' do
        expect(result[1].text).to eq('OT')
      end
      it 'puts typed non-primary titles last' do
        expect(result[2].text).to eq('AT')
      end
    end #describe order_titles

    describe '#order_elements' do
      let(:elements) { [
        '<part>part info</part>',
        '<subject><topic>sub</topic></subject>',
        '<abstract>abstract</abstract>',
        '<subject><topic>sub2</topic></subject>',
        '<titleInfo type="main" usage="primary"><title>PT</title></titleInfo>',
      ].map{ |e| Nokogiri::XML.fragment(e).xpath(".//*").first } }
      let(:result) { Mdmm::ModsElementOrderer.new(elements).result }

      it 'puts non-complex fields in order' do
        expect(result[0].text).to eq('PT')
        expect(result[1].text).to eq('part info')
        expect(result[2].text).to eq('sub')
        expect(result[3].text).to eq('sub2')
        expect(result[4].text).to eq('abstract')
      end
    end #describe order_elements

    # messy test that combines testing of functions:
    # - special_note_type?
    # - order_notes
    # - order_typed_notes
    describe '#order_notes' do
      let(:elements) { [
        '<identifier>id</identifier>',
        '<note type="preferred citation">citation</note>',
        '<note>note1</note>',
        '<targetAudience>audience</targetAudience>',
        '<note type="ownership">owned by</note>',
        '<note type="transcript">transcript</note>',
        '<note type="system details">system details</note>',
        '<note type="content">content</note>',
        '<note>note2</note>',
        '<genre>genre</genre>',
        '<language>eng</language>',
        '<abstract>abstract</abstract>',
      ].map{ |e| Nokogiri::XML.fragment(e).xpath(".//*").first } }
      let(:result) { Mdmm::ModsElementOrderer.new(elements).result }

      it 'puts non-complex fields in order' do
        expect(result[0].text).to eq('abstract')
        expect(result[1].text).to eq('content')
        expect(result[2].text).to eq('genre')
        expect(result[3].text).to eq('system details')
        expect(result[4].text).to eq('eng')
        expect(result[5].text).to eq('note1')
        expect(result[6].text).to eq('transcript')
        expect(result[7].text).to eq('note2')
        expect(result[8].text).to eq('owned by')
        expect(result[9].text).to eq('audience')
        expect(result[10].text).to eq('citation')
      end
    end #describe order_notes

    describe '#order_names' do
      let(:elements) { [
        '<name><namePart>untyped name no role</namePart></name>',
        '<name type="corporate"><namePart>corporate name no role</namePart></name>',
        '<name type="personal"><namePart>personal name no role</namePart></name>',
        '<name type="conference"><namePart>conference name all</namePart></name>',
        '<name type="family"><namePart>family name all</namePart></name>',
        '<name type="personal"><namePart>personal author2</namePart><role><roleTerm type="code">aut</roleTerm></role></name>',
        '<name><namePart>nontyped contributor</namePart><role><roleTerm>contributor</roleTerm></role></name>',
        '<name type="personal"><namePart>personal contributor</namePart><role><roleTerm>contributor</roleTerm></role></name>',
        '<name type="corporate"><namePart>corporate contributor</namePart><role><roleTerm>contributor</roleTerm></role></name>',

        '<name><namePart>nontyped interviewer</namePart><role><roleTerm type="code">ivr</roleTerm></role></name>',
        '<name type="personal"><namePart>personal interviewer</namePart><role><roleTerm>interviewer</roleTerm></role></name>',
        
        '<name><namePart>nontyped interviewee</namePart><role><roleTerm>interviewee</roleTerm></role></name>',
        '<name type="personal"><namePart>personal interviewee</namePart><role><roleTerm type="code">ive</roleTerm></role></name>',

        '<name><namePart>nontyped creator</namePart><role><roleTerm>creator</roleTerm></role></name>',

        '<name type="personal"><namePart>personal creator</namePart><role><roleTerm>creator</roleTerm></role></name>',        
        '<name type="corporate"><namePart>corporate creator</namePart><role><roleTerm>creator</roleTerm></role></name>',
        '<name><namePart>nontyped author</namePart><role><roleTerm>author</roleTerm></role></name>',
        '<name type="personal"><namePart>personal author</namePart><role><roleTerm>author</roleTerm></role></name>',        
        '<name type="corporate"><namePart>corporate author</namePart><role><roleTerm>author</roleTerm></role></name>',
        '<name type="personal"><namePart>personal interviewer and author</namePart><role><roleTerm>interviewer</roleTerm><roleTerm>author</roleTerm></role></name>',
      ].map{ |e| Nokogiri::XML.fragment(e).xpath(".//*").first } }
      let(:result) { Mdmm::ModsElementOrderer.new(elements).result }

      it 'puts personal authors first' do
        expect(result[0].xpath('namePart').text).to eq('personal author2')
        expect(result[1].xpath('namePart').text).to eq('personal author')
        expect(result[2].xpath('namePart').text).to eq('personal interviewer and author')
      end
      it 'puts personal creators next' do
        expect(result[3].xpath('namePart').text).to eq('personal creator')
      end
      it 'puts corporate authors next' do
        expect(result[4].xpath('namePart').text).to eq('corporate author')
      end
      it 'puts corporate creators next' do
        expect(result[5].xpath('namePart').text).to eq('corporate creator')
      end
      it 'puts untyped authors next' do
        expect(result[6].xpath('namePart').text).to eq('nontyped author')
      end
      it 'puts untyped creators next' do
        expect(result[7].xpath('namePart').text).to eq('nontyped creator')
      end
      it 'puts interviewees next' do
        expect(result[8].xpath('namePart').text).to eq('nontyped interviewee')
        expect(result[9].xpath('namePart').text).to eq('personal interviewee')
      end
      it 'puts interviewers next' do
        expect(result[10].xpath('namePart').text).to eq('nontyped interviewer')
        expect(result[11].xpath('namePart').text).to eq('personal interviewer')
      end
      it 'puts personal contributors next' do
        expect(result[12].xpath('namePart').text).to eq('personal contributor')
      end
      it 'puts other personal names next' do
        expect(result[13].xpath('namePart').text).to eq('personal name no role')
      end
      it 'puts family names next' do
        expect(result[14].xpath('namePart').text).to eq('family name all')
      end
      it 'puts conference names next' do
        expect(result[15].xpath('namePart').text).to eq('conference name all')
      end
      it 'puts corporate contributors next' do
        expect(result[16].xpath('namePart').text).to eq('corporate contributor')
      end
      it 'puts other corporate names next' do
        expect(result[17].xpath('namePart').text).to eq('corporate name no role')
      end
      it 'puts untyped, no-role names last' do
        expect(result[18].xpath('namePart').text).to eq('untyped name no role')
      end
    end #describe order_names

  end # describe .new
end
