require 'tufts_data_normalization'
require 'rails'
module TuftsDataNormalization
  class Railtie < Rails::Railtie
    railtie_name :tufts_data_normalization

    rake_tasks do
      load "tasks/aah_data_normalization.rake"
      load "tasks/elections_data_normalization.rake"

    end
  end
end
