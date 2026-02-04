class TarotResultCard < ApplicationRecord
  belongs_to :tarot_result
  belongs_to :tarot_card

  ORIENTATIONS = %w[upright reversed].freeze
  validates :orientation, inclusion: { in: ORIENTATIONS }
  validates :position, presence: true, inclusion: { in: 1..3 }
  validates :tarot_result_id, uniqueness: { scope: :position }

  orientation = rand < 0.5 ? "upright" : "reversed"
end
