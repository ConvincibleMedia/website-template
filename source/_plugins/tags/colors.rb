module Jekyll
	class ColorsTag < Liquid::Tag

		def initialize(tag_name, input, options)
			super
			@tag_name = tag_name
			@input = input
			@options = options
		end

		def render(context)

			scss = []
			colors = []
			if expect(key?(context.registers[:site].config, ['brand','colors']), Array) { |e| colors = e }

				def scss_var(name, value)
					return '$' + name + ': ' + value + ';'
				end

				def hex_color(str)
					if str.length > 0
						if str[0] == '#' then str = str[1..-1] end
						if str.length == 3 then str = str[0] + str[0] + str[1] + str[1] + str[2] + str[2]
						if str.length == 6
							r = str[0..1]
							g = str[2..3]
							b = str[4..5]
							if /[0-9a-f]/.match?(r) && /[0-9a-f]/.match?(g) && /[0-9a-f]/.match?(b)
								return {:r: r, :g: g, :b: b}
							end
						end
					end
					return false
				end

				def text(color)
					if color = hex_color(color)
						if luminance(color) < 0.5
							return '#ffffff'
						else
							return '#000000'
						end
					else
						raise 'Non hexadecimal defined color passed to text().'
					end
				end

				def luminance(color)
					if color = hex_color(color)
						color.each{ |_,hex| hex.to_i(16) / 255 }
						gamma = 2.2
						return 0.2126 * ( color['r'] ** gamma ) \
						     + 0.7152 * ( color['g'] ** gamma ) \
							  + 0.0722 * ( color['b'] ** gamma )
					else
						raise 'Non hexadecimal defined color passed to luminance().'
					end
				end

				colors.each_with_index { |color, index|
					# color = a color object
					color_val = ''
					if expect(present?(key?(color, ['color'])), String) { |e| color_val = e}
						# Color properly defined
						scss << scss_var('color-' + index, color_val)
						# Now we'll check for other aspects of the definition
						# Text color
						if expect(present?(key?(color, ['text'])), String) { |e|
							scss << scss_var('color-' + index + '-text', e)
						}
						else
							scss << scss_var('color-' + index + '-text', text(color['color']))
						end
					end
				}
			else
				raise 'No { brand: { colors: [ { ... }, { ... } ] } } object found in _config.yml'
			end

			return scss.join("\n")

		end

	end
end

Liquid::Template.register_tag('colors', Jekyll::ColorsTag)
