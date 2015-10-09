# based on the Rails Plugin

module Heroku
  class Plugin
    include Heroku::Helpers
    extend Heroku::Helpers

    class ErrorUpdatingSymlinkPlugin < StandardError; end

    DEPRECATED_PLUGINS = %w(
      heroku-addon-attachments
      heroku-cedar
      heroku-certs
      heroku-credentials
      heroku-dyno-size
      heroku-dyno-types
      heroku-fork
      heroku-kill
      heroku-labs
      heroku-logging
      heroku-netrc
      heroku-orgs
      heroku-pgdumps
      heroku-postgresql
      heroku-push
      heroku-releases
      heroku-shared-postgresql
      heroku-sql-console
      heroku-status
      heroku-stop
      heroku-suggest
      heroku-symbol
      heroku-two-factor
      pgbackups-automate
      pgcmd
    )

    attr_reader :name, :uri

    def self.directory
      File.expand_path("#{home_directory}/.heroku/plugins")
    end

    def self.list
      Dir["#{directory}/*"].sort.map do |folder|
        File.basename(folder)
      end
    end

    def self.load!
      list.each do |plugin|
        check_for_deprecation(plugin)
        next if skip_plugins.include?(plugin)
        load_plugin(plugin)
      end
    end

    def self.load_plugin(plugin)
      begin
        folder = "#{self.directory}/#{plugin}"
        $: << "#{folder}/lib"    if File.directory? "#{folder}/lib"
        load "#{folder}/init.rb" if File.exists?  "#{folder}/init.rb"
      rescue ScriptError, StandardError => error
        styled_error(error, "Unable to load plugin #{plugin}.")
        action("Updating #{plugin}") do
          begin
            Heroku::Plugin.new(plugin).update
          rescue => e
            $stderr.puts(format_with_bang(e.to_s))
          end
        end
        false
      end
    end

    def self.remove_plugin(plugin)
      FileUtils.rm_rf("#{self.directory}/#{plugin}")
    end

    def self.check_for_deprecation(plugin)
      return unless STDIN.isatty

      if DEPRECATED_PLUGINS.include?(plugin)
        if confirm "The plugin #{plugin} has been deprecated. Would you like to remove it? (y/N)"
          remove_plugin(plugin)
        end
      end
    end

    def self.skip_plugins
      @skip_plugins ||= ENV["SKIP_PLUGINS"].to_s.split(/[ ,]/)
    end

    def initialize(uri)
      @uri = uri
      guess_name(uri)
    end

    def to_s
      name
    end

    def path
      "#{self.class.directory}/#{name}"
    end

    def install
      if File.directory?(path)
        uninstall
      end
      FileUtils.mkdir_p(self.class.directory)
      Dir.chdir(self.class.directory) do
        git("clone #{uri}")
        unless $?.success?
          FileUtils.rm_rf path
          return false
        end
      end
      true
    end

    def uninstall
      ensure_plugin_exists
      FileUtils.rm_r(path)
    end

    def update
      ensure_plugin_exists
      if File.symlink?(path)
        raise Heroku::Plugin::ErrorUpdatingSymlinkPlugin
      else
        Dir.chdir(path) do
          unless git('config --get branch.master.remote').empty?
            message = git("pull")
            unless $?.success?
              raise "Unable to update #{name}.\n" + message
            end
          else
            raise <<-ERROR
#{name} is a legacy plugin installation.
Enable updating by reinstalling with `heroku plugins:install`.
ERROR
          end
        end
      end
    end

    private

    def ensure_plugin_exists
      unless File.directory?(path)
        error("#{name} plugin not found.")
      end
    end

    def guess_name(url)
      @name = File.basename(url)
      @name = File.basename(File.dirname(url)) if @name.empty?
      @name.gsub!(/\.git$/, '') if @name =~ /\.git$/
    end

  end
end
