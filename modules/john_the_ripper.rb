require 'tty-prompt'
require 'find'

class JohnTheRipper
  attr_accessor :flags, :parent_menu

  def initialize(parent_menu)
    @parent_menu = parent_menu
    @prompt = TTY::Prompt.new
    @flags = []
	@file_to_crack = ''
  end

def list_cracked_passwords
  return if @file_to_crack.empty?

  command = "john --show #{@file_to_crack}"
  puts "Running command: #{command}"
  system(command)

  puts "Press any key to continue..."
  STDIN.getch
  system('clear') # Clear the screen before returning to the main menu
end

  def get_wordlists
    wordlists = []

    Find.find("password_lists/") do |path|
      if File.file?(path)
        wordlists << path
      end
    end

    wordlists
  end

  def add_flag(flag)
    @flags << flag
  end

  def remove_flag(flag)
    @flags.delete(flag)
  end

  def clear_flags
    @flags.clear
  end

	def execute_john
		return if @file_to_crack.empty?

		command = "john #{flags.join(' ')} #{@file_to_crack}"
		puts "Running command: #{command}"
		system(command)

		puts "Press any key to continue..."
		STDIN.getch
		system('clear') # Clear the screen before returning to the main menu
	end

  def select_file_to_crack
    file_path = @prompt.ask("Enter the path to the file to crack:")
    if File.exist?(file_path)
      @file_to_crack = file_path
    else
      puts "File not found. Please try again."
    end
  end

	def menu
		loop do
			system('clear')
			@parent_menu.display_ascii_art
			display_current_settings

			options = [
				"Select file",
				"Add flag",
				"Remove flag",
				"Clear flags",
				"Execute John",
				"List Cracked Passwords",
				"Quit"
			]
			choice = @prompt.select("\n Select an option:", options)

			case choice.gsub(' ', '_')
			when "Select_file"
				select_file_to_crack
			when "Add_flag"
				add_flag_menu
			when "Remove_flag"
				remove_flag_menu
			when "Clear_flags"
				clear_flags
			when "Execute_John"
				execute_john
			when "List_Cracked_Passwords"
				list_cracked_passwords
			when "Quit"
				break
			end
		end
	end

  def add_flag_menu
    # Add more flags here following the pattern, check John's documentation for more options.
    available_flags = {
      'Cracking Modes' => [
        '--wordlist',
        '--incremental',
        '--incremental:Lower',
        '--incremental:Alpha',
        '--incremental:Digits',
        '--incremental:Alnum',
        '--external:',
        '--loopback',
        '--mask=?1?1?1?1?1?1?1?1 -1=[A-Z]',
        '--prince=wordlist'
      ],
      'Rules' => [
        '--rules:Single',
        '--rules:Wordlist',
        '--rules:Extra',
        '--rules:Jumbo',
        '--rules:KoreLogic',
        '--rules:All'
      ],
      'Format' => [
        '--format=bfegg',
        '--format=bf',
        '--format=afs',
        '--format=bsdi',
        '--format=crypt',
        '--format=des',
        '--format=dmd5',
        '--format=dominosec',
        '--format=hdaa',
        '--format=hmac-md5',
        '--format=hmailserver',
        '--format=ipb2',
        '--format=krb4',
        '--format=krb5',
        '--format=lm',
        '--format=lotus5',
        '--format=md4-gen',
        '--format=md5',
        '--format=mediawiki',
        '--format=mscash',
        '--format=mscash2',
        '--format=mschapv2',
        '--format=mskrb5',
        '--format=mssql05',
        '--format=mssql',
        '--format=mysql-fast',
        '--format=mysql',
        '--format=mysql-sha1',
        '--format=netlm',
        '--format=netlmv2',
        '--format=netntlm',
        '--format=netntlmv2',
        '--format=nethalflm',
        '--format=md5ns',
        '--format=nsldap',
        '--format=ssha',
        '--format=nt',
        '--format=openssha',
        '--format=oracle11',
        '--format=oracle',
        '--format=pdf',
        '--format=phpass-md5',
        '--format=phps',
        '--format=pix-md5',
        '--format=po',
        '--format=rar',
        '--format=raw-md4',
        '--format=raw-md5',
        '--format=raw-md5-unicode',
        '--format=raw-sha1',
        '--format=raw-sha224',
        '--format=raw-sha256',
        '--format=raw-sha384',
        '--format=raw-sha512',
        '--format=salted-sha',
        '--format=sapb',
        '--format=sapg',
        '--format=sha1-gen',
        '--format=skey',
        '--format=ssh',
        '--format=sybasease',
        '--format=xsha',
        '--format=zip'
      ]
    }

    flag_category = @prompt.select("Select a flag category:", available_flags.keys)
    selected_flag = @prompt.select("Select a flag to add:", available_flags[flag_category], per_page: 25, column_width: 20)

    if selected_flag == '--wordlist'
      wordlist = @prompt.select("Select a wordlist:", get_wordlists)
      selected_flag = "--wordlist=#{wordlist}"
    elsif selected_flag.start_with?('--external:')
		      rulename = @prompt.ask("Enter the rulename for --external:")
      selected_flag = "--external:#{rulename}"
    end

    if @flags.include?(selected_flag)
      puts "Flag already added. Skipping."
    else
      add_flag(selected_flag)
    end
  end


  def remove_flag_menu
    return if @flags.empty?

    selected_flag = @prompt.select("Select a flag to remove:", @flags)
    remove_flag(selected_flag)
  end

  def display_current_settings
    puts "Current flags: #{flags.join(' ')}"
		puts "Selected file to crack: #{@file_to_crack}"
  end
end
