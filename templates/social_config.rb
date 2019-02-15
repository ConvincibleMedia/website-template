module Transformer
	module Templates
		class SocialConfig < Template

			def slug(this, info, data, locale)
				data['profile'].downcase
			end

			def file(this, info, data, locale)
				{
					path: "_includes/partials/social",
					name: data['profile'] + '.json',
					type: 'json'
				}
			end

			def content(this, info, data, locale)
				data['config']
			end

		end
	end
end

Transformer::register_template('social', Transformer::Templates::SocialConfig)
