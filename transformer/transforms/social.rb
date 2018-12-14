TRANSFORM['social'] = lambda do |id, meta, data|
	{
		frontmatter: nil,
		data: {
			'profile' => data['profile'],
			'url' => data['url']
		},
		partials: { # No path! - so goes to _includes
			'config.json' => data['config'] # partial filename : partial's content
		}
	}
end