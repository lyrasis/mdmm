require 'mdmm'

module Mdmm
  class MappingChooser
    attr_reader :rec
    attr_reader :mappings
    attr_reader :mapping

    # mappings: Array of possible mappings
    # rec: JSON of Mdmm::CleanRecord
    def initialize(mappings, rec)
      @rec = rec
      @mappings = mappings.split(';;;')

      @mappings.each{ |mapping|
        mapfields =  mapping.scan(/%[^%]+%/).uniq.map{ |e| e.delete('%') }
        if record_has_fields(mapfields)
          @mapping = mapping
          break
        end
      }

      return @mapping
    end

    private

    def record_has_fields(fields)
      allfields = @rec.keys
      if fields.length == (allfields & fields).length
        return true
      else
        return false
      end
    end
    
  end #MappingSet
end #Module
