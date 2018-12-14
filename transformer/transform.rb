require '../utils/helpers.rb'
require 'dato'

CONFIG = YAML.load_file('./_config.yml')
SOURCE = CONFIG['source']

TIME_FORMAT = '%Y-%m-%d %H:%M:%S %z' #Internal representation
KEY_ID = 'id'
KEY_TITLE = 'title'
KEY_SLUG = 'slug'

require 'i18n'

I18n.load_path << Dir['./utils/i18n/*.yml']
I18n.default_locale = :en

require './cms/dato.rb'

module Spark

	class CMS < DatoCMS
		def initialize
			super
		end

	end

end

CMS = Spark::CMS.new


CMS.models[:blocks].each { |model_name, model_info|
	CMS.get_blocks(model_name)
}
CMS.models[:pages].each { |model_name, model_info|
	CMS.get_items(model_name)
}
CMS.get_files


require '../utils/markdown_builder.rb'

TRANSFORM = {}

def get_data(item, field, lang)
	if CMS.models[:pages][item[:meta][:model]][:fields][field][:localised]
		return item[:data][:field][lang] # Localised
	else
		return item[:data][:field] # Not localised
	end
end

#UNUSED
def get_parents(id)
	parents = []
	if this_parent = CMS.items[id][:meta][:parent]
		parents << this_parent
		parents << get_parents(this_parent)
	end
	return parents
end

def partial_slug(partial, slug)
	return slug + '_' + partial.sub('.', '.partial.')
end

# Defaults
TRANSFORM_BASE = lambda do |id, meta, data|
	{
		file: {
			path: path([t(:slug, [:models, meta[:model]], 2)])
		},
		frontmatter: {
			KEY_TITLE => data[KEY_TITLE],
			KEY_SLUG => data[KEY_SLUG],
			'published' => true,
			'date' => meta[:modified],
			# Metadata about this piece of content
			'meta' => {
				KEY_ID => id
			},
			'seo' => {
				'hidden' => meta[:hidden] == true
			},
		}
	}
end

TRANSFORM_UNDEFINED = lambda do |id, meta, data|
	dump = {
		frontmatter: {
			'data' => {}
		}
	}
	data.each { |field_name, field_data|
		dump[:frontmatter]['data'][field_name.to_s] = field_data unless [KEY_TITLE, KEY_SLUG].include?(field_name)
	}
	return dump
end

require './transforms/home.rb'
require './transforms/product.rb'
require './transforms/article.rb'
require './transforms/page.rb'
require './transforms/social.rb'

def blocks(block_array, filter = nil)
	if !block_array.is_a? Array
		block_array = []
	end

	if filter == nil
		filter = []
		# Get all expected types
	end

	if filter.is_a? String
		filter = [filter]
	elsif filter.is_a? Array
		filter.flatten!
	else
		raise "Invalid filter '#{filter.to_s}' to get blocks."
	end

	if filter.length == 1
		return block_array.select{|f| f.keys.any?{|k| filter.include?(k) } }.map{|i|
			i[filter[0]]
		}
	else
		return block_array.select{|f| f.keys.any?{|k| filter.include?(k) } }
	end
end


def transform(model, _id)
	id = _id.to_i
	item = CMS.items[model][id]
	meta = item[:meta]
	model_name = meta[:model]

	content = {}
	meta[:langs].each { |lang|
		data = item[:data][lang]
		I18n.locale = lang

		# Base transform
		content[lang] = TRANSFORM_BASE.call(id, meta, data)

		# Specific transform
		if TRANSFORM.key?(model)
			content[lang].deep_merge!(TRANSFORM[model].call(id, meta, data))
		else
			content[lang].deep_merge!(TRANSFORM_UNDEFINED.call(id, meta, data))
		end

		if content[lang][:frontmatter]
			# Language
			content[lang][:frontmatter]['meta'] ||= {}
			content[lang][:frontmatter]['meta']['lang'] = lang
			content[lang][:frontmatter]['meta']['langs'] = meta[:langs]
			content[lang][:frontmatter]['meta']['dir'] = 'ltr' #PLACEHOLDER

			# Universal tidying
			content[lang][:frontmatter][KEY_TITLE] = id.to_s if content[lang][:frontmatter][KEY_TITLE].blank?
			content[lang][:frontmatter][KEY_SLUG] = content[lang][:frontmatter][KEY_TITLE] if content[lang][:frontmatter][KEY_SLUG].blank?
			content[lang][:frontmatter][KEY_SLUG] = content[lang][:frontmatter][KEY_SLUG].parameterize
			content[lang][:frontmatter][KEY_SLUG] = id.to_s if content[lang][:frontmatter][KEY_SLUG].blank?
			content[lang][:file][:slug] = content[lang][:frontmatter][KEY_SLUG]
		end
	}

	return content
