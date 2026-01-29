class RemoveTarotResultFromTarotCards < ActiveRecord::Migration[7.0]
  def change
    remove_reference :tarot_cards, :tarot_result, foreign_key: true
  end
end
