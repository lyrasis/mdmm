
require 'mdmm'

module Mdmm
  class DateCleaner
    attr_reader :recid
    attr_reader :orig
    attr_reader :working
    attr_reader :encoding
    attr_reader :parsed
    attr_reader :qualifier
    attr_reader :point
    attr_reader :keydate
    attr_reader :result

    def initialize(recid, string)
      @recid = recid
      @orig = string
      @working = @orig.clone
      @parsed = []
      @encoding = []
      @qualifier = ''
      @point = []
      @keydate = []
      @result = []
      set_qualifier
      date_handler
    end

    private
    #["#{@parsed}&&&#{@encoding}&&&#{@qualifier}&&&#{@point}&&&{@keydate}"]

    def date_handler
      # Change September to m09 (etc) for more streamlined processing below
      substitute_numeric_months if @working.match?(/^\w+ \d{4}$/) || @working.match?(/^\d{4} \w+$/) 
      
      # YYYY-MM-DD or YYYY-MM or YYYY
      if w3cdtf?(@working)
        @parsed << @working
        @encoding << 'w3cdtf'
      # YYYY mMM
      elsif @working.match?(/^\d{4} m\d{2}$/)
        m = @working.match(/^(\d{4}) m(\d{2})$/)
        formatted = "#{m[1]}-#{m[2]}"
        @parsed << formatted
        Mdmm::LOG.debug("DATEPROCESSING: #{recid}: YYYY mMM fix: #{@working} --> #{formatted}")
      # mMM YYYY
      elsif @working.match?(/^m\d{2} \d{4}$/)
        m = @working.match(/^m(\d{2}) (\d{4})$/)
        formatted = "#{m[2]}-#{m[1]}"
        @parsed << formatted
        Mdmm::LOG.debug("DATEPROCESSING: #{recid}: mMM YYYY fix: #{@working} --> #{formatted}")
      # M-D-YYYY or MM-DD-YYYY
      elsif @working.match?(/^\d{1,2}-\d{1,2}-\d{4}$/)
        parse_by_pattern('%m-%d-%Y')
        # M/D/YYYY or MM/DD/YYYY  
      elsif @working.match?(/^\d{1,2}\/\d{1,2}\/\d{4}$/)
        parse_by_pattern('%m/%d/%Y')
        # 
      else
        date_parse(@working)
      end
    end

    def substitute_numeric_months
      o = @working.clone
      Date::MONTHNAMES.compact.each{ |month|
        if @working[month]
          num = "%02d" % Date::MONTHNAMES.index(month)
          rep = "m#{num}"
          @working.gsub!(month, rep)
        end
      }
      Date::ABBR_MONTHNAMES.compact.each{ |month|
        if @working[month]
          num = "%02d" % Date::ABBR_MONTHNAMES.index(month)
          rep = "m#{num}"
          @working.gsub!(month, rep)
        end
      }
      Mdmm::LOG.debug("DATEPROCESSING: #{recid}: month-to-number: #{o} --> #{working}") unless o == @working
    end
    
    def parse_by_pattern(pattern)
      o = @working.clone
      begin
        parsed = Date.strptime(@working, pattern)
      rescue ArgumentError => e
        Mdmm::LOG.warn("DATEPROCESSING: #{recid}: origdatevalue #{@working} cannot be converted: ERROR: #{e}")
      rescue
        Mdmm::LOG.error("DATEPROCESSING: #{recid}: parse_by_pattern error non-specified")
      else
        formatted = parsed.strftime("%Y-%m-%d")
        @parsed << formatted
        @encoding << 'w3cdtf'
        Mdmm::LOG.debug("DATEPROCESSING: #{recid}: Processed pattern ``#{pattern}``: #{o} --> #{formatted}")
      end      
    end
      
    def w3cdtf?(val)
      case val
      when /^\d{4}$/
        return true
      when /^\d{4}-\d{2}$/
        return true
      when /^\d{4}-\d{2}-\d{2}$/
        return true
      else
        return false
      end
    end
    
    def date_parse(val)
      begin
        parsed = Date.parse(val)
      rescue ArgumentError => e
        Mdmm::LOG.error("DATEPROCESSING: #{recid}: origdatevalue #{@working} cannot be converted: ERROR: #{e}")
      rescue
        Mdmm::LOG.error("DATEPROCESSING: #{recid}: date_parse error non-specified")
      else
        if Date.valid_date?(parsed.year, parsed.month, parsed.day)
          formatted = parsed.strftime("%Y-%m-%d")
          @parsed << formatted
          @encoding << 'w3cdtf'
          Mdmm::LOG.info("DATEPROCESSING: #{recid}: date_parse:  #{@working} --> #{formatted}")
        else
          Mdmm::LOG.error("DATEPROCESSING: #{recid}: origdatevalue #{@working} converts to invalid date")
        end
      end
    end

    def set_qualifier
      if @working.match(/^\[.*\]$/)
        @qualifier = 'inferred'
        @working.delete!('[]')
      end
      
      if @working['?']
        @qualifier = 'questionable'
        @working.delete!('?')
      end
      
      if @working['probably']
        @qualifier = 'questionable'
        @working.gsub!(/probably ?/, '')
      end

      if @working['circa']
        @qualifier = 'approximate'
        @working.gsub!(/circa ?/, '')
      end
    end

  end # DateCleaner
end # Mdmm
