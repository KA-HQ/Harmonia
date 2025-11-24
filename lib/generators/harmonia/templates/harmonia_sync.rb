# frozen_string_literal: true

module Harmonia
  class Sync < ApplicationRecord
    self.table_name = 'harmonia_syncs'

    validates :table, presence: true
    validates :ran_on, presence: true
    validates :status, presence: true, inclusion: { in: %w[pending in_progress completed failed] }

    # Scope to get syncs for a specific table
    scope :for_table, ->(table_name) { where(table: table_name) }
    scope :for_direction, ->(direction) {where(direction:)}

    # Scope to get recent syncs
    scope :recent, -> { order(ran_on: :desc) }

    # Scope to get syncs by date
    scope :on_date, ->(date) { where(ran_on: date) }

    # Scope by status
    scope :pending, -> { where(status: 'pending') }
    scope :in_progress, -> { where(status: 'in_progress') }
    scope :completed, -> { where(status: 'completed') }
    scope :failed, -> { where(status: 'failed') }

    # Get the most recent successful sync for a table in a given direction
    def self.last_sync_for(table_name, direction)
      completed.for_direction(direction).for_table(table_name).recent.first
    end

    # Calculate sync completion percentage
    def completion_percentage
      return 0 if records_required.to_i.zero?
      ((records_synced.to_f / records_required.to_f) * 100).round(2)
    end

    # Check if sync was complete
    def complete?
      status == 'completed' && records_synced == records_required
    end

    # Mark sync as started
    def start!
      update!(status: 'in_progress')
    end

    # Mark sync as completed
    def finish!(records_synced:, records_required:, failed_fm_ids: {}, failed_pg_ids: {})
      status = records_synced == records_required ? 'completed' : 'failed'
      update!(
        status: status,
        records_synced: records_synced,
        records_required: records_required,
        failed_fm_ids: failed_fm_ids,
        failed_pg_ids: failed_pg_ids
      )
    end

    # Mark sync as failed
    def fail!(error_message, failed_fm_ids: {}, failed_pg_ids: {})
      update!(
        status: 'failed',
        error_message: error_message,
        failed_fm_ids: failed_fm_ids,
        failed_pg_ids: failed_pg_ids
      )
    end
  end
end
