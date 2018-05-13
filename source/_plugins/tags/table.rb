class Table < Liquid::Block

	def initialize(tag_name, markup, tokens)
		super
		# tag_name = this tag's own name
		# markup = string passed with opening tag
		# tokens = options from Liquid
		# puts markup
	end

	def render(context)
		# calling `super` returns the content of the block
		table = context.registers[:site].find_converter_instance(Jekyll::Converters::Markdown).convert(super.to_s)
		return '<div class="table">' + table + '</div>'

	end

end

Liquid::Template.register_tag('table', Table)
