module TarotResultsHelper
  def fortune_badge(result)
    case result.fortune_type
    when "today"
      content_tag(:span, "今日", class: badge_class("today"))
    when "genre"
      label = result.genre.present? ? "ジャンル：#{result.genre}" : "ジャンル"
      content_tag(:span, label, class: badge_class("genre"))
    when "emotion"
      label = result.emotion.present? ? "感情：#{result.emotion}" : "感情"
      content_tag(:span, label, class: badge_class("emotion"))
    end
  end

  def badge_class(type)
    base = "inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold ring-1"
    case type
    when "today"
      "#{base} bg-blue-50 text-blue-700 ring-blue-200"
    when "genre"
      "#{base} bg-emerald-50 text-emerald-700 ring-emerald-200"
    else
      "#{base} bg-rose-50 text-rose-700 ring-rose-200"
    end
  end
end
