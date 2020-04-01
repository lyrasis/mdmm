
require 'mdmm'

module Mdmm

class ObjectTypeHash
  attr_reader :hash # Hash of objects by Islandora content model

  # initialize with array of Mdmm::Collection objects
  def initialize(colls)
    @hash = {}
    recs = recs_with_contentmodel(colls)
    hash_by_contentmodel(recs)
    pp(@hash)
  end

  private

  def hash_by_contentmodel(recs)
    recs.each{ |rec|
      @hash[rec.contentmodel] = {} unless @hash.has_key?(rec.contentmodel)
      hash_by_filetype(rec)
    }
  end

  def hash_by_filetype(rec)
    recid = "#{rec.coll.name}/#{rec.id}"

    if %w[compoundCModel bookCModel].include?(rec.contentmodel)
      @hash[rec.contentmodel][rec.childtypes] = [] unless @hash[rec.contentmodel].has_key?(rec.childtypes)
      @hash[rec.contentmodel][rec.childtypes] << recid
    else
      @hash[rec.contentmodel][rec.filetype] = [] unless @hash[rec.contentmodel].has_key?(rec.filetype)
      @hash[rec.contentmodel][rec.filetype] << recid
    end
  end
  
  def recs_with_contentmodel(colls)
    recs = []
    colls.each{ |coll|
      coll.cleanrecs.each{ |recpath|
        rec = Mdmm::CleanRecord.new(coll, recpath)
        recs << rec if rec.contentmodel
      }
    }
    return recs
  end

end #ObjectTypeHash class
end # Mdmm
