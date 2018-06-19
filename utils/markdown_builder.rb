def md_html(html)
	html = html.to_s.strip
	if html.length > 0
		Kramdown::Document.new(html, {
			html_to_native: true,
			line_width: -1
		}.merge(CONFIG['kramdown'])).to_kramdown.split(/(\r\n|\r|\n){2,}/).map{ |line| line.strip }.reject(&:blank?).join("\n\n")
	else
		return ''
	end
end

def liquid_tag(tag, args = [], contents = nil)
	args = args.join(' ') unless args.is_a? String
	if args.length > 0 then args = ' ' + args end
	if contents.nil?
		return "{% #{tag}#{args} %}"
	else
		return "<!--{% #{tag}#{args} %}-->\n#{contents}\n<!--{% end#{tag} %}-->"
	end
end

def md_link(text = '', href = '')
	return "[#{text}](#{href})"
end

def md_img(alt = '', src = '')
	return '!' + md_link(alt, src)
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
