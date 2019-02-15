module Transformer
	module Templates
		class Article < Template

			def slug(this, info, data, locale)
				data['slug']
			end

			def file(this, info, data, locale)
				{
					path: "_pages/#{locale}/articles/",
					name: this[:slug] + '.md',
					type: :markdown
				}
			end

			def metadata(this, info, data, locale)
				{
					reference: {
						image: data['image'],
						quoted: data.dial['sources'].call([]) { |sources|
							sources.map { |source|
								source.dial['source']['author'].call
							}.reject(&:blank?) if sources.is_a?(Array)
						}
					}
				}
			end

			def content(this, info, data, locale)
				#@write.with(Writers::Markdown)
				[
					Writers::Markdown.p(data['body'].to_s.truncate(50)),
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
				].reject(&:blank?).join("\n\n")
			end

		end
	end
end

Transformer::register_template('article', Transformer::Templates::Article)
