#PARENTAGE['page'] = 'home'
TRANSFORM['page'] = lambda do |id, meta, data|
	frontmatter = {}
	expect(data['publish_date']) { |e| frontmatter['date'] = e }
	{
		file: {
			path: '/'
		},
		frontmatter: frontmatter,
		content: md_p(data['text'])
	}
end
