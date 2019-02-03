module Transformer
	module Templates
		class Product < Template

			def initialize
				super
			end

			def file(id, meta, data, locale)
				{
					path: "_pages/#{locale}/products/",
					name: slug(data['slug']), #+ '.md' - not required as Jekyll handler will ensure
					type: :markdown
				}
			end

			def frontmatter(id, meta, data, locale)
				{
					'data' => {
						'image' => data['image'],
						'colour' => Spark::DatoCMS::rgba(data['colour_scheme']),
						'available' => data['available'],
						'price' => data['price']
					}
				}
			end

			def content(id, meta, data, locale)
				md_p([
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
			end

		end
	end
end

Transformer::register_template('product', Transformer::Templates::Product)
