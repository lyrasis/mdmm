require 'mdmm'

module Mdmm
  class ModsElementOrderer
    attr_reader :orig
    attr_reader :result

    # rec: JSON of Mdmm::CleanRecord
    # mapping: String: mapping to check against
    def initialize(elements)
      @orig = elements
      @result = []
      order_titles
      order_elements('part')
      order_names
      order_elements('originInfo')
      order_elements('subject')
      order_elements('abstract')
      order_typed_notes('content')
      order_elements('tableOfContents')
      order_elements('typeOfResource')
      order_elements('physicalDescription')
      order_elements('genre')
      order_typed_notes('system details')
      order_elements('language')
      order_notes
      order_typed_notes('ownership')
      order_elements('targetAudience')
      order_elements('relatedItem')
      order_elements('location')
      order_elements('classification')
      order_elements('accessCondition')      
      order_typed_notes('preferred citation')
      order_elements('identifier')
      order_elements('recordInfo')
      order_elements('extension')
    end

    private

    def special_note_type?(element)
      special_types = ['content',
                       'system details',
                       'ownership',
                       'preferred citation'
                      ]
      return true if special_types.include?(element['type'])
    end

    def order_typed_notes(type)
      @orig.select{ |e| e.name == 'note' && e['type'] == type }.each{ |e| order_element(e) }
    end

    def order_notes
      notes = @orig.select{ |e| e.name == 'note' }
      notes.reject!{ |e| special_note_type?(e) }
      notes.each{ |e| order_element(e) }
    end
    
    def order_titles
      titles = @orig.select{ |e| e.name == 'titleInfo' }
      # primary titles first
      titles.select{ |e| e['usage'] == 'primary' }.each{ |e| order_element(e) ; titles.delete(e) }
      # untyped non-primary titles next
      titles.select{ |e| e['usage'].nil? && e['type'].nil? }.each{ |e| order_element(e) ; titles.delete(e) }
        # typed non-primary titles last
      titles.select{ |e| e['usage'].nil? && e['type'] }.each{ |e|  order_element(e) ; titles.delete(e) }
    end

    def order_elements(elementname)
      @orig.select{ |e| e.name == elementname }.each{ |element|
        order_element(element)
      }
    end


    
    def order_names
      names = @orig.select{ |e| e.name == 'name' }
      # personal authors
      names.select{ |e| e['type'] == 'personal' && is_author?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
          # personal creators
      names.select{ |e| e['type'] == 'personal' && is_creator?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
          # corporate authors
      names.select{ |e| e['type'] == 'corporate' && is_author?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
          # corporate creators
      names.select{ |e| e['type'] == 'corporate' && is_creator?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
          # untyped authors
      names.select{ |e| e['type'].nil? && is_author?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
          # untyped creators
      names.select{ |e| e['type'].nil? && is_creator?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
            # interviewees
      names.select{ |e| is_interviewee?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
      # interviewers
      names.select{ |e| is_interviewer?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
      # personal contributors
      names.select{ |e| e['type'] == 'personal' && is_contributor?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
      # other personal
      names.select{ |e| e['type'] == 'personal' }.each{ |e|  order_element(e) ; names.delete(e) }
      # family names
      names.select{ |e| e['type'] == 'family' }.each{ |e|  order_element(e) ; names.delete(e) }
      # conference names
      names.select{ |e| e['type'] == 'conference' }.each{ |e|  order_element(e) ; names.delete(e) }
      # corporate contributors
      names.select{ |e| e['type'] == 'corporate' && is_contributor?(e) }.each{ |e|  order_element(e) ; names.delete(e) }
      # other corporate
      names.select{ |e| e['type'] == 'corporate' }.each{ |e|  order_element(e) ; names.delete(e) }
      # other 
      names.each{ |e|  order_element(e) ; names.delete(e) }
    end

    def is_author?(element)
      return true if element.xpath("role/roleTerm").text['author']
      return true if element.xpath("role/roleTerm[@type='code']").text['aut']
    end
    
    def is_creator?(element)
      return true if element.xpath("role/roleTerm").text['creator']
      return true if element.xpath("role/roleTerm[@type='code']").text['cre']
    end

    def is_contributor?(element)
      return true if element.xpath("role/roleTerm").text['contributor']
      return true if element.xpath("role/roleTerm[@type='code']").text['ctb']
    end
    
    def is_interviewee?(element)
      return true if element.xpath("role/roleTerm").text['interviewee']
      return true if element.xpath("role/roleTerm[@type='code']").text['ive']
    end
    
    def is_interviewer?(element)
      return true if element.xpath("role/roleTerm").text['interviewer']
      return true if element.xpath("role/roleTerm[@type='code']").text['ivr']
    end
    
    def order_element(element)
      @result << element
      @orig.delete(element)
    end
    
    def elements
      [
        'name',
        'originInfo',
        'subject',
        'abstract',
        'note',
        'tableOfContents',
        'typeOfResource',
        'physicalDescription',
        'genre',
        'language',
        'targetAudience',
        'classification',
        'relatedItem',
        'identifier',
        'location',
        'accessCondition',
        'extension',
        'recordInfo'
      ]
    end
  end #ModsElementOrderer
end #Module
