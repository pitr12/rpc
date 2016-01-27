# RPC file structure and content checker
# author: Peter Dubec
# email: peter.dubec93@gmail.com

require 'date'

class FormatChecker
  def self.check_regex_format(value, type, length)
    case type
      when 'N', 'R', 'D' #regex checking numeric characters
        return true if value == value.match(/[0-9]{#{length}}/).to_s

      when 'A', 'C' #regex checking alphanumeric characters (right padded with spaces)
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
  #   D = date(numeric)
  #   C = credit_card_number(alphanumeric)

  HEADER_FORMAT = %w(NNN NNNNNNNNNN NN NNNNNNNNNNNN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA NNNNNNNNNNNNNNN NNNNNN
                     NNNN RRRRRR NNN AAAAAAAAA)

  DETAIL_FORMAT = %w(NNN NNNNNNNNNN NN DDDDDDDD NNNN NNN DDDDDDDD CCCCCCCCCCCCCCCCCCCC NNN
                     NNNNNNNNNNNNNNN NNNNNN AAA AAAA RRRRRR AAAAAAAAAA)

  TRAILER_FORMAT = %w(NNN NNNNNNNNNN NN NNNNNNNNNNNN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA NNNNNNNNNNNNNNN
                      NNNNNN RRRRRR AAAAAAAAAA)

  ROW_NUMBERS_LENGTH = 6
  DATE_LENGTH = 8
  CREDIT_CARD_NUMBER_LENGTH = 20

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
        puts  "Row number of row #{number + 1} is incorrect. Number = #{actual_number} (correct number = #{number})"
      end
      line[index,ROW_NUMBERS_LENGTH] = '0' * ROW_NUMBERS_LENGTH #removes line numbering (for later duplicate row identifying)
    else
      puts "Format of #{type} does not have line numbering correctly defined"
    end

    return line
  end

  # extracts dates based on predefined format
  def self.extract_dates(line, format, type)
    format = format.join('')
    index = format.index('D')
    dates = []

    while index do
      if format[index,DATE_LENGTH] == "D" * DATE_LENGTH
        dates << line[index,DATE_LENGTH]
        line = line[index+DATE_LENGTH..-1]
        format = format[index+DATE_LENGTH..-1]
        index = format.index('D')
      else
        puts "Format of #{type} does not have date correctly defined"
        break
      end
    end
    return dates
  end

  # checks if dates are valid
  def self.check_dates(dates,number)
    dates.each do |date|
      date = date.to_s
      year = date[4,4].to_i
      month = date[2,2].to_i
      day = date[0,2].to_i
      if !Date.valid_date?(year, month, day)
       puts "Date #{day}/#{month}/#{year} on line #{number + 1} is not valid."
      end

    end
  end

  # identifies duplicate rows
  def self.check_duplicate_rows(lines)
    duplicate_lines = lines.select{|element| lines.count(element) > 1 }
    duplicate_lines.uniq.each do |duplicate|
      original_lines = lines.each_index.select{|i| lines[i] == duplicate;}
      if original_lines
        original_lines.map! {|x| x+1}
        puts "Lines #{original_lines.inspect} are duplicate!"
      end
    end
  end

  # extracts card number based on predefined format
  def self.extract_card_number(line)
    #check if format contains C's = contains credit card number
    format = DETAIL_FORMAT.join('')
    index = format.index('C')
    if index && (format[index,CREDIT_CARD_NUMBER_LENGTH] == "C" * CREDIT_CARD_NUMBER_LENGTH)
        number = line[index,CREDIT_CARD_NUMBER_LENGTH].to_i
        return number
    else
      puts "Format of DETAIL does not have credit card number correctly defined"
      return false
    end
  end

  # checks if card number is valid (Luhn algorithm)
  def self.check_card_number(line,row_number)
    number = extract_card_number(line)
    if number
      checksum = ''
      number.to_s.split('').reverse.each_with_index do |n,i|
        checksum += n if i%2 == 0
        checksum += (n.to_i * 2).to_s if i%2 == 1
      end

      sum = checksum.split('').inject(0) { |sum,x| sum + x.to_i}
      if sum % 10 != 0
        puts "Credit card number on line #{row_number + 1} is not valid"
      end
    end
  end

  # iterates through whole file and checks all lines
  file = File.open("#{ARGV[0]}", 'r')
  all_lines = []
  file.each_with_index do |line, index|
    line = line.gsub(/\r?\n?/, '') #removes newline character (handles all possible cases \n, \r, \r\n)
    if index == 0 # HEADER
      FormatChecker.check_format(line, compute_length(HEADER_FORMAT), HEADER_FORMAT, "HEADER format is invalid")
      check_dates(extract_dates(line, HEADER_FORMAT, "HEADER"),index)
      line = check_row_numbering(line, index, HEADER_FORMAT, "HEADER")
    else
      if file.eof? # TRAILER
        FormatChecker.check_format(line, compute_length(TRAILER_FORMAT), TRAILER_FORMAT, "TRAILER format is invalid")
        check_dates(extract_dates(line, TRAILER_FORMAT, "TRAILER"),index)
        line = check_row_numbering(line, index, TRAILER_FORMAT, "TRAILER")
      else # DETAIL
        FormatChecker.check_format(line, compute_length(DETAIL_FORMAT), DETAIL_FORMAT, "Format on line #{index} is invalid")
        check_dates(extract_dates(line, DETAIL_FORMAT, "DETAIL"),index)
        check_card_number(line, index)
        line = check_row_numbering(line, index, DETAIL_FORMAT, "DETAIL")
      end
    end

    all_lines << line
  end

  #finds all duplicate rows in file
  check_duplicate_rows(all_lines)
end