class AddUniqueIndexToLikes < ActiveRecord::Migration[7.0]
  def change
    add_index :likes, [:user_id, :tarot_result_id], unique: true, if_not_exists: true
  end
end
