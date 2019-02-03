module Transformer
	module Templates
		class Home < Template

			def initialize
				super
			end

			def file(id, meta, data, locale)
				{
					path: "_pages/#{locale}/",
					name: 'index', #+ '.md' - not required as Jekyll handler will ensure
					type: :markdown
				}
			end

			def frontmatter(id, meta, data, locale)
				{
					KEY_TITLE => 'Home',
					KEY_SLUG => 'index',
					'seo' => {
						'title' => expect_key(data, ['seo','title']),
						'description' => expect_key(data, ['seo','description']),
						'image' => expect_key(data, ['seo','image'])
					},
					'features' => ['form']
				}
			end

			def content(id, meta, data, locale)
				md_p([
					data['intro'],
					liquid_tag(
						'video',
						[expect_key(data,['video','provider']), expect_key(data,['video','provider_uid'])],
						md_link(md_img(expect_key(data,['video','title']), expect_key(data,['video','thumbnail_url'])), expect_key(data,['video','url']))
					),
					md_partial('form.html')
				])
			end

			def partials(id, meta, data, locale)
				{
					'form.html' => data['form']
				}
			end

		end
	end
end

Transformer::register_template('home', Transformer::Templates::Home)
