require './utils/helpers.rb'
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

module Spark

	class DatoCMS

		attr_reader :site
		attr_reader :models
		attr_reader :items
		attr_reader :files
		attr_reader :locales

		def initialize
			@API = Dato::Site::Client.new('38589353b1f7d1b630f77739b333224f581e432e87ca62aa2f')
			@site = {}
			@models = {}
			@items = {}
			@blocks = {}
			@files = {}
			@locales = []

			get_site()

			get_models()

		end

		def get_site()
			site = @API.site.find
			@locales = site['locales']
			I18n.default_locale = @locales[0]

			@site = {
				title: {},
				url: site['production_frontend_url'] || site['frontend_url'],
				assets_url: Addressable::URI.heuristic_parse(site['imgix_host']).normalize.omit(:scheme).to_s,
				seo: {
					title: {},
					description: {},
					image: {},
					suffix: {},
					hidden: site['no_index']
				},
				langs: @locales
			}

			@locales.each { |locale|
				@site[:title][locale] = expect_key(site, ['global_seo', locale, 'site_name']) || expect_key(site, ['global_seo', @locales[0], 'site_name']) || ''
				@site[:seo][:title][locale] = expect_key(site, ['global_seo', locale, 'fallback_seo', 'title']) || ''
				@site[:seo][:description][locale] = expect_key(site, ['global_seo', locale, 'fallback_seo', 'description']) || ''
				@site[:seo][:image][locale] = expect_key(site, ['global_seo', locale, 'fallback_seo', 'image']) || expect_key(site, ['global_seo', @locales[0], 'fallback_seo', 'image']) || ''
				@site[:seo][:suffix][locale] = expect_key(site, ['global_seo', locale, 'title_suffix']) || ''
			}
		end

		def get_models()
			@API.item_types.all.each {|model|
				if !model['modular_block']
					section = :pages
				else
					section = :blocks
				end
				@models[section] ||= {}

				model_name = model['api_key']
				@models[section][model_name] = {
					id: model['id'].to_i,
					type: '',
					fields: {},
					versioning: model['draft_mode_active']
				}
				if model[:singleton]
					@models[section][model_name][:type] = 'single'
				elsif model[:tree]
					@models[section][model_name][:type] = 'tree'
				else
					@models[section][model_name][:type] = 'multiple'
				end
				@API.fields.all(model['id']).each { |field|
					field_type_map = {
						'string' => {type: 'text', subtype: 'line', multiple: false},
						'text' => {type: 'text', subtype: 'multiline', multiple: false},
						'slug' => {type: 'text', subtype: 'line', multiple: false},
						'boolean' => {type: 'boolean', subtype: nil, multiple: false},
						'integer' => {type: 'number', subtype: 'integer', multiple: false},
						'float' => {type: 'number', subtype: 'decimal', multiple: false},
						'date_time' => {type: 'time', subtype: 'datetime', multiple: false},
						'date' => {type: 'time', subtype: 'date', multiple: false},
						'json' => {type: 'raw', subtype: 'integer', multiple: false},

						'link' => 'id/page',
						'links' => 'multi/id/page',
						'file' => 'id/asset',
						'gallery' => 'multi/id/asset',

						'seo' => 'struct/seo',
						'video' => 'struct/video',
						'lat_lon' => 'struct/gps',
						'color' => 'struct/color',

						'rich_text' => 'multi/id/page/inlinify'
					}
					type = field['field_type']

					@models[section][model_name][:fields][field['api_key']] = {
						type: type,
						localized: field['localized']
					}


				}
			}
		end


		def get_blocks(model_name)
			unless @blocks.key?(model_name)
				@API.items.all({
					'filter[type]' => @models[:blocks][model_name][:id],
					#'version' => 'published',
					#'orderBy' => 'position'
				}).each { |item|
					@blocks[item['id'].to_i] = {
						model_name => {}
					}
					#ap @items[model_name]

					@models[:blocks][model_name][:fields].each { |field_name, field_info|
						@blocks[item['id'].to_i][model_name][field_name] = item[field_name]
					}
				}
			end
		end

		def get_items(model_name)
			#puts "Getting items for model '#{model}'..."
			#puts "Model ID is '#{@models[model][:id]}'..."
			unless @items.key?(model_name)
				@items[model_name] = {}
				@API.items.all({
					'filter[type]' => @models[:pages][model_name][:id],
					'version' => 'published',
					#'orderBy' => 'position'
				}).each { |item|
					id = item['id'].to_i
					created = item['created_at'] || Time.now.to_s
					@items[model_name][id] = {
						meta: {
							KEY_ID => id,
							created: Time.parse(created).strftime(TIME_FORMAT),
							modified: Time.parse(item['published_at'] || item['updated_at'] || created).strftime(TIME_FORMAT),
							parent: item['parent_id'],
							order: item['position'],
							model: model_name
						},
						data: {}
					}
					#ap @items[model_name]

					@models[:pages][model_name][:fields].each { |field_name, field_info|
						@locales.each { |lang|
							if field_info[:localized]
								this_field = item[field_name][lang]
							else
								this_field = item[field_name]
							end
							case field_info[:type]
							when 'rich_text'
									this_field = [this_field] if !this_field.is_a? Array
									#if field_info[:inlinify]
										this_field = this_field.map{ |id|
											@blocks[id.to_i]
										}
									#end
							end
							@items[model_name][item['id'].to_i][:data][lang] = {} unless @items[model_name][item['id'].to_i][:data].key?(lang)
							@items[model_name][item['id'].to_i][:data][lang][field_name] = this_field
						}
					}
				}
			end
			return @items[model_name]
		end

		def get_files
			@API.uploads.all().each { |file|
				id = file['id'].to_i
				@files[id] = {
					type: file['is_image'] ? 'image' : 'other',
					format: file['format'],
					url: file['path'], # Does not include ASSETS URL on purpose
					alt: file['alt'],
					title: file['title'],
					size: file['size']
				}
				if file['is_image']
					@files[id][:width] = file['width']
					@files[id][:height] = file['height']
				end
			}
			return @files
		end

		def self.rgba(color)
			if color.is_a? Hash
				return "rgba(#{color['red']}, #{color['green']}, #{color['blue']}, #{color['alpha']})"
			else
				return nil
			end
		end

	end

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


