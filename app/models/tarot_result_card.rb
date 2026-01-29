class TarotResultCard < ApplicationRecord
  belongs_to :tarot_result
  belongs_to :tarot_card

  validates :position, presence: true
end
