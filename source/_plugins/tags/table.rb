module Jekyll
	class TableBlock < CustomBlock
		def output

			table = HTML::element('div')
			table['class'] = (@input ? 'table-' + @input : 'table')
			table.inner_html = @markdown.convert(@block)

			return table.to_html

		end
	end
end

Liquid::Template.register_tag('table', Jekyll::TableBlock)
