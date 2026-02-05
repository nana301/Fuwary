class AiFortuneService
  FALLBACK_GENERIC = "占い文の生成に失敗しました。もう一度お試しください。"
  FALLBACK_SOFT    = "カードのメッセージを整えています…。少し待ってから更新してみてください。"

  def initialize(tarot_result)
    @tarot_result = tarot_result
  end

  def call
    res = client.chat.completions.create(
      model: "gpt-4o-mini",
      messages: prompt_messages
    )

    content = res.choices&.first&.message&.content
    text = content.presence
    return [text, true] if text.present?

    [FALLBACK_GENERIC, false]
  rescue OpenAI::Errors::RateLimitError, OpenAI::Errors::AuthenticationError => e
    Rails.logger.warn("[AiFortuneService] #{e.class}: #{e.message}")
    [FALLBACK_SOFT, false]
  rescue StandardError => e
    Rails.logger.error("[AiFortuneService] #{e.class}: #{e.message}")
    [FALLBACK_GENERIC, false]
  end

  private
  attr_reader :tarot_result

  def system_prompt
    <<~TEXT
    あなたは優しく落ち着いた口調のタロット占い師です。
    マルセイユ版タロットカードの象徴や構図をもとに解釈してください。

    不安を煽らず、断定的な未来予言は行いません。
    説教口調・命令口調は禁止です。

    以下を必ず守ってください：
    ・今回引いたカード1枚分の内容だけを書く
    ・「気づき」「意識の向けどころ」を1点だけ示す
    ・抽象的な励まし（例：大丈夫、前向き、流れを信じる）は使わない
    ・感情・迷い・行動のどれか1つに焦点を当てる
    ・過去の内容は要約・繰り返さない

    重要（反復防止）：
    ・文頭で「現在、あなたは」「今は、あなたは」「あなたは今〜」を使わない
    ・導入の定型（こんにちは/まずは/次のカードで〜を見てみますか？）を1文目に置かない
    ・恋愛（genre）と感情（emotion）で同じ書き出し型を繰り返さない

    出力は100〜120文字以内。
    1〜2文で、冗長な前置きやまとめは書かないでください。
    TEXT
  end

  def client
    @client ||= OpenAI::Client.new(
      api_key: ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)
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

        #{card_specific_instruction}

        【カードの役割】
        #{position_roles}

        【今回の占いの読み取り方】
        #{reading_style}

        #{reversed_rule}

        【現在の状況】
         いま引いているカード枚数：#{tarot_result.tarot_result_cards.count}枚（最大#{tarot_result.max_cards}枚）

        【カード】
        #{cards_description}

        【全体トーン】
        #{overall_tone}

        【締めの指示】
        #{closing_instruction}

        【冒頭スタイル（必ず守る）】
        #{opening_style_instruction}

        【文章構成】
        ・冒頭スタイルに従い、すぐ核心へ入る
        ・最後は指示どおりに締める
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
      return pick_followup([
        "最後は「次のカードで、今日これから気を付けるべきことを見てみますか？」で締めてください。",
        "最後は「続けて1枚引いて、注意点だけ確かめますか？」で締めてください。"
      ]) if count == 1
      return ""
    end

    case count
    when 1
      pick_followup([
        "最後は「次のカードで、今後気を付けることを見てみますか？」で締めてください。",
        "最後は「もう1枚引いて、引っかかりの正体を見てみますか？」で締めてください。"
      ])
    when 2
      pick_followup([
        "最後は「次のカードで、次の一歩へのヒントを見てみますか？」で締めてください。",
        "最後は「最後に1枚だけ、整えるヒントを確かめますか？」で締めてください。"
      ])
    else
      ""
    end
  end

  def pick_followup(candidates)
    seed = [tarot_result.id, tarot_result.tarot_result_cards.count, tarot_result.fortune_type].join(":").hash
    candidates[seed % candidates.length]
  end

  def card_specific_instruction
    count   = tarot_result.tarot_result_cards.count
    card    = tarot_result.tarot_result_cards.last
    fortune = tarot_result.fortune_type

    base =
      if fortune == "today"
        case count
        when 1
          "今日の流れの『核心』を1文で言語化してください。"
        when 2
          "『今日1つだけやるなら？』という形で、5分以内にできる行動や心の向け方を1つ示してください。"
        else
          ""
        end
      else
        case count
        when 1
          "今の状態の『核心』を1文で言語化してください。"
        when 2
          "その状態を難しくしている思考や癖を1つ指摘してください。"
        when 3
          "すぐにできる心の向け方を1つだけ示してください。"
        else
          ""
        end
      end

    emotion_rule =
      if fortune == "emotion"
        word = emotion_word_for_card(card.tarot_card)
        "必ず「#{word}」という感情表現を1回だけ使ってください。"
      else
        ""
      end

    reversed_rule =
      if card.orientation == "reversed"
        "逆位置のため、本人が無意識に見ないふりをしていることを1つ指摘してください。"
      else
        ""
      end

    <<~TEXT
    【今回の出力ルール】
    #{base}
    #{emotion_rule}
    #{reversed_rule}
    TEXT
  end

  def last_card_reversed?
    tarot_result.tarot_result_cards.last&.orientation == "reversed"
  end

  def emotion_word_for_card(card)
    base = tarot_result.emotion
    type = card_tone(card)

    map = {
      "不安" => {
        calm:  "落ち着かなさ",
        active:"焦り",
        heavy: "怖さ",
        light: "そわそわ"
      },
      "怒り" => {
        calm:  "飲み込んだ苛立ち",
        active:"衝動的な怒り",
        heavy: "抑え込んだ不満",
        light: "小さな引っかかり"
      },
      "悲しい" => {
        calm:  "静かな寂しさ",
        active:"感情の波",
        heavy: "喪失感",
        light: "ふとした切なさ"
      },
      "嬉しい" => {
        calm:  "ほっとする喜び",
        active:"弾む気持ち",
        heavy: "胸いっぱいの喜び",
        light: "軽やかな嬉しさ"
      },
      "疲れた" => {
        calm:  "消耗感",
        active:"空回り感",
        heavy: "重だるさ",
        light: "気力の低下"
      },
      "前向き" => {
        calm:  "静かな前向きさ",
        active:"やる気",
        heavy: "腹をくくった前向きさ",
        light: "軽い追い風"
      }
    }

    map.dig(base, type) || base
  end

  def opening_style_instruction
    style = pick_opening_style

    case style
    when :card_subject
      <<~TEXT
      1文目は「このカードが示すのは〜」の形で始める（カード主語）。
      例：「このカードが示すのは、『与えすぎて疲れが溜まる配置』です。」
      TEXT
    when :concrete_scene
      <<~TEXT
      1文目は具体描写から始める（恋愛/感情の“場面”を描く）。
      例：「相手に合わせた後、どっと疲れが残りやすい時期です。」
      TEXT
    when :question
      <<~TEXT
      1文目は問いかけで始める（はい/いいえでなく内省を促す問い）。
      例：「最近、言いたいことを飲み込む場面が増えていませんか？」
      TEXT
    when :symbol
      <<~TEXT
      1文目は象徴の一語から始める（比喩は1つまで）。
      例：「『鎖』が見えるカードです——手放せないこだわりが焦点です。」
      TEXT
    end
  end

  def pick_opening_style
    styles =
      if tarot_result.fortune_type == "emotion"
        # 感情は「問いかけ」「具体描写」寄りが刺さる
        [:question, :concrete_scene, :card_subject]
      else
        # genre/todayはカード主語や象徴スタートが映える
        [:card_subject, :symbol, :concrete_scene]
      end

    seed = [
    tarot_result.id,
      tarot_result.fortune_type,
      tarot_result.genre,
      tarot_result.emotion,
      tarot_result.tarot_result_cards.count
    ].join(":").hash

    styles[seed % styles.length]
  end

  def card_tone(card)
    name = card.name.to_s

    # 重い・内省が深い・揺さぶりが強い
    return :heavy if name.match?(
      /死神|悪魔|塔|吊るされた男|月|審判/
    )

    # 動き・決断・外向きエネルギーが強い
    return :active if name.match?(
      /戦車|力|皇帝|恋人|太陽|世界|魔術師/
    )

    # 軽やか・希望・調整・回復
    return :light if name.match?(
      /愚者|星|節制|女教皇/
    )

    # 安定・観察・流れを見る
    :calm
  end

  def closing_structure_hint
    if tarot_result.can_draw_more? || single_card?
      "4. 問いかけで締める"
    else
      "4. 前向きな一言で締める"
    end
  end
end
