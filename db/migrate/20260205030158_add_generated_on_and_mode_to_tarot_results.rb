class AddGeneratedOnAndModeToTarotResults < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  INDEX_NAME = "index_tarot_results_unique_daily_per_mode"
  INDEX_COLS = [:user_id, :mode, :generated_on]

  def up
    add_column :tarot_results, :mode, :string unless column_exists?(:tarot_results, :mode)
    add_column :tarot_results, :generated_on, :date unless column_exists?(:tarot_results, :generated_on)

    execute <<~SQL
      UPDATE tarot_results
      SET mode = COALESCE(mode, 'unknown'),
          generated_on = COALESCE(generated_on, (created_at AT TIME ZONE 'UTC')::date)
    SQL

    change_column_null :tarot_results, :mode, false
    change_column_null :tarot_results, :generated_on, false

    execute <<~SQL
      DELETE FROM tarot_results a
      USING tarot_results b
      WHERE a.id > b.id
        AND a.user_id = b.user_id
        AND a.mode = b.mode
        AND a.generated_on = b.generated_on
    SQL

    unless index_exists?(:tarot_results, INDEX_COLS, name: INDEX_NAME)
      add_index :tarot_results, INDEX_COLS,
                unique: true,
                name: INDEX_NAME,
                algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:tarot_results, INDEX_COLS, name: INDEX_NAME)
      remove_index :tarot_results, column: INDEX_COLS, name: INDEX_NAME
    end
    remove_column :tarot_results, :generated_on if column_exists?(:tarot_results, :generated_on)
    remove_column :tarot_results, :mode if column_exists?(:tarot_results, :mode)
  end
end
