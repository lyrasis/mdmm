require 'mdmm'

module Mdmm
  class Collection
    attr_reader :name # collection name
    attr_reader :colldir # full path to collection directory
    attr_reader :migrecdir # path to directory for JSON object records modified with migration-specific data
    attr_reader :cleanrecdir # path to directory for transformed/cleaned migration records
    attr_reader :modsdir # path to directory for MODS records
    attr_reader :migrecs #array of migration record filenames
    attr_reader :cleanrecs #array of clean record filenames

    # Directories within WRK_DIR are identified as collections
    def initialize(colldir)
      @colldir = File.expand_path(colldir)
      @name = colldir.split('/').pop
      @migrecdir = "#{@colldir}/_migrecords"
      @cleanrecdir = "#{@colldir}/_cleanrecords"
      Dir.mkdir(@cleanrecdir) unless Dir::exist?(@cleanrecdir)
      @modsdir = "#{@colldir}/_mods"
      Dir.mkdir(@modsdir) unless Dir::exist?(@modsdir)
      set_migrecs
      self
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
      delete_existing_cleanrecs
      @migrecs.each{ |mr|
        migrec = MigRecord.new(self, mr)
        Mdmm::LOG.debug("Cleaning #{@name}/#{migrec.id}")
        migrec.clean
      }
      set_cleanrecs
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

    def delete_existing_cleanrecs
      ex_clean = Dir.new(@cleanrecdir).children.map{ |name| "#{@cleanrecdir}/#{name}" } if Dir.exist?(@cleanrecdir)
      ex_clean.each{ |crec| File.delete(crec) }
    end
    
    def set_migrecs
      @migrecs = Dir.new(@migrecdir).children.map{ |name| "#{@migrecdir}/#{name}" }
      if @migrecs.length == 0
        Mdmm::LOG.error("No migrecords in #{@migrecdir}.")
        return
      else
        Mdmm::LOG.info("Identified #{@migrecs.length} migration records for #{@name}...")
      end
    end

  end # Collection
end # Mdmm
