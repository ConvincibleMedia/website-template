module Transformer
	module Templates
		class Article < Template

			def initialize
				super
			end

			def slug(from)
				@slug ||= from.to_s.strip
			end

			def file(id, meta, data, locale)
				{
					path: "_pages/#{locale}/articles/",
					name: slug(data['slug']), #+ '.md' - not required as Jekyll handler will ensure
					type: :markdown
				}
			end

			def frontmatter(id, meta, data, locale)
				{
					data: {
						image: data['image'],
						quoted: data.dial['sources'].call([]) { |sources|
							sources.map { |source|
								source.dial['source']['author'].call
							}.reject(&:nil?) if sources.is_a?(Array)
						}
					}
				}
			end

			def content(id, meta, data, locale)
				#@write.with(Writers::Markdown)
				[
					Writers::Markdown.p(data['body']),
					data.dial['sources'].call { |sources|
						Writers::Liquid.tag('contentfor', 'hero',
							Writers::Markdown.h('Sources', 2),
							Writers::Markdown.ol(data['sources'].map { |source|
								#source = source['source']
								Writers::Markdown.link(
									"<cite>" + source['source']['title'] + "</cite>" +
									(source['source']['author'].present? ? ", " + source['source']['author'] : ''),
									source['source']['url']
								)
							})
						)
					}
				]
			end

			def partials(id, meta, data, locale)
				nil
			end

		end
	end
end

Transformer::register_template('article', Transformer::Templates::Article)
