module Transformer
	module Templates
		class Home < Template

			def slug(this, info, data, locale)
				'index'
			end

			def file(this, info, data, locale)
				{
					path: "_pages/#{locale}/",
					name: 'index' + '.md',
					type: :markdown
				}
			end

			def metadata(this, info, data, locale)
				{
					'title' => 'Home',
					'slug' => 'index',
					'seo' => {
						'title' => data.dial['seo']['title'].call,
						'description' => data.dial['seo']['description'].call,
						'image' => data.dial['seo']['image'].call
					},
					'features' => ['form']
				}
			end

			def content(this, info, data, locale)
				Writers::Markdown.p([
					data['intro'],
					Writers::Liquid.tag(
						'video',
						[
							data.dial['video']['provider'].call,
							data.dial['video']['provider_uid'].call
						],
						Writers::Markdown.link(
							Writers::Markdown.img(
								data.dial['video']['title'].call,
								data.dial['video']['thumbnail_url'].call
							),
							data.dial['video']['url'].call
						)
					),
					Writers::Liquid.partial(this[:slug] + '_form.html')
				])
			end

		end
	end
end

Transformer::register_template('home', Transformer::Templates::Home)
