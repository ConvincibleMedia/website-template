module Jekyll
	class LinkBlock < CustomBlock

		# {% link @238794 %}click here{% endlink %}
		# {% link http://www.google.com %}click here{% endlink %} - external - _blank
		# {% link #section %}click here{% endlink %}
		# {% link @238974#section %}click here{% endlink %}
		# {% link /blog/post.html#section %}click here{% endlink %}
		# {% link mailto:virgil@gmail %}click here{% endlink %}
		def output

			root = Addressable::URI::parse(@config['url'])
			type = ''

			a = HTML::element('a')
			a.inner_html = @block

			if present?(@input)
				if @input[0] == '@'
					# ID LINK
					type = 'internal id'
				else
					uri = Addressable::URI::parse(@input)
					# HREF LINK

					if uri.scheme
						# ABSOLUTE LINK

						if uri.host != root.host
							# EXTERNAL LINK
							a['target'] = '_blank'
							type = 'external absolute'
						else
							# INTERNAL BUT ABSOLUTE!
							@input = uri.route_from(root.authority).to_s
							type = 'internal absolute'
						end

					else
						# RELATIVE LINK

						type = 'internal relative'
					end
				end

				a['href'] = @input
			end

			# Debug
			a.inner_html = type + ': ' + @input

			return a.to_html
			#return '<a href="' + link[:href] + '">' + @block + '</a>'

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
