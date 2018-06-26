module Jekyll
	class LinkBlock < CustomBlock
=begin
		def input
			parse_input({
				required: {
					0 => String
				},
				optional: {
					'lang' => String
				}
			})
		end
=end
		def output

			a = HTML::element('a')
			a.inner_html = @block
			url = @args[0]

			type = ''

			if url[0] == '@'
				# ID LINK
				type = 'internal id'
				input_id, input_frag = url.split(/[@#]/).reject(&:empty?)
				input_id = input_id.to_i

				if expect_key(@data, ['sitemap', 'pages', input_id, 'link'])

					if expect_key(@data, ['sitemap', 'pages', input_id, 'title'])
						a['title'] = @data['sitemap']['pages'][input_id]['title']
					end
					url = @data['sitemap']['pages'][input_id]['link'] + (input_frag ? '#' + input_frag.to_s : '')

				else
					#raise "Link specified as #{url} but no such id found."
				end

			else

				if url[0] == '.'

					site_uri = Addressable::URI::parse(@config['url'])
					input_uri = Addressable::URI::parse(url)

					# Relative path
					page_uri = @context['page']['url'].chomp('index')
					type = 'internal relative to page'
					url = (site_uri + page_uri + input_uri).route_from(site_uri.site).to_s

				else

					# HREF LINK
					if input_uri.scheme
						# ABSOLUTE LINK

						if input_uri.site != site_uri.site
							# EXTERNAL LINK
							a['target'] = '_blank'
							a['class'] = 'external'
							a['rel'] = 'external'
							type = 'external absolute'
						else
							# INTERNAL BUT ABSOLUTE!
							url = input_uri.route_from(site_uri.site).to_s
							type = 'internal absolute'
						end

					else
						# RELATIVE LINK
						url = (site_uri + input_uri).route_from(site_uri.site).to_s
						type = 'internal relative to root'
					end

				end

			end

			url = '/' if url == '#'
			#puts input_uri.to_s + ' is ' + type + ' = ' + url

			a['href'] = url

			# Debug
			#a.inner_html = type + ': ' + url

			return a.to_html

		end
	end
end

Liquid::Template.register_tag('link', Jekyll::LinkBlock)
