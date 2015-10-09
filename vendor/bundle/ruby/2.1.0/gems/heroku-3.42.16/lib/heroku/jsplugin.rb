require 'rbconfig'

class Heroku::JSPlugin
  extend Heroku::Helpers

  def self.try_takeover(command, args)
    if command == 'help' && args.length > 0
      return help(find_command(args[0]))
    elsif args.include?('--help') || args.include?('-h')
      return help(find_command(command))
    end
    command = find_command(command)
    return if !command || command["hidden"]
    run(ARGV[0], nil, ARGV[1..-1])
  end

  def self.load!
    this = self
    topics.each do |topic|
      Heroku::Command.register_namespace(
        :name => topic['name'],
        :description => " #{topic['description']}"
      ) unless topic['hidden'] || Heroku::Command.namespaces.include?(topic['name'])
    end
    commands.each do |plugin|
      help = "\n\n  #{plugin['fullHelp']}"
      klass = Class.new do
        def initialize(args, opts)
          @args = args
          @opts = opts
        end
      end
      klass.send(:define_method, :run) do
        this.run(plugin['topic'], plugin['command'], ARGV[1..-1])
      end
      Heroku::Command.register_command(
        :command   => plugin['command'] ? "#{plugin['topic']}:#{plugin['command']}" : plugin['topic'],
        :namespace => plugin['topic'],
        :klass     => klass,
        :method    => :run,
        :banner    => plugin['usage'],
        :summary   => " #{plugin['description']}",
        :help      => help,
        :hidden    => plugin['hidden'],
      )
      if plugin['default']
        Heroku::Command.register_command(
          :command   => plugin['topic'],
          :namespace => plugin['topic'],
          :klass     => klass,
          :method    => :run,
          :banner    => plugin['usage'],
          :summary   => " #{plugin['description']}",
          :help      => help,
          :hidden    => plugin['hidden'],
        )
      end
    end
  end

  def self.plugins
    @plugins ||= `"#{bin}" plugins`.lines.map do |line|
      name, version = line.split
      { :name => name, :version => version }
    end
  end

  def self.is_plugin_installed?(name)
    plugins.any? { |p| p[:name] == name }
  end

  def self.topics
    commands_info['topics']
  end

  def self.commands
    commands_info['commands']
  end

  def self.commands_info
    @commands_info ||= begin
                         info = json_decode(`"#{bin}" commands --json`)
                         error "error getting commands #{$?}" if $? != 0
                         info
                       end
  end

  def self.install(name, opts={})
    system "\"#{bin}\" plugins:install #{name}" if opts[:force] || !self.is_plugin_installed?(name)
    error "error installing plugin #{name}" if $? != 0
  end

  def self.uninstall(name)
    system "\"#{bin}\" plugins:uninstall #{name}"
  end

  def self.update
    system "\"#{bin}\" update"
  end

  def self.version
    `"#{bin}" version`
  end

  def self.app_dir
    if windows? && ENV['LOCALAPPDATA']
      File.join(ENV['LOCALAPPDATA'], 'heroku')
    else
      File.join(Heroku::Helpers.home_directory, '.heroku')
    end
  end

  def self.bin
    File.join(app_dir, windows? ? 'heroku-cli.exe' : 'heroku-cli')
  end

  def self.setup
    check_if_old
    return if setup?
    require 'excon'
    $stderr.print "Installing Heroku Toolbelt v4..."
    FileUtils.mkdir_p File.dirname(bin)
    copy_ca_cert
    opts = excon_opts.merge(:middlewares => Excon.defaults[:middlewares] + [Excon::Middleware::Decompress])
    resp = Excon.get(url, opts)
    open(bin, "wb") do |file|
      file.write(resp.body)
    end
    File.chmod(0755, bin)
    if Digest::SHA1.file(bin).hexdigest != manifest['builds'][os][arch]['sha1']
      File.delete bin
      raise 'SHA mismatch for heroku-cli'
    end
    $stderr.puts " done.\nFor more information on Toolbelt v4: https://github.com/heroku/heroku-cli"
    version
  end

  def self.setup?
    File.exist? bin
  end

  def self.copy_ca_cert
    to = File.join(app_dir, "cacert.pem")
    return if File.exists?(to)
    from = File.expand_path("../../../data/cacert.pem", __FILE__)
    FileUtils.copy(from, to)
  end

  def self.run(topic, command, args)
    cmd = command ? "#{topic}:#{command}" : topic
    exec self.bin, cmd, *args
  end

  def self.arch
    case RbConfig::CONFIG['host_cpu']
    when /x86_64/
      "amd64"
    when /arm/
      "arm"
    else
      "386"
    end
  end

  def self.os
    case RbConfig::CONFIG['host_os']
    when /darwin|mac os/
      "darwin"
    when /linux/
      "linux"
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      "windows"
    when /openbsd/
      "openbsd"
    when /freebsd/
      "freebsd"
    else
      raise "unsupported on #{RbConfig::CONFIG['host_os']}"
    end
  end

  def self.manifest
    @manifest ||= JSON.parse(Excon.get("https://cli-assets.heroku.com/master/manifest.json", excon_opts).body)
  end

  def self.excon_opts
    if windows? || ENV['HEROKU_SSL_VERIFY'] == 'disable'
      # S3 SSL downloads do not work from ruby in Windows
      {:ssl_verify_peer => false}
    else
      {}
    end
  end

  def self.url
    manifest['builds'][os][arch]['url'] + ".gz"
  end

  def self.find_command(s)
    topic, cmd = s.split(':', 2)
    if cmd
      commands.find { |t| t["topic"] == topic && t["command"] == cmd }
    else
      commands.find { |t| t["topic"] == topic && (t["command"] == nil || t["default"]) }
    end
  end

  def self.help(cmd)
    return unless cmd
    puts "Usage: heroku #{cmd['usage']}\n\n#{cmd['description']}\n\n#{cmd['fullHelp']}"
    exit 0
  end

  # check if release is one that isn't able to update on windows
  def self.check_if_old
    File.delete(bin) if windows? && setup? && version.start_with?("heroku-cli/4.24")
  rescue => e
    Rollbar.error(e)
  rescue
  end

  def self.windows?
    os == 'windows'
  end
end
