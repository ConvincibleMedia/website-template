require 'nokogiri'
require 'addressable/uri'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/deep_dup'
require 'kramdown'
require 'fileutils'
require 'i18n'

I18n.load_path << Dir['./utils/i18n/*.yml']

# Debug
DEBUG = false
require 'awesome_print' if DEBUG

# UNIVERSAL FUNCTIONS

=begin
def debug(msg, variable = (no_var = true; nil))
	puts msg
	ap variable unless no_var
end
=end

def expect(var, var_class = NilClass, var_def = nil)
	if var_class == NilClass
		if var.nil? || (var.is_a?(Enumerable) && var.empty?)
			ret = var_def
		else
			ret = var
			ret = yield(var) if block_given?
		end
	else
		if var.is_a? var_class
			ret = var
			if block_given?
				#puts "Returning block with a " + ret.class.to_s + " = '" + ret.to_s + "'"
				ret = yield(var)
			end
		else
			ret = var_def
		end
	end
	return ret
end

def expect_text(str, str_strip = true)
	if str.is_a? String
		if str_strip then str = str.strip end
		if str.length > 0
			return str
		end
	end
	return false
end

def expect_key(hash, hash_keys, hash_def = nil)
	if (hash.is_a? Hash) && !hash.empty?
		if hash_keys.is_a? Array
			key_exists = true
			hash_inner = hash
			hash_keys.each { |k|
				if (hash_inner.is_a? Hash) && (hash_inner.has_key?(k))
					hash_inner = hash_inner[k]
				else
					key_exists = false
					break
				end
			}
			if key_exists
				return hash_inner
			else
				return hash_def
			end
		else
			if (hash.has_key?(hash_keys))
				return hash[hash_keys]
			else
				return hash_def
			end
		end
	else
		return hash_def
	end
end

def t(key, scope, count = 1)
	return I18n.t(key, :scope => scope.join('.'), :count => count)
end

def matches(needle, haystack)
	 start_at = 0
	 matches = []
	 while (m = haystack.match(needle, start_at))
		  matches.push(m)
		  start_at = m.end(0)
	 end
	 return matches
end

require 'facets/string/squish'

PATH_UNSAFE = Regexp.new('[' + Regexp.escape('<>:"/\|?*') + ']')
PATH_SEP = '/'
def path(*paths)
	paths = paths.flatten.map{ |i| path_clean(i) }.reject(&:blank?).join(PATH_SEP)
	return paths + PATH_SEP
end
def path_clean(path)
	return path.to_s.split(PATH_SEP).map{ |i| i.gsub(PATH_UNSAFE, '').strip }.reject(&:blank?).join(PATH_SEP)
end

module URLs
	extend self

	def query_encode(q)
		return Addressable::URI.normalize_component(q, 'a-zA-Z0-9')
	end

	def query_decode(q)
		return Addressable::URI.unencode_component(q, String)
	end

	def parse(*uri)
		if uri.is_a? Array
			uri = uri.flatten.map{ |i| i.strip.chomp('/') }.reject(&:blank?).map{ |i| Addressable::URI.parse(i) }
			return uri.length > 0 ? Addressable::URI.join(*uri) : Addressable::URI.new
		else
			uri = uri.to_s.strip
			return uri.length > 0 ? Addressable::URI.parse(uri) : Addressable::URI.new
		end
	end

	def join(*uris)
		return Addressable::URI.join(*uris)
	end

end

module HTML
	extend self

	def attr_encode(a)
		a = a.to_s
		{
			'&' => '&amp;',
			'<' => '&lt;',
			'>' => '&gt;',
			'"' => '&quot;',
			"'" => '&apos;'
		}.each { |from, to|
			a = a.gsub(from, to)
		}
		return a
	end

	def element(e)
		return Nokogiri::XML::Node.new(e, Nokogiri::HTML::DocumentFragment.parse(''))
	end

end



# CORE EXTENSION
require 'boolean'

class String
	def strip_of(chars, num = 0)
		if self.length > 0
			if chars.is_a? Array then chars = chars.flatten end
			chars = chars.to_s
			if space = chars =~ /[\s\n\r]/
				chars = chars.gsub(/[\s\n\r]/, '')
			end
			chars = chars.split(//).uniq.join

			if (chars.length > 0 || space)

				char_class = '[' + Regexp.escape(chars) + (space ? '\s' : '') + ']'

				num = [num.to_i, 0].max
				if num == 0 then num = '' else num = num.to_s end
				r = char_class + "{1,#{num}}"

				sub!(Regexp.new('^' + r), '')
				sub!(Regexp.new(r + '$'), '')

			end
		end
		return self
	end
end


=begin
# SPECIALISED HELPERS

module StringHelpers

	def strip_html(str)
		raise 'Non string passed to strip_html().' unless str.is_a? String



	end

end
=end
