module Transformer
	module Templates
		class Blockquote < StructTemplate

			def render(data)
				Writers::Markdown.blockquote(
					data['quote'],
					data['author']
				)
			end

		end
	end
end

Transformer::register_struct('blockquote', Transformer::Templates::Blockquote)
