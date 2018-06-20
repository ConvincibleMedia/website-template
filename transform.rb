require './utils/helpers.rb'
require 'dato'

CONFIG = YAML.load_file('./_config.yml')
SOURCE = CONFIG['source']

TIME_FORMAT = '%Y-%m-%d %H:%M:%S %z' #Internal representation

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
			@files = {}
			@locales = []

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

			@API.item_types.all.each {|model|
				if !model['modular_block']
					model_name = model['api_key']
					@models[model_name] = {
						id: model['id'].to_i,
						type: '',
						fields: {},
						versioning: model['draft_mode_active']
					}
					if model[:singleton]
						@models[model_name][:type] = 'single'
					elsif model[:tree]
						@models[model_name][:type] = 'tree'
					else
						@models[model_name][:type] = 'multiple'
					end
					@API.fields.all(model['id']).each { |field|
						@models[model_name][:fields][field['api_key']] = {
							type: field['field_type'],
							localized: field['localized']
						}
					}
				end
			}

		end

		def get_items(model_name)
			#puts "Getting items for model '#{model}'..."
			#puts "Model ID is '#{@models[model][:id]}'..."
			unless @items.key?(model_name)
				@items[model_name] = {}
				@API.items.all({
					'filter[type]' => @models[model_name][:id],
					'version' => 'published'
				}).each { |item|
					@items[model_name][item['id'].to_i] = {
						meta: {
							created: Time.parse(item['created_at']).strftime(TIME_FORMAT),
							modified: Time.parse(item['published_at'] || item['updated_at'] || item['created_at']).strftime(TIME_FORMAT),
							parent: item['parent'],
							model: model_name
						},
						data: {}
					}
					#ap @items[model_name]

					@models[model_name][:fields].each { |field_name, field_info|
						@locales.each { |lang|
							if field_info[:localized]
								this_field = item[field_name][lang]
							else
								this_field = item[field_name]
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
					url: URLs.parse(@site[:assets_url], file['path']),
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


CMS.models.each { |model_name, model_info|
	CMS.get_items(model_name)
}
CMS.get_files


require './utils/markdown_builder.rb'

TRANSFORM = {}

def get_data(item, field, lang)
	if CMS.models[item[:meta][:model]][:fields][field][:localised]
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

def path(paths)
	if paths.is_a? Array
		paths = paths.flatten.map{ |i| path_clean(i) }.reject(&:blank?).join(PATH_SEP)
	else
		paths = path_clean(paths)
	end
	return paths + PATH_SEP
end
def path_clean(path)
	return path.to_s.split(PATH_SEP).map{ |i| i.gsub(PATH_UNSAFE, '').strip }.reject(&:blank?).join(PATH_SEP)
end

KEY_ID = 'id'
KEY_TITLE = 'title'
KEY_SLUG = 'slug'

# Defaults
TRANSFORM_BASE = lambda do |id, meta, data|
	{
		meta: {
			id: id,
			parents: meta[:parents],
			path: path([t(:slug, [:models, meta[:model]], 2)])
		},
		frontmatter: {
			KEY_ID => id,
			KEY_TITLE => data[KEY_TITLE],
			KEY_SLUG => data[KEY_SLUG],
			'published' => true,
			'date' => meta[:modified] || meta[:created],
			# Metadata about this piece of content
			'meta' => {
				'parents' => meta[:parents],
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
		content: [
			data['intro'],
			liquid_tag(
				'video',
				[expect_key(data,['video','provider']), expect_key(data,['video','provider_uid'])],
				md_link(md_img(expect_key(data,['video','title']), expect_key(data,['video','thumbnail_url'])), expect_key(data,['video','url']))
			)
		].flatten.join("\n\n")
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

		# Universal tidying
		content[lang][:frontmatter][KEY_TITLE] = id.to_s if content[lang][:frontmatter][KEY_TITLE].blank?
		content[lang][:frontmatter][KEY_SLUG] = content[lang][:frontmatter][KEY_TITLE] if content[lang][:frontmatter][KEY_SLUG].blank?
		content[lang][:frontmatter][KEY_SLUG] = content[lang][:frontmatter][KEY_SLUG].parameterize
		content[lang][:frontmatter][KEY_SLUG] = id.to_s if content[lang][:frontmatter][KEY_SLUG].blank?
		content[lang][:meta][:slug] = content[lang][:frontmatter][KEY_SLUG]
		content[lang][:meta][:link] = content[lang][:meta][:path] + content[lang][:meta][:slug]
	}

	return content
end


$content = {}
$filepaths = {}
$sitemap = {}
CMS.locales.each { |lang|
	$filepaths[lang] = {}
	$sitemap[lang] = {}
}

CMS.models.each { |model_name, model_info|
	#puts "Constructing content and paths for model #{model_name}..."
	CMS.get_items(model_name).each { |id, item|
		#puts "Working on item id #{id}..."
		id = id.to_i
		$content[id] = transform(model_name, id)

		CMS.locales.each { |lang|
			#puts "...in language: #{lang}"
			meta = $content[id][lang][:meta]
			front = $content[id][lang][:frontmatter]
			content = $content[id][lang][:content]
			$filepaths[lang][meta[:path]] = ($filepaths[lang][meta[:path]] || [])
			$filepaths[lang][meta[:path]] << id
			$sitemap[id] = {} unless $sitemap.key?(id)
			$sitemap[id][lang] = {
				title: front[:title],
		      slug: front[:slug],
		      link: meta[:link],
		      path: meta[:path],
		      loc: CONFIG['url'] + meta[:link],
		      lastmod: meta[:modified],
		      type: model_name,
		      #order: '3'
		      hidden: meta[:hidden]
			}
		}
	}
}

def create_file(path, file, contents)
	puts "Will write #{path}#{file}..."
	FileUtils.mkdir_p(path) unless File.directory?(path)
	#f = File.open(path + file, 'w')
	File.write(path + file, contents)
	#f.close
end

def create_files_md(files, root)
	#puts "Destroying previous files (if exist)."
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

create_files_md($filepaths, './source/_pages/')
