class AddCardToTarotResults < ActiveRecord::Migration[7.0]
  def change
    add_reference :tarot_results, :tarot_card, foreign_key: true
  end
end
