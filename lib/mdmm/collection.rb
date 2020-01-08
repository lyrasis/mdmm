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
      delete_existing_mods
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

    def validate_mods
      schema = Nokogiri::XML::Schema(File.read(Mdmm::CONFIG.mods_schema))
      files = Dir.new(@modsdir).children.map{ |f| "#{@modsdir}/#{f}" }
      pb = ProgressBar.create(:title => "Validating #{files.length} MODS files for #{@name}",
                              :starting_at => 0,
                              :total => files.length,
                              :format => '%a |%b>>%i| %p%% %t')
      flag = 0
      files.each{ |f|
        doc = Nokogiri::XML(File.read(f))
        v = schema.validate(doc)
        if v.length == 0
          Mdmm::LOG.debug("MODS VALIDATION: valid MODS: #{f}")
        else
          v.each{ |e| Mdmm::LOG.error("MODS VALIDATION: invalid MODS: #{e}") }
          flag += 1
        end
        pb.increment
      }
      pb.finish
      puts "#{flag} invalid MODS files in #{name}. See log for details." if flag > 0
    end
    
    def compile_mods(path)
      Dir.mkdir(path) unless Dir.exist?(path)
      colldir = "#{path}/#{@name}"
      Dir.mkdir(colldir) unless Dir.exist?(colldir)
      Dir.new(@modsdir).children.each{ |modsfile|
        FileUtils.cp("#{@modsdir}/#{modsfile}", "#{colldir}/#{modsfile}")
      }
    end

    private

    def delete_existing_mods
      ex_mods = Dir.new(@modsdir).children.map{ |name| "#{@modsdir}/#{name}" } if Dir.exist?(@modsdir)
      ex_mods.each{ |modsfile| File.delete(modsfile) }
    end
    
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
