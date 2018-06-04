module Jekyll
	class ImgTag < CustomTag

		def output
			parse_input

			img = HTML::element('img')
			img['alt'] = ''

			if @input['image']
				images = @data['images']
				id = @input['image']
				if expect(key?(images, [id, 'src']), String) { |e| img['src'] = e }
					# While we're here...
					img['alt'] = expect(key?(images, [id, 'alt']), String, '')
					['width', 'height'].each { |d|
						expect(key?(images, [id, d[0]]), Integer) { |e| img[d] = e.to_s }
					}
				else
					raise "Image with id '#{id}' was not found in site.data.images."
				end
			elsif @input['src']
				img['src'] = @input['src']
			end
			if img['src'] == ''
				raise 'Cannot create image tag without an image id or src.'
			end

			if @input['format']
				fmt = @input['format']
				if formats = key?(@config, ['images'])
					if fmt = key?(formats, fmt)

						['width', 'height'].each { |d|
							expect(key?(fmt, d[0]), Integer) { |e| img[d] = e.to_s }
						}

						fmt = fmt.map{ |k, v|
							URI.query_encode(k.to_s) + '=' + \
							URI.query_encode(v.to_s)
						}.join('&')

						img['src'] += '?' + fmt if fmt != ''

					end
				end
			end

			img['alt'] = @input['alt'].to_s if @input['alt']
			img['width'] = @input['w'].to_s if expect(@input['w'], Integer)
			img['height'] = @input['h'].to_s if expect(@input['h'], Integer)

			@input.each{ |k, v|
				unless ['src', 'image', 'format', 'alt', 'w', 'h', 'url'].include?(k)
					img[k] = v
				end
			}

			# Deprecated attributes for ancient compatibility
			img['vspace'] = 0
			img['hspace'] = 0
			img['border'] = 0

			if !@input['url']
				return img.to_html
			else
				return img['src']
			end
		end

	end
end

Liquid::Template.register_tag('img', Jekyll::ImgTag)
