require 'nokogiri'
require 'open-uri'
require 'tty-prompt'

system('clear')

# Define color escape codes
BLACK        = "\e[30m"
RED          = "\e[31m"
GREEN        = "\e[32m"
YELLOW       = "\e[33m"
BLUE         = "\e[34m"
MAGENTA      = "\e[35m"
CYAN         = "\e[36m"
WHITE        = "\e[37m"
BLANK		 = "\033[0m"

# Define built-in regex patterns
PATTERNS = {
  "1" => { description: "Words", pattern: /\b\w+\b/ },
  "2" => { description: "Alphabetical words", pattern: /\b[A-Za-z]+\b/ },
  # Add more built-in regex patterns here
}

$ascii_art = "\e[31m" + <<~ASCII + "\033[0m"
@@@@@@@@  @@@@@@@    @@@@@@    @@@@@@@@  @@@@@@@@@@   @@@@@@@@  @@@  @@@  @@@@@@@  @@@  @@@  @@@@@@@@@@   
@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@@  @@@@@@@@@@@  @@@@@@@@  @@@@ @@@  @@@@@@@  @@@  @@@  @@@@@@@@@@@  
@@!       @@!  @@@  @@!  @@@  !@@        @@! @@! @@!  @@!       @@!@!@@@    @@!    @@!  @@@  @@! @@! @@!  
!@!       !@!  @!@  !@!  @!@  !@!        !@! !@! !@!  !@!       !@!!@!@!    !@!    !@!  @!@  !@! !@! !@!  
@!!!:!    @!@!!@!   @!@!@!@!  !@! @!@!@  @!! !!@ @!@  @!!!:!    @!@ !!@!    @!!    @!@  !@!  @!! !!@ @!@  
!!!!!:    !!@!@!    !!!@!!!!  !!! !!@!!  !@!   ! !@!  !!!!!:    !@!  !!!    !!!    !@!  !!!  !@!   ! !@!  
!!:       !!: :!!   !!:  !!!  :!!   !!:  !!:     !!:  !!:       !!:  !!!    !!:    !!:  !!!  !!:     !!:  
:!:       :!:  !:!  :!:  !:!  :!:   !::  :!:     :!:  :!:       :!:  !:!    :!:    :!:  !:!  :!:     :!:  
 ::       ::   :::  ::   :::  :!:: ::::  :::     ::    :: ::::   ::   ::    :::    ::::: ::  :::     ::   
 :         :   : :   :   : :   :: :: :    :      :    : :: ::    :    ::    :::     : :  :    :      :    
                                                                                                          
-Created by Asa Moore
ASCII

$prompt = TTY::Prompt.new

$url = ""
$pattern = ""
$output_file = ""

def select_regex_pattern
  options = PATTERNS.map { |key, value| { name: "#{key}: #{value[:description]}", value: value[:pattern] } }
  options << { name: "C: Custom regex pattern", value: :custom }

  option = $prompt.select("Select a regex pattern:", options, cycle: true, per_page: options.size)

  if option == :custom
    $pattern = Regexp.new($prompt.ask("Enter a custom regex pattern:") { |q| q.validate(/.+/) })
  else
    $pattern = option
  end
end


def set_website_url
  $url = $prompt.ask("Enter the website URL to scrape:")
end

def set_output_file_name
  $output_file = $prompt.ask("Enter the output file name:")
end

def start_scraping
  if $url.empty?
    $prompt.warn("Please enter a URL first")
  elsif $pattern.nil?
    $prompt.warn("Please select a regex pattern first")
  else
    begin
      doc = Nokogiri::HTML(URI.open($url))
      matches = doc.text.scan($pattern).uniq
      if $output_file.empty?
        $prompt.ok("Scraping complete. Results:")
        puts matches.join("\n")
      else
        File.open($output_file, "w") do |f|
          matches.each { |match| f.puts match }
        end
        $prompt.ok("Scraping complete. Results written to #{$output_file}")
      end
    rescue StandardError => e
      $prompt.error("Error: #{e}")
    end
  end
end

$prompt.say($ascii_art)

loop do
  system('clear')
  $prompt.say($ascii_art)
  $prompt.say("Current regex pattern: \e[32m#{$pattern.inspect}\033[0m")
  $prompt.say("Current URL: \e[32m#{$url}\033[0m \n")
  $prompt.say("Current output file name: \e[32m#{$output_file}\033[0m \n")

  choice = $prompt.select("\n Select an option:", %w(Select_regex_pattern Set_website_URL Set_output_file_name Start_scraping Quit))
  case choice
  when "Select_regex_pattern"
    select_regex_pattern
  when "Set_website_URL"
    set_website_url
  when "Set_output_file_name"
    set_output_file_name
  when "Start_scraping"
    start_scraping
  when "Quit"
    break
  end
end
