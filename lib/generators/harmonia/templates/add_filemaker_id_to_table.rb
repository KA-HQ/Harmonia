# frozen_string_literal: true

class AddFilemakerIdTo<%= table_name.camelize %> < ActiveRecord::Migration[<%= Rails::VERSION::MAJOR %>.<%= Rails::VERSION::MINOR %>]
  def change
    unless column_exists?(:<%= table_name %>, :filemaker_id)
      add_column :<%= table_name %>, :filemaker_id, :string
      add_index :<%= table_name %>, :filemaker_id, unique: true
    end
  end
end
