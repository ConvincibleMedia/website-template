TRANSFORM_BASE = lambda do |id, meta, data|
	{
		file: {
			path: path([t(:slug, [:models, meta[:model]], 2)])
		},
		frontmatter: {
			KEY_TITLE => data[KEY_TITLE],
			KEY_SLUG => data[KEY_SLUG],
			'published' => true,
			'date' => meta[:modified],
			# Metadata about this piece of content
			'meta' => {
				KEY_ID => id
			},
			'seo' => {
				'hidden' => meta[:hidden] == true
			},
		}
	}
end
