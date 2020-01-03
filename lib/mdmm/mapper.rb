require 'mdmm'

module Mdmm
  class Mapper
    attr_reader :rec
    attr_reader :mapping
    attr_reader :to_map
    attr_reader :top_level
    attr_reader :modselements

    # rec: JSON of Mdmm::CleanRecord
    # mapping: String: mapping to check against
    def initialize(rec, mapping)
      @rec = rec
      @mapping = mapping
      @to_map = Mdmm.get_mapping_fields(@mapping)
      @top_level = get_top_level_xml_fieldname
      @modselements = []
    end

    private
    
    def get_top_level_xml_fieldname
      @mapping.match(/^<([^ >]+)/)[1]
    end

  end #Mapper

  # handles mappings involving a single, non-date field. The field may have multiple values or not.
  class SingleFieldMapper < Mapper
    def initialize(rec, mapping)
      super
      map_data
    end

    private

    def map_data
      field = @to_map[0]
      vals = @rec[field].split(';;;')
      vals.each{ |val|
        result = mapping.clone
        result = result.sub("%#{field}%", val)
        @modselements << Nokogiri::XML.fragment(result).xpath(".//#{@top_level}").first
      }

    end
    
  end #SingleFieldMapper
end #Module
