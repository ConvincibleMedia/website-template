def create_file(path, file, contents)
	puts "Writing #{path}#{file}..."
	FileUtils.mkdir_p(path) unless File.directory?(path)
	#f = File.open(path + file, 'w')
	File.write(path + file, contents)
	#f.close
end
def partial_slug(partial, slug)
	return slug + '_' + partial.sub('.', '.partial.')
end

DIR_PAGES = './source/_pages/'
def create_files_md(files, root)
	puts "Clearing pages directory..."
	CMS.locales.each { |lang|
		path = path([root, lang])
		FileUtils.rm_r(path, {secure: false, force: true}) if File.directory?(path)
	}
	#puts 'Will now try to create files.'
	files.each { |lang, paths|
		paths = paths.sort.to_h
		#puts "For language '#{lang}', will create:\n" + paths.keys.join("\n")
		paths.each { |path, id_list|
			path = path([root, lang, path])
			id_list.each { |id|
				item = $content[id.to_i][:data][lang]
				# Create this item at this location
				create_file(path, item[:file][:slug] + '.md',
					[
						Psych.dump(item[:frontmatter], {line_width: -1, indentation: 3}).strip,
						'---','',
						item[:content]
					].join("\n")
				)
			}
		}
	}
end

DIR_DATA = './source/_data/test/'
def create_files_yml(files, root)
	#Destroy
	puts "Clearing data directory..."
	FileUtils.rm_r(Dir[path(root, "*")], {secure: false, force: true}) if File.directory?(root)
	#Create
	files.each { |path, id_list|
		path = path([root, path])
		id_list.each{ |id|
			item = $data[id]
			create_file(path, item[:meta][:slug] + '.yml',
				Psych.dump(item[:data], {line_width: -1, indentation: 3}).gsub(/^([\r\n\s]*\-{3,}[\r\n\s]*)|([\r\n\s]*\-{3,}[\r\n\s]*)$/, '')
			)
		}
	}
end

DIR_PARTIALS = './source/_includes/partials/'
def create_partials(files, root)
	puts "Clearing partials directory..."
	CMS.locales.each { |lang|
		path = path([root, lang])
		FileUtils.rm_r(path, {secure: false, force: true}) if File.directory?(path)
	}
	#puts 'Will now try to create files.'
	files.each { |lang, paths|
		paths = paths.sort_by{|k,v| k.to_s}.to_h
		#puts "For language '#{lang}', will create:\n" + paths.keys.join("\n")
		paths.each { |path, id_list|
			if path == 0 #special
				path = path([root, lang])
			else
				path = path([DIR_PAGES, lang, path])
			end
			id_list.each { |id|
				item = $partials[id][lang]
				# Create this item at this location
				create_file(path, item[:filename], item[:content])
			}
		}
	}
end


$content.each { |id, meta_data|

	meta = meta_data[:meta]
	data = meta_data[:data]

	data.each{ |lang, item|

		front = item[:frontmatter] # If defined?

		if item[:partials] && item[:partials].length > 0
			# Relative partial

			item[:partials].each { |p_name, p_content|
				$partials[id.to_s + p_name] ||= {}
				$partials[id.to_s + p_name][lang] = {
					filename: partial_slug(p_name, front['slug']),
					content: p_content
				}
				$partialpaths[lang] ||= {}
				$partialpaths[lang][item[:file][:path]] ||= []
				$partialpaths[lang][item[:file][:path]] << id.to_s + p_name
			}

		end
	}
}








#SITE DATA ITEMS

$content.each { |id, meta_data|

	meta = meta_data[:meta]
	data = meta_data[:data]

	data.each{ |lang, item|

		front = item[:frontmatter] # If defined?

		# Setup other references to this content item
		$filepaths[lang][item[:file][:path]] ||= []
		$filepaths[lang][item[:file][:path]] << id
		$sitemap[id] ||= {}
		$sitemap[id][lang] = {
			'title' => front['title'],
			'path' => item[:file][:path],
	      'slug' => front['slug'],
	      'link' => item[:file][:link],
	      'loc' => URLs.join(CONFIG['url'], item[:file][:link]).omit(:scheme).to_s,
	      'lastmod' => meta[:modified],
	      'type' => meta[:model],
	      #'order': '3'
	      'hidden' => meta[:hidden]
		}

	}
}

$images = CMS.files.reject{|k,v| v[:type] != 'image'}.map {|id, data|
	[id.to_i, data.stringify_keys]
}.to_h
$other_files = CMS.files.reject{|k,v| v[:type] == 'image'}.map {|id, data|
	[id.to_i, data.stringify_keys]
}.to_h

new_data('siteinfo', CMS.site.deep_stringify_keys)
new_data('sitemap', $sitemap)
new_data('images', $images)
new_data('files', $other_files)
