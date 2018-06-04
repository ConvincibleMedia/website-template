require './utils/helpers.rb'

CONFIG = YAML.load_file('./_config.yml')
SOURCE = CONFIG['source']


models = {
	'home' => {
		#title: 'Home',
		type: 'single', # single, multiple, tree
		fields: {
			'title' => {
				type: 'string', #text, modular, etc.
				localized: false,
				fields: {}
			}
		},
		versioning: false
	},
	'about_page' => 'single',
	'product' => 'multiple',
	'article' => 'tree',
	'social_profile' => 'multiple'
}



correlations = {
	'home' => {
		id: :id, # Core field - first item
 		# Read by Jekyll - must be top level
		layout: ,
		title: 'title',
		published: true,
		#categories: [],
		#tags: [],
		date: ,
		#permalink: ,
		#excerpt: ,
		# Most important data points
		slug: 'address',
		# HTML meta and OG/social card overrides
		seo:
			title: ,
			description: ,
			image: ,
		# Metadata about this piece of content
		meta:

			parents: ,
			hidden: false,
		# How to display this piece of content
		view:
			features: []
		# Data that contributes to the content of this piece of content
		data:
			image:

	}
}
