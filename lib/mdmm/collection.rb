require 'mdmm'

module Mdmm
  class Collection
    attr_reader :name # collection name
    attr_reader :colldir # full path to collection directory
    attr_reader :origrecdir # path to directory for original records for individual objects
    attr_reader :migrecdir # path to directory for JSON object records modified with migration-specific data
    attr_reader :cleanrecdir # path to directory for transformed/cleaned migration records
    attr_reader :migrecs #array of migration record filenames

    # Directories within WRK_DIR are identified as collections
    def initialize(dirname)
      @name = dirname
      @colldir = "#{Mdmm::WRK_DIR}/#{dirname}"
      @origrecdir = set_origrecdir
      @migrecdir = "#{@colldir}/_migrecords"
      @cleanrecdir = "#{@colldir}/_cleanrecords"
      set_migrecs
    end

    private

    def set_migrecs
      @migrecs = Dir.new(@migrecdir).children
      if @migrecs.length == 0
        Mdmm::LOG.error("No migrecords in #{@migrecdir}.")
        return
      else
        Mdmm::LOG.info("Identified #{@migrecs.length} records for #{@name}...")
      end
    end

    def set_origrecdir
      possible = [
        "#{@colldir}/_cdmrecords",
        "#{@colldir}/_oxrecords"
      ]
      extant = possible.select{ |d| Dir::exist?(d) }
      case extant.length
      when 1
        return extant[0]
      when 0
        Mdmm::LOG.warn("No original record directory was identified for collection: #{@colldir}")
        return nil
      else
        Mdmm::LOG.warn("Multiple original record directories identified for collection: #{@colldir}")
        return nil
      end
    end
    
  end # Collection
end # Mdmm
