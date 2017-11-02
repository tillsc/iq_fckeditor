# -*- encoding : utf-8 -*-
require((File.dirname(__FILE__) + "/../../lib/iq_fckeditor"))

class SimpleFckUploadController < ActionController::Base

  include(IqFckeditor::Controller)
  
  # # You can modify where the uploads should go to and from which url they are
  # # accessible from the web. Paste, uncomment and modify some of the following
  # # lines in your environment.rb or whereever you want them to place.
  #
  # SimpleFckUploadController.fckeditor_command_action_url = fubar_url()
  #
  # # Use this plugin as File-Uploader only
  # SimpleFckUploadController.fckeditor_uploads_base_path = "#{RAILS_ROOT}/public/uploads"
  # SimpleFckUploadController.fckeditor_uploads_base_url = "http://www.example.com/uploads" # or just "/uploads"
  #
  # # If you want to use This controller as FileProvider leave
  # fckeditor_uploads_base_url as it is and only set the following if you don't
  # use map.resource for this controller (then it will determine the url
  # automatically).
  # SimpleFckUploadController.fckeditor_file_action_url = foo_bar_path()

end
