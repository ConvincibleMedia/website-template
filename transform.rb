require './utils/helpers.rb'
require 'dato'

CONFIG = YAML.load_file('./_config.yml')
SOURCE = CONFIG['source']


module Spark

	class DatoCMS

		def initialize
			@API = Dato::Site::Client.new('38589353b1f7d1b630f77739b333224f581e432e87ca62aa2f')
			@models = {}

			@API.item_types.all.each {|model|
				if !model['modular_block']
					model_name = model['api_key']
					@models[model_name] = {
						id: model['id'],
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
			@items = {}
			puts @models
		end

		def get_items(model)
			puts "Getting items for model '#{model}'..."
			puts "Model ID is '#{@models[model][:id]}'..."
			unless @items[model]
				@items[model] = {}
				@API.items.all({
					'filter[type]' => @models[model][:id],
					'version' => 'published'
				}).each { |item|
					@items[model][item['id']] = {
						date: item['published_at'],
						content: {}
					}
					@models[model][:fields].each { |field|
						#if field[:localized]

						#else
							@items[model][item['id']][:content][field] = item[field]
						#end
					}
				}
			end
			return @items[model]
		end

	end

	class CMS < DatoCMS
		def initialize
			super
		end

		attr_reader :models
		attr_reader :items
	end

end

CMS = Spark::CMS.new

CMS.models.each { |model_name, model|
	pp CMS.get_items(model_name).inspect
}
