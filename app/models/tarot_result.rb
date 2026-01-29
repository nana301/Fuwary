class TarotResult < ApplicationRecord
  belongs_to :user, optional: true

  has_many :tarot_result_cards, dependent: :destroy
  has_many :tarot_cards, through: :tarot_result_cards

  enum fortune_type: { today: 0, genre: 1, emotion: 2 }

  def can_draw_more?
    tarot_result_cards.count < 3
  end
end
