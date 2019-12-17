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
      Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: starting mapping of record")
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
      @elements.each{ |node| root.add_child(node) }
    end

    def do_mappings
      @mappings.each{ |mapping|
        Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: starting mapping: #{mapping}")
        #pp(mapping)
        to_map = mapping.scan(/%[^%]+%/)
        #pp(to_map)
        
        insert_current_date if to_map.include?('%insertcurrentdate%')
        
        case to_map.length
        when 1
          field = to_map[0]
          simple_mapping(field, mapping) if field_present?(field) && !Mdmm.date_field?(field.delete('%'))
          simple_date_mapping(field, mapping) if field_present?(field) && Mdmm.date_field?(field.delete('%'))
        else
          chk = check_multivals(to_map)
          case chk
          when 'single'
            @elements << complex_single_val_mapping(to_map, mapping)
          when 'multi even'
            Mdmm::LOG.warn("MODSMAPPINGS: #{@coll.name}/#{@id}: cannot map ``multi even`` mapping: #{mapping}")
          when 'multi uneven'
            Mdmm::LOG.warn("MODSMAPPINGS: #{@coll.name}/#{@id}: cannot map ``multi uneven`` mapping: #{mapping}")
          when 'missing field'
            Mdmm::LOG.warn("MODSMAPPINGS: #{@coll.name}/#{@id}: cannot map ``missing field`` mapping: #{mapping}")
          end
        end
      }
    end

    def complex_single_val_mapping(to_map, mapping)
      mapping = mapping.clone
      xmlfieldname = get_top_level_xml_fieldname(mapping)
      to_map.each{ |field|
        if Mdmm.date_field?(field.delete('%'))
          Mdmm::LOG.warn("MODSMAPPINGS: #{@coll.name}/#{@id}: only simple date handling available for #{field} in ``complex single val`` mapping: #{mapping}")
        end

        mapping = mapping.sub(field, @orig[field.delete('%')])
      }
      Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: finished ``complex single val`` mapping: #{mapping}")
      Nokogiri::XML.fragment(mapping).xpath(".//#{xmlfieldname}").first
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

    def simple_date_mapping(field, mapping)
      fieldvals = @orig[field.delete('%')].split(';;;')
      fieldvals = fieldvals.map{ |v| get_date_hash(v) }
      case mapping.include?('<originInfo>')
      when true
        origininfo_date_mapping_simple(field, fieldvals, mapping)
      else
        other_date_mapping_simple(field, fieldvals, mapping)
      end
    end

    def origininfo_date_mapping_simple(field, fieldvals, mapping)
      mapping = mapping.gsub(/<\/?originInfo>/, '')
      origininfo = Nokogiri::XML.fragment('<originInfo></originInfo>').xpath('.//originInfo').first
      xmlfieldname = get_top_level_xml_fieldname(mapping)
      fieldvals.each{ |valhash|
        datefieldstring = mapping.sub(field, valhash['value'])
        datefield = Nokogiri::XML.fragment(datefieldstring).xpath(".//#{xmlfieldname}").first
        valhash.each{ |k, v| datefield[k] = v unless k == 'value' }
        origininfo.add_child(datefield)
      }
      @elements << origininfo
      Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: finished ``origininfo date simple`` mapping: #{mapping}")
    end
    
    def other_date_mapping_simple(field, fieldvals, mapping)
      xmlfieldname = get_top_level_xml_fieldname(mapping)
      if fieldvals.length == 1
        use_fieldhash = fieldvals[0]
      else
        use_fieldhash = fieldvals.select{ |h| h['keyDate'] == 'yes' }[0]
      end
      datefieldstring = mapping.sub(field, use_fieldhash['value'])
      datefield = Nokogiri::XML.fragment(datefieldstring).xpath(".//#{xmlfieldname}").first
      @elements << datefield
      Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: finished ``other date simple`` mapping: #{mapping}")
    end
    

    # 1941&&&encoding=w3cdtf&&&keyDate=yes&&&point=start&&&qualifier=approximate
    def get_date_hash(val)
      h = {}
      valarr = val.split('&&&')
      h['value'] = valarr.shift
      valarr.each{ |pair|
        p = pair.split('=')
        h[p[0]] = p[1]
      }
      h
    end

    # circa 1941-1945&&&qualifier=approximate
    # 1941&&&encoding=w3cdtf&&&point=end&&&qualifier=approximate
    def simple_mapping(field, mapping)
      xmlfieldname = get_top_level_xml_fieldname(mapping)
      fieldvals = @orig[field.delete('%')].split(';;;')
      fieldvals.each{ |val|
        result = mapping.clone
        result = result.sub(field, val)
        @elements << Nokogiri::XML.fragment(result).xpath(".//#{xmlfieldname}").first
        Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: finished ``simple`` mapping: #{mapping}")
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

    def get_top_level_xml_fieldname(mapping)
      mapping.match(/^<([^ >]+)/)[1]
    end
    
  end #RecordMapper
end #Module
