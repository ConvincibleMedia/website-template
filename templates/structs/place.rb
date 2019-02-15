module Transformer
	module Templates
		class Place < StructTemplate

			def render(data)
				Writers::Markdown.p(
					'We are opening on :' + data['opening'].to_s + '.',
					if data['featured']
						"It's gonna be huge!"
					end,
					"Check out our gallery:",
					data['gallery'].to_s
				)
			end

		end
	end
end

Transformer::register_struct('place', Transformer::Templates::Place)
