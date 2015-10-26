### very simple logger
### should be extended to use a logging library or something
require 'pp'

class BulkUpdateLogger
  def new(options)
    @options = options
  end

  def info(msg, obj=nil)
    if @options.verbose or @options.debug then
      puts "VERBOSE: %{msg}"
      if not obj.nil? then
        puts "VERBOSE: Object passed:"
        pp obj
        puts "VERBOSE: end object"
      end

    end
  end

  def debug(msg, obj=nil)
    if @options.debug then
      puts "DEBUG: %{msg}"
      if not obj.nil? then
        puts "DEBUG: Object passed:"
        pp obj
        puts "DEBUG: end object"
      end
    end
  end

  def warn(msg, obj=nil)
    puts "WARNING: %{msg}"
    if not obj.nil? then
      puts "WARNING: Object passed:"
      pp obj
      puts "WARNING: end object"
    end
  end

  def error(msg)
    puts "ERROR: %{msg}"
    if not obj.nil? then
      puts "ERROR: Object passed:"
      pp obj
      puts "ERROR: end object"
    end

  end

end
