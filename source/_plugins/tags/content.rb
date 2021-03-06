module Jekyll

	module ContentPlugin

		def content_for_block(context)
			context.environments.first['contentblocks'] ||= {}
			context.environments.first['contentblocks'][@path] ||= {}
			context.environments.first['contentblocks'][@path][@args] ||= []
		end

	end

	module Tags

		class ContentForBlock < CustomBlock
			include Jekyll::ContentPlugin

			def output(_args, _block)
				content_for_block(@context) << _block.dup
				return ''
			end

		end


		class ContentTag < CustomTag
			include Jekyll::ContentPlugin

			def output(_args)
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
