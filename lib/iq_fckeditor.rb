require 'iq_fckeditor/version'
require 'iq_fckeditor/engine'

# -*- encoding : utf-8 -*-
module IqFckeditor

  cattr_accessor :default_uploads_base_path

  # Include as InstanceMethods into the acts_as_fckeditor_file_provider
  module Controller
    #accepted MIME types for upload
    MIME_TYPES = [
      "image/jpeg",
      "image/pjpeg",
      "image/gif",
      "image/png",
      "application/pdf",
      "application/zip",
      "application/x-shockwave-flash",
      "application/octet-stream" #TODO: Muss weg!
    ]

    # Generates a config providing urls for the plugin. This is the hook to
    # provide different fck configs for different resources
    def fckeditor_custom_config
      respond_to do |format|
        @command_url = self.fckeditor_command_action_url || url_for_action("fckeditor_command")
        format.js do
          render :template => 'iq_fckeditor/custom_config', :layout => false
        end
      end
    end

    # Accessor to the uploaded files. E.g. an image will have the path:
    #   <controller resource path>/fckeditor_file?file=<path and filename>
    def fckeditor_file
      if (params[:file])
        dir, url_to_dir = fckeditor_base_dir_and_url
        path = append_path dir, params[:file]
        if FileTest.file?(path)
          if (params[:thumb] =~ /^[1-9][0-9][0-9]?$/) # 10 - 999
            ext = File.extname(path)
            thumb_path = File.join(File.dirname(path), '.thumbs', File.basename(path, ext)) + ".#{params[:thumb]}#{ext}"
            if !(FileTest.file?(thumb_path))
              FileUtils.mkdir(File.dirname(thumb_path)) unless File.directory?(File.dirname(thumb_path))
              tmp = Paperclip::Thumbnail.new(File.new(path), :geometry => "#{params[:thumb]}x#{params[:thumb]}>").make
              FileUtils.mv(tmp.path, thumb_path)
              tmp.unlink
            end
            path = thumb_path
          end
          if stale?(:last_modified => File.mtime(path).utc)
            if stale?(:etag => Digest::MD5.hexdigest(File.read(path))) #Only calc checksum if :last_modified 'failes'
              send_file(path, :type => Mime::Type.lookup_by_extension(File.extname(path)), :disposition => 'inline') #Finally send the file
            end
          end
        else
          head 404
        end
      else
        head 404
      end
    end

    # This is a resource based variant of fckeditor_command?Command=GetFoldersAndFiles
    def fckeditor_directory
      respond_to do |format|
        format.xml do
          fckeditor_get_folders_and_files(true)
        end
      end
    end

    # Executes some server side commands the js client side calls:
    #   GetFoldersAndFiles, GetFolders (2.times{GET})
    #   CreateFolder (GET)
    #   FileUpload (POST)
    # These operations are addessed by parameters:
    #   fckeditor_command?Command=<command>
    # I found no way to configure this in the FCK javascriptside. Also the GETs
    # on modifications realy suck. If you find a way to modify this: please tell
    # me how you did it.
    def fckeditor_command
      case params[:Command]
      when 'GetFoldersAndFiles', 'GetFolders'
        respond_to do |format|
          format.xml do
            fckeditor_get_folders_and_files(params[:Command] == 'GetFoldersAndFiles')
          end
        end
      when 'CreateFolder'
        respond_to do |format|
          format.xml do
            fckeditor_create_folder
          end
        end
      when 'FileUpload'
        respond_to do |format|
          format.html do
            fckeditor_upload
          end
        end
      else
        if (params[:NewFile])
          fckeditor_upload
        else
          head 404
        end
      end
    end

    protected

    def url_for_action(action = nil)
      path = ((ActionController::Base::relative_url_root || "") + request.path).split('/')
      path.pop
      path << action.to_s if action
      path.join('/')
    end

    def self.included(klass)
      class << klass
        # Some Configurtion Parameters
        cattr_accessor :fckeditor_file_action_url

        cattr_accessor :fckeditor_command_action_url


        cattr_accessor :fckeditor_uploads_base_path
        # This will default to IqFckeditor.default_uploads_base_path

        cattr_accessor :fckeditor_uploads_base_url
        self.fckeditor_uploads_base_url = ":fckeditor_file_action_url?file="
      end
      #TODO: geht das besser?
      klass.protect_from_forgery :except => [:fckeditor_command]
    end

    # This method returns the real base directory of this request and the path
    # for the url used by the clients later. This two strings are prefixed to
    # the path given by the fck javascriptside:
    #   <path on the server filesystem>: <base dir> + <fck path>
    #   <url>: http://<servername>/<base url> + <fck path>
    def fckeditor_base_dir_and_url
      resource_path = url_for_action(nil)
      dir = (self.class.fckeditor_uploads_base_path || IqFckeditor.default_uploads_base_path).gsub(/:resource_path/, resource_path)
      FileUtils.mkdir_p(dir)
      url = self.class.fckeditor_uploads_base_url.gsub(/:resource_path/, resource_path).gsub(/:fckeditor_file_action_url/, self.class.fckeditor_file_action_url || url_for_action("fckeditor_file"))
      return [dir, url]
    end

    # Appends a path to a given base directory and verifies that the result is
    # in the base path (think about ''../bla'').
    def append_path base_dir, path
      res = File.expand_path(File.join(base_dir, path)).to_s
      if res.index(File.expand_path(base_dir).to_s) == 0 # ok
        res
      else
        File.expand_path(base_dir + path)
      end
    end

    # This renders a XML file for the FCK client providing the folders (and
    # files) in the directory given by 'CurrentFolder'.
    def fckeditor_get_folders_and_files(include_files = true)
      @folders = []
      @files = {}
      dir, @url_to_dir = fckeditor_base_dir_and_url
      @current_folder = params[:CurrentFolder] || '/'
      @url_to_dir += @current_folder # Complete URL path to this directory
      dir = append_path(dir, @current_folder) + "/" #Complete 'local' path to this directory
      Dir.entries(dir).each do |entry|
        next if entry =~ /^\./
        path = dir + entry
        if FileTest.directory?(path)
          @folders.push entry
        elsif (include_files and FileTest.file?(path))
          @files[entry] = (File.size(path) / 1024)
        end
      end
      render :template => 'iq_fckeditor/file_listing.xml', :layout => false
    end

    # Creates a folder given by 'NewFolderName' under 'CurrentFolder' and
    # returns a XML to the FCK client.
    def fckeditor_create_folder
      begin
        dir, @url_to_dir = fckeditor_base_dir_and_url
        dir = append_path(dir, params[:CurrentFolder]) + "/"
        @current_folder = params[:CurrentFolder] + params[:NewFolderName]
        new_path = dir + params[:NewFolderName]
        if !(File.stat(dir).writable?)
          @error_number = 103
          #elsif params[:CurrentFolder] !~ /[\w\d\s]+/
          #  @errorNumber = 102
        elsif FileTest.exists?(new_path)
          @error_number = 101
        else
          Dir.mkdir(new_path, 0775)
          @new_folder = params[:NewFolderName]
          @error_number = 0
        end
      rescue => e
        logger.error(e)
        @error_number = 110 if @error_number.nil?
      end
      render :template => 'iq_fckeditor/file_listing.xml', :layout => false
    end

    # Moves an uploaded file to it's final destination on the server and returns
    # a javascript encapsulated into HTML to fck client.
    def fckeditor_upload
      begin
        ftype = params[:NewFile].content_type.strip
        if ! MIME_TYPES.include?(ftype)
          @error_number = 202
          raise "#{ftype} is invalid MIME type"
        else
          dir, url_to_dir = fckeditor_base_dir_and_url
          dir = append_path(dir, (params[:CurrentFolder] ? params[:CurrentFolder] : "/")) + "/"
          @file_name = params[:NewFile].original_filename
          full_file_name = dir + @file_name
          @file_url = url_to_dir + (params[:CurrentFolder] ? params[:CurrentFolder] : "/") + @file_name
          File.open(full_file_name,"wb",0664) do |fp|
            FileUtils.copy_stream(params[:NewFile], fp)
          end
          @error_number = 0
        end
      rescue => e
        logger.error(e)
        @error_number = 110 if @error_number.nil?
      end
      render :template => 'iq_fckeditor/file_uploaded.html', :layout => false
    end

  end
end
