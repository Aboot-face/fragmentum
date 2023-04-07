class WordlistManager
  attr_accessor :parent_menu

  SYMBOLS = %w(! @ # $ % ^ & * ( ) _ + - = { } [ ] | \ : ; " ' < > ? , . / ` ~)

  def initialize(parent_menu)
    @parent_menu = parent_menu
    @prompt = TTY::Prompt.new
  end

  def combine_wordlists(lists)
    output_file = @prompt.ask("Enter the name of the output file (it will be saved in the current directory):")
    File.open(output_file, 'w') do |output|
      iterate_lists(lists, 0, "", output)
    end
    puts "Wordlists combined successfully."
  end

  def iterate_lists(lists, index, current_line, output)
    if index == lists.size
      output.puts(current_line)
      return
    end

    case lists[index][:type]
    when 'word'
      File.foreach(lists[index][:path]) do |line|
        iterate_lists(lists, index + 1, current_line + line.chomp, output)
      end
    when 'num'
      number_range(lists[index][:digits]).each do |num|
        iterate_lists(lists, index + 1, current_line + num.to_s.rjust(lists[index][:digits], '0'), output)
      end
    when 'sym'
      SYMBOLS.each do |sym|
        iterate_lists(lists, index + 1, current_line + sym, output)
      end
    end
  end

  def number_range(digits)
    min_num = 0
    max_num = 10**digits - 1
    (min_num..max_num)
  end

  def get_lists_info(num_lists)
    lists = []
    num_lists.times do |i|
      type = @prompt.select("Select type for list #{i + 1}:", %w(word num sym))
      list_info = { type: type }
      case type
      when 'word'
        path = @prompt.ask("Enter the path to the wordlist:")
        list_info[:path] = path
      when 'num'
        digits = @prompt.ask("Enter the number of digits (e.g., 2 for two digits):").to_i
        list_info[:digits] = digits
      end
      lists << list_info
    end
    lists
  end

  def menu
    loop do
      system('clear')
      @parent_menu.display_ascii_art

      choice = @prompt.select("\n Select an option:", %w(Wordlist\ Combination Quit))
      case choice
      when "Wordlist\ Combination"
        num_lists = @prompt.ask("How many word lists would you like to combine?").to_i
        lists = get_lists_info(num_lists)
        combine_wordlists(lists)
      when "Quit"
        break
      end
    end
  end
end
