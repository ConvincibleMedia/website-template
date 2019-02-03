module Transformer
	module Templates
		class Page < Template

			def initialize
				super
			end

			def file(id, meta, data, locale)
				{
					path: "_pages/#{locale}/",
					name: slug(data['slug']), #+ '.md' - not required as Jekyll handler will ensure
					type: :markdown
				}
			end

			def frontmatter(id, meta, data, locale)
				demand(data['publish_date']) { |e| frontmatter['date'] = e }
			end

			def content(id, meta, data, locale)
				md_p(data['text'])
			end

		end
	end
end

Transformer::register_template('page', Transformer::Templates::Page)
