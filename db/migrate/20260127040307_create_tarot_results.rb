class CreateTarotResults < ActiveRecord::Migration[7.0]
  def change
    create_table :tarot_results do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :fortune_type, null: false, default: 0
      t.string :genre
      t.string :emotion
      t.string :question
      t.text :result_text

      t.timestamps
    end
  end
end
