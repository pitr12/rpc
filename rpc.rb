class FileChecker

  HEADER_FORMAT = ['NNN','NNNNNNNNNN','NN','NNNNNNNNNNNN','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','NNNNNNNNNNNNNNN','NNNNNN','NNNN','NNNNNN','NNN','AAAAAAAAA']
  HEADER_LENGTH = 100
  DETAIL_FORMAT = ['NNN','NNNNNNNNNN','NN','NNNNNNNN','NNNN','NNN','NNNNNNNN','AAAAAAAAAAAAAAAAAAAA','NNN','NNNNNNNNNNNNNNN','NNNNNN','AAA','AAAA','NNNNNN','AAAAAAAAAA']
  DETAIL_LENGTH = 105
  TRAILER_FORMAT = ['NNN','NNNNNNNNNN','NN','NNNNNNNNNNNN','AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','NNNNNNNNNNNNNNN','NNNNNN','NNNNNN','AAAAAAAAAA']
  TRAILER_LENGTH = 98

  def self.check_format(value, type, length)
    case type
      when 'N'
        return true if value == value.match(/[[:digit:]]{#{length}}/).to_s

      when 'A'
        return true if value == value.match(/(?=[[:alnum:] ]{#{length}})[[:alnum:]]{0,#{length}} {0,#{length}}/).to_s
    end

    return false
  end

  def self.check_header_format(line)
    if line.length == (HEADER_LENGTH) #checks if line length is correct
      position = 0
      HEADER_FORMAT.each do |format|
        value = line[position,format.length]
        position += format.length
        if check_format(value, format[0], format.length) == false
          puts "HEADER format is invalid"
          break
        end
      end
    else
      puts "HEADER format is invalid"
    end
  end

  def self.check_detail_format(line, number)
    if line.length == (DETAIL_LENGTH) #checks if line length is correct
      position = 0
      DETAIL_FORMAT.each do |format|
        value = line[position,format.length]
        position += format.length
        if check_format(value, format[0], format.length) == false
          puts "Format on line #{number} is invalid"
          break
        end
      end
    else
      puts "Format on line #{number} is invalid"
    end
  end

  def self.check_trailer_format(line)
    if line.length == (TRAILER_LENGTH) #checks if line length is correct
      position = 0
      TRAILER_FORMAT.each do |format|
        value = line[position,format.length]
        position += format.length
        if check_format(value, format[0], format.length) == false
          puts "TRAILER format is invalid"
          break
        end
      end
    else
      puts "TRAILER format is invalid"
    end
  end

  file = File.open('VSTUP.DAT', 'r')
  file.each_with_index do |line, index|
    line = line.gsub(/\r?\n?/, '') #removes newline character (handles all possible cases \n, \r, \r\n)
    check_header_format(line) if index == 0
    check_trailer_format(line) if file.eof?
    check_detail_format(line, index) if index != 0 && file.eof? == false
  end

end