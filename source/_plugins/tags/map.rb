module Jekyll
	class MapTag < Liquid::Tag

		def initialize(tag_name, input, options)
			super
			@tag_name = tag_name
			@input = input
			@options = options
		end

		def render(context)
			@site = context.registers[:site]
			@config = @site.config
			
		end

	end
end

Liquid::Template.register_tag('map', Jekyll::MapTag)

=begin
{% assign key = '' %}
{% assign format = site.data.images[include.format] %}
{%- capture params -%}
   zoom=14
   scale=2
   format=jpg
   maptype=roadmap
   size={{ include.w }}x{{ include.h }}
   center={{ include.y }},{{ include.x }}
{%- endcapture -%}
{%- assign params = params | newline_to_br | strip_newlines | split: '<br />' -%}
{%- for param in params %-}
   {%- assign param = param | trim -%}
   {%- capture params_all -%}
      {{ params_all }}&amp;{{ param | strip }}
   {%- endcapture -%}
{%- endfor -%}
{%- capture src -%}
   https://maps.googleapis.com/maps/api/staticmap?key={{ key }}{{ params_all }}
{%- endcapture -%}
<a target="_new" href="https://www.google.com/maps/{% if include.place %}place/{{ include.place | url_encode }}/{% endif %}@{{ include.y }},{{ include.x }},14z">
   {% include helpers/img.html
      src=src
      alt='Map'
      w=include.w
      h=include.h
   %}
</a>
=end
