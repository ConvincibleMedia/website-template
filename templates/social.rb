module Transformer
	module Templates
		class Social < Template

			def slug(this, info, data, locale)
				data['profile'].downcase
			end

			def file(this, info, data, locale)
				{
					path: '_data/',
					name: 'social' + '.yml',
					type: :yaml
				}
			end

			def content(this, info, data, locale)
				{
					'profile' => data['profile'],
					'url' => data['url']
				}
			end

		end
	end
end

Transformer::register_template('social', Transformer::Templates::Social)
