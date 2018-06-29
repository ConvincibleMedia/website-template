module Jekyll
	class VideoBlock < CustomBlock
		def output(_args, _block)

			return @block

		end
	end
end

Liquid::Template.register_tag('video', Jekyll::VideoBlock)

=begin
{%- assign format = site.data.videos[include.on][include.format] -%}
{%- assign method = site.data.videos.method | default: 'reactive' -%}
{%- capture w -%}
	{%- if include.w != nil -%}
		{{ include.w }}
	{%- elsif format.w != nil -%}
		{{ format.w }}
	{%- else -%}
		640
	{%- endif -%}
{%- endcapture -%}
{%- capture h -%}
	{%- if include.h != nil -%}
		{{ include.h }}
	{%- elsif format.h != nil -%}
		{{ format.h }}
	{%- else -%}
		360
	{%- endif -%}
{%- endcapture -%}
{%- assign id = include.id | split: '/' | last -%}
{%- capture params -%}
	{%- if format != nil -%}
		{%- case method -%}
			{%- when 'iframe' -%}
				?
				{%- for param in format -%}
					{%- assign param-name = param | first | url_param_escape -%}
					{%- assign param-value = param | last | url_param_escape -%}
					{{ param-name }}={{ param-value }}
					{%- if forloop.last == false -%}&amp;{%- endif -%}
				{%- endfor -%}
			{%- when 'reactive' -%}
				{%- for param in format -%}
					{%- assign param-name = param | first | url_param_escape -%}
					{%- assign param-value = param | last | url_param_escape -%}
					data-{{ param-name }}="{{ param-value }}"|
				{%- endfor -%}
		{%- endcase -%}
	{%- endif -%}
{%- endcapture -%}
{%- capture src -%}
	https://www.youtube.com/embed/{{ id }}
	{%- if method == 'iframe' -%}{{ params }}{%- endif -%}
{%- endcapture -%}
{%- capture thumb -%}
	https://i.ytimg.com/vi/{{ id }}/hqdefault.jpg
{%- endcapture -%}
{%- if include.src_only -%}
	{{ src }}
{%- else -%}
	<div class="video">
		{% if include.on == 'youtube' %}
			<div class="no-js-hide">
				{% case method %}
					{% when 'reactive' %}
						<div class="player"
							data-id="{{ id }}"{% if params %} {{ params | split: '|' | join: ' ' }}{%- endif -%}>
							<a href="https://www.youtube.com/watch?v={{ id }}" class="video-thumb" style="background-image: url('{% include helpers/img.html src=thumb src_only=true format='thumb' %}')" target="_new">
								<span class="play"><span class="hide">Play Video </span>&#9654;</span>
							</a>
						</div>
					{% when 'iframe' %}
						<iframe
							width="{{ w }}"
							height="{{ h }}"
							src="{{ src }}"
							frameborder="0"
							allowfullscreen="allowfullscreen"></iframe>
				{% endcase %}
			</div>
		{% endif %}
	</div>
{%- endif -%}
=end
