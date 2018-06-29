module Jekyll
	class GalleryBlock < CustomBlock
		def output(_args, _block)

			return @block

		end
	end
end

Liquid::Template.register_tag('gallery', Jekyll::GalleryBlock)
