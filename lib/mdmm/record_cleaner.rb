require 'mdmm'

module Mdmm
  class RecordCleaner
    attr_reader :coll
    attr_reader :orig
    attr_reader :working
    attr_reader :cleaned
    attr_reader :fields
    attr_reader :id
    
    def initialize(migrec)
      @coll = migrec.coll
      @orig = migrec.json
      @id = migrec.id
      @fields = migrec.cleanfields
      @cleaned = {}

      fields_cat = categorize_fields
      @working = fields_cat[:to_clean]
      remove_empty_fields
      replacement_handler(Mdmm::CONFIG.prelim_replacements)
      replacement_handler(Mdmm::CONFIG.splits)
      whitespace_cleaner
      field_remapping_handler(Mdmm::CONFIG.move_fields)
      field_remapping_handler(Mdmm::CONFIG.move_and_replaces)
      field_remapping_handler(Mdmm::CONFIG.derive_fields)
      field_remapping_handler(Mdmm::CONFIG.extractions)
      replacement_handler(Mdmm::CONFIG.replacements)
      add_constants if Mdmm::CONFIG.constant_fields      
      whitespace_cleaner #to take care of any issues introduced by replacements
      change_case
      replacement_handler(Mdmm::CONFIG.cross_multival_replacements, split: false)
      remove_empty_fields
      clean_dates
      compile_cleaned_record(fields_cat[:to_ignore])
      write_clean_record
    end

    private

    def clean_dates
      date_fields = {}
      @working.each{ |field, value|
        date_fields[field] = value if Mdmm.date_field?(field)
      }
      date_fields.each{ |field, value|
        d = Mdmm::DateParser.new("#{coll.name}/#{id}", value).result
        @working["#{field}_cleaned"] = d.join(Mdmm::CONFIG.multivalue_delimiter)
      }
    end
    
    def add_constants
      Mdmm::CONFIG.constant_fields.each{ |config|
        if applies_to_coll?(config)
          fieldname = config['field']
          if @working[fieldname]
            fieldval = @working[fieldname].split(Mdmm::CONFIG.multivalue_delimiter)
          else
            fieldval = []
          end

          fieldval << config['value']
          @working[fieldname] = fieldval.join(Mdmm::CONFIG.multivalue_delimiter)
        end
      }
    end

    def remove_empty_fields
      empty_fields.each{ |fieldname| @working.delete(fieldname) }
    end

    def empty_fields
      fieldlist = []
      #@working.each{ |field, value| fieldlist << field if value == {} || value == [] || value == ''}
      @working.each{ |field, value| fieldlist << field if value.empty?}
      fieldlist
    end
    
    def field_remapping_handler(configs)
      configs.each{ |config|
        to_remap = []
        
        if applies_to_coll?(config)
          @working.each{ |field, value|
            if applies_to_field?(config, field)
              if value.split(Mdmm::CONFIG.multivalue_delimiter).select{ |e| e.match?(config['condition']) }.length > 0
                to_remap << field
              end
            end
          }
          remap_fields(config, to_remap)
        end
      }
    end

    def add_field_value(newfieldname, value)
      if @working[newfieldname]
        newfieldval = @working[newfieldname].split(Mdmm::CONFIG.multivalue_delimiter)
      else
        newfieldval = []
      end        
      newfieldval << value
      @working[newfieldname] = newfieldval.join(Mdmm::CONFIG.multivalue_delimiter)
    end
    

    def remap_fields(config, fieldnames)
      fieldnames.each { |fieldname|
        exfieldval = @working[fieldname].split(Mdmm::CONFIG.multivalue_delimiter)
        if config['moveto']
          exfieldval.select{ |e| e.match?(config['condition']) }.each { |val|
            add_field_value(config['moveto'], val)
            exfieldval.delete(val)
            Mdmm::LOG.info("#{@coll.name}/#{@id}: Moved field value ''#{val}'' to #{config['moveto']} because it matched ''#{config['condition']}''")
          }
        end
        
        if config['replacewith']
          exfieldval << config['replacewith']
          Mdmm::LOG.info("#{@coll.name}/#{@id}: Added replacement field value ''#{config['replacewith']}'' to #{fieldname} because original value matched ''#{config['condition']}''")
        end

        if config['derivefield']
          exfieldval.select{ |e| e.match?(config['condition']) }.each { |val|
            unless @working[config['derivefield']] && @working[config['derivefield']].split(Mdmm::CONFIG.multivalue_delimiter).include?(config['derivevalue'])
              add_field_value(config['derivefield'], config['derivevalue'])
              Mdmm::LOG.info("#{@coll.name}/#{@id}: Added derived field value ''#{config['derivevalue']}'' to #{config['derivefield']} because #{fieldname} value matched ''#{config['condition']}''")
            end
          }
        end

        if config['extracttofield']
          exfieldval.select{ |e| e.match?(config['condition']) }.each { |val|
            fieldpart = val.match(config['condition'])[config['extractmatch']]
            add_field_value(config['extracttofield'], fieldpart)
            Mdmm::LOG.info("#{@coll.name}/#{@id}: Extracted #{fieldpart} from #{fieldname} to #{config['extracttofield']}")
          }
        end
        
        if exfieldval.length > 0
          @working[fieldname] = exfieldval.join(Mdmm::CONFIG.multivalue_delimiter)
        else
          @working.delete(fieldname)
        end
      }
    end
    
    def change_case
      Mdmm::CONFIG.case_changes.each{ |cc|
        if applies_to_coll?(cc)
          @working.each{ |field, value|
            if applies_to_field?(cc, field)
              vsplit = value.split(Mdmm::CONFIG.multivalue_delimiter)
              case cc['case']
              when 'upper'
                result = vsplit.map{ |e| e.sub(/^(.)(.*)/){ $1.upcase << $2 } }
              when 'lower'
                result = vsplit.map{ |e| e.sub(/^(.)(.*)/){ $1.downcase << $2 } }
              end
              result = result.join(Mdmm::CONFIG.multivalue_delimiter)
              @working[field] = result
              Mdmm::LOG.info("#{@coll.name}/#{@id}: Normalized case in #{field}: ''#{value}'' -> ''#{result}''") if value != result
            end
          }
        end
      }
    end
    
    def whitespace_cleaner
      @working.each{ |field, val|
        val = val.split(Mdmm::CONFIG.multivalue_delimiter)
        cleaned = val.map{ |v| remove_whitespace(v) }
        @working[field] = cleaned.join(Mdmm::CONFIG.multivalue_delimiter)
      }
    end

    def remove_whitespace(val)
      val = val.gsub("\n", ' ')
      val = val.strip
      val = val.gsub(/  +/, ' ')
    end
    
    def compile_cleaned_record(ignored_fields)
      @working.each{ |field, value|
        @cleaned[field] = value.split(Mdmm::CONFIG.multivalue_delimiter).uniq.reject{ |v| v.empty? }.join(Mdmm::CONFIG.multivalue_delimiter)
      }
      ignored_fields.each{ |field, value|
        v = value if value.is_a?(Hash)
        v = value.join(Mdmm::CONFIG.multivalue_delimiter) if value.is_a?(Array)
        v = value if value.is_a?(String)
        @cleaned[field] = v
      }
    end

    def write_clean_record
      path = "#{@coll.cleanrecdir}/#{@id}.json"
      File.open(path, 'w'){ |f|
        f.write(@cleaned.to_json)
      }
    end

    def replacement_handler(configs = [], split: true)
      configs.each{ |sub|
        case applies_to_coll?(sub)
        when false
          next
        when true
          @working.each{ |field, value|
            do_replacements_on_field(sub, field, value, split)
          }
        end
      }
    end

    def do_replacements_on_field(sub, field, value, split)
      case applies_to_field?(sub, field)
      when false
        @working[field] = value
      when true
        do_replacement(sub, field, value, split)
      end
    end

    def do_replacement(sub, field, value, split)
      vsplit = value.split(Mdmm::CONFIG.multivalue_delimiter) if split
      case sub['type']
      when 'plain'
        cleaned = vsplit.map{ |e| e.gsub(sub['find'], sub['replace']) } if split
        cleaned = value.gsub(sub['find'], sub['replace'])  if !split
      when 'regexp'
        cleaned = vsplit.map{ |e| e.gsub(Regexp.new(sub['find']), sub['replace']) } if split
        cleaned = value.gsub(Regexp.new(sub['find']), sub['replace']) if !split
      else
        puts "No type given for REPLACEMENT (''#{sub['find']}'' -> ''#{sub['replace']}''"
      end
      result = cleaned.join(Mdmm::CONFIG.multivalue_delimiter) if split
      result = cleaned if !split
      @working[field] = result

      case value == result
      when false
        Mdmm::LOG.info("#{@coll.name}/#{@id}: #{sub['type'].upcase} REPLACEMENT (''#{sub['find']}'' -> ''#{sub['replace']}'') IN #{field} WITH RESULT: ''#{value}'' -> ''#{result}''")
      end
    end
    
    def applies_to_coll?(sub)
      return true if sub['colls'] == ''
      return true if sub['colls'].include?(@coll.name)
      return false
    end

    def applies_to_field?(sub, field)
      return true if sub['fields'] == ''
      return true if sub['fields'].include?(field)
      return false
    end

    def categorize_fields
      h = { :to_clean => {},
           :to_ignore => {}
          }
      
      @orig.each{ |field, value|
        case @fields.include?(field)
        when true
          h[:to_clean][field] = value
        when false
          h[:to_ignore][field] = value
        end
      }
      h
    end
    
  end

end
