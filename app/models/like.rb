class Like < ApplicationRecord
  belongs_to :user
  belongs_to :tarot_result

  validates :user_id, uniqueness: { scope: :tarot_result_id }
end
