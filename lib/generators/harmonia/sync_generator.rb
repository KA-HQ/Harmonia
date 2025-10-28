# frozen_string_literal: true

module Harmonia
  module Generators
    class SyncGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, required: true, banner: "ModelName"

      def create_sync_file
        template "sync_template.rb", "app/syncers/#{file_name}_syncer.rb"
      end

      def show_readme
        readme_content = <<~README

          ========================================
          #{class_name}Syncer has been generated!
          ========================================

          Next steps:
          1. Implement the records_to_create method
             - Set @total_create_required to the total number of records that should be created
             - Return an array of Trophonius records to create

          2. Implement the records_to_update method
             - Set @total_update_required to the total number of records that should be updated
             - Return an array of Trophonius records to update

          3. Implement the records_to_delete method (optional)
             - Return an array of record identifiers to delete

          Note: The total_required count used for sync tracking is automatically calculated
          from @total_create_required + @total_update_required

        README

        say readme_content, :green if behavior == :invoke
      end

      private

      def file_name
        name.underscore
      end

      def class_name
        name.camelize
      end

      def table_name
        name.underscore.pluralize
      end
    end
  end
end
