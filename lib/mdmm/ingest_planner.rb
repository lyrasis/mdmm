require 'mdmm'

module Mdmm
  class IngestPlanner
    attr_reader :coll # Mdmm::Collection to which record belongs
    attr_reader :plan # Array. The ingest plan steps
    attr_reader :recs # Array. Paths to migrecs with islandora_content_model field

    # initialize with Mdmm::Collection object
    def initialize(coll)
      @coll = coll
      @plan = []
      @recs = get_recs
      @recs.each{ |rec| add_ingest_plan(rec) }
      add_plan_step_ids
      write_plan
    end

    private

    def add_plan_step_ids
      ct = 1
      @plan.each{ |h|
        h['stepid'] = ct
        ct += 1
      }
    end
    
    def write_plan
      File.open("#{@coll.colldir}/_ingest_plan.json", 'w'){ |f|
        f.write(@plan.to_json)
      }
    end

    def add_ingest_plan(rec)
      case rec.contentmodel
      when 'sp_large_image_cmodel'
        simple_ingest_plan(rec, 'large_image')
      when 'sp_pdf'
        simple_ingest_plan(rec, 'pdf')
      when 'sp_videoCModel'
        simple_ingest_plan(rec, 'video')
      when 'sp_basic_image'
        if rec.is_external_media?
          external_media_ingest_plan(rec)
        else
          simple_ingest_plan(rec, 'basic_image')
        end
      when 'bookCModel'
        single_level_hierarchical_ingest_plan(rec, 'books')
      when 'compoundCModel'
        single_level_hierarchical_ingest_plan(rec, 'compound')
      end
    end

    def single_level_hierarchical_ingest_plan(rec, type)
      pkgdir = rec.in_subcollection? ? "#{rec.coll.ingestpkgdir}/subcoll#{rec.subcollection}" : rec.coll.ingestpkgdir
      if rec.has_mods?
        origmods = rec.mods_path
        newmods = "#{pkgdir}/#{type}/#{rec.id}/MODS.xml"
      else
        Mdmm::LOG.warn("INGEST_PLAN: No MODS for #{type} parent #{rec.coll.name}/#{rec.id}")
        return
      end

      if rec.children
        rec.children.each{ |childid| child_ingest_plan(rec, type, childid) }
      else
        Mdmm::LOG.warn("INGEST_PLAN: No children for #{type} parent #{rec.coll.name}/#{rec.id}")
        return
      end

      @plan << hash_up('copy', [origmods, newmods])
    end

    def child_ingest_plan(parentrec, type, id)
      pkgdir = parentrec.in_subcollection? ? "#{parentrec.coll.ingestpkgdir}/subcoll#{parentrec.subcollection}" : parentrec.coll.ingestpkgdir
      childid = id.sub("#{parentrec.id}-", '').sub('-', '')
      safeid = childid == '0' ? '01' : childid
      path = "#{parentrec.coll.migrecdir}/#{id}.json"
      rec = Mdmm::MigRecord.new(parentrec.coll, path)

      if rec.has_mods?
        origmods = rec.mods_path
        newmods = "#{pkgdir}/#{type}/#{parentrec.id}/#{safeid}/MODS.xml"
      else
        Mdmm::LOG.warn("INGEST_PLAN: No MODS for #{type} child #{rec.coll.name}/#{rec.id}")
        return
      end

      if rec.has_obj?
        origobj = rec.obj_path
        ext = File.extname(origobj)
        newobj = "#{pkgdir}/#{type}/#{parentrec.id}/#{safeid}/OBJ#{ext}"
      else
        Mdmm::LOG.warn("INGEST_PLAN: No OBJ for #{type} child #{rec.coll.name}/#{rec.id}")
        return
      end

      @plan << hash_up('copy', [origmods, newmods])
      @plan << hash_up('move', [origobj, newobj])
    end
    
    def simple_ingest_plan(rec, type)
      pkgdir = rec.in_subcollection? ? "#{rec.coll.ingestpkgdir}/subcoll#{rec.subcollection}" : rec.coll.ingestpkgdir

      if rec.has_mods?
        origmods = rec.mods_path
        newmods = "#{pkgdir}/#{type}/#{rec.id}.xml"
      else
        Mdmm::LOG.warn("INGEST_PLAN: No MODS for simple #{type} #{rec.coll.name}/#{rec.id}")
        return
      end
      
      if rec.has_obj?
        origobj = rec.obj_path
        newobj = "#{pkgdir}/#{type}/#{rec.id}.#{rec.filetype}"
      else
        Mdmm::LOG.warn("INGEST_PLAN: No OBJ for simple #{type} #{rec.coll.name}/#{rec.id}")
        return
      end
      

      @plan << hash_up('copy', [origmods, newmods])
      @plan << hash_up('move', [origobj, newobj])
      #      h = {type => {origmods => newmods, origobj => newobj}}
      #      @plan = @plan.merge(h){ |key, oldval, newval| oldval.merge(newval) }
    end

    def external_media_ingest_plan(rec)
      pkgdir = rec.in_subcollection? ? "#{rec.coll.ingestpkgdir}/subcoll#{rec.subcollection}" : rec.coll.ingestpkgdir
      
      if rec.has_mods?
        origmods = rec.mods_path
      else
        Mdmm::LOG.warn("INGEST_PLAN: No MODS for #{rec.coll.name}/#{rec.id}")
        return
      end
      
      if rec.has_obj?
        origobj = rec.obj_path
      elsif rec.has_tn?
        origobj = rec.tn_path
      else
        default_img = Mdmm::CONFIG.default_external_media_image
      end

      if origobj || default_img
        newmods = "#{pkgdir}/basic_image/#{rec.id}.xml"
        @plan << hash_up('copy', [origmods, newmods])
        
        if origobj
          obj_basename = File.basename(origobj)
          newobj = "#{pkgdir}/basic_image/#{obj_basename}"
          @plan << hash_up('move', [origobj, newobj])
        elsif default_img
          ext = File.extname(default_img)
          newobj = "#{pkgdir}/basic_image/#{rec.id}#{ext}"
          @plan << hash_up('copy', [default_img, newobj])
        end
      else
        Mdmm::LOG.warn("INGEST_PLAN: No OBJ for external media record #{rec.coll.name}/#{rec.id}")
        return
      end
    end

    def hash_up(operation, arr)
      {'do' => operation, 'origpath' => arr[0], 'ingestpath' => arr[1]}
    end

    def get_recs
      recs = []
      @coll.cleanrecs.each{ |path|
        cleanrec = Mdmm::CleanRecord.new(@coll, path)
        recs << cleanrec if cleanrec.contentmodel
      }
      recs
    end
  end #IngestPlanner class
end # Mdmm
