require 'mdmm'

module Mdmm
  class Collection
    attr_reader :name # collection name
    attr_reader :colldir # full path to collection directory
    attr_reader :migrecdir # path to directory for JSON object records modified with migration-specific data
    attr_reader :cleanrecdir # path to directory for transformed/cleaned migration records
    attr_reader :modsdir # path to directory for MODS records
    attr_reader :objdir # path to directory for harvested objects
    attr_reader :tndir # path to directory for thumbnails
    attr_reader :ingestpkgdir # path to directory for ingest packages
    attr_reader :migrecs #array of migration record filepaths
    attr_reader :cleanrecs #array of clean record filepaths
    attr_reader :omittedrecs #array of rec ids to be omitted from processing
    attr_reader :mappings #metadata mappings for this collection

    # Directories within WRK_DIR are identified as collections
    def initialize(colldir)
      @colldir = File.expand_path(colldir)
      @name = colldir.split('/').pop
      @migrecdir = "#{@colldir}/_migrecords"
      @cleanrecdir = "#{@colldir}/_cleanrecords"
      Dir.mkdir(@cleanrecdir) unless Dir::exist?(@cleanrecdir)
      @objdir = "#{@colldir}/_objects"
      @ingestpkgdir = "#{@colldir}/_ingestpackages"
      Dir.mkdir(@ingestpkgdir) unless Dir::exist?(@ingestpkgdir)
      @modsdir = "#{@colldir}/_mods"
      Dir.mkdir(@modsdir) unless Dir::exist?(@modsdir)
      @tndir = "#{@colldir}/thumbnails"
      Dir.mkdir(@tndir) unless Dir::exist?(@tndir)
      @omittedrecs = omitted_recs
      set_migrecs
      set_cleanrecs
      set_mappings
      self
    end

    # recs = Array of record pointers
    def clear_recs(recs)
      recs.each{ |recid|
        to_delete = [
          "#{modsdir}/#{recid}.xml",
          "#{cleanrecdir}/#{recid}.json",
          "#{migrecdir}/#{recid}.json",
          "#{colldir}/_cdmrecords/#{recid}.json",
          "#{colldir}/_oxrecords/#{recid}.xml"
        ]
        to_delete.each{ |path| File.delete(path) if File.exist?(path) }
      }
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

    def set_mappings
      mappings = Mdmm::CONFIG.mappings
      if mappings[@name]
        @mappings = mappings[@name].uniq
      else
        Mdmm::LOG.warn("No mappings for collection: #{name}")
      end
    end
    
    def set_cleanrecs
      @cleanrecs = Dir.new(@cleanrecdir).children.map{ |name| name.sub('.json', '') }
      if @cleanrecs.length == 0
        Mdmm::LOG.warn("No clean records in #{@cleanrecdir}. Run `exe/mdmm clean_recs`.")
        return
      else
        Mdmm::LOG.info("Identified #{@cleanrecs.length} clean records for #{@name}...")
        @cleanrecs = @cleanrecs - omitted_recs
        @cleanrecs = @cleanrecs.map{ |id| "#{cleanrecdir}/#{id}.json" }
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
          v.each{ |e| Mdmm::LOG.error("MODS VALIDATION: invalid MODS: #{f}: #{e}") }
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

    def recs_missing_objs
      result = []
      @cleanrecs.each{ |cr|
        rec = Mdmm::CleanRecord.new(self, cr)
        unless rec.is_compound?
          unless rec.is_external_media?
            unless rec.has_obj?
              result << "#{rec.id} - #{rec.json['migobjcategory']}"
            end
          end
        end
      }
      return result
    end

    def objs_missing_recs
      result = []

      children = Dir.new(@objdir).children
      unless children.empty?
        children.each{ |objfilename|
          objpath = "#{@objdir}/#{objfilename}"
          objid = objfilename.sub(File.extname(objfilename), '')
          recpaths = [
            "#{@migrecdir}/#{objid}.json",
            "#{@cleanrecdir}/#{objid}.json",
            "#{@colldir}/_oxrecords/#{objid}.xml",
            "#{@colldir}/_cdmrecords/#{objid}.json"
          ].select{ |filepath| File.exist?(filepath) }
          result << objpath if recpaths.empty?
        }
      end
      return result
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
      @migrecs = Dir.new(@migrecdir).children.map{ |name| name.sub('.json', '') }
      @migrecs = @migrecs - @omittedrecs
      @migrecs = @migrecs.map{ |id| "#{@migrecdir}/#{id}.json" }
      if @migrecs.length == 0
        Mdmm::LOG.error("No migrecords in #{@migrecdir}.")
        return
      else
        Mdmm::LOG.info("Identified #{@migrecs.length} migration records for #{@name}...")
      end
    end

    def omitted_recs
      config = Mdmm::CONFIG.omitted_records
      if config.nil?
        return []
      else
        if config.has_key?(@name)
          return config[@name].map{ |e| e.to_s }
        else
          return []
        end
      end
    end


  end # Collection
end # Mdmm
