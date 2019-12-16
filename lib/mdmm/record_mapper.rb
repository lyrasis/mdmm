require 'mdmm'

module Mdmm
  class RecordMapper
    attr_reader :coll
    attr_reader :orig
    attr_reader :id
    attr_reader :mappings
    attr_reader :mods
    attr_reader :elements
	
    def initialize(cleanrec)
      @coll = cleanrec.coll
      @orig = cleanrec.json
      @id = cleanrec.id
      @mappings = Mdmm::CONFIG.mappings[@coll.name].uniq
      @mods = base_mods
      @elements = []
      do_mappings
      build_doc
      write_doc
    end

    private
    def build_doc
      root =  @mods.root
      @elements.each{ |nodeset|
        nodeset.children.each{ |child| root.add_child(child) }
      }
    end

    def do_mappings
      @mappings.each{ |mapping|
        #pp(mapping)
        to_map = mapping.scan(/%[^%]+%/)
        #pp(to_map)

        insert_current_date if to_map.include?('%insertcurrentdate%')
        
        case to_map.length
        when 1
          field = to_map[0]
          simple_mapping(field, mapping) if field_present?(field)
        else
          chk = check_multivals(to_map)
          case chk
          when 'single'
            @elements << Nokogiri::XML.fragment(complex_single_val_mapping(to_map, mapping))
          when 'multi even'
          when 'multi uneven'
          when 'missing field'
          end
        end
      }
    end

    def complex_single_val_mapping(to_map, mapping)
      mapping = mapping.clone
      to_map.each{ |field|
        mapping = mapping.sub(field, @orig[field.delete('%')])
      }
      mapping
    end

    def insert_current_date
      @orig['insertcurrentdate'] = Time.now.strftime("%Y-%m-%d")
    end

    def check_multivals(to_map)
      lengths = {}
      to_map.each{ |field|
        if field_present?(field)
          ln = @orig[field.delete('%')].split(';;;').length
          lengths[ln] = ''
        else
          lengths[0] = ''
        end
      }
      lengths = lengths.keys
      result = 'single' if lengths == [1]
      result = 'multi even' if lengths.length == 1 && lengths != [1]
      result = 'missing field' if lengths.include?(0) && lengths.length > 1
      result = 'multi uneven' if !lengths.include?(0) && lengths.length > 1
      result
    end
    
    def simple_mapping(field, mapping)
      fieldvals = @orig[field.delete('%')].split(';;;')
      fieldvals.each{ |val|
        result = mapping.clone
        result = result.sub(field, val)
        @elements << Nokogiri::XML.fragment(result)
      }
    end

    def field_present?(field)
      field = field.delete('%')
      return true if @orig[field]
    end

    
    def base_mods
      s = '<?xml version="1.0"?><mods xmlns="http://www.loc.gov/mods/v3" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:drs="http://www.lyrasis.org/drs"></mods>'
      Nokogiri::XML(s)
    end

    def write_doc
      path = "#{@coll.modsdir}/#{@id}.xml"
      File.write(path, @mods.to_xml)
    end

  end #RecordMapper
end #Module
