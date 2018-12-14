
# PARSE PARENTS
$content.each { |id, meta_data|
	#puts "Reading parents of content id: #{id}, '#{langs['en'][:frontmatter]['slug']}', which has #{langs.size.to_s} langs."
	meta = meta_data[:meta]
	data = meta_data[:data]

	#puts meta_data

	data.each_with_index{ |(lang, item), index|
		#puts "...Lang \##{index + 1}: #{lang}"

		front = item[:frontmatter] # If defined?

		# Create an array of parents for each piece of content
		parents = []
		parent = meta[:parent].to_i if meta[:parent]

		while parent && $content[parent]
			#puts "Parent \##{(parents.size + 1).to_s} = #{parent.to_s}"
			parent_info = {id: parent}
			if slug = expect_key($content[parent], [:data,lang,:frontmatter,KEY_SLUG])
				# The identified parent exists in the same language
				parent_info[:slug] = slug
			else
				# The identified parent does not exist in the same language
				if CONFIG['I18n']['missing']['parents']
					# Jump to next available language
					first_lang = $content[parent][:data].keys[0]
					slug = $content[parent][:data][first_lang][:frontmatter][KEY_SLUG]
					parent_info[:slug] = slug
					parent_info[:lang] = first_lang
				else
					# Skip this parent in the item's parent tree
					parent_info = nil
				end
			end
			parents << parent_info if parent_info

			# Look for grandparent
			if parent = $content[parent][:meta][:parent]
				parent = parent.to_i
			else # No grandparents
				parent = nil
			end

			#puts "Next parent up is: #{parent.inspect}"
		end
		#puts "#{parents.size.to_s} parents identified for id #{id} in lang: #{lang}"

		$content[id][:data][lang][:frontmatter]['meta'] ||= {}
		$content[id][:data][lang][:frontmatter]['meta']['parents'] = parents.map{|i| i.stringify_keys }
		$content[id][:meta][:parents] = parents

		# Reconstruct this item's path with base that's already set
		$content[id][:data][lang][:file][:path] = path(
			$content[id][:data][lang][:file][:path],
			parents.map{ |branch|
				branch[:slug]
			}.reverse.join('/')
		)

		# Reconstruct this item's link based on new path
		$content[id][:data][lang][:file][:link] = path(
			$content[id][:data][lang][:file][:path],
			$content[id][:data][lang][:file][:slug]
		)
	}
}
