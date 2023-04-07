require_relative 'modules/john_the_ripper'
require_relative 'modules/web_scraper'
require_relative 'modules/wordlist_manager'
require_relative 'modules/decoder'

require 'tty-prompt'

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

class Menu
  def initialize
    @prompt = TTY::Prompt.new
    @web_scraper = WebScraper.new(self)
    @john_the_ripper = JohnTheRipper.new(self)
		@wordlist_manager = WordlistManager.new(self)
		@decoder = Decoder.new(self)
  end

  def display_ascii_art
    puts $ascii_art
  end

	def run
		loop do
			system('clear')
			display_ascii_art
			choice = @prompt.select("Select an option:", %w(Web\ Scraper John\ the\ Ripper Wordlist\ Manager Decoder Quit))
			case choice
			when "Web Scraper"
				@web_scraper.menu
			when "John the Ripper"
				@john_the_ripper.menu
			when "Wordlist Manager"
				@wordlist_manager.parent_menu = self
				@wordlist_manager.menu
			 when "Decoder"
        @decoder.menu
			when "Quit"
				break
			end
		end
	end

	def web_scraper_menu
		loop do
			system('clear')
			display_ascii_art
			@web_scraper.display_current_settings

			choice = @prompt.select("\n Select an option:", %w(Select\ Regex\ pattern Set\ Website\ URL Set\ Output\ File\ Name Start\ Scraping Quit))
			case choice
			when "Select Regex pattern"
				@web_scraper.select_regex_pattern
			when "Set Website URL"
				@web_scraper.set_website_url
			when "Set Output File Name"
				@web_scraper.set_output_file_name
			when "Start Scraping"
				@web_scraper.start_scraping
			when "Quit"
				break
			end
		end
	end
end

menu = Menu.new
menu.run
