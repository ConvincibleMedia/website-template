require_relative '../../utils/helpers.rb'

# CUSTOM TAG BASE
module Jekyll

	module CustomPlugin

		def initialize(tag, params, options)
			super
			@tag = tag
			puts 'INITIALISE: ' + @tag + ' ' + params + rand.to_s
			@input = params.dup.strip || ''
			@args_raw = @input.dup
			@liquid = [
				'{% ' + @tag + (@args_raw.length > 0 ? ' ' + @args_raw : '') + ' %}',
				'{% end' + @tag + ' %}'
			]
			@options = options
			#puts 'Initialised ' + @tag + ' Tag'
		end

		def tag_error(err_text = '')
			if defined? @block
				raise "Invalid tag on page #{@path}:\n#{@liquid[0]}\n#{@block}\n#{@liquid[1]}\n" + err_text
			else
				raise "Invalid tag on page #{@path}:\n#{@liquid[0]}\n" + err_text
			end
			return false
		end

		def setup
			set_context # Setup other basic stuff
			puts "Setup new tag on page #{@path}:\n   #{@liquid[0]}\n   #{@block}\n   #{@liquid[1]}" if @tag == 'link'
			render_variables # Convert any {{ variables }} in input to their contexual values
			if defined? input # Parse input into arguments and/or check validity
				puts "input() method defined for tag: #{@tag}"
				if !input
					tag_error('Input check failed.')
				end
			end
		end

		def set_context
			@site = @context.registers[:site]
			@page = @context.environments.first['page']
			@path = @page['path']
			@config = @site.config
			@data = @site.data #Data files
			@markdown = @context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
		end

		def check_input(validation = {})

			if validation.key?(:required) && validation[:required].is_a?(Hash)
				validation[:required].each { |k, type|
					if !@args.key?(k) || !@args[k].present?
						tag_error("Parameter #{k.to_s} was not supplied")
						return false
					elsif type.is_a?(Class)
						 unless @args[k].is_a?(type)
							 tag_error("Parameter #{k.to_s} is not #{type.to_s}")
							 return false
						 end
					end
				}
			end

			if validation.key?(:optional) && validation[:optional].is_a?(Hash)
				validation[:optional].each { |k, type|
					if @args.key?(k)
						unless type.is_a?(Class) && @args[k].is_a?(type)
							tag_error("Parameter #{k.to_s} is not #{type.to_s}")
							return false
						end
					end
				}
			end

			return true
		end

		VARIABLE_SYNTAX = %r! (?: \{\{ \s* ("[^"]+"|[\w\-\.]+) \s* (?:\|.*)? \}\} ) !x
		def render_variables
			puts "Input was: {% #{@tag} #{@args} %}" if @tag == 'link'
			matches(VARIABLE_SYNTAX, @args).each { |match|
				puts "...found variable: #{match[0].to_s}" if @tag == 'link'
				if match[1] =~ /^["\s]+.*["\s]+$/ # {{ " literal " }}
					val = match[1].strip_of('" ')
					@args = @args.sub(match[0], val)
				elsif val = @context[match[1]]
					val = val.to_s
					val.gsub!(/[\r\n]+/, ' ')
					val.gsub!(/(["'])/, '\\\1')
					if val.include?(' ') then val = "'#{val}'" end
					@args = @args.sub(match[0], val)
				end
			}
			puts "Input changed to: #{@args.to_s}" if @tag == 'link'
		end

		def parse_input(validation = {})
			quote = '(?<!\\\\)[\'"]'
			types =  []
			types << quote + '.*?' + quote # String literals: 'ab c=de f' or "ab c=de f"
			types << '[^=\s]+=' + types[0] # Var = string literal: abc='def g=hi'
			types << '[^=\s]+=[^\s]*' # Variables: abc=def
			types << '[^\s]+' # Without assignment: abcdef
			r = Regexp.new(types.join('|'))

			puts "Scanning '#{@args}' for arguments..." if @tag == 'link'
			matches = @args.scan(r)
			puts "Identified args: #{matches.inspect}"

			hash = []
			args = 0
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
							split.push(val)
						end
						hash.push(split) # Add on key: val
						args += 1
					else # No equals sign
						# Parameter switch as boolean
						pair.gsub!(/^['"]|['"]$/, '')
						pair.gsub!('\"', '"')
						pair.gsub!('\\\'', "'")
						hash.push([index, pair]) # [index] = val
						hash.push([pair, true]) # val = true
						args += 1
					end
				else
					# String literal as value
					pair.gsub!(/^['"]|['"]$/, '')
					pair.gsub!('\"', '"')
					pair.gsub!('\\\'', "'")
					hash.push([index, pair]) # [index] => value
					args += 1
				end
			}
			#if args == 1 && hash.key?(0)
			#	@args = hash[0] # If only 1 unnamed argument, make the whole @args just that
			#else
				@args = hash.to_h # Otherwise, return a hash of arguments
			#end
			#puts "Input split into #{args.to_s} args:" if @tag == 'link'
			#ap @args if @tag == 'link'
			check_input(validation) if validation.key?(:required) || validation.key?(:optional)
		end

	end

	class CustomTag < Liquid::Tag
		include Jekyll::CustomPlugin
		def render(context)
			puts '---------Rendering ' + @tag + ' Tag'
			@context = context
			setup(context)
			return output
		end
	end

	class CustomBlock < Liquid::Block
		include Jekyll::CustomPlugin
		def render(context)
			puts '---------Rendering ' + @tag + ' Tag'
			@context = context
			@block = super
			@commented = [@block[0..2] == '-->', @block[-4..-1] == '<!--']
			if @commented[0] then @block = @block[3..-1] end
			if @commented[1] then @block = @block[0..-5] end

			setup

			return (@commented[0] ? "#{@liquid[0]}-->\n" : '') + output + (@commented[1] ? "\n<!--#{@liquid[1]}" : '')
		end
	end

end
