require '../utils/helpers.rb'

ROOT = '../'
THIS_DIR = 'transformer'
CONFIG = YAML.load_file('../_config.yml')
SOURCE = CONFIG['source']

TIME_FORMAT = '%Y-%m-%d %H:%M:%S %z' #Internal representation
KEY_ID = 'id'
KEY_TITLE = 'title'
KEY_SLUG = 'slug'

require 'i18n'

I18n.load_path << Dir['./utils/i18n/*.yml']
I18n.default_locale = :en

require './cms/dato.rb'
require '../utils/markdown_builder.rb'

module Transformer
	class CMS < DatoCMS
		def initialize
			super # Initialises from the loaded CMS file
			# Connects to CMS
			# Downloads all of its data into some local representation (specific to the CMS)
			# Shunts it into standard format (above)
		end
	end

	class SSG #< JekyllSSG
		def initialize
			#super # Initialises from the loaded SSG file
		end

		def transform

		end

		def create

		end

	end

	module Transform
		#All declarative methods below placed here

		CMS = Transformer::CMS.new

	end

end

TRANSFORM = {}

=begin
#UNUSED
def get_data(item, field, lang)
	if CMS.models[:pages][item[:meta][:model]][:fields][field][:localised]
		return item[:data][:field][lang] # Localised
	else
		return item[:data][:field] # Not localised
	end
end
def get_parents(id)
	parents = []
	if this_parent = CMS.items[id][:meta][:parent]
		parents << this_parent
		parents << get_parents(this_parent)
	end
	return parents
end
=end

# Defaults
require './transforms/default/base.rb'
require './transforms/default/undefined.rb'

# This site
require './transforms/home.rb'
require './transforms/product.rb'
require './transforms/article.rb'
require './transforms/page.rb'
require './transforms/social.rb'

=begin
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
=end

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


require './ssg/jekyll.rb'

create_files_yml($datapaths, DIR_DATA)
create_files_md($filepaths, DIR_PAGES)
create_partials($partialpaths, DIR_PARTIALS)
