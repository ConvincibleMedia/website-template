module Transformer
	module Templates
		class Social < Template

			def initialize
				super
			end

			def file(id, meta, data, locale)
				[
					{
						path: '_data/',
						name: 'social', # One filename = concatenate all transforms
						type: :yaml
					},
					{
						path: '_includes/',
						name: data['profile'],
						type: 'json'
					}
				]
			end

			def content(id, meta, data, locale)
				[
					{
						'profile' => data['profile'],
						'url' => data['url']
					},
					config['json']
				]
			end

		end
	end
end

Transformer::register_template('social', Transformer::Templates::Social)
