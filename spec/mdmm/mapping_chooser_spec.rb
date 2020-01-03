RSpec.describe Mdmm::MappingChooser do
  # let!(Mdmm::CONFIGPATH) { stub_const('Mdmm::CONFIGPATH', 'spec/fixtures/files/nearly_blank_config.yaml') }

  # before do
  #   stub_const('Mdmm::CONFIG', Mdmm::ConfigReader.new)
  # end
  
  describe "#mapping" do
    context 'when all fields from first mapping present' do
      it "returns first mapping" do
        s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mappings = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>;;;<relatedItem type=""host""><titleInfo><title>Folder</title></titleInfo><location><url displayLabel=""Folder"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChooser.new(mappings, rec).mapping
        expect(result).to eq('<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>')
      end
    end

    context 'when all fields from first mapping are NOT present' do
      context 'AND when all fields from second mapping are present' do
        it "returns second mapping" do
          s = '{"relfolderlink":"https://link.to.foldera"}'
          rec = JSON.parse(s)
          mappings = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>;;;<relatedItem type=""host""><titleInfo><title>Folder</title></titleInfo><location><url displayLabel=""Folder"">%relfolderlink%</url></location></relatedItem>'
          result = MappingChooser.new(mappings, rec).mapping
          expect(result).to eq('<relatedItem type=""host""><titleInfo><title>Folder</title></titleInfo><location><url displayLabel=""Folder"">%relfolderlink%</url></location></relatedItem>')
        end
      end
    end

    context 'when all fields from no mappings are present' do
      it "returns nil" do
        s = '{"relseriestitle":"Folder A","relserieslink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mappings = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>;;;<relatedItem type=""host""><titleInfo><title>Folder</title></titleInfo><location><url displayLabel=""Folder"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChooser.new(mappings, rec).mapping
        expect(result).to be_nil
      end
    end

  end # describe mapping
end
