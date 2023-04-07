require 'base64'
require 'tty-prompt'

class RailFenceCipher
  VERSION = 1
  def self.decode(ciphertext, rails, start_top = true, offset = 0)
    zigzag(rails, ciphertext.length, start_top, offset).
      sort.
      zip(ciphertext.chars).
      sort_by { |a| a[0][1] }.
      map { |a| a[1] }.
      join
  end
  def self.encode(plaintext, rails)
    zigzag(rails, plaintext.length).
      zip(plaintext.chars).
      sort.
      map { |a| a[1] }.
      join
  end
  def self.zigzag(rails, size, start_top = true, offset = 0)
    pattern = (0..rails - 1).to_a + (1..rails - 2).to_a.reverse
    zigzag_indices = pattern.cycle.first(size).zip(0..size)
    zigzag_indices.rotate!(offset) if start_top
    zigzag_indices
  end
end

class Decoder
  def initialize(parent_menu)
    @parent_menu = parent_menu
    @prompt = TTY::Prompt.new
  end

	def menu
		loop do
			system('clear')
			@parent_menu.display_ascii_art
			
			ciphers = {
				'Auto-detect' => 'auto-detect',
				'Binary' => 'binary',
				'Base64' => 'base64',
				'Caesar' => 'caesar',
				'Hex' => 'hex',
				'Morse' => 'morse',
				'Rail Fence' => 'rail_fence',
				'Vigenere' => 'vigenere',
				'Quit' => 'quit'
			}
			
			display_names = ciphers.keys
			choice = @prompt.select("\nSelect a cipher:", display_names)
			cipher = ciphers[choice]

			case cipher
			when "quit"
				break
			else
				input_text = @prompt.ask("Enter the text to be decoded:")

				if cipher == "auto-detect"
					cipher = auto_detect(input_text)
					puts "Detected cipher: #{cipher.capitalize}"
				end

				decoded_text = nil

				case cipher
				when 'binary'
					decoded_text = decode_binary(input_text)
					puts "Decoded text (Binary): #{decoded_text}"
				when 'base64'
					decoded_text = decode_base64(input_text)
					puts "Decoded text (Base64): #{decoded_text}"
				when "caesar"
					decoded_texts = decode_caesar(input_text)
					puts "Possible decoded texts for Caesar cipher:"
					decoded_texts.each do |decoded|
						puts "Shift #{decoded[:shift]}: #{decoded[:text]}"
					end
				when "hex"
					decoded_text = decode_hex(input_text)
					puts "Decoded text (Hex): #{decoded_text}"
				when "morse"
					decoded_text = decode_morse(input_text)
					puts "Decoded text (Morse code): #{decoded_text}"
				when "rail_fence"
					rails = @prompt.ask("Enter the number of rails:", convert: :int)
					start_from_top = @prompt.yes?("Start from the top rail? (default: Yes)")
					offset = @prompt.ask("Enter the offset (default: 0):", default: 0, convert: :int)
					decoded_text = RailFenceCipher.decode(input_text, rails, start_from_top, offset)
					puts "Decoded text (Rail Fence): #{decoded_text}"
				when "vigenere"
					key = @prompt.ask("Enter the passcode:")
					decoded_text = decode_vigenere(input_text, key)
					puts "Decoded text (Vigenère): #{decoded_text}"
				else
					puts "Couldn't auto-detect the cipher or unsupported cipher."
				end
				@prompt.keypress("Press any key to continue...")
			end
		end
	end



	def auto_detect(text)
		cipher_detectors = {
			'binary' => method(:binary?),
			'base64' => method(:base64?),
			'hex' => method(:hex?),
			'morse' => method(:morse?)
		}

		detected_ciphers = cipher_detectors.select { |_cipher, detector| detector.call(text) }
		
		if detected_ciphers.size == 1
			return detected_ciphers.keys.first
		elsif detected_ciphers.empty?
			decoded_caesar = decode_caesar(text)
			english_words = File.readlines('english_words.txt').map(&:strip).to_set

			caesar_score = decoded_caesar.map do |decoded|
				decoded[:text].split.count { |word| english_words.include?(word.downcase) }
			end.max

			return 'caesar' if caesar_score >= 3
		elsif detected_ciphers.size > 1
			cipher_priorities = %w[hex binary morse base64]
			return cipher_priorities.detect { |cipher| detected_ciphers.key?(cipher) }
		else
			return 'unknown'
		end

		'unknown'
	end

  # Detection methods
	def binary?(text)
	  # Remove common delimiters
		text_without_delimiters = text.gsub(/[ ,]/, '')
		
		return false unless text.match?(/^[01 ]+/) && (text_without_delimiters.length % 8).zero?

		decoded = decode_binary(text)
		decoded.match?(/\A[\x20-\x7E]+\z/)
	end

  def base64?(text)
    # Check if the text is a valid Base64 string
    Base64.strict_encode64(Base64.decode64(text)) == text
  rescue ArgumentError
    false
  end

  def caesar?(text)
    # It's difficult to accurately detect Caesar cipher, so return true for any text
    true
  end

	def hex?(text)
		# Remove common delimiters
		text_without_delimiters = text.gsub(/[ ,]/, '')

		return false unless text_without_delimiters.match?(/^[0-9a-fA-F]+$/) && (text_without_delimiters.length % 2).zero?

		decoded = decode_hex(text_without_delimiters)
		decoded.match?(/\A[\x20-\x7E]+\z/)
	end

	def morse?(text)
		return false unless text.match?(/^[-\. \/]+/)

		morse_chars = text.split(' ')
		morse_chars.count { |char| char.match?(/^[-.]+$/) }.to_f / morse_chars.size >= 0.5
	end

  # Decoding methods
	def decode_binary(text)
		# Remove common delimiters
		text_without_delimiters = text.gsub(/[ ,]/, '')

		text_without_delimiters.gsub(/[01]{8}/) { |octet| octet.to_i(2).chr }
	end

  def decode_caesar(text)
    (1..25).map do |shift|
      decoded_text = text.chars.map { |c| decode_caesar_char(c, shift) }.join
      { shift: shift, text: decoded_text }
    end
  end

  def decode_caesar_char(char, shift)
    return char unless char.match?(/[a-zA-Z]/)

    base = char.ord < 91 ? 65 : 97
    (((char.ord - base - shift) % 26) + base).chr
  end

	def decode_hex(text)
		# Remove common delimiters
		text_without_delimiters = text.gsub(/[ ,]/, '')

		[text_without_delimiters].pack('H*')
	end

  def decode_morse(text)
    morse_dict = {
      '.-'=>'A', '-...'=>'B', '-.-.'=>'C', '-..'=>'D', '.'=>'E', '..-.'=>'F',
      '--.'=>'G', '....'=>'H', '..'=>'I', '.---'=>'J', '-.-'=>'K', '.-..'=>'L',
      '--'=>'M', '-.'=>'N', '---'=>'O', '.--.'=>'P', '--.-'=>'Q', '.-.'=>'R',
      '...'=>'S', '-'=>'T', '..-'=>'U', '...-'=>'V', '.--'=>'W', '-..-'=>'X',
      '-.--'=>'Y', '--..'=>'Z', '-----'=>'0', '.----'=>'1', '..---'=>'2',
      '...--'=>'3', '....-'=>'4', '.....'=>'5', '-....'=>'6', '--...'=>'7',
      '---..'=>'8', '----.'=>'9', '.-.-.-'=>'.', '--..--'=>',', '..--..'=>'?',
      '-.-.--'=>'!', '---...'=>':', '.----.'=>"'", '-..-.'=>"'", '.-..-.'=>'"',
      '-....-'=>'-', '-...-'=>'=', '.-.-.'=>'+', '.--.-.'=>'@'
    }

    text.split(' ').map { |code| morse_dict[code] || ' ' }.join
  end

	def decode_vigenere(text, key)
		key_chars = key.upcase.chars.map { |char| char.ord - 65 }
		key_len = key.length

		index = 0
		text.chars.map do |char|
			if char.match?(/[a-zA-Z]/)
				base = char.ord < 91 ? 65 : 97
				key_shift = key_chars[index % key_len]
				index += 1
				(((char.ord - base - key_shift) % 26) + base).chr
			else
				char
			end
		end.join
	end
end