RSpec.describe Mdmm::MappingChecker do

  describe "#multifield" do
    context 'when more than one field is used in mapping' do
      it "returns true" do
        s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).multifield
        expect(result).to be true
      end
    end

    context 'when one field is used in mapping' do
      it "returns false" do
        s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo></relatedItem>'
        result = MappingChecker.new(rec, mapping).multifield
        expect(result).to be false
      end
    end
  end

  describe "#missingfield" do
    context 'when there is only one field in the mapping' do
      context 'and when mapping field is present in record' do
        it "returns false" do
          s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
          rec = JSON.parse(s)
          mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo></relatedItem>'
          result = MappingChecker.new(rec, mapping).missingfield
          expect(result).to be false
        end
      end

      context 'and when mapping field is missing from record' do
        it "returns true" do
          s = '{"title":"Folder A","relfolderlink":"https://link.to.foldera"}'
          rec = JSON.parse(s)
          mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo></relatedItem>'
          result = MappingChecker.new(rec, mapping).missingfield
          expect(result).to be true
        end
      end
end
    
    context 'when there are multiple fields in the mapping' do
      context 'and when all mapping fields are present in record' do
        it "returns false" do
          s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
          rec = JSON.parse(s)
          mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
          result = MappingChecker.new(rec, mapping).missingfield
          expect(result).to be false
        end
      end

      context 'and when one mapping field is missing from record' do
        it "returns true" do
          s = '{"relfoldertitle":"Folder A"}'
          rec = JSON.parse(s)
          mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
          result = MappingChecker.new(rec, mapping).missingfield
          expect(result).to be true
        end
      end

      context 'and when all mapping fields are missing from record' do
        it "returns true" do
          s = '{"title":"Folder A"}'
          rec = JSON.parse(s)
          mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
          result = MappingChecker.new(rec, mapping).missingfield
          expect(result).to be true
        end
      end

    end
  end
  
  describe "#even" do
    context 'when all fields have a single value' do
      it "returns true" do
        s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).even
        expect(result).to be true
      end
    end

    context 'when all fields have two values' do
      it "returns true" do
        s = '{"relfoldertitle":"Folder A;;;Folder B","relfolderlink":"https://link.to.foldera;;;https://link.to.folderb"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).even
        expect(result).to be true
      end
    end

    context 'when one field has one values and another has two values' do
      it "returns false" do
        s = '{"relfoldertitle":"Folder A;;;Folder B","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).even
        expect(result).to be false
      end
    end

    context 'when one field is used in mapping' do
      it "returns false" do
        s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo></relatedItem>'
        result = MappingChecker.new(rec, mapping).even
        expect(result).to be false
      end
    end
end # describe even

  describe "#multival" do
    context 'when all fields have a single value' do
      it "returns false" do
        s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).multival
        expect(result).to be false
      end
    end

    context 'when all fields have two values' do
      it "returns true" do
        s = '{"relfoldertitle":"Folder A;;;Folder B","relfolderlink":"https://link.to.foldera;;;https://link.to.folderb"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).multival
        expect(result).to be true
      end
    end

    context 'when one field has one values and another has two values' do
      it "returns true" do
        s = '{"relfoldertitle":"Folder A;;;Folder B","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).multival
        expect(result).to be true
      end
    end
    
  end # describe multival

  describe '#dates' do
    let!(Mdmm::CONFIGPATH) { stub_const('Mdmm::CONFIGPATH', 'spec/fixtures/files/nearly_blank_config.yaml') }

    before do
      stub_const('Mdmm::CONFIG', Mdmm::ConfigReader.new)
    end

    context 'when none of the fields are date fields' do
      it "returns false" do
        s = '{"relfoldertitle":"Folder A","relfolderlink":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%relfolderlink%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).dates
        expect(result).to be false
      end
    end

    context 'when one of the fields are date fields' do
      it "returns true" do
        s = '{"relfoldertitle":"Folder A","publis":"https://link.to.foldera"}'
        rec = JSON.parse(s)
        mapping = '<relatedItem type=""host""><titleInfo><title>%relfoldertitle%</title></titleInfo><location><url displayLabel=""%relfoldertitle%"">%publis%</url></location></relatedItem>'
        result = MappingChecker.new(rec, mapping).dates
        expect(result).to be true
      end
    end

  end
end
