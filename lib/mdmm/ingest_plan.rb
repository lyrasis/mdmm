
require 'mdmm'

module Mdmm

=begin
An ingest plan is an array of hashes.
Each hash has three keys:
- do - the operation (copy or move)
- origpath - path to file in original, flat collection structure
- ingestpath - path to file in ingest package
=end  

class IngestPlan
    attr_reader :coll # Mdmm::Collection to which record belongs
    attr_reader :plan # Array. The ingest plan steps

    # initialize with Mdmm::Collection object
    def initialize(coll)
      @coll = coll
      set_plan
    end

    def print
      @plan.each{ |h|
        puts "#{h['do'].upcase}: #{h['origpath']} --> #{h['ingestpath']}"
      }
    end

    def list_packages
      dests = ingest_paths.map{ |p| p.sub(/^.*_ingestpackages/, '') }
      pkgs = []
      dests.each{ |d|
        basename = File.basename(d)
        val = d.sub(basename, '').sub(/\/\d+\/*$/, '').sub(/\/\d+$/, '').sub(/\/$/, '')
        val = val.split('/').reject{ |e| e.empty? }
        if val[0].start_with?('subcoll')
          val = "#{val[0]}/#{val[1]}"
        else
          val = val[0]
        end
        pkgs << val
      }
      pkgs = pkgs.uniq.sort
      puts "Collection: #{@coll.name}"
      pkgs.each{ |p| puts " - #{p}" }
    end

    def list_omitted_objs
      omitted = all_objs - included_objs
      omitted = omitted - @coll.omittedrecs
      unless omitted.empty?
        puts "Collection: #{@coll.name}"
        omitted.each{ |id| puts " #{id}" }
      end
    end

    def execute_plan
      plan.each{ |step|
        Mdmm::LOG.debug("EXECUTE_PLAN: Beginning #{@coll.name} ingest plan step #{step['stepid']}")
        
        dirpath = File.dirname(step['ingestpath'])
        FileUtils.mkdir_p(dirpath)
        
        case step['do']
        when 'copy'
          FileUtils.copy_file(step['origpath'], step['ingestpath'])
          Mdmm::LOG.debug("EXECUTE_PLAN: Copied #{step['origpath']} to #{step['ingestpath']}")
        when 'move'
          FileUtils.mv(step['origpath'], step['ingestpath'])
          Mdmm::LOG.debug("EXECUTE_PLAN: Moved #{step['origpath']} to #{step['ingestpath']}")
        end
      }
    end

    def reverse_plan
      plan.each{ |step|
        Mdmm::LOG.debug("REVERSE_PLAN: Beginning #{@coll.name} ingest plan step #{step['stepid']}")
        
        case step['do']
        when 'move'
          FileUtils.mv(step['ingestpath'], step['origpath'])
          Mdmm::LOG.debug("REVERSE_PLAN: Moved #{step['ingestpath']} to #{step['origpath']}")
        end        
      }
        FileUtils.rm_r(Dir.glob("#{@coll.ingestpkgdir}/*"))
    end

    private

    # returns array of unique object ids included in ingest plan
    def included_objs
      orig_paths.map{ |p| File.basename(p) }.map{ |bn| bn.sub(/\..*$/, '') }.uniq
    end

    # returns array of all objects in collection expected to be ingested
    def all_objs
      @coll.migrecs.map{ |p| File.basename(p) }.map{ |bn| bn.sub('.json', '') }.uniq
    end

    def orig_paths
      @plan.map{ |h| h['origpath'] }
    end
    
    def ingest_paths
      @plan.map{ |h| h['ingestpath'] }
    end
    
    def set_plan
      planpath = "#{@coll.colldir}/_ingest_plan.json"
      if File::exist?(planpath)
        @plan = JSON.parse(File.read(planpath))
      else
        @plan = []
        puts "No ingest plan for #{@coll.name}."
        Mdmm::LOG.warn("No ingest plan for #{@coll.name}.")
      end
    end

  end #IngestPlan class
end # Mdmm
