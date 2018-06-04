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

=begin
{%- assign href = include.href -%}

{%- if href.first -%}
	{%- if href.id -%}
		{%- assign href = href.id -%}
	{%- else -%}
		{%- assign href = '' -%}
	{%- endif -%}
{%- endif -%}

{%- assign href = href | strip -%}
{%- assign type = 'local' -%}

{%- if href.size > 0 -%}
	{%- if href contains '://' -%}
		{%- comment -%}{%- assign protocol = href | split: '://' | first -%}{%- endcomment -%}

		{%- assign type = 'url' -%}

	{%- else -%}
		{%- assign first = href | slice: 0 -%}
		{%- case first -%}
			{%- when '#' -%}

				{%- assign type = 'anchor' -%}

			{%- when '@' -%}

				{%- assign type = 'id' -%}

			{%- else -%}

				{%- assign nums = href |
					remove: '0' |
					remove: '1' |
					remove: '2' |
					remove: '3' |
					remove: '4' |
					remove: '5' |
					remove: '6' |
					remove: '7' |
					remove: '8' |
					remove: '9'
				%}
				{%- assign nums = nums.size -%}
				{%- if nums == 0 -%}

					{%- assign type = 'id' -%}

				{%- endif -%}
		{%- endcase -%}
	{%- endif -%}
{%- endif -%}

{%- capture url -%}
	{%- case type -%}
		{%- when 'id' -%}
			{%- if site.data.sitemap.pages[href] -%}
				{{ site.data.sitemap.pages[href].loc }}
			{%- endif -%}
		{%- else -%}
			{{ href }}
	{%- endcase -%}
{%- endcapture -%}

{%- capture text -%}
	{{ include.text | newline_to_br | split: '<br />' | join: ' ' | strip_newlines | strip | markdownify | strip | remove: '<p>' | remove: '</p>' }}
{%- endcapture -%}

{%- unless include.href_only -%}
	{%- if url.size > 0 -%}
		<a {% if include.target %}target="{{ include.target }}"{% endif %} {% if include.class %}class="{{ include.class }}"{% endif %} href="{{ url }}">{{ text }}</a>
	{%- elsif include.fail == 'dead' -%}
		<a title="This page is not available at present.">{{ text }}</a>
	{%- elsif include.fail == 'empty' -%}
	{%- else -%}
		{{ text }}
	{%- endif -%}
{%- else -%}
	{{ url }}
{%- endunless -%}

=end
