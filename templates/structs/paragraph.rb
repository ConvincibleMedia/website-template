module Transformer
	module Templates
		class Paragraph < StructTemplate

			def render(data)
				'Text = ' + data['text'].to_s
			end

		end
	end
end

Transformer::register_struct('paragraph', Transformer::Templates::Paragraph)
