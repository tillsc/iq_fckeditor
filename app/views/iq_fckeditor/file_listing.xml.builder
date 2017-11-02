xml.instruct!
#=> <?xml version="1.0" encoding="utf-8" ?>
xml.Connector("command" => params[:Command], "resourceType" => 'File') do
  xml.CurrentFolder("url" => @url_to_dir, "path" => params[:CurrentFolder])
  if @folders
    xml.Folders do
      @folders.each do |folder|
        xml.Folder("name" => folder)
      end
    end
  end
  if @files
    xml.Files do
      @files.keys.sort.each do |f|
        xml.File("name" => f, "size" => @files[f])
      end
    end
  end
  xml.NewFolder(:name => @new_folder) if @new_folder
  xml.Error("number" => @error_number) if @error_number
end