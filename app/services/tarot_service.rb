class TarotService
  def initialize(tarot_result)
    @tarot_result = tarot_result
  end

  def intro_message
    case @tarot_result.fortune_type
    when "today"
      "今日の流れをカードで見ていきます 🔮"
    when "genre"
      "「#{@tarot_result.genre.presence || 'このテーマ'}」をカードで読み解きます 🔮"
    when "emotion"
      "「#{@tarot_result.emotion.presence || 'いまの気持ち'}」を手がかりに整理します 🔮"
    else
      "カードでメッセージを受け取っていきます 🔮"
    end
  end

  def progress_message
    cards = ordered_cards
    return "" if cards.empty?

    lines = cards.map { |rc| "・#{rc.position}枚目：#{rc.tarot_card.name}" }.join("\n")
    "いま出ているカード：\n#{lines}"
  end

  def final_message
    cards = ordered_cards
    return "" if cards.size < 3

    names = cards.map { |rc| rc.tarot_card.name }.join("・")
    <<~TEXT
      3枚のカードが揃いました ✨
      今回の流れは「#{names}」です。
      最後のカードを結論として受け取りつつ、1〜2枚目の示す流れを踏まえて行動してみてください。
    TEXT
  end

  def full_message
    parts = []
    parts << intro_message
    parts << progress_message if progress_message.present?
    parts << final_message if final_message.present?
    parts.join("\n\n")
  end

  private

  def ordered_cards
    @tarot_result.tarot_result_cards.includes(:tarot_card).order(:position)
  end
end
