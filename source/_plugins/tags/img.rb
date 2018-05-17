module Jekyll
	class ImgTag < Liquid::Tag

		def initialize(tag_name, input, options)
			super
			@tag_name = tag_name
			@input = input
			@options = options
		end

		# {% img image=id format=thumb %}
		# {% img src=img.jpg alt=Image format=thumb %}
		# {% img src=img.jpg alt=Image w=auto h=auto tag=true %}
		def render(context)
			@site = context.registers[:site]
			@config = @site.config

			@input = Liquid::Template.parse(@input).render(context)

			return @input
		end

	end
end

Liquid::Template.register_tag('img', Jekyll::ImgTag)

=begin
{%- capture w -%}
	{%- if include.w != nil -%}
		{{ include.w }}
	{%- elsif include.format.w != nil and include.format.crop != nil -%}
		{{ include.format.w }}
	{%- endif -%}
{%- endcapture -%}
{%- capture h -%}
	{%- if include.h != nil -%}
		{{ include.h }}
	{%- elsif include.format.h != nil and include.format.crop != nil -%}
		{{ include.format.h }}
	{%- endif -%}
{%- endcapture -%}
{%- capture src -%}
	{%- if include.src -%}
		{{ include.src }}
	{%- elsif include.image.url -%}
		{{ include.image.url }}
	{%- else -%}
		{%- comment -%}/assets/images/load.svg{%- endcomment -%}
	{%- endif -%}
{%- endcapture -%}
{%- assign src = src | strip -%}
{%- assign format = site.data.images[include.format] -%}
{%- if include.format != nil and format.size > 0 and src.size > 0 -%}
	{%- capture src -%}
		{{ src }}?
		{%- for param in format -%}
			{%- assign param-name = param | first | url_param_escape -%}
			{%- assign param-value = param | last | url_param_escape | replace: ',','%2C' -%}
			{%- comment -%}
				{%- if param-name == 'w' and w != 'auto' -%}{%- assign param-value = w -%}{%- endif -%}
				{%- if param-name == 'h' and h != 'auto' -%}{%- assign param-value = h -%}{%- endif -%}
			{%- endcomment -%}
			{{ param-name }}={{ param-value }}
			{%- if forloop.last == false -%}&amp;{%- endif -%}
		{%- endfor -%}
	{%- endcapture -%}
{%- endif -%}
{%- capture alt -%}
	{%- if include.alt -%}
		{{ include.alt }}
	{%- elsif include.image.alt -%}
		{{ include.image.alt }}
	{%- elsif include.image.title -%}
		{{ include.image.title }}
	{%- endif -%}
{%- endcapture -%}
{%- if include.src_only -%}
	{{ src }}
{%- elsif src.size > 0 -%}
	<img src="{{ src }}" alt="{{ alt | xml_escape }}"
		{%- if include.title != nil %} title="{{ include.title | xml_escape }}"{%- endif -%}
		{%- if w.size > 0 %} width="{{ w }}"{%- endif -%}
		{%- if h.size > 0 %} height="{{ h }}"{%- endif %} border="0" vspace="0" hspace="0" />
{%- endif -%}
=end
