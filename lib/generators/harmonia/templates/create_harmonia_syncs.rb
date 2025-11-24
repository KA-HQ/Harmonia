# frozen_string_literal: true

class CreateHarmoniaSyncs < ActiveRecord::Migration[<%= Rails::VERSION::MAJOR %>.<%= Rails::VERSION::MINOR %>]
  def change
    create_table :harmonia_syncs do |t|
      t.datetime :ran_on
      t.string :table
      t.integer :records_synced, default: 0
      t.integer :records_required, default: 0
      t.string :status, default: 'pending'
      t.string :direction
      t.text :error_message
      t.string :failed_fm_ids, array: true
      t.integer :failed_pg_ids, array: true

      t.timestamps
    end

    add_index :harmonia_syncs, [:table, :ran_on]
    add_index :harmonia_syncs, :status
  end
end
