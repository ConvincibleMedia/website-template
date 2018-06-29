module Jekyll
	class IncludeSpecialBlock < CustomBlock

		def output(_args, _block)

			features(_block)
			# include features.html with result

		end

		def features(_block)
			return {}
		end

	end
end

Liquid::Template.register_tag('include_special', Jekyll::IncludeSpecialBlock)
