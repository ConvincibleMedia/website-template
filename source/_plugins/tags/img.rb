module Jekyll
	class ImgTag < CustomTag

		def output
			parse_input

			image = {
				src: '',
				w: '', h: '',
				alt: ''
			}

			if @input['image']
				images = @data['images']
				id = @input['image']
				if expect(key?(images, [id, 'src']), String) { |e| image[:src] = e }
					# While we're here...
					image[:alt] = expect(key?(images, [id, 'alt']), String, '')
					['w', 'h'].each { |d|
						image[d.to_sym] = expect(key?(images, [id, d]), Integer, '').to_s
					}
				else
					raise "Image with id '#{id}' was not found in site.data.images."
				end
			elsif @input['src']
				image[:src] = @input['src']
			end
			if image[:src] == ''
				raise 'Cannot create image tag without an image id or src.'
			end

			if @input['format']
				fmt = @input['format']
				if formats = key?(@config, ['images'])
					if fmt = key?(formats, fmt)

						['w', 'h'].each { |d|
							if expect(key?(fmt, d), Integer) then image[d.to_sym] = fmt[d].to_s end
						}

						fmt = fmt.map{ |k, v|
							URI.query_encode(k.to_s) + '=' + \
							URI.query_encode(v.to_s)
						}.join('&')

						image[:src] += '?' + fmt if fmt != ''

					end
				end
			end

			image[:alt] = @input['alt'] if @input['alt']
			image[:w] = @input['w'] if @input['w']
			image[:h] = @input['h'] if @input['h']

			additional = []
			@input.each{ |k, v|
				unless ['src', 'image', 'format', 'alt', 'w', 'h', 'url'].include?(k)
					additional << k + '="' + URI.attr_encode(v) + '"'
				end
			}
			additional = additional.join(' ')

			if !@input['url']
				return '<img src="' + URI.attr_encode(image[:src]) + '" ' \
			             + 'width="' + URI.attr_encode(image[:w]) + '" ' \
				          + 'height="' + URI.attr_encode(image[:h]) + '" ' \
				          + 'alt="' + URI.attr_encode(image[:alt]) + '" ' \
				          + additional + ' ' \
				          + 'vspace="0" hspace="0" border="0" />' # Deprecated attributes for ancient compatibility
			else
				return image[:src]
			end
		end

	end
end

Liquid::Template.register_tag('img', Jekyll::ImgTag)
