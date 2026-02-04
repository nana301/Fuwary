class CreateTarotCards < ActiveRecord::Migration[7.2]
  def change
    create_table :tarot_cards do |t|
      t.references :tarot_result, null: false, foreign_key: true
      t.string :name
      t.boolean :upright
      t.text :meaning

      t.timestamps
    end
  end
end
