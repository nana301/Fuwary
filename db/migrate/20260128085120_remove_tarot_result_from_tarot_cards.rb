class RemoveTarotResultFromTarotCards < ActiveRecord::Migration[7.2]
  def change
    remove_reference :tarot_cards, :tarot_result, null: false, foreign_key: true
  end
end
