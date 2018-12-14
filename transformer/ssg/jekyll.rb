def create_file(path, file, contents)
	puts "Writing #{path}#{file}..."
	FileUtils.mkdir_p(path) unless File.directory?(path)
	#f = File.open(path + file, 'w')
	File.write(path + file, contents)
	#f.close
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
