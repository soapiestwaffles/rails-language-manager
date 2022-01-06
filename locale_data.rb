#!/usr/bin/env ruby

require "rubygems"
require "yaml"
require "find"

PRIMARY_LANGUAGE = 'en'

class LocaleData

	attr_reader :language_data, :locale_files_paths, :locale_file_path

	def initialize(path_to_language_files)
		# Instance variables
		@language_data = {}
		@_updates = false
		# Find and load all language files into memory
		@locale_file_paths = []
		@locale_file_path = File.absolute_path(path_to_language_files)
		Find.find(@locale_file_path) { |path| @locale_file_paths << path if path =~ /.*\.yml/ }
		
		@locale_file_paths.each {|path| load_locale_file(path) }
	end

	def reload!
		@language_data = nil
		@language_data = {}
		@locale_file_paths.each {|path| load_locale_file(path) }
	end

	def has_changes?
		return @_updates
	end

	def save  # save all changes made to disk
		destroy_existing_files
		write_locale_files
	end

	def languages
		l = []
		@language_data.each_key {|key| l << key}
		return l
	end

	def yaml_dump_language(lang)
		YAML::dump(@language_data[lang])
	end

	def subkeys_for_language(language, path=nil)
		current = @language_data[language]
		unless path.nil?
			p = parse_language_path(path)
			(0..(p.length-1)).each do |i|
					current = current[p[i]]
			end
		end
	
		return get_subkeys(current)
	end

	def has_subkeys_for_language(language, path=nil)
		sk = subkeys_for_language(language, path)
		sk.length > 0
	end

	def get_phrase(path, language_arr=nil)
		langs = nil
		if language_arr.nil?
			langs = self.languages   # all languges
		else
			langs = language_arr
		end
		
		p = parse_language_path(path)
		results = {}
		langs.each do |l|
			current = @language_data[l]
			(0..(p.length-1)).each do |i|
				unless current[p[i]].nil?
					current = current[p[i]] 
				else
					current = nil
					break
				end
			end
			results[l] = current unless current.class == Hash
		end

		return results
	end

	def set_phrase(language, path, new_phrase) 
		p = parse_language_path(path)
		current = @language_data[language]
		(0..(p.length-1)).each do |i|
			unless current[p[i]].nil?
				current = current[p[i]]
			else
				unless i == (p.length-1)
					current[p[i]] = {}
				else
					current[p[i]] = String.new()
				end
				current = current[p[i]]
			end
		end
		@_updates = true
		current.replace(new_phrase)
	end

	def phrases_by_language_and_path(language, path=nil)
		results = []
		current = @language_data[language]
		unless path.nil?
			p = parse_language_path(path)
			(0..(p.length-1)).each do |i|
				current = current[p[i]]
			end
		end

		current.each_key do |key|
			results << key.to_s unless current[key].class == Hash
		end

		return results
	end

	def has_missing_translations?(path)
		current_status = :none
		v = get_phrase(path).values
		current_status = :possible if v.length != v.uniq.length
		current_status = :missing if v.include?(nil) || v.include?("")
		return current_status
	end
  #---------------
	private

	def get_subkeys(h)
		subkeys = []
		h.each_key { |key| subkeys << key if h[key].class == Hash }
		return subkeys
	end

	def load_locale_file(file)
		lang_yaml = YAML::load(File.open(file))
		@language_data.merge!(lang_yaml)
		puts "Loaded file #{File.basename(file)}"
	end

	def parse_language_path(language_path)
		language_path.split('.')
	end

	def destroy_existing_files
		current_locale_files = []
		Find.find(@locale_file_path) { |path| current_locale_files << path if path =~ /.*\.yml/ }
		current_locale_files.each{|f| File.delete(f)}
	end

	def write_locale_files
		begin
			self.languages.each do |lang|
				file_to_write = File.join(@locale_file_path, "#{lang}.yml")
				writeme = { lang => @language_data[lang] }
				File.open(file_to_write, "w+") {|f| f.write(writeme.to_yaml)}
				puts "Wrote file #{file_to_write}"
			end
		rescue
			return false
		end
		return true
	end

end


# unless ARGV.length == 1
# 	puts "Please supply language file path."
# 	exit 0
# end

# ld = LocaleData.new(ARGV[0])
# puts "\n+----Valid languages ----+\n"
# puts ld.languages

