TRANSFORM['product'] = lambda do |id, meta, data|
	{
		frontmatter: {
			'data' => {
				'image' => data['image'],
				'colour' => Spark::DatoCMS::rgba(data['colour_scheme']),
				'available' => data['available'],
				'price' => data['price']
			}
		},
		content: md_p([
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
	}
end
