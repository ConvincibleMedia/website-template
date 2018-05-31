require_relative '../../utils/helpers.rb'

#require 'liquid-tag-parser'

# CUSTOM TAG BASE
module Jekyll
	class CustomTag < Liquid::Tag

		def initialize(tag, input, options)
			super
			@tag = tag
			@input = input
			@options = options
			#puts 'Initialised ' + @tag + ' Tag'
		end

		def render(context)
			#puts 'Rendering ' + @tag + ' Tag'
			@context = context
			@site = context.registers[:site]
			@config = @site.config
			@data = @site.data
			@markdown = context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
			return output
		end

		def parse_input()
			types =  []
			types << '[\'"][^\'"]*[\'"]' # 'ab c=de f'
			types << '[^=\s]+=[\'"][^\'"]*[\'"]' # abc='def g=hi'
			types << '[^=\s]+=[^\s]*' # abc=def
			types << '[^\s]+' # abcdef

			matches = @input.scan(Regexp.new(types.join('|')))

			hash = []
			matches.each_with_index { |pair, index|
				literal = Regexp.new('^' + types[0] + '$')
				if !pair.match(literal) # is the whole thing a string literal?
					split = []
					eq = pair.index(/(?<!\\)=|(?<=\\\\)=/)
					if eq != nil
						# Set a variable
						key = pair[0, eq]
						val = pair[eq+1..-1]
						split.push(key)
						if val.match(literal)
							split.push(val.gsub(/^['"]|['"]$/, ''))
						else
							# key=val - render variable value if this is a variable
							split.push(expect(@context[val], NilClass, val))
						end
						hash.push(split)
					else
						# Parameter switch as boolean
						hash.push([pair.gsub(/^['"]|['"]$/, ''), true])
					end
				else
					# String lieral as value
					hash.push([index, pair.gsub(/^['"]|['"]$/, '')])
				end
			}
			@input = hash.to_h
		end

	end
end
