# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Converts an ActiveRecord record to FileMaker-compatible attributes
  # This method should be overridden in each model that syncs to FileMaker
  # @param record [ActiveRecord::Base] The ActiveRecord record instance to convert
  # @return [Hash] Hash of FileMaker field names and values
  def to_fm(record)
    raise NotImplementedError, "#{self.class.name}#to_fm must be implemented to convert ActiveRecord records to FileMaker attributes"
  end
end
