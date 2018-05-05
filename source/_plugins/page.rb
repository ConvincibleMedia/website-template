module Jekyll
  class PageInfo < Generator
    def generate(site)

      sep = site.data.siteinfo.seo.separator || ''

      @site = site
      site.pages.each do |page|

         # Meta tags
         page.data['meta'] = {
            title: 'test',
            description: 'testdesc'
         }

         # Home page?
         page.data['home'] = page.url == 'index.html'

      end

  end
end
