module Jekyll
	class LinkBlock < CustomBlock
		def output

			a = HTML::element('a')
			a.inner_html = @block

			if present?(@input)
				site_uri = Addressable::URI::parse(@config['url'])
				input_uri = Addressable::URI::parse(@input)
				type = ''

				if @input[0] == '@'
					# ID LINK
					type = 'internal id'
					input_id, input_frag = @input.split(/[@#]/).reject(&:empty?)
					input_id = input_id.to_i

					if key?(@data, ['sitemap', 'pages', input_id, 'link'])

						if key?(@data, ['sitemap', 'pages', input_id, 'title'])
							a['title'] = @data['sitemap']['pages'][input_id]['title']
						end
						@input = @data['sitemap']['pages'][input_id]['link'] + (input_frag ? '#' + input_frag.to_s : '')

					else
						#raise "Link specified as #{@input} but no such id found."
					end

				elsif @input[0] == '.'
					# Relative path
					page_uri = @context['page']['url'].chomp('index')
					type = 'internal relative to page'
					@input = (site_uri + page_uri + input_uri).route_from(site_uri.site).to_s
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
							@input = input_uri.route_from(site_uri.site).to_s
							type = 'internal absolute'
						end

					else
						# RELATIVE LINK
						@input = (site_uri + input_uri).route_from(site_uri.site).to_s
						type = 'internal relative to root'
					end

				end

				@input = '/' if @input == '#'
				#puts input_uri.to_s + ' is ' + type + ' = ' + @input

				a['href'] = @input
			end

			# Debug
			#a.inner_html = type + ': ' + @input

			return a.to_html

		end
	end
end

Liquid::Template.register_tag('link', Jekyll::LinkBlock)
