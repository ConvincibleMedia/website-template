module Transformer
	module Templates
		class Related < StructTemplate

			def render(data)
				Writers::Markdown.p(
					'Article: ' + data['article'].to_s,
					'Location: ' + data['location'].to_s
				)
			end

		end
	end
end

Transformer::register_struct('related', Transformer::Templates::Related)
