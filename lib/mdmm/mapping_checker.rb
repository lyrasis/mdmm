require 'mdmm'

module Mdmm
  class MappingChecker
    attr_reader :rec
    attr_reader :mapping
    attr_reader :multifield #boolean: true if mapping involves values from more than one field
    attr_reader :even #boolean: whether the field(s) involved in mapping have even numbers of values
    attr_reader :multival #boolean: whether the field(s) involved in mapping have >1 value
    attr_reader :missingfield #boolean: whether all field(s) involved in mapping are missing
    attr_reader :dates #boolean: whether the field(s) involved in mapping include any date fields

    # rec: JSON of Mdmm::CleanRecord
    # mapping: String: mapping to check against
    def initialize(rec, mapping)
      @rec = rec
      @mapping = mapping
      set_multifield
      @multifield ? set_even : @even = false
      set_multival
      set_missingfield
      set_dates
    end

    private

    def set_multifield
      if Mdmm.get_mapping_fields(@mapping).length > 1
        @multifield = true
      else
        @multifield = false
      end
    end
    
    def set_even
      fvc = get_field_value_counts
      if fvc.length == 1
        @even = true
      else
        @even = false
      end
    end

    def set_multival
      fvc = get_field_value_counts
      longest = fvc.max
      if longest == 1
        @multival = false
      else
        @multival = true
      end
    end

    def set_missingfield
      fvc = get_field_value_counts
      if fvc == [0]
        @missingfield = true
      elsif fvc.include?(0)
        @missingfield = true
      else
        @missingfield = false
      end
    end
    
    def set_dates
      @dates = false
      Mdmm.get_mapping_fields(@mapping).each{ |f| @dates = true if Mdmm.date_field?(f) }
    end
    
    def get_field_value_counts
      mapfields = Mdmm.get_mapping_fields(@mapping)
      lenhash = {}
      mapfields.each{ |f|
        if @rec[f]
          lenhash[@rec[f].split(';;;').length] = ''
        else
          lenhash[0] = ''
        end
        }
      lenhash.keys
    end
  end #MappingSet
end #Module
