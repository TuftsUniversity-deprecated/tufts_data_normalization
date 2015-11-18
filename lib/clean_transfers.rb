def clean_transfers(objects)
  objects.each do |obj|
    record = TuftsPdf.find(obj)
    label_filename = File.basename record.local_path_for('transferClosed')
    filename = record.local_path_for("Transfer.binary")
    dir = File.dirname(filename)
    FileUtils.rm(filename)

    if (Dir.entries(dir) - %w{ . .. }).empty?
      FileUtils.remove_dir(dir)
      puts "removing directory #{dir}"
    else
      puts "directory not empty #{dir}"
    end

    record.datastreams['Transfer.binary'].delete
    record.save

    ds_opts = {:label => label_filename, :control_group => 'E'}
    new_transfer_binary = record.create_datastream ActiveFedora::Datastream, 'Transfer.binary', ds_opts
    new_transfer_binary.controlGroup='E'
    new_transfer_binary.dsLabel = label_filename
    new_transfer_binary.mimeType = record.datastreams['transferClosed'].mimeType
    new_transfer_binary.dsLocation = record.datastreams['transferClosed'].dsLocation
    record.add_datastream new_transfer_binary
    record.save

    record.datastreams['transferClosed'].delete
    record.save

    record.datastreams['preservationClosed'].delete
    record.save
  end
end