=begin
module Kramdown_Sanitized

  def self.convert(markdown, options={})
    Kramdown::Document.new(markdown.to_s, options.merge(input: "GFM")).to_slack
  end

end
=end

module Kramdown
	module Converter
		class Wipedown < Kramdown #Base
			# Overrides https://github.com/gettalong/kramdown/blob/master/lib/kramdown/converter/kramdown.rb
			def convert_a(el, opts)
				if el.attr['href'].empty?
					"[#{inner(el, opts)}]()"
				#elsif el.attr['href'] =~ /^(?:http|ftp)/ || el.attr['href'].count("()") > 0
				elsif el.attr['href'].count("()") > 0
					# It's an ~~absolute URI~~ or a reference link
					if link_el = @linkrefs.find {|c| c.attr['href'] == el.attr['href']}
						index = @linkrefs.index(link_el) + 1
					else
						@linkrefs << el
						index = @linkrefs.size
					end
					"[#{inner(el, opts)}][#{index}]"
				else
					# It's any other kind of link
					title = parse_title(el.attr['title'])
					href = el.attr['href']
					"[#{inner(el, opts)}](#{href}#{title})"
				end
			end

			#ESCAPED_CHAR_RE = /(\$\$|[\\*_`\[\]\{"'|])|^[ ]{0,3}(:)/

			class << self
				def escape_alt(alt)
					return alt.to_s.gsub(self::ESCAPED_CHAR_RE) { $1 ? "\\#{$1}" : $2 }
				end
			end

			def convert_img(el, opts)
				alt_text = 'test' + self.class.escape_alt(el.attr['alt'])
				src = el.attr['src'].to_s
				if src.empty?
					"![#{alt_text}]()"
				else
					title = parse_title(el.attr['title']) # Read ALT here!
					if src.count("()") > 0
						link = "<#{src}>"
					else
						src = URLs.parse(src)
						if src.absolute?
							if src.normalized_site == CMS.site[:assets_url]
								link = src.omit(:scheme)
							else
								if src.scheme =~ /(?:http|https)/
									link = src.omit(:scheme)
								else
									link = src
								end
							end
						else
							link = URLs.join(CMS.site[:assets_url], src)
						end
					end
					"![#{alt_text}](#{link}#{title})"
				end
			end

			def convert_entity(el, opts)
				case el.value.name
					when 'nbsp'
						return ' '
					else
		      		return entity_to_str(el.value, el.options[:original])
				end
	      end

			# NO CUSTOM FUNNY HTML
			def convert_html_element(el, opts)
				innerHTML = inner(el, opts).lstrip.sub(/(?:\h*[\r|\n]+\h*)+$/, "\n")
				if innerHTML.strip.length == 0
					return ''
				else
					return innerHTML
				end
			end

			# DISABLE ALL IAL
			def ial_for_element(el)
				return nil
			end

		end
	end
end

def md_html(html)
	html = html.to_s.strip
	if html.length > 0
		html = Kramdown::Document.new(html, CONFIG['kramdown'].merge({
			html_to_native: true,
			line_width: -1,
			remove_block_html_tags: true,
			remove_span_html_tags: true
		}))

		#html = md_hijack(html)

		#html = html.to_kramdown
		html = html.to_wipedown

		return html.split(/(\r\n|\r|\n){2,}/).map{ |line| line.strip }.reject(&:blank?).join("\n\n")
	else
		return ''
	end
end

=begin
MD_IMG = "![]()"
def md_hijack(md)
	puts "--"
	md_traverse(md.root) { |element|
		case element.type
		when :img
			element = Kramdown::Element.new(element.type, nil, {src: 'bongo', alt: element.attr(:alt)})
		end
	}
	puts "--"

	return md
end

def md_traverse(element, ancestors = [], &block)
	type = element.type.to_s
	unless ['text', 'entity'].include?(type)
		#pp (ancestors + [type]).join(' > ')
		yield(element)
		descendants = element.children
		if descendants.present?
			descendants.each { |child|
				md_traverse(child, ancestors + [type], &block)
			}
		end
	end
end
=end

def liquid_tag(tag, args = [], contents = nil)
	args = args.join(' ') unless args.is_a? String
	if args.length > 0 then args = ' ' + args end
	if contents.nil?
		return "{% #{tag}#{args} %}"
	else
		return "<!--{% #{tag}#{args} %}-->\n#{contents}\n<!--{% end#{tag} %}-->"
	end
end

def md_link(text = '', href = '') # ADD TITLE
	return "[#{text}](#{href})"
end

def md_img(alt = '', src = '')
	return '!' + md_link(Kramdown::Converter::Wipedown.escape_alt(alt), src)
end

def md_h(h, level = 1)
	return ('#' * between(level, 1, 6)) + ' ' + h.to_s
end

def md_p(p)
	if p.is_a? Array
		p = p.flatten.map{ |line| line.to_s.strip }.reject(&:blank?).join("\n\n")
	end

	if p.is_a? String
		return p.strip
	else
		return ''
	end
end

def md_list(list, type = 'ul', start = 1, level = 1)
	bump = max((start - 1), 0)
	space = " " * ((level - 1) * 3)
	if list.is_a? Array #sanity check

		list = list.each_with_index{|li, i|
			if li.is_a? Array
				list[index] = markdown_list(li, type, 1, level + 1)
			elsif li.is_a? String
				if type == 'ol'
					list[index] = space + (i + bump).to_s + '. ' + li
				else
					list[index] = space + '*  ' + li
				end
			end
		}

		return list.flatten.join("\n")
	end
end


def md_ul(list)
	return markdown_list(list, 'ul')
end

def md_ol(list, start = 1)
	return markdown_list(list, 'ol', start)
end
