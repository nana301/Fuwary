class AddLastDrawAtToTarotResults < ActiveRecord::Migration[7.2]
  def change
    add_column :tarot_results, :last_draw_at, :datetime
  end
end
