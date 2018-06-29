module Jekyll
	class ImgTag < CustomTag

		def output(_args)
			parse_input

			img = HTML::element('img')
			img['alt'] = ''

			if @args['image']
				images = @data['images']
				id = @args['image']
				if expect(expect_key(images, [id, 'src']), String) { |e| img['src'] = e }
					# While we're here...
					img['alt'] = expect(expect_key(images, [id, 'alt']), String, '')
					['width', 'height'].each { |d|
						expect(expect_key(images, [id, d[0]]), Integer) { |e| img[d] = e.to_s }
					}
				else
					raise "Image with id '#{id}' was not found in site.data.images."
				end
			elsif @args['src']
				img['src'] = @args['src']
			end
			if img['src'] == ''
				raise 'Cannot create image tag without an image id or src.'
			end

			if @args['format']
				fmt = @args['format']
				if formats = expect_key(@config, ['images'])
					if fmt = expect_key(formats, fmt)

						['width', 'height'].each { |d|
							expect(expect_key(fmt, d[0]), Integer) { |e| img[d] = e.to_s }
						}

						fmt = fmt.map{ |k, v|
							URLs.query_encode(k.to_s) + '=' + \
							URLs.query_encode(v.to_s)
						}.join('&')

						img['src'] += '?' + fmt if fmt != ''

					end
				end
			end

			img['alt'] = @args['alt'].to_s if @args['alt']
			img['width'] = @args['w'].to_s if expect(@args['w'], Integer)
			img['height'] = @args['h'].to_s if expect(@args['h'], Integer)

			@args.each{ |k, v|
				unless ['src', 'image', 'format', 'alt', 'w', 'h', 'url'].include?(k)
					img[k] = v
				end
			}

			# Deprecated attributes for ancient compatibility
			img['vspace'] = 0
			img['hspace'] = 0
			img['border'] = 0

			if !@args['url']
				return img.to_html
			else
				return img['src']
			end
		end

	end
end

Liquid::Template.register_tag('img', Jekyll::ImgTag)
