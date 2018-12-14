#PARENTAGE['article'] = 'home'
TRANSFORM['article'] = lambda do |id, meta, data|
	#data['sources'] = blocks(data['sources'], 'source')
	{
		frontmatter: {
			'data' => {
				'image' => data['image'],
				'quoted' => data['sources'].map{ |source|
					source['author']
				}
			}
		},
		content: md_p([
			md_html(data['body']),
			expect(data['sources']) { |sources|
				liquid_tag('contentfor', 'hero',
					md_h('Sources', 2),
					md_ol(data['sources'].map{ |source|
						md_link(
							"<cite>" + source['title'] + "</cite>" +
							(source['author'].present? ? ", " + source['author'] : ''),
							source['url'])
					})
				)
			}
		])
	}
end
