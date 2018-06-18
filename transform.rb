require './utils/helpers.rb'
require 'dato'

CONFIG = YAML.load_file('./_config.yml')
SOURCE = CONFIG['source']

TIME_FORMAT = '%Y-%m-%d %H:%M:%S %z'

module Spark

	class DatoCMS

		def initialize
			@API = Dato::Site::Client.new('38589353b1f7d1b630f77739b333224f581e432e87ca62aa2f')
			@site = {}
			@models = {}
			@items = {}
			@files = {}
			@locales = []

			site = @API.site.find
			@locales = site['locales']
			@site = {
				title: {},
				url: site['production_frontend_url'] || site['frontend_url'],
				assets_url: site['imgix_host'],
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
				@site[:title][locale] = key?(site, ['global_seo', locale, 'site_name']) || key?(site, ['global_seo', @locales[0], 'site_name']) || ''
				@site[:seo][:title][locale] = key?(site, ['global_seo', locale, 'fallback_seo', 'title']) || ''
				@site[:seo][:description][locale] = key?(site, ['global_seo', locale, 'fallback_seo', 'description']) || ''
				@site[:seo][:image][locale] = key?(site, ['global_seo', locale, 'fallback_seo', 'image']) || key?(site, ['global_seo', @locales[0], 'fallback_seo', 'image']) || ''
				@site[:seo][:suffix][locale] = key?(site, ['global_seo', locale, 'title_suffix']) || ''
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
			unless @items[model_name]
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
							if field[:localized]
								this_field = item[field_name][lang]
							else
								this_field = item[field_name]
							end
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
					url: @site[:assets_url] + file['path'],
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

		attr_reader :models
		attr_reader :items
		attr_reader :files
		attr_reader :locales
	end

end

CMS = Spark::CMS.new


CMS.models.each { |model_name, model_info|
	CMS.get_items(model_name).each { |id, item|

	}
}
CMS.get_files


require './utils/markdown_builder.rb'

TRANSFORM = {}
TRANSFORM_UNKNOWN = lambda do |id, meta, data, parents|
	{
		meta: {
			id: id,
			parents: parents
		},
		frontmatter: {
			id: id,
			title: id,
			slug: id,
			layout: nil,
			published: true,
			date: meta['modified'],
			# Metadata about this piece of content
			meta: {
				parents: parents,
				hidden: false
			},
			# How to display this piece of content
			#view: {
			#	features: []
			#},
			# HTML meta and OG/social card overrides
			#seo: {
			#	title: nil,
			#	description: nil,
			#	image: nil
			#},
			# Data that contributes to the content of this piece of content
			#data: {}
		},
		content: ''#,
		#partials: []
	}
end

def get_data(item, field, lang)
	if CMS.models[item[:meta][:model]][:fields][field][:localised]
		return item[:data][:field][lang] # Localised
	else
		return item[:data][:field] # Not localised
	end
end

# Defaults
TRANSFORM_BASE = lambda do |item|
	meta = item[:meta]
	data = item[:data]
	model_name = meta[:model]
	id = meta[:id]

	CMS.locales.map { |lang|
		lang => {
			meta: {
				id: id,
				parents: meta[:parents],
				path: '/' + model_name + '/',
				link: '/' + model_name + '/' + (data['address'].to_s || id.to_s)
			},
			frontmatter: {
				id: id,
				title: data['title'] || id.to_s,
				slug: data['address'] || data['title'] || id.to_s,
				published: true,
				date: meta[:modified] || meta[:created],
				# Metadata about this piece of content
				meta: {
					parents: meta[:parents],
					hidden: meta[:hidden]
				},
			}
		}
	}
end

TRANSFORM_UNDEFINED = lambda do |id, meta, data|
	frontmatter = { data: {}}
	data.each { |field_name, field_data|
		frontmatter[:data][field_name] = field_data
	}
	return frontmatter
end


TRANSFORM['home'] = lambda do |id, meta, data|
	{
		frontmatter: {
			title: 'Home',
			slug: '',
			seo: {
				title: data['seo']['title'],
				description: data['seo']['description'],
				image: data['seo']['image']
			}
		},
		content: [
			data['intro'],
			liquid_tag(
				'video',
				[data['video']['provider'], data['video']['provider_uid']],
				md_link(md_img(data['video']['title'], data['video']['thumbnail_url']), data['video']['url'])
			)
		].flatten.join("\n\n")
	}
end

TRANSFORM['product'] = lambda do |id, meta, data|
	{
		meta: {
			path: '/product/'
		},
		frontmatter: {
			data: {
				image: data['image'],
				colour: Spark::DatoCMS::rgba(data['colour_scheme']),
				available: data['available'],
				price: data['price']
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
	content = TRANSFORM_BASE.call(model, id, item[:meta], item[:data])
	if TRANSFORM[model]
		content = content.deep_merge(TRANSFORM[model].call(id, item[:meta], item[:data]))
	else
		content = content.deep_merge(TRANSFORM_UNDEFINED.call(id, item[:meta], item[:data]))
	end
	unless content[:frontmatter][:slug]
		content[:frontmatter][:slug] = content[:frontmatter][:title].downcase.gsub(/[^A-Za-z0-9]+/, '')
	end
	content[:meta][:slug] = content[:frontmatter][:slug]
	return content
end


$content = {}
$filepaths = {}
$sitemap = {}

CMS.models.each { |model_name, model_info|
	puts "For model #{model_name}..."
	CMS.get_items(model_name).each { |id, item|
		id = id.to_i
		$content[id] = transform(model_name, id)
		meta = $content[id][:meta]
		front = $content[id][:frontmatter]
		content = $content[id][:content]
		($filepaths[meta[:path]] ||= []) << id
		$sitemap[id] = {
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

def create_file(path, file)
	puts "Will write #{path}#{file}..."
	FileUtils.mkdir_p(path) unless File.directory?(path)
	f = File.open(path + file)
	f.write(yield)
	f.close
end

def create_files_md(files, root)
	files.sort.each { |pair|
		path = root + pair[0]
		id_list = pair[1]


			id_list.each { |id|
				puts item = $content[id.to_i]
				# Create this item at this location
				create_file(path, item[:meta][:slug] + '.md') {
					item[:frontmatter].to_yaml
					item[:content]
				}

			}

	}
end

create_files_md($filepaths, 'source/_pages')
