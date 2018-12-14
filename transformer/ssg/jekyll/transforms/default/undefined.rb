TRANSFORM_UNDEFINED = lambda do |id, meta, data|
	dump = {
		frontmatter: {
			'data' => {}
		}
	}
	data.each { |field_name, field_data|
		dump[:frontmatter]['data'][field_name.to_s] = field_data unless [KEY_TITLE, KEY_SLUG].include?(field_name)
	}
	return dump
end
