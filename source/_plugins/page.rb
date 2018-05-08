require 'jekyll'

module Jekyll
	class PageInfo < Generator
		safe true
		priority :highest

		def generate(site)
			@site = site

			sep = site.data['siteinfo']['seo']['separator'] || ''

			site.pages.each { |page|

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
