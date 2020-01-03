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

  # handles mappings involving a single date field. The field may have multiple values or not.
  # only one value gets used and field attributes are not set
  class DateFieldMapper < Mapper
    attr_reader :field
    attr_reader :vals
    
    def initialize(rec, mapping)
      super
      @field = @to_map[0]
      @vals = @rec["#{field}_cleaned"].split(';;;').map{ |val| get_date_hash(val) }
    end

    private
    # 1941&&&encoding=w3cdtf&&&keyDate=yes&&&point=start&&&qualifier=approximate
    def get_date_hash(val)
      h = {}
      valarr = val.split('^^^')
      h['value'] = valarr.shift
      valarr.each{ |pair|
        p = pair.split('=')
        h[p[0]] = p[1]
      }
      h
    end
  end #DateFieldMapper

  class OtherDateFieldMapper < DateFieldMapper
    def initialize(rec, mapping)
      super
      map_data
    end

    private
    
    def map_data
      if @vals.length == 1
        use_fieldhash = @vals[0]
      else
        use_fieldhash = @vals.select{ |h| h['keyDate'] == 'yes' }[0]
      end

      result = mapping.clone
      result = result.sub("%#{field}%", use_fieldhash['value'])
      @modselements << Nokogiri::XML.fragment(result).xpath(".//#{@top_level}").first
    end
  end #OtherDateFieldMapper

    class OrigininfoDateFieldMapper < DateFieldMapper
    def initialize(rec, mapping)
      super
      @mapping = @mapping.gsub(/<\/?originInfo>/, '')
      @top_level = get_top_level_xml_fieldname
      map_data
    end

    private
    
    def map_data
      origininfo = Nokogiri::XML.fragment('<originInfo></originInfo>').xpath('.//originInfo').first
      @vals.each{ |valhash|
      result = @mapping.clone
      result = result.sub("%#{field}%", valhash['value'])
      datefield = Nokogiri::XML.fragment(result).xpath(".//#{@top_level}").first
        valhash.each{ |k, v| datefield[k] = v unless k == 'value' }
        origininfo.add_child(datefield)
      }
      @modselements << origininfo
    end
  end #OrigininfoDateFieldMapper

    



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

  # handles mappings involving multiple, non-date fields.
  # The field may have multiple values or not. The number of values should be even.
  class MultiFieldMapper < Mapper
    def initialize(rec, mapping)
      super
      map_data
    end

    private

    def map_data
      splitvals = []
      @to_map.each{ |field| splitvals << @rec[field].split(';;;') }
      sets = splitvals.transpose
      labeled = sets.map{ |set| set.map.with_index{ |val, i| [@to_map[i], val] } }
      sethashes = labeled.map{ |set| set.to_h }

      sethashes.each{ |sethash|
        mapcopy = mapping.clone
        sethash.each{ |field, value|
          fsub = "%#{field}%"
          mapcopy = mapcopy.gsub(fsub, value)
        }
        @modselements << Nokogiri::XML.fragment(mapcopy).xpath(".//#{@top_level}").first
      }
    end
  end #MultiFieldMapper
end #Module
