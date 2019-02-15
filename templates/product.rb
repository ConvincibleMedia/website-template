module Transformer
	module Templates
		class Product < Template

			def slug(this, info, data, locale)
				data['title']
			end

			def file(this, info, data, locale)
				{
					path: "_pages/#{locale}/products/",
					name: data['title'] + '.md',
					type: :markdown
				}
			end

			def metadata(this, info, data, locale)
				{
					'data' => {
						'image' => data['image'],
						'colour' => data.dial['colour_scheme'].call { |colour|
							if colour
								colour.inject('#000000') { |s,(k,v)|
									case k
									when 'red'
										s[1..2] = v.to_i.to_s(16)
									when 'green'
										s[3..4] = v.to_i.to_s(16)
									when 'blue'
										s[5..6] = v.to_i.to_s(16)
									end
									s
								}
							end
						},
						'available' => data['available'],
						'price' => data['price']
					}
				}
			end

			def content(this, info, data, locale)
				Writers::Markdown.p([
					Writers::Markdown.p(data['description'].to_s.truncate(50)),
					data['gallery'] ? Writers::Liquid.tag(
						'gallery', '',
						data['gallery'].map { |id|
							Writers::Markdown.img('image',id)
						}.join("\n"),
					) : nil,
					data['origin'] ? Writers::Liquid.tag(
						'map', '',
						Writers::Markdown.link('Map Link',
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
