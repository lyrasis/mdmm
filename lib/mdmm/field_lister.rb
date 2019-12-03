require 'mdmm'

module Mdmm
  class FieldLister
    # initialize with array of Mdmm::Collection objects
    def initialize(colls)
      collfields = []
      colls.each{ |coll| collfields << get_collfields(coll) }
      CSV.open("#{Mdmm::WRK_DIR}/_fields.csv", 'wb'){ |csv|
        csv << ['collection', 'fieldname']
        collfields.each{ |cf| cf.each{ |f| csv << f } }
      }
    end

    private

    def get_collfields(coll)
      fields = []
      coll.migrecs.each{ |recfile|
        rec = Mdmm::MigRecord.new(coll, "#{coll.migrecdir}/#{recfile}")
        fields << rec.fields
      }
      finalfields = fields.flatten.uniq
      finalfields.map!{ |field| [coll.name, field] }
    end
    
  end # FieldLister
end # Mdmm
