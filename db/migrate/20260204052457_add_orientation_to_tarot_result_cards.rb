class AddOrientationToTarotResultCards < ActiveRecord::Migration[7.2]
  def change
    add_column :tarot_result_cards, :orientation, :string
  end
end
