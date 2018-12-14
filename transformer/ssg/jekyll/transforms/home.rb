TRANSFORM['home'] = lambda do |id, meta, data|
	{
		file: {
			path: '/'
		},
		frontmatter: {
			KEY_TITLE => 'Home',
			KEY_SLUG => 'index',
			'seo' => {
				'title' => expect_key(data, ['seo','title']),
				'description' => expect_key(data, ['seo','description']),
				'image' => expect_key(data, ['seo','image'])
			},
			'features' => ['form']
		},
		content: md_p([
			data['intro'],
			liquid_tag(
				'video',
				[expect_key(data,['video','provider']), expect_key(data,['video','provider_uid'])],
				md_link(md_img(expect_key(data,['video','title']), expect_key(data,['video','thumbnail_url'])), expect_key(data,['video','url']))
			),
			md_partial('form.html')
		]),
		partials: {
			'form.html' => data['form']
		}
	}
end
