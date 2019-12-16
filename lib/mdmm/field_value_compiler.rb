require 'mdmm'

module Mdmm
  class FieldValueCompiler
    attr_reader :colls, :type, :format, :headers, :rows, :recs
    
    # initialize with array of Mdmm::Collection objects
    def initialize(colls, type, format)
      @colls = colls
      @type = type
      @format = format
      @headers = []
      @rows = []
      @recs = []

      set_recs
      set_headers
      set_rows
      write_csv
    end


    private

    def set_rows
      case @format
      when 'compact'
        set_compact_rows
      when 'exploded'
        set_exploded_rows
      end
    end

    def set_compact_rows
      @recs.each{ |recobj|
        row = []
        @headers.each{ |h| row << field_value(h, recobj) }
        @rows << row
      }
    end

    def field_value(fieldname, recobj)
      rec = recobj.json
      case fieldname
      when 'coll'
        return recobj.coll.name
      when 'recordid'
        return "#{recobj.coll.name}/#{recobj.id}"
      else
        if rec[fieldname]
          return rec[fieldname]
        else
          return ''
        end
      end
    end
    
    def get_all_fields
      fields = {}
      @recs.each{ |rec| rec.reportfields.each{ |f| fields[f] = '' } }
      fields.keys.sort
    end
    
    def set_exploded_rows
      @recs.each{ |rec| get_field_values(rec, rec.coll.name).each{ |fv| @rows << fv } }
    end
    
    def set_recs      
      colls.each{ |coll|
        recs = get_recs(coll)
        if recs.length == 0
          Mdmm::LOG.warn("#{coll.name} has no #{@type} records. Skipping collection.")
          next
        else
          recs.each{ |rec| @recs << rec }
        end
      }
    end
    
    def set_headers
      case @format
      when 'compact'
        @headers = ['coll', 'recordid']
        get_all_fields.each{ |f| @headers << f }
      when 'exploded'
        @headers = ['coll', 'field', 'fieldvalue', 'recordid']
      end
    end
    
    def write_csv
      CSV.open(Mdmm::CONFIG.fieldvalues_file, 'wb'){ |csv|
        csv << headers
        rows.each{ |row| csv << row }
      }
    end

    def get_recs(coll)
      case @type
      when 'mig'
        recs = coll.migrecs.map{ |r| Mdmm::MigRecord.new(coll, r) }
      when 'clean'
        coll.set_cleanrecs
        recs = coll.cleanrecs.map{ |r| Mdmm::CleanRecord.new(coll, r) }
      end
      recs
    end

    def get_field_values(recobj, collname)
      keepfields = recobj.reportfields
      rec = recobj.json
      id = "#{collname}/#{recobj.id}"
      results = []
      rec.each{ |field, value|
        results << [collname,field, value, id] if keepfields.include?(field)
      }
      results
    end
    
  end # FieldValueCompiler
end # Mdmm
