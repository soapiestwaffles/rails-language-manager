require 'rubygems'
require 'sinatra'
require 'coffee-script'
require 'sass'
require 'slim'
require 'json'
# require 'compass'


require "./locale_data"

PATH_TO_LANGUAGE = File.dirname(__FILE__) + "/../some-rails-project/config/locales/"

module CompassInitializer
	def self.registered(app)
		require 'sass/plugin/rack'
		# Compass.configuration do |config|
		# 	config.project_path = File.dirname(__FILE__)
		# 	config.sass_dir = File.join('public', 'stylesheets', 'scss')
		# 	config.project_type = :stand_alone
		# 	config.http_path = "/"
		# 	config.css_dir = File.join('public', 'stylesheets')
		# 	config.images_dir = File.join('public', 'images')
		# 	config.javascripts_dir = File.join('public', 'javascripts')
		# end
		# Compass.configure_sass_plugin!
		# Compass.handle_configuration_change!
		app.use Sass::Plugin::Rack
	end
end

class CoffeeEngine < Sinatra::Base
	set :views, File.join(File.dirname(__FILE__), 'public', 'javascripts', 'coffee')

	get "/javascripts/*.js" do
		filename = params[:splat].first
		coffee filename.to_sym
	end

end

class SassEngine < Sinatra::Base
	set :views, File.join(File.dirname(__FILE__), 'public', 'stylesheets', 'scss')
	set :scss, {:style => :compact, :debug_info => false}
	# register CompassInitializer

	# Compass.configuration do |config|
	# 	config.project_path = File.dirname(__FILE__)
	# 	config.sass_dir = File.join('public', 'stylesheets', 'scss')
	# end

	get "/stylesheets/*.css" do
		content_type 'text/css', :charset => 'utf-8'
		filename = params[:splat].first
		scss filename.to_sym, Compass.sass_engine_options
	end
end

class LanguageManager < Sinatra::Base

	use CoffeeEngine
	use SassEngine

	use Rack::Session::Pool, :expire_after => 2592000 # Configure sessions to use memory pool instead of cookie storage
	set :session_secret, 'thisdoesntmattercause'

	puts "Path to language files: #{PATH_TO_LANGUAGE}"
	
	# Set up our language data variable for each hit
	before do
		pass if request.path_info == '/'   # skip if we're at the root
		@language_data = session[:language_data] # sets up the global language processing variable
	end

	get '/' do
		session.clear    # Make sure our session is fresh
		@language_data = LocaleData.new(PATH_TO_LANGUAGE)
		session[:language_data] = @language_data

		@languages = @language_data.languages
		slim :index	
	end

	get '/update_phrases/?:node?/list.html' do
		@phrases = @language_data.phrases_by_language_and_path('en', params[:node]).sort
		@phrase_path = params[:node].nil? ? "" : "#{params[:node]}."
		slim :phrases_list, layout: false
	end

	get '/phrase/:node/data.json' do
		content_type :json
		@language_data.get_phrase(params[:node]).to_json
	end

	get '/update_folders/root.html' do # update root folder list
		@top_level_keys = @language_data.subkeys_for_language('en')
		slim :keys_box_top, layout: false
	end

	get '/update_folders/:node/list.html' do
		@path = params[:node]
		@keys = @language_data.subkeys_for_language('en', @path)
		slim :sub_keys_box, layout: false
	end

	post '/alter_phrase/:language/:path.json' do
		content_type :json
		l 			= params[:language]
		p 			= params[:path]
		phrase 	= params[:phrase]
		if @language_data.set_phrase(l, p, phrase)
			return {:success => true, :path => p, :phrase => phrase}.to_json 
		end

		{ :success => false }.to_json
	end

	post '/add_phrase/:path/create.json' do
		content_type :json
		path 				= params[:path]
		name 				= params[:name]
		phrase_path = nil

		if path == "__ROOT__"
			phrase_path = name
		else
			phrase_path = "#{path}.#{name}"
		end

		if @language_data.set_phrase("en", phrase_path, "")
			return {:success => true, :phrase => phrase_path, :path => path}.to_json
		end

		{:success => false }.to_json
	end

	post '/mass_update/:path.json' do
		content_type :json
		phrases = params[:phrases]
		path    = params[:path]

		success = true
		phrases.each do |k,v|
			unless @language_data.set_phrase(k, path, v)
				success = false
			end
		end

		return {:success => success, :path => path}.to_json
	end

	get '/savedata.json' do  # write the data to disk
		return {:success => @language_data.save()}.to_json
	end

	not_found do
		'The page you are trying to access is not found.'
	end

	private

	def name_for_lang(lang)
		names = {
			'ch' => "Chinese",
			'en' => "English",
			'es' => "Spanish",
			'jp' => "Japanese",
			'ko' => "Korean",
			'tl' => "Tagalog",
			'vi' => "Vietnamese"
		}

		name = lang
		name = names[lang] unless names[lang].nil?

		return name
	end

end
