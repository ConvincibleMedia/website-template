module Jekyll
	class GalleryBlock < CustomBlock
		def output

			return @block

		end
	end
end

Liquid::Template.register_tag('gallery', Jekyll::GalleryBlock)
