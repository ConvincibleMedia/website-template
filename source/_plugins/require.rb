require_relative '../../utils/helpers.rb'

# CUSTOM TAG BASE
module Jekyll

	module CustomPlugin

		def initialize(tag, args, options)
			super
			@tag = tag
			@args = args.strip || ''
			@liquid = {
				open: '{% ' + @tag + (@args.present? ? ' ' + @args : '') + ' %}',
				close: '{% end' + @tag + ' %}' # Only in fact used if a block tag
			}
			@options = options
			#puts 'Initialised ' + @tag + ' tag'
		end

		def tag_error(err_text = '')
			if defined? @block
				raise [
					"Invalid tag on page #{@path}:",
					@liquid[:open],
					@block,
					@liquid[:close],
					err_text
				].join("\n")
			else
				raise [
					"Invalid tag on page #{@path}:",
					@liquid[:open],
					err_text
				].join("\n")
			end
			return false
		end

		def process_args(_input_string, block = nil)
			args = render_variables(_input_string) # Convert any {{ variables }}
			if self.respond_to?(:input) # Call input first
				args = parse_args(args, input())
			end
			return args
		end

		VARIABLE_SYNTAX = %r! (?: \{\{ \s* ("[^"]+"|[\w\-\.]+) \s* (?:\|.*)? \}\} ) !x
		def render_variables(_input_string)
			input_string = _input_string.dup
			#puts "Input was: {% #{@tag} #{input_string} %}" if @tag == 'link'
			matches(VARIABLE_SYNTAX, input_string).each { |match|
				#puts "...found variable: #{match[0].to_s}" if @tag == 'link'
				if match[1] =~ /^["\s]+.*["\s]+$/ # {{ " literal " }}
					val = match[1].strip_of('" ')
					input_string = input_string.sub(match[0], val)
				elsif val = @context[match[1]]
					val = val.to_s
					val.gsub!(/[\r\n]+/, ' ')
					val.gsub!(/(["'])/, '\\\1')
					if val.include?(' ') then val = "'#{val}'" end
					input_string = input_string.sub(match[0], val)
				end
			}
			#puts "Input changed to: #{input_string.to_s}" if @tag == 'link'
			return input_string
		end

		NOT_ESCAPED = '(?<!\\\\)'
		QUOTE = NOT_ESCAPED + '[\'"]'
		EQUALS = NOT_ESCAPED + '='
		VALID = {
			quoted: QUOTE + '.*?' + QUOTE,
			variable_quoted: '[^=\s]+' + EQUALS + QUOTE + '.*?' + QUOTE,
			variable: '[^=\s]+' + EQUALS + '[^\s]*',
			flag: '[^\s]+'
		}
		VALID_REGEX = Regexp.new(VALID.map{|_,v| v}.join('|'))
		QUOTED_REGEX = Regexp.new('^' + VALID[:quoted] + '$')
		def parse_args(_input_string, validation = {})
			args = _input_string.dup
			validation.freeze

			#puts "Scanning '#{args}' for arguments..." if @tag == 'link'
			matches = args.scan(VALID_REGEX)
			#puts "Identified args: #{matches.inspect}"

			hash = []
			count = 0
			matches.each_with_index { |pair, index|
				if pair !~ QUOTED_REGEX # Check the whole thing is not a string literal
					split = []
					eq = pair.index(/(?<!\\)=/) # Find an equals not escaped
					if eq != nil # There is an equals sign in this piece
						# Set a variable
						key = pair[0, eq]
						val = pair[eq+1..-1]
						split.push(key)
						if val =~ QUOTED_REGEX # Key = 'literal'
							val.gsub!(/^['"]|['"]$/, '')
							val.gsub!('\"', '"')
							val.gsub!('\\\'', "'")
							split.push(val) # Remove the literal quotes
						else
							# key=val - use appropriate type if possible
							if val.to_i.to_s == val then val = val.to_i end
							if val.to_f.to_s == val then val = val.to_f end
							if val == 'true' then val = true end
							if val == 'false' then val = false end
							split.push(val)
						end
						hash.push(split) # Add on key: val
						count += 1
					else # No equals sign
						# Parameter switch as boolean
						pair.gsub!(/^['"]|['"]$/, '')
						pair.gsub!('\"', '"')
						pair.gsub!('\\\'', "'")
						hash.push([index + 1, pair]) # [index] = val
						hash.push([pair, true]) # val = true
						count += 1
					end
				else
					# String literal as value
					pair.gsub!(/^['"]|['"]$/, '')
					pair.gsub!('\"', '"')
					pair.gsub!('\\\'', "'")
					hash.push([index + 1, pair]) # [index] => value
					count += 1
				end
			}
			#if args == 1 && hash.key?(0)
			#	args = hash[0] # If only 1 unnamed argument, make the whole args just that
			#else
			args = hash.to_h # Otherwise, return a hash of arguments
			#end
			#puts "Input split into #{count.to_s} args:" if @tag == 'link'
			#ap args if @tag == 'link'

			# Ensures args matches expected structure
			args = validate_args(args, validation) if validation.present?

			return args
		end

		def validate_args(_args, _validation)
			args = _args.dup
			validation = _validation.dup

			args_valid = {}
			#puts "Begin validation"
			if validation.key?(:block)
				if @block.blank?
					tag_error("Required non-empty block was not supplied.")
					return false
				elsif validation[:block].is_a? Regexp
					if m = validation[:block].match(@block)
						m.names.each { |name|
							# If found named groups, promote these matches to named arguments (which will next be validated!)
							args[name] = m[name]
						}
					else
						tag_error("Block did not pass Regex: #{validation[:block]}")
						return false
					end
				end
			end
			if validation.key?(:required)
				#puts "Validating required arguments..."
				validation[:required] = [validation[:required]] unless validation[:required].is_a?(Array)
				reqs_valid = [true]

				validation[:required].each_with_index { |reqs, index| # Each set
					if reqs.is_a?(Hash)
						reqs.each { |k, type| # Each requirement in this set
							#puts "...requirement set #{index + 1}, expecting #{k.to_s} as #{type.to_s}"
							if !args.key?(k) || !args[k].present?
								reqs_valid[index] = "Required argument #{k.to_s} was not supplied"
								break # Fail = no need to check other requirements in this set
							elsif type.is_a?(Class)
								if !args[k].is_a?(type)
									reqs_valid[index] = "Required argument #{k.to_s} supplied, but is not #{type.to_s}"
									break # Fail = no need to check other requirements in this set
								end
							end
							#puts "...validation passed."
							args_valid[k] = args[k].dup unless args_valid.key?(k)
							reqs_valid[index] = true # Can be overriden by later failure
						}
					end
				}
				unless reqs_valid.include?(true)
					#puts "...Overall: validation failure"
					tag_error(reqs_valid.join(" + \n"))
					return false
				end
			end
			if validation.key?(:optional) && validation[:optional].is_a?(Hash)
				#puts "Validating optional arguments..."
				validation[:optional].each { |k, type|
					if args.key?(k)
						#puts "...optional argument #{k} was passed..."
						if !type.is_a?(Class) || !args[k].is_a?(type)
							tag_error("Optional argument #{k.to_s} supplied, but is not #{type.to_s}")
							return false
						else
							#puts "...validaton passed."
							args_valid[k] = args[k].dup unless args_valid.key?(k)
						end
					end
				}
			end

			#puts "Validation complete. Arguments ensured as:"
			#ap args_valid

			return args_valid
		end

		def render_context(context)
			# Set additional class variables
			@context = context
			@site = @context.registers[:site]
			@config = @site.config
			@data = @site.data #Data files
				@langs = @data['langs']
			@page = @context.environments.first['page']
				@lang = @page['meta']['lang'] || @langs[0]
				@path = @page['path']
			@markdown = @context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
			I18n.locale = @lang.to_sym
		end

		def block_uncomment(_block)
			block = _block.dup
			@commented = {
				open: block[0..2] == '-->',
				close: block[-4..-1] == '<!--'
			}
			if @commented[:open] then block = block[3..-1] end
			if @commented[:close] then block = block[0..-5] end
			return block
		end

		def convert(_block)
			return @markdown.convert(_block)
		end

		def convert_inline(_block)
			block = _block.to_s.dup
			if block.length > 0
				block = inlinify(block)
				block = @markdown.convert(block)
				return block.gsub(/(^<p>|<\/p>$)/, '').strip
			end
			return block
		end

	end


	class CustomTag < Liquid::Tag
		include Jekyll::CustomPlugin
		def render(context)
			render_context(context)
			args = process_args(@args)
			return output(arguments)
		end
	end

	class CustomBlock < Liquid::Block
		include Jekyll::CustomPlugin
		def render(context)
			render_context(context)
			@block = block_uncomment(super)
			args = process_args(@args)
			return (
				@commented[:open] ? "#{@liquid[:open]}-->\n" : ''
				) + output(args, @block) + (
				@commented[:close] ? "\n<!--#{@liquid[:close]}" : ''
			)
		end
	end

end
