# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Converts an ActiveRecord record to FileMaker-compatible attributes
  # This method should be overridden in each model that syncs to FileMaker
  # @param record [ActiveRecord::Base] The ActiveRecord record instance to convert
  # @return [Hash] Hash of FileMaker field names and values
  def self.to_fm(record)
    raise NotImplementedError, "#{name}.to_fm must be implemented to convert ActiveRecord records to FileMaker attributes"
  end
end