end





$datapaths = {}
$data = {}
def new_data(name, data, path = '/')
	id = $data.length
	$data[id] = {
		meta: {
			slug: name,
			path: path
		},
		data:	data
	}
	$datapaths[path] ||= []
	$datapaths[path] << id
end



$content = {}
$filepaths = {}
$sitemap = {}
CMS.locales.each { |lang|
	$filepaths[lang] = {}
}
$partials = {}
$partialpaths = {}



# TRANSFORM CONTENT
CMS.models[:pages].each { |model_name, model_info|
	#puts "Constructing content and paths for model #{model_name}..."
	CMS.get_items(model_name).each { |_id, item|
		#puts "Working on item id #{id}..."
		id = _id.to_i
		meta = item[:meta]

		transformed = transform(model_name, id)
		#transformed = [lang] = data structure

		meta[:langs].each { |lang|
			#puts "...in language: #{lang}"

			item_in_lang = transformed[lang]
			front = item_in_lang[:frontmatter] # If defined?

			if item_in_lang[:content] || item_in_lang[:frontmatter]
				# Page to be created from this item

				$content[id] ||= {}
				$content[id][:meta] ||= meta

				$content[id][:data] ||= {}
				$content[id][:data][lang] = item_in_lang

			end
			if item_in_lang[:data]
				# Data file to be added to from this item

				$data[meta[:model]] ||= {
						meta: {
							slug: meta[:model],
							path: '/'
						},
						data:	{}
					}
				$data[meta[:model]][:data][lang] ||= []
				$data[meta[:model]][:data][lang] << item_in_lang[:data]
				$datapaths['/'] ||= []
				$datapaths['/'] << meta[:model] unless $datapaths['/'].include?(meta[:model])

			end
			if item_in_lang[:partials] && !item_in_lang[:content] && !item_in_lang[:frontmatter]
				# Partial defined without content = not relative

				item_in_lang[:partials].each { |p_name, p_content|
					$partials[p_name] ||= {}
					$partials[p_name][lang] ||= {}
					if $partials[p_name][lang][:content]
						p_content = $partials[p_name][lang][:content] + "\n" + p_content.to_s
					end
					$partials[p_name][lang] = {
						filename: meta[:model] + '_' + p_name.sub('.', '.partial.'),
						content: p_content
					}
					$partialpaths[lang] ||= {}
					$partialpaths[lang][0] ||= []
					$partialpaths[lang][0] << p_name unless $partialpaths[lang][0].include?(p_name)
				}

			end

		}
	}
}


