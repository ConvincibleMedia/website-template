module Transformer
	module Templates
		class Category < Template

			def initialize
				super
			end

			def file(id, meta, data, locale)
				{
					path: '_data/',
					name: 'categories',
					type: 'json',
					nesting: {
						parent: meta[:parent],
						join_at: 'subcategories'
					}
				}
			end

			def content(id, meta, data, locale)
				[
					{
						data['name'] => {
							'description' => data['description'],
							'parent' => meta[:parent],
							'subcategories' => nil
						}
					}
				] # Returning an array and then concatenating files will join the arrays
			end

		end
	end
end

Transformer::register_template('category', Transformer::Templates::Category)