require './utils/markdown_builder.rb'

TRANSFORM = {}

def get_data(item, field, lang)
	if CMS.models[:pages][item[:meta][:model]][:fields][field][:localised]
		return item[:data][:field][lang] # Localised
	else
		return item[:data][:field] # Not localised
	end
end

def t(key, scope, count = 1)
	return I18n.t(key, :scope => scope.join('.'), :count => count)
end

PATH_UNSAFE = Regexp.new('[' + Regexp.escape('<>:"/\|?*') + ']')
PATH_SEP = '/'

def path(*paths)
	paths = paths.flatten.map{ |i| path_clean(i) }.reject(&:blank?).join(PATH_SEP)
	return paths + PATH_SEP
end
def path_clean(path)
	return path.to_s.split(PATH_SEP).map{ |i| i.gsub(PATH_UNSAFE, '').strip }.reject(&:blank?).join(PATH_SEP)
end


def get_parents(id)
	parents = []
	if this_parent = CMS.items[id][:meta][:parent]
		parents << this_parent
		parents << get_parents(this_parent)
	end
	return parents
end

# Defaults
TRANSFORM_BASE = lambda do |id, meta, data|
	{
		meta: meta.deep_merge({
			path: path([t(:slug, [:models, meta[:model]], 2)])
		}),
		frontmatter: {
			KEY_ID => id,
			KEY_TITLE => data[KEY_TITLE],
			KEY_SLUG => data[KEY_SLUG],
			'published' => true,
			'date' => meta[:modified],
			# Metadata about this piece of content
			'meta' => {
				'parent' => meta[:parent],
				'hidden' => meta[:hidden]
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


TRANSFORM['home'] = lambda do |id, meta, data|
	{
		meta: {
			path: '/'
		},
		frontmatter: {
			KEY_TITLE => 'Home',
			KEY_SLUG => 'index',
			'seo' => {
				'title' => expect_key(data, ['seo','title']),
				'description' => expect_key(data, ['seo','description']),
				'image' => expect_key(data, ['seo','image'])
			}
		},
		content: md_p([
			data['intro'],
			liquid_tag(
				'video',
				[expect_key(data,['video','provider']), expect_key(data,['video','provider_uid'])],
				md_link(md_img(expect_key(data,['video','title']), expect_key(data,['video','thumbnail_url'])), expect_key(data,['video','url']))
			)
		])
	}
end

TRANSFORM['product'] = lambda do |id, meta, data|
	{
		frontmatter: {
			'data' => {
				'image' => data['image'],
				'colour' => Spark::DatoCMS::rgba(data['colour_scheme']),
				'available' => data['available'],
				'price' => data['price']
			}
		},
		content: md_p([
			md_html(data['description']),
			data['gallery'] ? liquid_tag(
				'gallery', '',
				data['gallery'].map { |id|
					md_img(CMS.files[id.to_i][:alt], CMS.files[id.to_i][:url])
				}.join("\n"),
			) : nil,
			data['origin'] ? liquid_tag(
				'map', '',
				md_link('Map Link',
					'geo:' +
					data['origin']['latitude'].to_s + ',' +
					data['origin']['longitude'].to_s)
			) : nil,
		])
	}
end

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

TRANSFORM['article'] = lambda do |id, meta, data|
	data['sources'] = blocks(data['sources'], 'source')
	{
		frontmatter: {
			'data' => {
				'image' => data['image'],
				'quoted' => data['sources'].map{ |source|
					source['author']
				}
			}
		},
		content: md_p([
			md_html(data['body']),
			expect(data['sources']) { |sources|
				liquid_tag('contentfor', 'hero',
					md_h('Sources', 2),
					md_ol(data['sources'].map{ |source|
						md_link(
							"<cite>" + source['title'] + "</cite>" +
							(source['author'].present? ? ", " + source['author'] : ''),
							source['url'])
					})
				)
			}
		])
	}
end

TRANSFORM['page'] = lambda do |id, meta, data|
	frontmatter = {}
	expect(data['publish_date']) { |e| frontmatter['date'] = e }
	{
		frontmatter: frontmatter,
		content: md_p(data['text'])
	}
end

TRANSFORM['social'] = lambda do |id, meta, data|
	{
		meta: {
			KEY_TITLE => data['profile'],
		},
		frontmatter: nil,
		data: {
			'profile' => data['profile'],
			'url' => data['url']
		},
		partials: { # No path! - so goes to _includes?
			'config.json' => data['config'] # partial filename : partial's content
		}
	}
end

=begin
TRANSFORM_PARTIAL['source'] = lambda do |data|
	{
		frontmatter: {
			'quoted' => [data['author']] # Array should be appended during deep_merge
		},
		content: md_link("<cite>" + data['title'] + "</cite>," + data['author'], data['url'])
	}
end
=end

def transform_partial(id)

end

def transform(model, id)
	id = id.to_i
	item = CMS.items[model][id]
	meta = item[:meta]
	model_name = meta[:model]

	content = {}
	CMS.locales.each { |lang|
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
			content[lang][:frontmatter]['meta']['lang'] = lang
			content[lang][:frontmatter]['meta']['dir'] = 'ltr'

			# Universal tidying
			content[lang][:frontmatter][KEY_TITLE] = id.to_s if content[lang][:frontmatter][KEY_TITLE].blank?
			content[lang][:frontmatter][KEY_SLUG] = content[lang][:frontmatter][KEY_TITLE] if content[lang][:frontmatter][KEY_SLUG].blank?
			content[lang][:frontmatter][KEY_SLUG] = content[lang][:frontmatter][KEY_SLUG].parameterize
			content[lang][:frontmatter][KEY_SLUG] = id.to_s if content[lang][:frontmatter][KEY_SLUG].blank?
			content[lang][:meta][:slug] = content[lang][:frontmatter][KEY_SLUG]
			content[lang][:meta][:link] = content[lang][:meta][:path] + content[lang][:meta][:slug]
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

CMS.models[:pages].each { |model_name, model_info|
	#puts "Constructing content and paths for model #{model_name}..."
	CMS.get_items(model_name).each { |id, _|
		#puts "Working on item id #{id}..."
		id = id.to_i
		transformed = transform(model_name, id)
		#$content[id] = [lang] = data structure

		CMS.locales.each { |lang|
			#puts "...in language: #{lang}"

			item = transformed[lang]
			meta = item[:meta]
			front = item[:frontmatter] # If defined?

			if item[:content] || item[:frontmatter]
				# Page to be created from this item

				$content[id] ||= {}
				$content[id][lang] = item

				if item[:partials] && item[:partials].length > 0
					# Relative partial

					item[:partials].each { |p_name, p_content|
						$partials[id.to_s + p_name] ||= {}
						$partials[id.to_s + p_name][lang] = {
							filename: front['slug'] + '_' + p_name.sub('.', '.partial.'),
							content: p_content
						}
						$partialpaths[lang] ||= {}
						$partialpaths[lang][meta[:path]] ||= []
						$partialpaths[lang][meta[:path]] << id.to_s + p_name
					}

				end

				# Setup other references to this content item

				$filepaths[lang][meta[:path]] ||= []
				$filepaths[lang][meta[:path]] << id
				$sitemap[id] ||= {}
				$sitemap[id][lang] = {
					'title' => front['title'],
					'path' => meta[:path],
			      'slug' => front['slug'],
			      'link' => meta[:link],
			      'loc' => URLs.join(CONFIG['url'], meta[:link]).omit(:scheme).to_s,
			      'lastmod' => meta[:modified],
			      'type' => model_name,
			      #'order': '3'
			      'hidden' => meta[:hidden]
				}

			end
			if item[:data]
				# Data file to be added to from this item

				$data[meta[:model]] ||= {
						meta: {
							slug: meta[:model],
							path: '/'
						},
						data:	{}
					}
				$data[meta[:model]][:data][lang] ||= []
				$data[meta[:model]][:data][lang] << item[:data]
				$datapaths['/'] ||= []
				$datapaths['/'] << meta[:model] unless $datapaths['/'].include?(meta[:model])

				if item[:partials] && !item[:content] && !item[:frontmatter]
					# Partial defined without content = not relative

					item[:partials].each { |p_name, p_content|
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
			end

		}
	}
}

def create_file(path, file, contents)
	puts "Writing #{path}#{file}..."
	FileUtils.mkdir_p(path) unless File.directory?(path)
	#f = File.open(path + file, 'w')
	File.write(path + file, contents)
	#f.close
end

DIR_PAGES = './source/_pages/'
def create_files_md(files, root)
	puts "Clearing pages directory..."
	CMS.locales.each { |lang|
		path = path([root, lang])
		FileUtils.rm_r(path, {secure: false, force: true}) if File.directory?(path)
	}
	#puts 'Will now try to create files.'
	files.each { |lang, paths|
		paths = paths.sort.to_h
		#puts "For language '#{lang}', will create:\n" + paths.keys.join("\n")
		paths.each { |path, id_list|
			path = path([root, lang, path])
			id_list.each { |id|
				item = $content[id.to_i][lang]
				# Create this item at this location
				create_file(path, item[:meta][:slug] + '.md',
					[
						Psych.dump(item[:frontmatter], {line_width: -1, indentation: 3}).strip,
						'---','',
						item[:content]
					].join("\n")
				)
			}
		}
	}
end

DIR_DATA = './source/_data/test/'
def create_files_yml(files, root)
	#Destroy
	puts "Clearing data directory..."
	FileUtils.rm_r(Dir[path(root, "*")], {secure: false, force: true}) if File.directory?(root)
	#Create
	files.each { |path, id_list|
		path = path([root, path])
		id_list.each{ |id|
			item = $data[id]
			create_file(path, item[:meta][:slug] + '.yml',
				Psych.dump(item[:data], {line_width: -1, indentation: 3}).gsub(/^([\r\n\s]*\-{3,}[\r\n\s]*)|([\r\n\s]*\-{3,}[\r\n\s]*)$/, '')
			)
		}
	}
end

DIR_PARTIALS = './source/_includes/partials/'
def create_partials(files, root)
	puts "Clearing partials directory..."
	CMS.locales.each { |lang|
		path = path([root, lang])
		FileUtils.rm_r(path, {secure: false, force: true}) if File.directory?(path)
	}
	#puts 'Will now try to create files.'
	files.each { |lang, paths|
		paths = paths.sort.to_h
		#puts "For language '#{lang}', will create:\n" + paths.keys.join("\n")
		paths.each { |path, id_list|
			if path == 0 #special
				path = path([root, lang])
			else
				path = path([DIR_PAGES, lang, path])
			end
			id_list.each { |id|
				item = $partials[id][lang]
				# Create this item at this location
				create_file(path, item[:filename], item[:content])
			}
		}
	}
end

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

#pp $data['social']
#pp $partials
#pp $partialpaths

create_files_yml($datapaths, DIR_DATA)
create_files_md($filepaths, DIR_PAGES)
create_partials($partialpaths, DIR_PARTIALS)
