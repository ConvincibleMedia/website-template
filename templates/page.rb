module Transformer
	module Templates
		class Page < Template

			def slug(this, info, data, locale)
				data['title']
			end

			def file(this, info, data, locale)
				{
					path: "_pages/#{locale}/" + slugs(info[:parents]),
					name: data['title'] + '.md',
					type: :markdown
				}
			end

			def metadata(this, info, data, locale)
				{
					published: data['publish_date']
				}
			end

			def content(this, info, data, locale)
				Writers::Markdown.p(
					structs(data['text'])
				)
			end

		end
	end
end

Transformer::register_template('page', Transformer::Templates::Page)
