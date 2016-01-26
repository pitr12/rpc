class RPCchecker
  def self.check_regex_format(value, type, length)
    case type
      when 'N' #regex checking numeric characters
        return true if value == value.match(/[[:digit:]]{#{length}}/).to_s

      when 'A' #regex checking alphanumeric characters (right padded with spaces)
        return true if value == value.match(/(?=[[:alnum:] ]{#{length}})[[:alnum:]]{0,#{length}} {0,#{length}}/).to_s
    end

    return false
  end

  def self.check_format(line, predefined_length, predefined_format, msg)
    if line.length == (predefined_length) #checks if line length is correct
      position = 0
      predefined_format.each do |format|
        value = line[position,format.length]
        position += format.length
        if check_regex_format(value, format[0], format.length) == false
          puts msg
          break
        end
      end
    else
      puts msg
    end
  end

end

class FileChecker

  HEADER_FORMAT = %w(NNN NNNNNNNNNN NN NNNNNNNNNNNN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA NNNNNNNNNNNNNNN NNNNNN
                     NNNN NNNNNN NNN AAAAAAAAA)

  DETAIL_FORMAT = %w(NNN NNNNNNNNNN NN NNNNNNNN NNNN NNN NNNNNNNN AAAAAAAAAAAAAAAAAAAA NNN
                     NNNNNNNNNNNNNNN NNNNNN AAA AAAA NNNNNN AAAAAAAAAA)

  TRAILER_FORMAT = %w(NNN NNNNNNNNNN NN NNNNNNNNNNNN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA NNNNNNNNNNNNNNN
                      NNNNNN NNNNNN AAAAAAAAAA)

  def self.compute_length(format)
    lengths = format.collect {|x| x.length}
    length = lengths.inject { |sum,x| sum + x}
    return length
  end

  file = File.open("#{ARGV[0]}", 'r')
  file.each_with_index do |line, index|
    line = line.gsub(/\r?\n?/, '') #removes newline character (handles all possible cases \n, \r, \r\n)
    if index == 0
      RPCchecker.check_format(line, compute_length(HEADER_FORMAT), HEADER_FORMAT, "HEADER format is invalid")
    else
      file.eof? ? RPCchecker.check_format(line, compute_length(TRAILER_FORMAT), TRAILER_FORMAT, "TRAILER format is invalid")
                : RPCchecker.check_format(line, compute_length(DETAIL_FORMAT), DETAIL_FORMAT, "Format on line #{index} is invalid")
    end
  end
end