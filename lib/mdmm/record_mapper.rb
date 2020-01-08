require 'mdmm'

module Mdmm
  class RecordMapper
    attr_reader :coll
    attr_reader :rec
    attr_reader :orig
    attr_reader :id
    attr_reader :mappings
    attr_reader :mods
    attr_reader :elements
	
    def initialize(cleanrec)
      @rec = cleanrec
      @coll = @rec.coll
      @orig = @rec.json
      @id = @rec.id
      Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: starting mapping of record")
      @mappings = Mdmm::CONFIG.mappings[@coll.name].uniq
      @mods = base_mods
      @elements = []
      escape_characters
      do_mappings
      @elements = ModsElementConsolidator.new(@elements).result unless Mdmm::CONFIG.single_mods_top_elements.empty?
      @elements = ModsElementOrderer.new(@elements).result
      build_doc
      write_doc
    end

    private

    def escape_characters
      replacements = {
        '&' => '&amp;',
        '"' => '&quot;',
        "'" => '&apos;',
        '<' => '&lt;',
        '>' => '&gt;'
      }

      changed = {}
      
      @orig.each{ |field, val|
        if val.is_a?(String)
          valcopy = val.clone
          needs_escape(replacements.keys, val).each{ |repchar|
            valcopy = valcopy.gsub(repchar, replacements[repchar])
          }
          changed[field] = valcopy unless val == valcopy
        end
      }

      changed.each{ |field, val| @orig[field] = val }
    end

    # returns array of characters that need escaping in field
    # or blank array if no characters need escaping
    def needs_escape(escape_chars, string)
      return escape_chars & string.split(//).uniq
    end
    
    def build_doc
      root =  @mods.root
      @elements.each{ |node| root.add_child(node) }
    end

    def do_mappings
      @mappings.each{ |m|
        Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: starting mapping: #{m}")
        insert_current_date if m['%insertcurrentdate%']
        mapping = m.include?(';;;') ? Mdmm::MappingChooser.new(m, @orig).mapping : m

        if mapping.nil?
          Mdmm::LOG.warn("MODSMAPPINGS: #{@coll.name}/#{@id}: No usable mapping in #{m}")
        else
          chk = MappingChecker.new(@orig, mapping)
          if chk.missingfield
            Mdmm::LOG.info("MODSMAPPINGS: #{@coll.name}/#{@id}: skipping ``missing fields`` mapping: #{mapping}")
            next
          end
          if chk.multifield && !chk.even
            Mdmm::LOG.warn("MODSMAPPINGS: #{@coll.name}/#{@id}: cannot map ``multi uneven`` mapping: #{mapping}")
            next
          end
          if chk.multifield && chk.dates
            Mdmm::LOG.warn("MODSMAPPINGS: #{@coll.name}/#{@id}: cannot map ``multi-field date`` mapping: #{mapping}")
            next
          end
          if !chk.multifield && !chk.dates
            Mdmm::SingleFieldMapper.new(@orig, mapping).modselements.each{ |e| @elements << e }
            Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: finished `single field` mapping: #{mapping}")
          end
          if chk.multifield && !chk.dates
            Mdmm::MultiFieldMapper.new(@orig, mapping).modselements.each{ |e| @elements << e }
            Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: finished `multi field` mapping: #{mapping}")
          end
          if chk.dates
            if mapping['originInfo']
            Mdmm::OrigininfoDateFieldMapper.new(@orig, mapping).modselements.each{ |e| @elements << e }
            Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: finished `origininfo date field` mapping: #{mapping}")
            else
              Mdmm::OtherDateFieldMapper.new(@orig, mapping).modselements.each{ |e| @elements << e }
              Mdmm::LOG.debug("MODSMAPPINGS: #{@coll.name}/#{@id}: finished `other date field` mapping: #{mapping}")
            end
          end
        end
      }
    end

    def insert_current_date
      @orig['insertcurrentdate'] = Time.now.strftime("%Y-%m-%d")
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
