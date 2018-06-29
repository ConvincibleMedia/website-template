module Jekyll
	class TableBlock < CustomBlock
		def output(_args, _block)

			table = HTML::element('div')
			table['class'] = (@args ? 'table-' + @args : 'table')
			table.inner_html = @markdown.convert(@block)

			return table.to_html

		end
	end
end

Liquid::Template.register_tag('table', Jekyll::TableBlock)