# PARENTS
$content.each { |id, meta_data|
	#puts "Reading parents of content id: #{id}, '#{langs['en'][:frontmatter]['slug']}', which has #{langs.size.to_s} langs."
	meta = meta_data[:meta]
	data = meta_data[:data]

	#puts meta_data

	data.each_with_index{ |(lang, item), index|
		#puts "...Lang \##{index + 1}: #{lang}"

		front = item[:frontmatter] # If defined?

		# Create an array of parents for each piece of content
		parents = []
		parent = meta[:parent].to_i if meta[:parent]

		while parent && $content[parent]
			#puts "Parent \##{(parents.size + 1).to_s} = #{parent.to_s}"
			parent_info = {id: parent}
			if slug = expect_key($content[parent], [:data,lang,:frontmatter,KEY_SLUG])
				# The identified parent exists in the same language
				parent_info[:slug] = slug
			else
				# The identified parent does not exist in the same language
				if CONFIG['I18n']['missing']['parents']
					# Jump to next available language
					first_lang = $content[parent][:data].keys[0]
					slug = $content[parent][:data][first_lang][:frontmatter][KEY_SLUG]
					parent_info[:slug] = slug
					parent_info[:lang] = first_lang
				else
					# Skip this parent in the item's parent tree
					parent_info = nil
				end
			end
			parents << parent_info if parent_info

			# Look for grandparent
			if parent = $content[parent][:meta][:parent]
				parent = parent.to_i
			else # No grandparents
				parent = nil
			end

			#puts "Next parent up is: #{parent.inspect}"
		end
		#puts "#{parents.size.to_s} parents identified for id #{id} in lang: #{lang}"

		$content[id][:data][lang][:frontmatter]['meta'] ||= {}
		$content[id][:data][lang][:frontmatter]['meta']['parents'] = parents.map{|i| i.stringify_keys }
		$content[id][:meta][:parents] = parents

		# Reconstruct this item's path with base that's already set
		$content[id][:data][lang][:file][:path] = path(
			$content[id][:data][lang][:file][:path],
			parents.map{ |branch|
				branch[:slug]
			}.reverse.join('/')
		)

		# Reconstruct this item's link based on new path
		$content[id][:data][lang][:file][:link] = path(
			$content[id][:data][lang][:file][:path],
			$content[id][:data][lang][:file][:slug]
		)
	}
}

#PARTIALS
$content.each { |id, meta_data|

	meta = meta_data[:meta]
	data = meta_data[:data]

	data.each{ |lang, item|

		front = item[:frontmatter] # If defined?

		if item[:partials] && item[:partials].length > 0
			# Relative partial

			item[:partials].each { |p_name, p_content|
				$partials[id.to_s + p_name] ||= {}
				$partials[id.to_s + p_name][lang] = {
					filename: partial_slug(p_name, front['slug']),
					content: p_content
				}
				$partialpaths[lang] ||= {}
				$partialpaths[lang][item[:file][:path]] ||= []
				$partialpaths[lang][item[:file][:path]] << id.to_s + p_name
			}

		end
	}
}

#SETUP VARS
$content.each { |id, meta_data|

	meta = meta_data[:meta]
	data = meta_data[:data]

	data.each{ |lang, item|

		front = item[:frontmatter] # If defined?

		# Setup other references to this content item
		$filepaths[lang][item[:file][:path]] ||= []
		$filepaths[lang][item[:file][:path]] << id
		$sitemap[id] ||= {}
		$sitemap[id][lang] = {
			'title' => front['title'],
			'path' => item[:file][:path],
	      'slug' => front['slug'],
	      'link' => item[:file][:link],
	      'loc' => URLs.join(CONFIG['url'], item[:file][:link]).omit(:scheme).to_s,
	      'lastmod' => meta[:modified],
	      'type' => meta[:model],
	      #'order': '3'
	      'hidden' => meta[:hidden]
		}

	}
}

#pp $content


$images = CMS.files.reject{|k,v| v[:type] != 'image'}.map {|id, data|
	[id.to_i, data.stringify_keys]
}.to_h
$other_files = CMS.files.reject{|k,v| v[:type] == 'image'}.map {|id, data|
	[id.to_i, data.stringify_keys]
}.to_h

new_data('siteinfo', CMS.site.deep_stringify_keys)
new_data('sitemap', $sitemap)
new_data('images', $images)
new_data('files', $other_files)

#pp $content
#pp $partials
#$partialpaths


require './ssg/jekyll.rb'

create_files_yml($datapaths, DIR_DATA)
create_files_md($filepaths, DIR_PAGES)
create_partials($partialpaths, DIR_PARTIALS)
