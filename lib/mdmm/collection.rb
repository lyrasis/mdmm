require 'mdmm'

module Mdmm
  class Collection
    attr_reader :name # collection name
    attr_reader :colldir # full path to collection directory
    attr_reader :origrecdir # path to directory for original records for individual objects
    attr_reader :migrecdir # path to directory for JSON object records modified with migration-specific data
    attr_reader :cleanrecdir # path to directory for transformed/cleaned migration records
    attr_reader :modsdir # path to directory for MODS records
    attr_reader :migrecs #array of migration record filenames
    attr_reader :cleanrecs #array of clean record filenames

    # Directories within WRK_DIR are identified as collections
    def initialize(colldir)
      @colldir = colldir
      @name = colldir.split('/').pop
      @origrecdir = set_origrecdir
      @migrecdir = "#{@colldir}/_migrecords"
      @cleanrecdir = "#{@colldir}/_cleanrecords"
      @modsdir = "#{@colldir}/_mods"
      Dir.mkdir(@modsdir) unless Dir::exist?(@modsdir)
      set_migrecs
    end

    def map_records
      set_cleanrecs
      @cleanrecs.each{ |cr|
        cleanrec = CleanRecord.new(self, cr)
        Mdmm::LOG.debug("Mapping #{@name}/#{cleanrec.id}")
        cleanrec.map
      }
    end

    def clean_records
      @migrecs.each{ |mr|
        migrec = MigRecord.new(self, mr)
        Mdmm::LOG.debug("Cleaning #{@name}/#{migrec.id}")
        migrec.clean
      }
    end
    
    def set_cleanrecs
      @cleanrecs = Dir.new(@cleanrecdir).children.map{ |name| "#{@cleanrecdir}/#{name}" }
      if @cleanrecs.length == 0
        Mdmm::LOG.warn("No clean records in #{@cleanrecdir}. Run `exe/mdmm clean_recs`.")
        return
      else
        Mdmm::LOG.info("Identified #{@cleanrecs.length} clean records for #{@name}...")
      end
    end

    private

    def set_migrecs
      @migrecs = Dir.new(@migrecdir).children.map{ |name| "#{@migrecdir}/#{name}" }
      if @migrecs.length == 0
        Mdmm::LOG.error("No migrecords in #{@migrecdir}.")
        return
      else
        Mdmm::LOG.info("Identified #{@migrecs.length} migration records for #{@name}...")
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
