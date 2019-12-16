require 'mdmm'

module Mdmm
  class FieldLister
    # initialize with array of Mdmm::Collection objects
    def initialize(colls)
      CSV.open("#{Mdmm::WRK_DIR}/_fields.csv", 'wb'){ |csv|
        csv << ['collection', 'fieldname']
        colls.each{ |coll|
          get_collfields(coll).each{ |f| csv << f }
        }
      }
    end

    private

    def get_collfields(coll)
      fields = []
      coll.migrecs.each{ |recfile|
        rec = Mdmm::MigRecord.new(coll, recfile)
        fields << rec.reportfields
      }
      fields = fields.flatten.uniq
      fields.map!{ |field| [coll.name, field] }
    end

  end # FieldLister
end # Mdmm
