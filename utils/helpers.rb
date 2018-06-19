require 'nokogiri'
require 'addressable/uri'
#require 'uri'
require 'active_support/core_ext/string/inflections'
#require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/deep_merge'
require 'pp'
require 'kramdown'
require 'fileutils'

# UNIVERSAL FUNCTIONS

def expect(var, var_class = NilClass, var_def = nil)
	if var_class == NilClass
		if var.nil? || (var.is_a?(Enumerable) && var.empty?)
			ret = var_def
		else
			yield(ret) if block_given?
			ret = var
		end
	else
		if var.is_a? var_class
			ret = var
			if block_given?
				#puts "Returning block with a " + ret.class.to_s + " = '" + ret.to_s + "'"
				yield(ret)
			end
		else
			ret = var_def
		end
	end
	return ret
end

def present?(str, str_strip = true)
	if str.is_a? String
		if str_strip then str = str.strip end
		if str.length > 0
			return str
		end
	end
	return false
end

def key?(hash, hash_keys, hash_def = nil)
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

def between(num, bottom, top)
	if num > top then return top end
	if num < bottom then return bottom end
	return num
end

def matches(needle, haystack)
	 start_at = 0
	 matches  = []
	 while(m = haystack.match(needle, start_at))
		  matches.push(m)
		  start_at = m.end(0)
	 end
	 return matches
end

module URL
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


class HashTree < Hash
	def initialize
		super do |hash, key|
			hash[key] = HashTree.new
		end
	end
end

=begin
# SPECIALISED HELPERS

module StringHelpers

	def strip_html(str)
		raise 'Non string passed to strip_html().' unless str.is_a? String



	end

end



# CORE EXTENSION

class String
	def truncate(truncate_at, options = {})
		return dup unless length > truncate_at

		omission = options[:omission] || "..."
		length_with_room_for_omission = truncate_at - omission.length
		separator = options[:separator] || " "

		stop = \
			if separator.length > 0
				rindex(separator, length_with_room_for_omission) || length_with_room_for_omission
			else
				length_with_room_for_omission
			end

		"#{self[0, stop]}#{omission}"
	end
end
=end
