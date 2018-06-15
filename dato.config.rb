require './utils/helpers.rb'

CONFIG = YAML.load_file('./_config.yml')
SOURCE = CONFIG['source']

PARTIAL_SEPARATOR = '#'

LANGS = dato.site.locales # ['en', 'fr', etc.]

field_types = {
	text: String, #also slug
	file: {
		url: String,
		size: Integer,
		format: String,
		width: Integer,
		height: Integer,
		alt: String,
		title: String
	},
	color: {
		red: Integer,
		green: Integer,
		blue: Integer,
		alpha: Float,
		rgb: String, # => "rgb(255, 127, 0)"
		hex: String # => "#ff7f00"
	},
	geo: {
		latitude: Float,
		longitude: Float
	},
	video: {
		title: String,
		url: String,
		thumbnail_url: String,
		provider: String,
		provider_uid: String,
		height: Integer,
		width: Integer
	},
	seo: {
		title: String,
		description: String,
		image: {}#Image
	},
	date: String, #"2018-06-15T16:05:00+01:00"
	number: Numeric, # Could be integer or float
	boolean: Boolean,
	json: String,
	link: [String],
	modular: [Object]
}

models = {
	'home' => {
		#title: 'Home',
		type: 'single', # single, multiple, tree
		fields: {
			'intro' => {
				type: 'text', #text, modular, etc.
				localized: false
			},
			'video' => {
				type: 'video', #text, modular, etc.
				localized: false
			},
			'seo' => {
				type: 'seo', #text, modular, etc.
				localized: false
			}
		},
		versioning: false
	},
	'page' => {
		type: 'tree',
		fields: {},
		versioning: false
	},
	'product' => {
		type: 'multiple',
		fields: {},
		versioning: false
	},
	'article' => {
		type: 'tree',
		fields: {},
		versioning: false
	},
	'social_profile' => {
		type: 'multiple',
		fields: {},
		versioning: false
	}
}


# DEFAULT -- OVERRIDABLE
correlations = {
	'home' => {
		meta: {
			id: 'id'
		},
		frontmatter: {
			id: 'id', # Core field - first item
	 		# Read by Jekyll - must be top level
			layout: nil,
			title: 'title',
			published: true,
			#categories: [],
			#tags: [],
			date: nil,
			#permalink: ,
			#excerpt: ,
			# Most important data points
			slug: 'address',
			# Metadata about this piece of content
			meta: {
				parents: nil,
				hidden: false
			},
			# How to display this piece of content
			view: {
				features: []
			},
			# HTML meta and OG/social card overrides
			seo: {
				title: nil,
				description: nil,
				image: nil
			},
			# Data that contributes to the content of this piece of content
			data: {
				image: nil
			}
		},
		content: [
			markdown_block(body),
			markdown_h(features_heading),
			field_modular(features) { |block|
				[
					markdown_h(block['title'], 4),
					markdown_p(block['author']),
					markdown_p(html_tag('cite', block['source']))
				]
			}
		].flatten.join("\n\n"),
		partials: {
			'form.html' => item.form_html,
			'calculator.js' => item.calculator_js
		}
	}
}


def create_files_yaml(files, root)
	files.sort.each { |pair|
		path = root + pair[0]
		id_list = pair[1]
		directory(path) {
			id_list.each { |id|
				item = {id}
				create_data_file(id + '.yml', :yaml, item)
			}
		}
	}
end

def create_files_md(files, root)
	files.sort.each { |pair|
		path = root + pair[0]
		id_list = pair[1]
		directory(path) {
			id_list.each { |id|
				item = {id}
				# Create this item at this location
				create_post(item[:meta][:slug] + '.md') {
					frontmatter(:yaml,
						item[:frontmatter]
					)
					content(item[:content])
				}
				# Create partials for this item alongside it
				item.partials.each { |name, partial|
					create_post(item[:meta][:slug] + PARTIAL_SEPARATOR + name.reverse.sub('.', '.partial.').reverse) {
						content(partial)
					}
				}
			}
		}
	}
end




def liquid_block(block, contents)

end


def markdown_h(h, level = 1)
	return ('#' * between(level, 1, 6)) + ' ' + h.to_s
end

def markdown_p(p)
	if p.is_a Array
		p = p.flatten.join("\n\n")
	end

	if p.is_a String
		return p
	else
		return ''
	end
end

def markdown_list(list, type = 'ul', start = 1, level = 1)
	bump = max((start - 1), 0)
	space = " " * ((level - 1) * 3)
	if list.is_a Array #sanity check

		list = list.each_with_index{|li, i|
			if li.is_a Array
				list[index] = markdown_list(li, type, 1, level + 1)
			elsif li.is_a String
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


def markdown_ul(list)
	return markdown_list(list, 'ul')
end

def markdown_ol(list, start = 1)
	return markdown_list(list, 'ol', start)
end
