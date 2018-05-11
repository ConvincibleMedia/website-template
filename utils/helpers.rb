# UNIVERSAL FUNCTIONS

def expect(var, var_class = NilClass, var_def = nil)
	if var_class == NilClass
		if var.nil? || var.empty?
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
