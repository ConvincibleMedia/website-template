module Transformer
	module Templates
		class Category < Template

			def slug(this, info, data, locale)
				data['name']
			end

			def file(this, info, data, locale)
				{
					path: '_data/',
					name: 'categories' + '.yml',
					type: 'json',
					nesting: {
						parent: info[:parent],
						join_at: 'subcategories'
					}
				}
			end

			def content(this, info, data, locale)
				{
					data['name'] => {
						'description' => data['description'],
						'parent' => info[:parent],
						'subcategories' => nil
					}
				}
			end

		end
	end
end

Transformer::register_template('category', Transformer::Templates::Category)
