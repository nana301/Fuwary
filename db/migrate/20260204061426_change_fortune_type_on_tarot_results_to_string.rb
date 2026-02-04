class ChangeFortuneTypeOnTarotResultsToString < ActiveRecord::Migration[7.0]
  def up
    change_column :tarot_results, :fortune_type, :string, null: false, default: "today"

    execute <<~SQL
      UPDATE tarot_results
      SET fortune_type = CASE fortune_type
        WHEN '0' THEN 'today'
        WHEN '1' THEN 'genre'
        WHEN '2' THEN 'emotion'
        ELSE fortune_type
      END
    SQL
  end

  def down
    execute <<~SQL
      UPDATE tarot_results
      SET fortune_type = CASE fortune_type
        WHEN 'today' THEN '0'
        WHEN 'genre' THEN '1'
        WHEN 'emotion' THEN '2'
        ELSE '0'
      END
    SQL

    change_column :tarot_results, :fortune_type, :integer, null: false, default: 0
  end
end
