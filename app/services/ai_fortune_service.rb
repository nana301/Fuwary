class AiFortuneService
  def initialize(tarot_result)
    @tarot_result = tarot_result
  end

  def call
    res = client.chat.completions.create(
      model: "gpt-4o-mini",
      messages: prompt_messages
    )

    content = res.choices&.first&.message&.content
    content.presence || "占い文の生成に失敗しました。もう一度お試しください。"
  rescue OpenAI::Errors::RateLimitError, OpenAI::Errors::AuthenticationError
    "今はメッセージが静かに整えられている最中のようです。焦らず、少し時間をおいてからもう一度受け取ってみてください。"
  end

  private

  attr_reader :tarot_result

  def system_prompt
    <<~TEXT
    あなたは優しく落ち着いた口調のタロット占い師です。
    不安を煽らず、断定的な未来予言は避け、
    今の心の状態を整理し、前向きな一歩を示します。
    説教口調・命令口調は禁止です。
    TEXT
  end

  def client
    @client ||= OpenAI::Client.new(
      api_key: Rails.application.credentials.dig(:openai, :api_key)
    )
  end

  def prompt_messages
    [
      {
        role: "system",
        content: system_prompt
      },
      {
        role: "user",
        content: <<~TEXT
        次のタロット結果をもとに、占い文を作ってください。

        【カードの役割】
        #{position_roles}

        【今回の占いの読み取り方】
        #{reading_style}

        #{reversed_rule}

        【現在の状況】
         いま引いているカード枚数：#{tarot_result.tarot_result_cards.count}枚（最大#{tarot_result.max_cards}枚）

         【条件】
        ・文字数は400〜600文字程度
        ・優しく落ち着いた日本語
        ・「〜でしょう」ではなく「〜かもしれません」を使う
        ・未来を断定しない
        ・読み手を否定しない

        【カード】
        #{cards_description}

        【全体トーン】
        #{overall_tone}

        【締めの指示】
        #{closing_instruction}

        【文章構成】
        1. 今の全体的な流れ
        2. カードから読み取れる心の状態
        3. 今意識すると良いこと
        #{closing_structure_hint}
        TEXT
      }
    ]
  end

  def position_roles
    case tarot_result.fortune_type
    when "today"
      <<~TEXT
      1枚目：今日の運勢（全体の流れ）
      2枚目：今日これから過ごす上で気を付けるべきこと
      TEXT
    when "emotion"
      <<~TEXT
      1枚目：いまの心の状態（#{tarot_result.emotion}の核）
      2枚目：その感情を強めている要因／引っかかり
      3枚目：整えるヒント／次の一歩
      TEXT
    when "genre"
      <<~TEXT
      1枚目：#{tarot_result.genre}の現状（流れ）
      2枚目：気を付けること／落とし穴
      3枚目：うまく進めるコツ／具体的な一手
      TEXT
    else
      <<~TEXT
      1枚目：現在のテーマ
      2枚目：気を付けること
      3枚目：ヒント／次の一歩
      TEXT
    end
  end

  def reading_style
    case tarot_result.tarot_result_cards.count
    when 1
      "シンプルで焦点を絞った占い"
    when 2
      "気持ちと状況のバランスを読む占い"
    when 3
      "流れ・課題・ヒントを丁寧に読み解く占い"
    else
      "全体を俯瞰して読み解く占い"
    end
  end

  def overall_tone
    has_reversed_card? ? "全体的に慎重で落ち着いたトーン" : "前向きで穏やかなトーン"
  end

  def has_reversed_card?
    tarot_result.tarot_result_cards.any? { |c| c.orientation == "reversed" }
  end

  def single_card?
    tarot_result.tarot_result_cards.count == 1
  end

  def reversed_rule
    return "" unless has_reversed_card?

    <<~TEXT
    【逆位置の読み取りルール】
    ・否定的な断定はしない
    ・「内面」「準備」「見直し」「一時的」という表現を使う
    ・注意点はあっても不安を煽らない
    ・改善や気づきにつながる表現にする
    TEXT
  end

  def closing_instruction
    if tarot_result.can_draw_more?
      followup_question_instruction
    elsif single_card?
      "最後は断定せず、問いかけの一文で締めてください。例：「今のあなたにとって、本当に大切にしたいことは何かもしれませんか？」"
    elsif has_reversed_card?
      "最後は『休むことも前進のひとつです』など、安心感のある言葉で締めてください。"
    else
      "最後は前向きな行動をそっと促す言葉で締めてください。"
    end
  end

  def cards_description
    tarot_result.tarot_result_cards.map do |trc|
      card = trc.tarot_card

      orientation_text =
        if trc.orientation == "reversed"
          "逆位置（内省・調整・一時的な停滞を示す）"
        else
          "正位置"
        end

      meaning_text =
        if card.respond_to?(:meaning) && card.meaning.present?
          card.meaning
        else
          "（意味情報が未登録です）"
        end

      <<~CARD
      ・#{card.name}（#{orientation_text}）
        キーワード/意味：#{meaning_text}
      CARD
    end.join("\n")
  end

  def followup_question_instruction
    return "" unless tarot_result.can_draw_more?

    count = tarot_result.tarot_result_cards.count

    if tarot_result.fortune_type == "today"
      return "最後は「次のカードで、今日これから気を付けるべきことを見てみますか？」という問いかけで締めてください。" if count == 1
      return ""
    end

    case count
    when 1
      "最後は「次のカードで、気を付けること（引っかかり）を見てみますか？」という問いかけで締めてください。"
    when 2
      "最後は「次のカードで、ヒント（次の一歩）を見てみますか？」という問いかけで締めてください。"
    else
      ""
    end
  end

  def closing_structure_hint
    if tarot_result.can_draw_more? || single_card?
      "4. 問いかけで締める"
    else
      "4. 前向きな一言で締める"
    end
  end
end
