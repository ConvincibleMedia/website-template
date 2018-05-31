module Jekyll
	class LinkTag < Liquid::Tag

		def initialize(tag_name, input, options)
			super
			@tag_name = tag_name
			@input = input
			@options = options
		end

		def render(context)
			@site = context.registers[:site]
			@config = @site.config

			return @tag_name
		end

	end
end

Liquid::Template.register_tag('link', Jekyll::LinkTag)

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
