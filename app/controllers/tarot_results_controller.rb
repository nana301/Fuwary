class TarotResultsController < ApplicationController
  before_action :set_tarot_result, only: %i[show draw]
  before_action :authorize_tarot_result!, only: %i[show draw]

  def authorize_tarot_result!
    return if @tarot_result.user_id.nil? # ゲスト許可ならここ調整
    return if user_signed_in? && @tarot_result.user_id == current_user.id

    redirect_to root_path, alert: "アクセスできません"
  end

  def create
    if guest_today?
      build_guest_today
      return render :guest_show
    end

    require_login_for_member_fortunes!
    return unless user_signed_in?

    @tarot_result =
      if user_signed_in?
        build_member_result!
      else
        build_guest_result!
      end

    draw_next_card!(@tarot_result)

    begin
      refresh_result_text!(@tarot_result)
    rescue OpenAI::Errors::RateLimitError
      @tarot_result.update!(result_text: nil) if @tarot_result.result_text.present?
      flash[:alert] = "AI占い文の生成上限に達しています。課金設定後にもう一度お試しください。"
    rescue OpenAI::Errors::AuthenticationError
      flash[:alert] = "AI設定（APIキー）に問題があります。管理者に連絡してください。"
    end

    redirect_to @tarot_result
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.first
    flash.now[:invalid_fortune_type] = params[:fortune_type]
    render "home/index", status: :unprocessable_entity
  end

  def show
    @result_cards = @tarot_result.tarot_result_cards.order(:position)
  end

  def draw
    @tarot_result.with_lock do
      return redirect_to @tarot_result unless @tarot_result.can_draw_more?

      new_card = draw_next_card!(@tarot_result)

      begin
        refresh_result_text!(@tarot_result)
      rescue OpenAI::Errors::RateLimitError
      # 429: クォータ不足 / 上限到達
        flash.now[:alert] = "AI占い文の生成上限に達しています。課金設定後に再度お試しください。"
      # result_text は「前回のまま」でもOK。空にしたいなら↓
      # @tarot_result.update!(result_text: nil)
      rescue OpenAI::Errors::AuthenticationError
      # 401: キー不正など（今は直ったはずだけど保険）
        flash.now[:alert] = "AI設定（APIキー）に問題があります。"
      rescue StandardError => e
      # 予期せぬエラーでも落とさない（ログには残す）
        Rails.logger.error("[AiFortuneService] #{e.class}: #{e.message}")
        flash.now[:alert] = "AI占い文の生成に失敗しました。時間をおいて再度お試しください。"
      end

      @result_cards = @tarot_result.tarot_result_cards.order(:position)
      @just_drawn_id = new_card.id

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @tarot_result, status: :see_other }
      end
    end
  end

  def regenerate
    @tarot_result.with_lock do
      refresh_result_text!(@tarot_result)
    end
    redirect_to @tarot_result, notice: "占い文を更新しました"
  rescue OpenAI::Errors::RateLimitError
    redirect_to @tarot_result, alert: "AI占い文の生成上限に達しています。課金設定後に再度お試しください。"
  end

  private

  def guest_today?
    params[:fortune_type] == "today" && !user_signed_in?
  end

  def build_guest_today
    card = draw_card!

    @tarot_result = TarotResult.new(
      fortune_type: "today",
      result_text: TarotService.new.today_message
    )

    @result_cards = [card]
  end

  def require_login_for_member_fortunes!
    return if user_signed_in?

    redirect_to new_user_session_path, alert: "ログインが必要です"
  end

  def build_member_result!
    tr = current_user.tarot_results.new(
      fortune_type: params[:fortune_type],
      genre: params[:genre],
      emotion: params[:emotion]
    )

    tr.save!
    tr
  end

  def refresh_result_text!(tarot_result)
    text = AiFortuneService.new(tarot_result).call
    tarot_result.update!(result_text: text)
  end

  def draw_next_card!(tarot_result)
    position = tarot_result.tarot_result_cards.count + 1

    card = pick_card_for(tarot_result) 

    orientation = rand < 0.5 ? "upright" : "reversed"

    tarot_result.tarot_result_cards.create!(
      tarot_card: card,
      position: position,
      orientation: orientation
    )
  end

  def set_tarot_result
    @tarot_result = TarotResult.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "結果が見つかりませんでした。もう一度占ってください。"
  end

  def pick_card_for(tarot_result)
    used_ids = tarot_result.tarot_result_cards.pluck(:tarot_card_id)
    scope = TarotCard.where.not(id: used_ids)

    raise "TarotCard がありません。seed しましたか？" if scope.none?

    scope.order(Arel.sql("RANDOM()")).first
  end
end
