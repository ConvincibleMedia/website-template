require 'dato'

module Transformer

	class DatoCMS

		attr_reader :site
		attr_reader :models
		attr_reader :items
		attr_reader :files
		attr_reader :locales

		def initialize

			# READ ENVIRONMENT VARIABLE
			@API = Dato::Site::Client.new($DATO_API_TOKEN)

			@site = {}
			@models = {}
			@items = {}
			@blocks = {}
			@files = {}
			@locales = []

			get_site()
			get_models()

			#For each block model, get the blocks
			@models[:blocks].each { |model_name, model_info|
				get_blocks(model_name)
			}
			#For each page model, get the pages
			@models[:pages].each { |model_name, model_info|
				get_items(model_name)
			}
			#Get all files
			get_files()

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

				# Does this model have ANY localized fields?
				localized_fields = @models[:pages][model_name][:fields].select { |field_name, field_info|
					field_info[:localized]
				}
				#puts "In model #{model_name} there are #{localized_fields.size.to_s} localized fields: " + localized_fields.map{|name,_| name}.join(', ')

				@API.items.all({
					'filter[type]' => @models[:pages][model_name][:id],
					'version' => 'published',
					#'orderBy' => 'position'
				}).each { |item|
					id = item['id'].to_i
					created = item['created_at'] || Time.now.to_s
					@items[model_name][id] = {
						meta: {
							KEY_ID.to_sym => id,
							created: Time.parse(created).strftime(TIME_FORMAT),
							modified: Time.parse(item['published_at'] || item['updated_at'] || created).strftime(TIME_FORMAT),
							parent: item['parent_id'],
							order: item['position'],
							model: model_name
						},
						data: {}
					}
					#ap @items[model_name]

					localized = []
					if localized_fields.size > 0
						# Has ANY localised content in fact been defined for ANY of those fields?
						#check = @locales.deep_dup
						#check.each { |lang|
						@locales.each { |lang|
							localized_fields.each { |field_name, field_info|
								if item[field_name][lang].present?
									localized << lang
									#check.delete(lang)
									#puts "For item #{id} in #{model_name}, language #{lang} is present in field #{field_name} with value: " + item[field_name][lang].to_s
									break # Stop looking through fields, go to next lang
								end
							}
							#if localized.size == @locales.size then break end
						}
						#puts "For item #{id}, no localized data could be found." if localized.size == 0
					end
					if localized.size == 0
						# Always at least the default lang, even if this is empty
						localized = [@locales[0]]
					end

					@items[model_name][item['id'].to_i][:meta][:langs] = localized
					puts "Received item #{id} (#{model_name}) in languages: " + localized.join(', ')

					@models[:pages][model_name][:fields].each { |field_name, field_info|

						localized.each { |lang|
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
			#pp @items[model_name]
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

end
