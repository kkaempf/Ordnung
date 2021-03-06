Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "sinatra/base"
require "sprockets"
require "haml"
require "json"
require "time"

require_relative "ordnung"

class App < Sinatra::Base
  set :environment, Sprockets::Environment.new
  environment.append_path "assets/stylesheets"
  environment.append_path "assets/javascripts"

  ROOT_PATH = File.join(File.expand_path("..", File.dirname(__FILE__)))
  self.set :root, File.join(ROOT_PATH, "lib")
  set :public_folder, File.join(ROOT_PATH, "public")
  set :views, File.join(ROOT_PATH, "views")
  set :bind, "0.0.0.0"
  set :port, Ordnung::Config["port"] || 4567
  theme = Ordnung::Config["theme"] || "default"
end

class App < Sinatra::Base
  def initialize
    super
    @title = Ordnung::Config["title"] || "Ordnung"
    @theme_type = get_theme_type
    @colors = Ordnung.get_colors
    STDERR.puts "Starting server app #{ARGV.inspect}"
  end

  helpers do
    ### generic helpers

    def get_theme_type
      theme = Ordnung::Config["theme"] || "default"
      if ["cyborg", "darkly", "slate", "superhero"].include? theme
        "dark"
      else
        "light"
      end
    end

    def entry
      @entry ||= Ordnung.database.read(params[:id]) rescue halt(404)
    end
  end
end

class App < Sinatra::Base
  #
  # MAIN Routes
  #

  get "/" do
    haml :index
  end

  get "/assets/*" do
    env["PATH_INFO"].sub!("/assets", "")
    settings.environment.call(env)
  end

  get "/json/help" do
    routes = []
    App.each_route do |route|
      routes << {:route => route.path} if route.path.is_a? String
    end
    routes.uniq.to_json
  end

  get "/help" do
    haml :help
  end

  get "/error" do
    haml :error
  end

  get "/ordnung/index", provides: :json do
    begin
      items = Ordnung.database.index
      return items.to_json
    rescue Exception => e
      Ordnung.logger.error "Error getting index: #{e}"
      redirect to('/error'), e
    end
  end

  get "/ordnung/entry/:hash", provides: :json do
    begin
      entry = Ordnung.database.read params["hash"]
      return entry.to_json
    rescue Exception => e
      Ordnung.logger.error "Error getting entry (#{hash}): #{e}"
      redirect to('/error'), e
    end
  end
end
