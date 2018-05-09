require 'jekyll'

module Jekyll
	class PageInfo < Generator
		safe true
		priority :highest

		def generate(site)
			@site = site

			sep = site.data['siteinfo']['seo']['separator'] || ''

			# Iterate over the _pages collection only
			site.collections['pages'].docs.each { |page|

				# Meta tags
				page.data['meta'] = {
					'title' => 'testtitle',
					'description' => 'testdesc'
				}

				# Home page?
				page.data['home'] = page.url == '/index'

			}

		end
	end
end
