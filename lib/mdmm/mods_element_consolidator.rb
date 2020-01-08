require 'mdmm'

module Mdmm
  class ModsElementConsolidator
    attr_reader :result

    # rec: JSON of Mdmm::CleanRecord
    # mapping: String: mapping to check against
    def initialize(oldelements)
      @result = []
      to_consolidate = CONFIG.single_mods_top_elements
      h = {}
      oldelements.each{ |element|
        if to_consolidate.include?(element.name)
          children = element.children
          h.has_key?(element.name) ? h[element.name] << children : h[element.name] = [children] 
        else
          @result << element
        end
      }
      h.each{ |element, children|
        f = Nokogiri::XML.fragment("<#{element}></#{element}>").xpath(".//*").first
        children.each{ |child| f.add_child(child) }
        @result << f
      }
    end

    private
  end #ModsElementConsolidator
end #Module
