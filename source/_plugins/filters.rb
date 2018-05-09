require_relative "../../helpers"

module Jekyll

   module Helpers

		include Liquid::StandardFilters

		extend self # Make all methods (including those included above) statically available


      def imgify(content)
         formats = @context.registers[:site].data['images']
         params = []
         formats['body'].each do |k, v|
            params += [k.to_s + "=" + v.to_s]
         end
         params = params.join('&amp;')

         # Define function to return array of matches for Regex re in String s
         def matches(s, re)
             start_at = 0
             matches  = []
             while(m = s.match(re, start_at))
                 matches.push(m)
                 start_at = m.end(0)
             end
             return matches
         end

         regex_attrb_str = '\s+(?<k>[A-Za-z]+)(="(?<v>[^"]*)")?' # Pulls out substrings named k and v for attributes
         regex_attrb = Regexp.new(regex_attrb_str)
         regex_img = Regexp.new('<img(' + regex_attrb_str + ')+[\s\/]*>')

         image_tags = []
         images = matches(content, regex_img)
         images.each do |image| # For each image
            image_tag = "<img"
            matches(image[0], regex_attrb).each do |attrb| # For each of its attribute pairs
               if (attrb['k'] == 'src')
                  image_tag += " src=\"" + attrb['v'] + "?" + params + "\""
               end
               if (['alt', 'title'].include?(attrb['k']))
                  image_tag += " " + attrb['k'] + "=\"" + attrb['v'] + "\""
                  #content = content + "<p>Image #" + index.to_s + ": " + attrb['k'] + "=" + attrb['v'] + "</p>"
               end
            end
            image_tag+= ' hspace="0" vspace="0" border="0" />'
            content = content.sub(image[0], image_tag) # For each tag found, swap it with newly written tag
         end

         return content

      end

      def split_newlines(content)
         unless (content == nil)
            content.split(/[\n\r]+/)
         end
      end

      def inlinify(content)
         unless (content == nil)
            content = self.split_newlines(content)
            content.each{ |s| s.strip }.join(' ')
         end
      end

      def markdownify_inline(content)
         unless (content == nil)
            m = ['{inline}', '{/inline}']
            #content = content.gsub(/^(#+|)/, '')
            content = m[0] + self.inlinify(content) + m[1]
            content = @context.registers[:site].find_converter_instance(Jekyll::Converters::Markdown).convert(content)
            content = self.inlinify(content)
            content.gsub(Regexp.new('(^(<p>)?' + Regexp.escape(m[0]) + '|' + Regexp.escape(m[1]) + '(<\/p>)?$)'),'')
         end
      end

   end
end

Liquid::Template.register_filter(Jekyll::Helpers)
