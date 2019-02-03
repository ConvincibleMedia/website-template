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
					path: '_pages/',
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
				data['body']
				#md_p([
				#	md_html(data['body']),
				#	expect(data['sources']) { |sources|
				#		liquid_tag('contentfor', 'hero',
				#			md_h('Sources', 2),
				#			md_ol(data['sources'].map{ |source|
				#				md_link(
				#					"<cite>" + source['title'] + "</cite>" +
				#					(source['author'].present? ? ", " + source['author'] : ''),
				#					source['url'])
				#			})
				#		)
				#	}
				#])
			end

			def partials(id, meta, data, locale)
				nil
			end

		end
	end
end

Transformer::register_template('article', Transformer::Templates::Article)
