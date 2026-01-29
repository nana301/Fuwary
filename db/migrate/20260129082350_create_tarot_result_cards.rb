class CreateTarotResultCards < ActiveRecord::Migration[7.2]
  def change
    create_table :tarot_result_cards do |t|
      t.references :tarot_result, null: false, foreign_key: true
      t.references :tarot_card, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
