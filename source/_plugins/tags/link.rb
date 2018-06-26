module Jekyll
	class LinkBlock < CustomBlock

		def input
			{
				required: {
					1 => String
				},
				optional: {
					'lang' => String
				}
			}
		end

		def output(args, block)

			a = HTML::element('a')
			a.inner_html = block
			url = args[1]
			lang = args['lang'] if args['lang']

			type = ''

			if url[0] == '@'
				# ID LINK
				type = 'internal id'
				input_id, input_frag = url.split(/[@#]/).reject(&:empty?)
				input_id = input_id.to_i

				if id = expect_key(@data, ['sitemap', input_id])

					item = id[lang] || id[id.keys[0]]

					a['title'] = expect_key(item, 'title')
					url = '/' + path(lang || @page['lang'], expect_key(item, 'link')) + (input_frag ? '#' + input_frag.to_s : '')

				else
					#raise "Link specified as #{url} but no such id found."
				end

			else

				site_uri = Addressable::URI::parse(@config['url'])
				input_uri = Addressable::URI::parse(url)

				if url[0] == '.'

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
			if lang
				a['lang'] = lang
				a['rel'] = 'alternate'
				a['hreflang'] = lang
			end

			# Debug
			#a.inner_html = type + ': ' + url

			return a.to_html

		end
	end
end

Liquid::Template.register_tag('link', Jekyll::LinkBlock)
