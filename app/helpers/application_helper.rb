# -*- encoding : utf-8 -*-
module ApplicationHelper

  # Renders a text-field for the given object and method plus a FCK integration
  # for this field. The parameter ''fckeditor_custom_config_url'' should contain
  # the url of a (static) fckcustom_config.js or the url to a
  # ''fckeditor_custom_config'' action, given by
  # ''acts_as_fckeditor_file_provider'' to use file handling over the controller.
  # Valid ''fck_options'' are:
  #   width, hight: the dimensions for the fck control
  #   toolbarset: name of a toolbar set used. You can specify custom toolbar
  #     sets in the custom_config.js.erb file under 'app/views' in this plugin.
  #   base_path: a custom BasePath the fck editor should use
  def fckeditor( object_name, method_name, fckeditor_custom_config_url, fck_options = { }, options = { })
    # Try to get the value to be shown
    obj = instance_variable_get("@#{object_name}")
    value = (obj && obj.send(method_name.to_sym)) || ""
    id = (obj && "#{object_name}_#{obj.id}_#{method_name}_editor") || "#{object_name}_0_#{method_name}_editor"

    fck_options[:toolbarset] ||= fck_options[:toolbarSet] #Accept both styles

    render :partial => 'iq_fckeditor/fckeditor', :locals => {
      :v => "oFck#{id}", :object_name => object_name, :method_name => method_name,
      :custom_config_url => fckeditor_custom_config_url,
      :width => (fck_options[:width] && "'#{fck_options[:width] }'") || 'null',
      :height => (fck_options[:height] && "'#{fck_options[:height] }'") || 'null',
      :toolbarset => (fck_options[:toolbarset] && "'#{fck_options[:toolbarset] }'") || "'Default'",
      :value => value,
      :id => id,
      :base_path => (fck_options[:base_path]  && "'#{fck_options[:base_path] }'") || 'null'
    }
  end

end
