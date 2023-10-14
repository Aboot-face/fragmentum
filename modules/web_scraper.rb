require 'nokogiri'
require 'open-uri'
require 'tty-prompt'

class WebScraper
  attr_accessor :url, :pattern, :output_file

  PATTERNS = {
    "1" => { description: "Words", pattern: /\b\w+\b/ },
    "2" => { description: "Alphabetical words", pattern: /\b[A-Za-z]+\b/ },
    # Add more built-in regex patterns here
  }

  def initialize(parent_menu)
    @parent_menu = parent_menu
    @prompt = TTY::Prompt.new
    @url = ""
    @pattern = ""
    @output_file = ""
  end

  def menu
    loop do
      system('clear')
	  @parent_menu.display_ascii_art
      display_current_settings

      choice = @prompt.select("Select an option:", %w(Select\ Regex\ Pattern Set\ Website\ URL Set\ Output\ File\ Name Start\ Scraping Quit))
      case choice
      when "Select\ Regex\ Pattern"
        select_regex_pattern
      when "Set\ Website\ URL"
        set_website_url
      when "Set\ Output\ File\ Name"
        set_output_file_name
      when "Start\ Scraping"
        start_scraping
      when "Quit"
        break
      end
    end
  end

  def display_current_settings
    @prompt.say("Current regex pattern: \e[32m#{@pattern.inspect}\033[0m")
    @prompt.say("Current URL: \e[32m#{@url}\033[0m \n")
    @prompt.say("Current output file name: \e[32m#{@output_file}\033[0m \n")
  end

  def select_regex_pattern
    options = PATTERNS.map { |key, value| { name: "#{key}: #{value[:description]}", value: value[:pattern] } }
    options << { name: "C: Custom regex pattern", value: :custom }
  
    option = @prompt.select("Select a regex pattern:", options, cycle: true, per_page: options.size)
  
    if option == :custom
      custom_pattern_str = @prompt.ask("Enter a custom regex pattern:") { |q| q.required(true) }
      begin
        @pattern = Regexp.new(custom_pattern_str)
        puts "Created regex: #{@pattern.inspect}" # This line prints the regex
      rescue RegexpError => e
        @prompt.error("Invalid regex pattern: #{e.message}")
        retry
      end
    else
      @pattern = option
      puts "Selected predefined regex: #{@pattern.inspect}" # This line prints the regex
    end
  end


  def set_website_url
    @url = @prompt.ask("Enter the website URL to scrape:")
  end

  def set_output_file_name
    @output_file = @prompt.ask("Enter the output file name:")
  end

  def start_scraping
    if @url.empty?
      @prompt.warn("Please enter a URL first")
    elsif @pattern.nil?
      @prompt.warn("Please select a regex pattern first")
    else
      begin
        doc = Nokogiri::HTML(URI.open(@url))
        text_content = []
  
        # Iterate over significant elements and capture their text
        doc.traverse do |node|
          if node.text? && node.content.strip.length > 0
            # Add text content of the node to the array, along with newlines for separation
            text_content << node.content.strip
          end
        end
  
        # Join the text content array into a single string, separated by newlines
        formatted_text = text_content.join("\n")
  
        # Scan for matches
        matches = formatted_text.scan(@pattern).uniq
  
        if @output_file.empty?
          @prompt.ok("Scraping complete. Results:")
          puts matches.join("\n")
        else
          File.open(@output_file, "w") do |f|
            matches.each { |match| f.puts match }
          end
          @prompt.ok("Scraping complete. Results written to #{@output_file}")
        end
      rescue StandardError => e
        @prompt.error("Error: #{e}")
      end
    end
  end
end
