class TarotResult < ApplicationRecord
  belongs_to :user, optional: true

  has_many :tarot_result_cards, dependent: :destroy
  has_many :tarot_cards, through: :tarot_result_cards
  has_many :likes, dependent: :destroy

  FORTUNE_TYPES = %w[today genre emotion].freeze

  validates :fortune_type, presence: true, inclusion: { in: FORTUNE_TYPES }
  validates :genre, presence: true, if: -> { fortune_type == "genre" }
  validates :emotion, presence: true, if: -> { fortune_type == "emotion" }

  def max_cards
    fortune_type == "today" ? 2 : 3
  end

  def can_draw_more?
    tarot_result_cards.count < max_cards
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end

  def drawn_cards_count
    tarot_result_cards.count
  end

  def draw_status_label
    "#{drawn_cards_count}/3 枚"
  end

  def complete?
    drawn_cards_count == 3
  end
end
