#!ruby -Ks

# require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '/../lib/'))
require 'snarl/snp'

# You may use Winamp plugin "File Runner" (gen_runner.dll)
# http://www.geocities.jp/nanasiya3/ext.html#WA-GEN-RUNNER
#
# "File Runner" Command: "fullpath_rubyw_with_quote"
# "File Runner" Parameter: "fullpath_winamp_nowplaying.rb_with_quote" quoted_params
# quoted_params => "%artist%||%album%||%title%||%tracknumber%||%year%||%genre%||%comment%||%filename%||%index%||icon=>:album"
# or
# quoted_params => "%artist%||%album%||%title%||%tracknumber%||%year%||%genre%||%comment%||%filename%||%index%||icon=>c:\icon.jpg"
# icon=>:album means icon=>"#{File.dirname(%filename%)}\#{%album%}.[jpg|gif|png|bmp]"
# icon=>:loose means icon=>"Dir.glob(#{File.dirname(%filename%)}\**.[jpg|gif|png|bmp])[0]"

# just run me, and you will get parameters infomation.
# See WinampNowPlaying#warn_paramerter_infomation_and_exit.
class WinampNowPlaying

  class MusicData
    WINAMPDATA_ORDER = %w(artist album title tracknumber year genre comment filename index iconinfo)
    def initialize(data)
      @data = data
    end

    def [](k) ; @data[k] ; end
    def []=(k, v) ; @data[k] = v ; end

    WINAMPDATA_ORDER.each do |mes|
      eval("def #{mes} ; self['#{mes}'] ; end; def #{mes}=(v) ; self['#{mes}']=v ; end")
    end
    def icon_value
      iconinfo.to_s.scan(/icon=>(.+?)\Z/).flatten[0]
    end

    def query
      WINAMPDATA_ORDER[0..-2].map do |e|
        s = self.__send__(e)
        if (s.nil? || s.empty?) then '' else s end
      end.join('||')
    end

    def to_s
      "#{query}||icon=>#{icon_value}"
    end

    def self.parse(argv)
      self.new(Hash[*WINAMPDATA_ORDER.zip(argv.join(" ").split(/\|\|/)).flatten])
    end
    def icon_mode
      case
      when /icon=>:album\Z/ =~ iconinfo then
        :album
      when /icon=>:loose\Z/ =~ iconinfo then
        :loose
      when /icon=>\Z|icon=>nil\Z|icon=>:default\Z/ =~ iconinfo then
        :default
      when iconinfo.nil? then
        :default
      else
        :user
      end
    end
  end

  ## Winamp data "icon=>xxxx"
  # icon=>:album
  #     use "#{@album}.{gif,png,jpg,bmp}" ,if none, go :default
  # icon=>:loose
  #     use "#{@album}.{gif,png,jpg,bmp}", if none, Dir.glob(*.{gif,png,jpg,bmp})[0] , or, go :default
  # icon=>:default
  #     use Snarl Setting (maybe Snarl facemark)
  # icon=>full_file_path_for_image
  #     use filepath for reading icon(i.e, C:\icon.jpg). separators are '\' or "/"
  # icon=>image_url
  #     access url and use it
  class Icon

    ICON_EXTNAME = %w(gif png jpg bmp jpeg)

    def initialize(d, strict = false)
      @d = d
      @albumdir = File.dirname(@d['filename']) #or Winamp %folder%
      @strict = strict
    end

    def expecting_jacketimages
      ICON_EXTNAME.map{|ext| File.join(@albumdir, "#{@d['album']}.#{ext}")}
    end

    def album_name_image
      expecting_jacketimages.find{|path| FileTest.file?(path)}
    end

    def albumdir_entries
      albumdir_glob = @albumdir.gsub(/\\/){'/'} + '/*'
      Dir.glob(albumdir_glob)
    end

    def is_image?(f)
      /#{ICON_EXTNAME.join('|')}/ =~ f
    end

    def altanative_image
      albumdir_entries.find{|file| is_image?(file)}
    end

    def user_image
      @d.icon_value
    end

    def icon
      # xxxx_image actually returns nil.
      case @d.icon_mode
      when :album   then album_name_image || nil
      when :loose   then album_name_image || altanative_image || nil
      when :default then nil
      when :user    then user_image || nil
      end
    end
  end
  
  def initialize(host, port, &block)
    warn_paramerter_infomation_and_exit if argv.empty?

    @host = host || '127.0.0.1'
    @port = port || 9887
    # The following applications are registered with Snarl:
    @app = "Winamp"
    # Notification classes:
    @class = "Now Playing"
    # Message "First Line"
    @title = "Winamp Now Playing:"
    @text = nil
    @icon = nil

    @log_output = File.join(ENV['HOME'], 'snarl_winamp.log.txt')
    @logger = defined?(Logger) ? Logger.new(@log_output) : nil
    @data = MusicData.parse(argv)

    yield(self) if block_given?
  end

  attr_writer :host, :app, :class, :title, :logger, :log_output, :text, :icon
  attr_reader :data

  def argv
    ARGV
  end

  def icon
    case
    when %w(default system none).include?(@icon.to_s) then nil
    when @icon.nil?                                   then Icon.new(@data).icon
    when %w(album).include?(@icon.to_s)               then Icon.new(@data).icon
    when @icon                                        then @icon
    end
  end

  def text
    # do not join with "\r\n"
    case
    when @text.kind_of?(Proc) then
      res = @text.call(self)
    when @text.kind_of?(String) then
      res = @text
    else
      res = [@data.title, "#{@data.artist}/#{@data.album}"].join("\n")
    end
    res
  end

  def show_message
    Snarl::SNP.open(@host, @port) do |c|
      c.logger = @logger if @logger
      c.register(@app)
      c.add_class(@class)
      c.notification(@title, text, icon, 8, @class)
    end
  end

  def warn_paramerter_infomation_and_exit
    require 'rbconfig'
    warn 'You may use Winamp plugin "File Runner" (gen_runner.dll)'
    warn 'http://www.geocities.jp/nanasiya3/ext.html#WA-GEN-RUNNER'
    warn ''

    # display path of rubyw.exe
    if Config::CONFIG.has_key?('rubyw_install_name')
      rubyw = File.join(Config::CONFIG['bindir'], Config::CONFIG['rubyw_install_name'])
      warn %Q{"#{rubyw}"}
    else
      warn "*** rubyw is missing? ***"
    end
    # display where_am_i and Winamp param
    me = File.expand_path(__FILE__)
    params = WinampNowPlaying::MusicData::WINAMPDATA_ORDER[0..-2].map{|e| "%#{e}%"}.join('||')
    param = "#{params}||icon=>:album"
    warn %Q{"#{me}" "#{param}"}
    exit(1)
  end
end

if $0 == __FILE__ then
  WinampNowPlaying.new(ENV['SNARL_HOST'], ENV['SNARL_PORT']) do |amp|
    ## The following applications are registered with Snarl: / nil default
    amp.app = "Winamp"
    ## Notification classes: /nil default
    amp.class = "Now Playing"
    ## Message "First Line" / nil default
    amp.title = "Winamp Now Playing:"
    ## Message Body / Proc is called, String is as-is, default is nil
    amp.text = lambda{|x| "#{x.data.title}\n#{x.data.artist}\n#{x.data.album}"}
    ## Message Icon / path is path, :default is Snarl Setting, nil is album
    ## when nil, if playing dir has "#{@album}.{gif,png,jpg,bmp}", use it as Message icon.
    # amp.icon = 'C:\icon.jpg'

    ## logger for SNP log output
    # require 'logger'
    # output_file = File.join(ENV['HOME'], 'winamp_nowplaying_log_for_rubyw.txt')
    # amp.logger = Logger.new(output_file)

    amp.show_message
  end
end
