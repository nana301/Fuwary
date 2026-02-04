class TarotCard < ApplicationRecord
  has_many :tarot_result_cards
  has_many :tarot_results, through: :tarot_result_cards

  validates :name, :meaning, presence: true
end
