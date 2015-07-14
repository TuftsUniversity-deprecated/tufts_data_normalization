require 'tufts_data_normalization'
require 'rails'
module TuftsDataNormalization
  class Railtie < Rails::Railtie
    railtie_name :tufts_data_normalization

    rake_tasks do
      load "tasks/aah_data_normalization.rake"
      load "tasks/elections_data_normalization.rake"
      load "tasks/election_images_data_normalization.rake"
      load "tasks/perseus_data_normalization.rake"
      load "tasks/generic_dca_wo_created_by_normalization.rake"
      load "tasks/generic_dca_wo_created_by_wo_steward_normalization.rake"
      load "tasks/generic_dca_dl_normalization.rake"
      load "tasks/generic_dca_dl_with_embargo_normalization.rake"
      load "tasks/sample_object_normalization.rake"
      load "tasks/tisch_data_migration.rake"
      load "tasks/election_record_xml_export.rake"
      load "tasks/verify_dca_admin.rake"
      load "tasks/clean_up_audio_datastreams.rake"
      load "tasks/clean_up_access_xml.rake"
      load "tasks/member_of_analysis.rake"
      load "tasks/bibliographic_citation_audit.rake"
      load "tasks/remap_facpub_to_pdf.rake"
      load "tasks/remap_audio_text_to_audio.rake"
      load "tasks/remap_3ds_4ds.rake"
      load "tasks/drafts.rake"
    end
  end
end
