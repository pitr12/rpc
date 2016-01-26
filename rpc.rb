class FormatChecker
  def self.check_regex_format(value, type, length)
    case type
      when 'N', 'R' #regex checking numeric characters
        return true if value == value.match(/[0-9]{#{length}}/).to_s

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

  # FORMAT EXPLANATION:
  #   N = numeric
  #   A = alphanumeric
  #   R = row_number(numeric)

  HEADER_FORMAT = %w(NNN NNNNNNNNNN NN NNNNNNNNNNNN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA NNNNNNNNNNNNNNN NNNNNN
                     NNNN RRRRRR NNN AAAAAAAAA)

  DETAIL_FORMAT = %w(NNN NNNNNNNNNN NN NNNNNNNN NNNN NNN NNNNNNNN AAAAAAAAAAAAAAAAAAAA NNN
                     NNNNNNNNNNNNNNN NNNNNN AAA AAAA RRRRRR AAAAAAAAAA)

  TRAILER_FORMAT = %w(NNN NNNNNNNNNN NN NNNNNNNNNNNN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA NNNNNNNNNNNNNNN
                      NNNNNN RRRRRR AAAAAAAAAA)

  ROW_NUMBERS_LENGTH = 6

  # computes length of predefined format
  def self.compute_length(format)
    lengths = format.collect {|x| x.length}
    length = lengths.inject { |sum,x| sum + x}
    return length
  end

  # checks row numbering
  def self.check_row_numbering(line,number,format, type)
    #check if format contains R's = rows are numbered and if numbering is correct
    format = format.join('')
    index = format.index('R')
    if index && (format[index,ROW_NUMBERS_LENGTH] == "R" * ROW_NUMBERS_LENGTH)
      if number != line[index,ROW_NUMBERS_LENGTH].to_i
        actual_number = line[index,ROW_NUMBERS_LENGTH].to_i
        puts  "Row number of row #{number} is incorrect. Number = #{actual_number} (correct number = #{number})"
      end
    else
      puts "Format of #{type} does not have line numbering correctly defined"
    end
  end

  # iterates through whole file and checks all lines
  file = File.open("#{ARGV[0]}", 'r')
  file.each_with_index do |line, index|
    line = line.gsub(/\r?\n?/, '') #removes newline character (handles all possible cases \n, \r, \r\n)
    if index == 0 # HEADER
      FormatChecker.check_format(line, compute_length(HEADER_FORMAT), HEADER_FORMAT, "HEADER format is invalid")
      check_row_numbering(line, index, HEADER_FORMAT, "HEADER")
    else
      if file.eof? # TRAILER
        FormatChecker.check_format(line, compute_length(TRAILER_FORMAT), TRAILER_FORMAT, "TRAILER format is invalid")
        check_row_numbering(line, index, TRAILER_FORMAT, "TRAILER")
      else # DETAIL
        FormatChecker.check_format(line, compute_length(DETAIL_FORMAT), DETAIL_FORMAT, "Format on line #{index} is invalid")
        check_row_numbering(line, index, DETAIL_FORMAT, "DETAIL")
      end
    end
  end
end