
require 'mdmm'

module Mdmm
  class DateParser
    attr_reader :recid
    attr_reader :orig
    attr_reader :working
    attr_reader :encoding
    attr_reader :parsed
    attr_reader :qualifier
    attr_reader :result

    def initialize(recid, string)
      @recid = recid
      @orig = string
      @working = @orig.clone
      @parsed = []
      @encoding = []
      @qualifier = ''
      @result = []
      clean_working
      # sets qualifier from punctuation and words found in @working
      # removes said punctuation/words from @working for cleaner date processing
      set_qualifier
      # the following step enables the subsequent processing to be simpler
      # it changes September to m09, Oct to m10, etc.
      @working = substitute_numeric_months(@working) if @working.match?(/^[A-Za-z]+ \d{4}$/) || @working.match?(/^\d{4} [A-Za-z]+$/)
      # this should handle most single-date values
      date_handler(@working)
      # attempts to handle @working as range
      range_date_handler
      @encoding = @encoding.uniq.join(';;;')
      compile_result
    end

    private

    def compile_result
      #if there is no parsed date, return @orig as keydate, no encoding, no point. Include qualifier if present
      if @parsed.empty?
        r = "#{orig}&&&keyDate=yes"
        r << "&&&qualifier=#{@qualifier}" unless @qualifier.empty?
        @result << r
        # if there is one or more parsed values...
      else
        # if there one parsed value... 
        if @parsed.length == 1
          # if there's a qualifier, return orig version first as display value, with qualifier
          @result << "#{orig}&&&qualifier=#{@qualifier}" if !@qualifier.empty?
          # return the parsed value as key date with encoding (and qualifier, if present)
          r = "#{parsed[0]}&&&encoding=#{@encoding}&&&keyDate=yes"
          r << "&&&qualifier=#{@qualifier}" unless @qualifier.empty?
          @result << r
          # if there are two parsed values
        else
          # return orig for display, adding qualifier if present
          r = "#{orig}"
          r << "&&&qualifier=#{@qualifier}" unless @qualifier.empty?
          @result << r
          # return the first parsed value as key date with encoding and start point (and qualifier, if present)
          r = "#{parsed[0]}&&&encoding=#{@encoding}&&&keyDate=yes&&&point=start"
          r << "&&&qualifier=#{@qualifier}" unless @qualifier.empty?
          @result << r
          # return the second parsed value as with encoding and point point (and qualifier, if present)
          r = "#{parsed[0]}&&&encoding=#{@encoding}&&&point=end"
          r << "&&&qualifier=#{@qualifier}" unless @qualifier.empty?
          @result << r
        end
      end
    end

    def date_handler(val)
      # YYYY-MM-DD or YYYY-MM or YYYY
      if w3cdtf?(val)
        @parsed << val
        @encoding << 'w3cdtf'
        # MM-DD-YYYY
      elsif val.match?(/^\d{1,2}-\d{1,2}-\d{4}$/)
        parse(val)
        # YYYY Month DD
      elsif val.match?(/^\d{4} \w+ \d{1,2}$/)
        parse(val)
        # Month DD, YYYY
      elsif val.match?(/^\w+ \d{1,2}, \d{4}$/)
        parse(val)
        # YYYY mMM
      elsif val.match?(/^\d{4} m\d{2}$/)
        m = val.match(/^(\d{4}) m(\d{2})$/)
        formatted = "#{m[1]}-#{m[2]}"
        @parsed << formatted
        @encoding << 'w3cdtf'
        Mdmm::LOG.debug("DATEPROCESSING: #{recid}: YYYY mMM fix: #{val} --> #{formatted}")
        # mMM YYYY
      elsif val.match?(/^m\d{2} \d{4}$/)
        m = val.match(/^m(\d{2}) (\d{4})$/)
        formatted = "#{m[2]}-#{m[1]}"
        @parsed << formatted
        @encoding << 'w3cdtf'
        Mdmm::LOG.debug("DATEPROCESSING: #{recid}: mMM YYYY fix: #{val} --> #{formatted}")
        # M-D-YYYY or MM-DD-YYYY
      elsif val.match?(/^\d{1,2}-\d{1,2}-\d{4}$/)
        parse_by_pattern('%m-%d-%Y')
        # M/D/YYYY or MM/DD/YYYY  
      elsif val.match?(/^\d{1,2}\/\d{1,2}\/\d{4}$/)
        parse_by_pattern('%m/%d/%Y')
      end
    end

    def range_date_handler
      # YYYY-YYYY
      if @working.match?(/^\d{4}-\d{4}$/)
        @working.split('-').each{ |val| date_handler(val) }
        # YYYY/YY
      elsif @working.match?(/^\d{4}\/\d{2}$/)
        wrkarr = @working.split('/')
        date_handler(wrkarr[0])
        date_handler("#{wrkarr[0][0..1]}#{wrkarr[1]}")
        # YYYY-MM, YYYY-MM+
      elsif @working.match?(/^(\d{4}-\d{1,2}, )+\d{4}-\d{1,2}$/)
        arr = @working.split(', ')
        date_handler(arr.shift)
        date_handler(arr.pop)
        # YYYY-MM-DD, YYYY-MM-DD+
      elsif @working.match?(/^(\d{4}-\d{1,2}-\d{1,2}, )+\d{4}-\d{1,2}-\d{1,2}$/)
        arr = @working.split(', ')
        date_handler(arr.shift)
        date_handler(arr.pop)
        # YYYY-MM-DD or YYYY-MM-DD
      elsif @working.match?(/^\d{4}-\d{1,2}-\d{1,2} or \d{4}-\d{1,2}-\d{1,2}$/)
        @qualifier = 'questionable'
        @working.split(' or ').each{ |d| date_handler(d) }
        # YYYYs or YYYYs
      elsif @working.match?(/^\d{4}s or \d{4}s$/)
        wrkarr = @working.split(' or ')
        date_handler(wrkarr[0].delete('s'))
        date_handler("#{wrkarr[1][0..2]}9")
        # YYYYs
      elsif @working.match?(/^\d{4}s$/)
        d = @working.delete('s')
        date_handler(d)
        date_handler("#{d[0..2]}9")
        # Mid YYYYs
      elsif @working.match?(/^[Mm]id \d{4}s$/)
        @qualifier = 'approximate'
        yr = @working.match(/(\d{4})/)[1]
        date_handler("#{yr[0..2]}5")
        # Early YYYYs
      elsif @working.match?(/^[Ee]arly \d{4}s$/)
        @qualifier = 'approximate'
        yr = @working.match(/(\d{4})/)[1]
        date_handler(yr)
        date_handler("#{yr[0..2]}4")
        # Late YYYYs
      elsif @working.match?(/^[Ll]ate \d{4}s$/)
        @qualifier = 'approximate'
        yr = @working.match(/(\d{4})/)[1]
        date_handler("#{yr[0..2]}6")
        date_handler("#{yr[0..2]}9")
        # Spring YYYY
      elsif @working.match?(/^[Ss]pring \d{4}$/)
        yr = @working.match(/(\d{4})$/)[1]
        date_handler("#{yr}-03-01")
        date_handler("#{yr}-05-31")
        # Summer YYYY
      elsif @working.match?(/^[Ss]ummer \d{4}$/)
        yr = @working.match(/(\d{4})$/)[1]
        date_handler("#{yr}-06-01")
        date_handler("#{yr}-08-31")
        # Fall or Autumn YYYY
      elsif @working.match?(/^([Ff]all|[Aa]utumn) \d{4}$/)
        yr = @working.match(/(\d{4})$/)[1]
        date_handler("#{yr}-09-01")
        date_handler("#{yr}-11-30")
        # Winter YYYY
      elsif @working.match?(/^[Ww]inter \d{4}$/)
        yr = @working.match(/(\d{4})$/)[1]
        prev = yr.to_i - 1
        date_handler("#{prev}-12-01")
        date_handler("#{yr}-02-28")
        # YYYY Month DD-DD
      elsif @working.match?(/^\d{4} [A-Za-z]+ \d{1,2}-\d{1,2}$/)
        m = @working.match(/^(\d{4}) ([A-Za-z]+) (\d{1,2})-(\d{1,2})$/)
        date_handler("#{m[1]} #{m[2]} #{m[3]}")
        date_handler("#{m[1]} #{m[2]} #{m[4]}")
        # YYYY Month DD-Month DD
      elsif @working.match?(/^\d{4} \w+ \d{1,2}-\w+ \d{1,2}$/)
        arr = @working.split('-')
        yr = arr[0][0..3]
        date_handler(arr[0])
        date_handler("#{yr} #{arr[1]}")
        # YYYY Month DD, DD
      elsif @working.match?(/^\d{4} \w+ \d{1,2}, \d{1,2}$/)
        m = @working.match(/^(\d{4}) (\w+) (\d{1,2}), (\d{1,2})$/)
        date_handler("#{m[1]} #{m[2]} #{m[3]}")
        date_handler("#{m[1]} #{m[2]} #{m[4]}")
        # Month DD-DD, YYYY
      elsif @working.match?(/^[A-Za-z]+ \d{1,2}-\d{1,2},? \d{4}$/)
        yr = @working.match(/(\d{4})/)[1]
        m = @working.match(/^([A-Za-z]+)/)[1]
        days = @working.match(/(\d{1,2}-\d{1,2})/)[1].split('-')
        date_handler("#{yr} #{m} #{days[0]}")
        date_handler("#{yr} #{m} #{days[1]}")
        # Month DD-Month DD, YYYY
      elsif @working.match?(/^[A-Za-z]+ \d{1,2}-[A-Za-z]+ \d{1,2},? \d{4}$/)
        m = @working.match(/^([A-Za-z]+ \d{1,2})-([A-Za-z]+ \d{1,2}),? (\d{4})$/)
        date_handler("#{m[3]} #{m[1]}")
        date_handler("#{m[3]} #{m[2]}")
        # YYYY Month DD, Month DD, DD-DD
      elsif @working.match?(/^\d{4} [A-Za-z]+ \d{1,2}, [A-Za-z]+ \d{1,2}, \d{1,2}-\d{1,2}$/)
        m = @working.match(/^(\d{4}) ([A-Za-z]+) (\d{1,2}), ([A-Za-z]+) \d{1,2}, \d{1,2}-(\d{1,2})$/)
        date_handler("#{m[1]} #{m[2]} #{m[3]}")
        date_handler("#{m[1]} #{m[4]} #{m[5]}")
        # YYYY Month-Month
      elsif @working.match?(/^\d{4} [A-Za-z]+-[A-Za-z]+$/)
        arr = @working.split('-')
        date_handler(substitute_numeric_months(arr[0]))
        year = @working.match(/^(\d{4})/)[1]
        date_handler(substitute_numeric_months("#{year} #{arr[1]}"))
        # Month-Month YYYY
      elsif @working.match?(/^[A-Za-z]+-[A-Za-z]+ \d{4}$/)
        w = substitute_numeric_months(@working)
        m = w.match(/^(m\d{2})-(m\d{2}) (\d{4})$/)
        date_handler("#{m[3]} #{m[1]}")
        date_handler("#{m[3]} #{m[2]}")
        # YYYY Month DD-YYYY Month DD
      elsif @working.match?(/^\d{4} [A-Za-z]+ \d{1,2}-\d{4} [A-Za-z]+ \d{1,2}$/)
        @working.split('-').each{ |d| date_handler(d) }
        # YYYY Month DD (non letters) and DD
      elsif @working.match?(/^\d{4} [A-Za-z]+ \d{1,2}[^A-Za-z]+ and \d{1,2}/)
        m = @working.match(/^(\d{4} [A-Za-z]+) (\d{1,2})[^A-Za-z]+and (\d{1,2})/)
        date_handler("#{m[1]} #{m[2]}")
        date_handler("#{m[1]} #{m[3]}")
        # YYYY-MM-00-YYYY-MM-00
      elsif @working.match?(/^\d{4}-\d{1,2}-0{1,2}-\d{4}-\d{1,2}-0{1,2}$/)
        m = @working.match(/^(\d{4}-\d{1,2})-0{1,2}-(\d{4}-\d{1,2})-0{1,2}$/)
        date_handler(m[1])
        date_handler(m[2])
        # YYYY-MM-00-YYYY-MM-00
      elsif @working.match?(/^\d{4}-\d{1,2}-\d{1,2}-\d{4}-\d{1,2}-\d{1,2}$/)
        m = @working.match(/^(\d{4}-\d{1,2}-\d{1,2})-(\d{4}-\d{1,2}-\d{1,2})$/)
        date_handler(m[1])
        date_handler(m[2])
      end
    end
    

    def substitute_numeric_months(val)
      o = val.clone
      Date::MONTHNAMES.compact.each{ |month|
        if val[month]
          num = "%02d" % Date::MONTHNAMES.index(month)
          rep = "m#{num}"
          val.gsub!(month, rep)
        end
      }
      Date::ABBR_MONTHNAMES.compact.each{ |month|
        if val[month]
          num = "%02d" % Date::ABBR_MONTHNAMES.index(month)
          rep = "m#{num}"
          val.gsub!(month, rep)
        end
      }
      Mdmm::LOG.debug("DATEPROCESSING: #{recid}: month-to-number: #{o} --> #{working}") unless o == val
      return val
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
    
    def parse(val)
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

      if @working['an unknown date in']
        @qualifier = 'approximate'
        @working.gsub!(/an unknown date in ?/, '')
      end

      if @working['circa']
        @qualifier = 'approximate'
        @working.gsub!(/circa ?/, '')
      end
    end

    def clean_working
      @working.gsub!(/:$/, '')
      @working.gsub!(/^(\d{4})([A-Z])/, '\1 \2')
      @working.gsub!(/^(\d{4}) ([A-Za-z]+)(\d{1,2})$/, '\1 \2 \3')
      @working.gsub!(/ \(bulk \d{4}-\d{4}\)/, '')
      @working.gsub!(/^([A-Za-z]+)- ([A-Za-z]+)/, '\1-\2')
      @working.gsub!(/^([A-Za-z]+ \d{1,2})- ([A-Za-z]+)/, '\1-\2')
      @working.gsub!(/^(\d{4})- (\d{4})/, '\1-\2')
      @working.gsub!(/^(\d{4}) (\w+ \d{1,2})- (\w+ \d{1,2})$/, '\1 \2-\1 \3')
    end

  end # DateCleaner
end # Mdmm
