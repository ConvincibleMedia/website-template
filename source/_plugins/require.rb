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

		def process_args(args)
			args = render_variables(args) # Convert any {{ variables }}
			if self.respond_to?(:input) # Call input first
				args = parse_args(args, input)
			end
			return args
		end

		VARIABLE_SYNTAX = %r! (?: \{\{ \s* ("[^"]+"|[\w\-\.]+) \s* (?:\|.*)? \}\} ) !x
		def render_variables(args)
			#puts "Input was: {% #{@tag} #{args} %}" if @tag == 'link'
			matches(VARIABLE_SYNTAX, args).each { |match|
				#puts "...found variable: #{match[0].to_s}" if @tag == 'link'
				if match[1] =~ /^["\s]+.*["\s]+$/ # {{ " literal " }}
					val = match[1].strip_of('" ')
					args = args.sub(match[0], val)
				elsif val = @context[match[1]]
					val = val.to_s
					val.gsub!(/[\r\n]+/, ' ')
					val.gsub!(/(["'])/, '\\\1')
					if val.include?(' ') then val = "'#{val}'" end
					args = args.sub(match[0], val)
				end
			}
			#puts "Input changed to: #{args.to_s}" if @tag == 'link'
			return args
		end

		def parse_args(args, validation = {})
			quote = '(?<!\\\\)[\'"]'
			types =  []
			types << quote + '.*?' + quote # String literals: 'ab c=de f' or "ab c=de f"
			types << '[^=\s]+=' + types[0] # Var = string literal: abc='def g=hi'
			types << '[^=\s]+=[^\s]*' # Variables: abc=def
			types << '[^\s]+' # Without assignment: abcdef
			r = Regexp.new(types.join('|'))

			#puts "Scanning '#{args}' for arguments..." if @tag == 'link'
			matches = args.scan(r)
			#puts "Identified args: #{matches.inspect}"

			hash = []
			count = 0
			matches.each_with_index { |pair, index|
				literal = Regexp.new('^' + types[0] + '$')
				if !pair.match(literal) # Check the whole thing is not a string literal
					split = []
					eq = pair.index(/(?<!\\)=/) # Find an equals not escaped
					if eq != nil # There is an equals sign in this piece
						# Set a variable
						key = pair[0, eq]
						val = pair[eq+1..-1]
						split.push(key)
						if val.match(literal) # Key = 'literal'
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

		def validate_args(args, validation)
			new_args = {}
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
							new_args[k] = args[k] unless new_args.key?(k)
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
							new_args[k] = args[k] unless new_args.key?(k)
						end
					end
				}
			end

			#puts "Validation complete. Arguments ensured as:"
			#ap new_args

			return new_args
		end

		def render_context(context)
			# Set additional class variables
			@context = context
			@site = @context.registers[:site]
			@page = @context.environments.first['page']
			@path = @page['path']
			@config = @site.config
			@data = @site.data #Data files
			@markdown = @context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
		end

		def block_uncomment(block)
			@commented = {
				open: block[0..2] == '-->',
				close: block[-4..-1] == '<!--'
			}
			if @commented[:open] then block = block[3..-1] end
			if @commented[:close] then block = block[0..-5] end
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
			block = block_uncomment(super)
			args = process_args(@args)
			return (
				@commented[:open] ? "#{@liquid[:open]}-->\n" : ''
				) + output(args, block) + (
				@commented[:close] ? "\n<!--#{@liquid[:close]}" : ''
			)
		end
	end

end
