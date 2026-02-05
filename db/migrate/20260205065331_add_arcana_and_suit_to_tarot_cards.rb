class AddArcanaAndSuitToTarotCards < ActiveRecord::Migration[7.2]
  def change
    add_column :tarot_cards, :arcana, :integer, null: false, default: 0
    add_column :tarot_cards, :suit, :string
    add_index :tarot_cards, :arcana
    add_index :tarot_cards, :suit
  end
end
