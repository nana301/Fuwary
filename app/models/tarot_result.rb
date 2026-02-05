class TarotResult < ApplicationRecord
  before_validation :set_mode_and_generated_on, on: :create
  belongs_to :user, optional: true

  has_many :tarot_result_cards, dependent: :destroy
  has_many :tarot_cards, through: :tarot_result_cards
  has_many :likes, dependent: :destroy

  FORTUNE_TYPES = %w[today genre emotion].freeze

  validates :fortune_type, presence: true, inclusion: { in: FORTUNE_TYPES }
  validates :genre, presence: true, if: -> { fortune_type == "genre" }
  validates :emotion, presence: true, if: -> { fortune_type == "emotion" }

  def set_mode_and_generated_on
    self.mode ||= fortune_type.presence || "unknown"
    self.generated_on ||= Time.zone.today
  end

   def max_cards
    case fortune_type
    when "today"
      2
    else
      3
    end
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

  def set_generated_on
    self.generated_on ||= Time.zone.today
  end

  def draw_next_card!
    return :limit unless can_draw_more?

    position = tarot_result_cards.count + 1
    card = pick_card_for
    return :no_card unless card

    orientation = rand < 0.5 ? "upright" : "reversed"
    tarot_result_cards.create!(tarot_card: card, position: position, orientation: orientation)

    :ok
  end


  private

  def pick_card_for
    scope =
      if tarot_result_cards.empty?
        TarotCard.where(arcana: "major")
      else
        TarotCard.all
      end

    drawn_ids = tarot_result_cards.pluck(:tarot_card_id)
    scope = scope.where.not(id: drawn_ids) if drawn_ids.any?

    scope.order(Arel.sql("RANDOM()")).first
  end

end
