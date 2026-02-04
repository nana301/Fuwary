class AddUniqueIndexToTarotResultCards < ActiveRecord::Migration[7.2]
  def change
    add_index :tarot_result_cards, [:tarot_result_id, :position], unique: true
  end
end
