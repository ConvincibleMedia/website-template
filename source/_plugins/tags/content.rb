module Jekyll

	module ContentPlugin

		def content_for_block(context)
			page = context.environments.first['page']['path']
			context.environments.first['contentblocks'] ||= {}
			context.environments.first['contentblocks'][page] ||= {}
			context.environments.first['contentblocks'][page][@input] ||= []
		end

	end

	module Tags

		class ContentForBlock < CustomBlock
			include Jekyll::ContentPlugin

			def output
				content_for_block(@context) << @block
				return ''
			end

		end


		class ContentTag < CustomTag
			include Jekyll::ContentPlugin

			def output
				content = []
				content << @markdown.convert(content_for_block(@context).join("\n"))
				content.push('<!--' + @liquid[1] + '-->')
				content.unshift('<!--' + @liquid[0] + '-->')
				return content.join("\n")
			end

		end

	end

end

Liquid::Template.register_tag('contentfor', Jekyll::Tags::ContentForBlock)
Liquid::Template.register_tag('content', Jekyll::Tags::ContentTag)
