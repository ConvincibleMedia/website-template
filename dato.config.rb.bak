# SETTINGS
# ##############################################################################

# Separator
sep = '/'
suf = ''
if defined?(dato.site.global_seo.title_suffix)
	suf = dato.site.global_seo.title_suffix
	sep2 = suf.match(/^\s*([^\w\s\d]{1,2})\s*/)
	if sep2 != nil
		sep = sep2[1]
		suf2 = suf.match(/^\s*[^\w\s\d]{1,2}\s*(.+)\s*$/)
		if suf2 != nil
			suf = suf2[1]
		end
	end
end
if suf == sep then suf = '' end

# SEO
create_data_file "source/_data/siteinfo.yml", :yaml,
	title: dato.site.global_seo.site_name,
	url: dato.site.to_hash[:frontend_url],
	seo: {
		title: dato.site.global_seo.fallback_seo.title,
		description: dato.site.global_seo.fallback_seo.description,
		image: dato.site.global_seo.fallback_seo.image,
		separator: sep,
		suffix: suf,
		hidden: dato.site.to_hash[:no_index] == true ? true : false
	},
	langs: dato.site.locales

#create_data_file "source/_data/favicon.yml", :yaml, dato.site.favicon_meta_tags
#create_data_file "resources/site_data.yml", :yaml, dato.site.to_hash


# SITEMAP
# ##############################################################################



$sitemap = { # $ = global scope
	models: Hash.new,
	pages: Hash.new,
	tree: Hash.new,
	types: Hash.new
}

$hidden = ['Non-Existent Page', 'Hide from Search Engines']

# Pages
=begin
dato.subpages.each_with_index { |item, index|
   #path = sitemap[:models][item.item_type.api_key.to_sym][:path]
	path = ""
	sitemap[:pages][item.id] = {
		title: item.title,
		slug: item.slug,
		path: '/' + path,
		loc: '/' + path + item.slug + '.html',
      lastmod: item.updated_at,
      # changefreq
      # priority
		type: item.item_type.api_key,
		order: index + 1,
		live: defined?(item.draft) ? (item.draft == true ? false : true) : true
	}
}
=end

def tree_map(model, path)
	def tree_iterate(tree, path, parents)
		tree.each { |branch|
			file_path = path # always has trailing slash
			file_name = branch.slug + ".html"
			unless (defined?(branch.hidden) && branch.hidden == $hidden[0])
				$sitemap[:pages][branch.id] = {
					title: branch.title,
					slug: branch.slug,
					path: file_path,
					file: file_name,
					loc: file_path + file_name, # Sitemap schema field
					lastmod: branch.updated_at.strftime('%F'), # Sitemap schema field
					# Sitemap schema field changefreq
					# Sitemap schema field priority
					type: branch.item_type.api_key,
					order: branch.position,
					hidden: branch.hidden == $hidden[1] ? true : false
				}
			end
			if (branch.children.length > 0)
				new_path = path + branch.slug + "/"
				new_parents = [{title: branch.title, id: branch.id}] + parents
				tree_iterate(branch.children, new_path, new_parents)
			end
		}
	end
	roots = model.select{|page| page.parent.nil? }.sort_by(&:position)
	tree_iterate(roots, path, [])
end

tree_map(dato.subpages, "/")




create_data_file "source/_data/sitemap.yml", :yaml,
	$sitemap


# MENUS
# ##############################################################################

create_data_file "source/_data/menu.yml", :yaml,
   main: dato.menu.main_menu.map{ |link|
      {
      	title: link.title,
      	link: link.id
      }
   },
   footer: dato.menu.footer_menu.map{ |link|
      {
      	title: link.title,
   		link: link.id
      }
   }


# PAGES
# ##############################################################################

# Home
home = dato.home
create_post "source/index.md" do
	frontmatter :yaml, {
		id: home.id,
		heading: home.heading,
		blurb: home.blurb,
		image: defined?(home.image.url) ? home.image.to_hash.slice(:url, :alt, :title) : '',
		links_heading: home.links_heading,
		links: home.links.map{ |link|
			{
				title: link.title,
				blurb: link.blurb,
				link: link.id
			}
		}
	}
	content(home.body)
end

# Subpages
def tree_grow(model, path, &block)
	def tree_iterate(tree, path, parents, &block)
		directory path do
			tree.each { |branch|
				unless (defined?(branch.hidden) && branch.hidden == $hidden[0])
					create_post "#{branch.slug}.md" do
						data = yield(branch, parents);
						frontmatter :yaml, data[:frontmatter]
						content(data[:content])
					end
				end
				if (branch.children.length > 0)
					new_parents = [{title: branch.title, id: branch.id}] + parents
					tree_iterate(branch.children, path + "/" + branch.slug, new_parents, &block)
				end
			}
		end
	end
	roots = model.select{|page| page.parent.nil? }.sort_by(&:position)
	tree_iterate(roots, path, [], &block)
end

tree_grow(dato.subpages, "source/_pages") do |branch, parents|
	{
		frontmatter: {
			id: branch.id,
			parents: parents,
			title: branch.title,
			heading: branch.heading,
			slug: branch.slug,
			seo: branch.seo,
			blurb: branch.blurb,
			image: defined?(branch.image.url) ? branch.image.to_hash.slice(:url, :alt, :title) : nil,
			links_heading: branch.links_heading,
			links: branch.links.map { |link|
				{
					title: link.title,
					blurb: link.blurb,
					link: link.id
				}
			},
			form: defined?(branch.form.html) ? branch.form.to_hash.slice(:heading, :html) : nil,
			hidden: branch.hidden == $hidden[1] ? true : false
		},
		content: branch.body
	}
end
