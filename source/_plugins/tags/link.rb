module Jekyll
	class LinkBlock < CustomBlock

		BLOCK_TEXT = /[^\]]*/
		BLOCK_URL = /[^)]+/

		def input
			{
				block: %r<
					\[
						(?<text>  (?: [^\]] | \\\] )*? )
					\] \s?
					\(
						(?<href>  (?: [^\)] | \\\) )+? )
						(?:
							\s+
								" (?<title> (?: [^"] | \\" )+? ) "
							\s*
						)?
					\)
				>x,
				required: {
					'href' => String,
				},
				optional: {
					'text' => String,
					'lang' => String
				},
			}
		end

		def output(_args, _block)

			# @config['I18n']['missing']['force']
			# @config['I18n']['missing']['repeat']
			# @config['I18n']['missing']['links']

			# @page['meta']['lang']
			# @data['langs'] = ["en", ...]

			destination = _args['href']
			text = _args['text'].gsub(/\\(.)/, '\1') || ''
			title = _args['title'] || ''
			lang = _args['lang'] || @lang # Language for links = explicit, or current

			a = HTML::element('a')

			if lang && @data['langs'].include?(lang) # Sanity check
				if destination[0] == '@'
					# ID LINK

					input_id, input_frag = destination.split(/[@#]/).reject(&:empty?)
					input_id = input_id.to_i

					if id = expect_key(@data, ['sitemap', input_id])

						# Behaviour if language is missing
						# links: force: true
						if !id[lang] && @config['I18n']['missing']['links']
							# Transparently link to the first available language for this ID
							lang = id.keys[0]
						end

						if lang && id[lang]
							item = id[lang]
							if href = expect_key(item, 'link')

								href = '/' +	path(lang, href) + (input_frag ? '#' + input_frag.to_s : '')

								a['title'] = expect_key(item, 'title', '')

							end
						end

					end

				else

					site_uri = Addressable::URI::parse(@config['url']).normalize
					given_uri = Addressable::URI::parse(destination).normalize

					if destination[0] == '.'
						# EXPLICITLY RELATIVE PATH

						page_uri = Addressable::URI::parse(@context['page']['url'].chomp('index')).normalize

						href = (page_uri + given_uri).to_s
						# Converted to absolute relative to site

					else

						if given_uri.scheme
							# ABSOLUTE LINK

							if given_uri.site != site_uri.site
								# EXTERNAL LINK

								href = given_uri.to_s

								a['target'] = '_blank'
								a['class'] = 'external'
								a['rel'] = 'external'

							else
								# INTERNAL BUT ABSOLUTE!

								href = given_uri.omit(:site).to_s
								# Converted to absolute relative to site

							end

						else
							# LINK RELATIVE TO SITE

							href = '/' + path(given_uri.to_s)

						end

					end

				end

				# If this links to a language other than the current page's
				if lang != @page['meta']['lang']
					a['rel'] = 'alternate'
					a['hreflang'] = lang
				end

			end

			if !href
				a['title'] = t('404', 'system')
				a['class'] = 'broken'
			else
				a['href'] = href
			end

			a.inner_html = text

			return a.to_html

		end
	end
end

Liquid::Template.register_tag('link', Jekyll::LinkBlock)
