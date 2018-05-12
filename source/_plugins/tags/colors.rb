module Jekyll
	class ColorsTag < Liquid::Tag

		def initialize(tag_name, input, options)
			super
			@tag_name = tag_name
			@input = input
			@options = options
		end

		def render(context)

			@scss = []
			colors = []
			if expect(key?(context.registers[:site].config, ['brand','colors']), Array) { |e| colors = e }

				def scss_var(name, value)
					return '$' + name + ': ' + value + ';'
				end

				def hex_color(str)
					if (str.is_a?(String) && str.length > 0)
						if str[0] == '#' then str = str[1..-1] end
						if str.length == 3 then str = str[0] + str[0] + str[1] + str[1] + str[2] + str[2] end
						if str.length == 6
							r = str[0..1]
							g = str[2..3]
							b = str[4..5]
							if /[0-9a-f]/.match(r) && /[0-9a-f]/.match(g) && /[0-9a-f]/.match(b)
								return {'r' => r, 'g' => g, 'b' => b}
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
					color.each{ |k,hex| color[k] = hex.to_i(16).to_f / 255 }
					gamma = 2.224 # Convert sRGB back to linear light intensity
					# Calculate perceived light intensity of color components (factors are based on linear intensity)
					return (0.2126 * ( color['r'] ** gamma )) \
					     + (0.7152 * ( color['g'] ** gamma )) \
						  + (0.0722 * ( color['b'] ** gamma ))
				end

				def shade(color, adj)
					if color = hex_color(color)
						color.each{ |k,hex| color[k] = hex.to_i(16).to_f / 255 }
						gamma = 2.224 # Convert sRGB back to linear light intensity
						# Adjust linearly by amount proportional to perceived brightness of that colour channel, to reduce luminance overall by adj
						color['r'] = between(( color['r'] ** gamma ) + (adj * 0.2126), 0, 1)
					   color['g'] = between(( color['g'] ** gamma ) + (adj * 0.7152), 0, 1)
						color['b'] = between(( color['b'] ** gamma ) + (adj * 0.0722), 0, 1)

						color['r'] = between(color['r'] ** (1 / gamma), 0, 1)
						color['g'] = between(color['g'] ** (1 / gamma), 0, 1)
						color['b'] = between(color['b'] ** (1 / gamma), 0, 1)
						color.each{ |k,dec| color[k] = (dec * 255).to_i.to_s(16) }
						color.each{ |k,hex| color[k] = color[k] = hex.length < 2 ? "0" + hex : hex }
						color = '#' + color['r'] + color['g'] + color['b']
						return color
					else
  						raise 'Non hexadecimal defined color passed to shade().'
					end
				end

				@variants = {
					'dark' => -0.25,
					'light' => 0.25
				}

				def drop_colors(colors, suff, look_for_variants, comment = '')
					colors.each_with_index { |color, index|
						# color = a color object
						color_val = ''
						if expect(present?(key?(color, ['color'])), String) { |e| color_val = e}
							# Color properly defined

							unless suff == 'bg'
								suffix = suff + (index + 1).to_s
							else
								suffix = suff
							end

							@scss << scss_var('color-' + suffix, color_val[0] == '#' ? color_val : '#' + color_val) + comment
							# Now we'll check for other aspects of the definition
							# Text color
							if expect(present?(key?(color, ['text'])), String) { |e|
								@scss << scss_var('color-' + suffix + '-text', e[0] == '#' ? e : '#' + e) + comment
							}
							else
								@scss << scss_var('color-' + suffix + '-text', text(color['color'])) + " // Generated" + comment
							end

							if look_for_variants
								@variants.each { |var, adj|
									if expect(key?(color, [var]), Array) { |e|
										drop_colors(e, suffix + '-' + var + '-', false)
									}
									else
										puts 'Creating ' + var + ' variant.'
										drop_colors([{'color' => shade(color['color'], adj)}], suffix + '-' + var + '-', false, ' // Generated')
									end
								}
							end

						end
					}
				end

				drop_colors(colors[0...-1], '', true)
				drop_colors([colors[-1]], 'bg', true)

			else
				raise 'No { brand: { colors: [ { ... }, { ... } ] } } object found in _config.yml'
			end

			puts @scss.join("\n")
			return @scss.join("\n")

		end

	end
end

Liquid::Template.register_tag('colors', Jekyll::ColorsTag)
