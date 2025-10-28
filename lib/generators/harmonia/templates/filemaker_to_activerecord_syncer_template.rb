# frozen_string_literal: true

class <%= class_name %>Syncer
  attr_acc :database_connector

  def initialize(database_connector)
    @database_connector = database_connector
  end

  # Main sync method
  # Executes the sync process for <%= class_name %> records
  def run
    raise StandardError, 'No database connector set' if @database_connector.blank?

    sync_record = create_sync_record

    @database_connector.open_database do
      sync_record.start!
      sync_records(sync_record)
    end
  rescue StandardError => e
    sync_record&.fail!(e.message)
    raise
  end

  private

  def sync_records(sync_record)
    created_count = create_records
    updated_count = update_records
    delete_records

    total_synced = created_count + updated_count
    total_required = (@total_create_required || 0) + (@total_update_required || 0)

    sync_record.finish!(
      records_synced: total_synced,
      records_required: total_required
    )
  end

  # Returns an array of Trophonius records that need to be created
  # Use YourTrophoniusModel.to_pg(record) to convert to PostgreSQL attributes
  # Set @total_create_required to the total number of records that should exist after creation
  # @return [Array<Trophonius::Record>] Array of Trophonius records
  def records_to_create
    # TODO: Implement logic to fetch records from FileMaker that need to be created in PostgreSQL
    # Example:
    # filemaker_records = YourTrophoniusModel.all
    # @total_create_required = filemaker_records.length
    # existing_ids = <%= class_name %>.pluck(:filemaker_id)
    # filemaker_records.reject { |record| existing_ids.include?(record.record_id) }
    @total_create_required = 0
    []
  end

  # Returns an array of Trophonius records that need to be updated
  # Use YourTrophoniusModel.to_pg(record) to convert to PostgreSQL attributes
  # Set @total_update_required to the total number of records that should be updated
  # @return [Array<Trophonius::Record>] Array of Trophonius records
  def records_to_update
    # TODO: Implement logic to fetch records from FileMaker that need to be updated in PostgreSQL
    # Example:
    # filemaker_records = YourTrophoniusModel.all
    # records_needing_update = filemaker_records.select { |fm_record|
    #   pg_record = <%= class_name %>.find_by(filemaker_id: fm_record.record_id)
    #   pg_record && needs_update?(fm_record, pg_record)
    # }
    # @total_update_required = records_needing_update.length
    # records_needing_update
    @total_update_required = 0
    []
  end

  # Returns an array of record identifiers that need to be deleted
  # @return [Array] Array of record identifiers
  def records_to_delete
    # TODO: Implement logic to determine which PostgreSQL records should be deleted
    # Example:
    # filemaker_ids = YourTrophoniusModel.all.map(&:record_id)
    # <%= class_name %>.where.not(filemaker_id: filemaker_ids).pluck(:id)
    []
  end

  def create_records
    records = records_to_create
    return 0 if records.empty?

    attributes_array = records.map do |trophonius_record|
      YourTrophoniusModel.to_pg(trophonius_record).merge(
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    <%= class_name %>.insert_all(attributes_array)
    records.size
  end

  def update_records
    records = records_to_update
    return 0 if records.empty?

    records.each do |trophonius_record|
      pg_attributes = YourTrophoniusModel.to_pg(trophonius_record)

      <%= class_name %>.where(filemaker_id: trophonius_record.record_id).update_all(
        pg_attributes.merge(updated_at: Time.current)
      )
    end

    records.size
  end

  def delete_records
    ids = records_to_delete
    return if ids.empty?

    <%= class_name %>.where(id: ids).destroy_all
  end

  def create_sync_record
    Harmonia::Sync.create!(
      table: '<%= table_name %>',
      ran_on: Date.today,
      status: 'pending'
    )
  end
end
