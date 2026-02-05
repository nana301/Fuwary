class TarotResultsController < ApplicationController
  before_action :set_tarot_result, only: %i[show draw]
  before_action :authorize_tarot_result!, only: %i[show draw]

  def authorize_tarot_result!
    return if @tarot_result.user_id.nil?
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

    mode = params[:fortune_type].to_s

    if daily_limit_enabled?
      existing = current_user.tarot_results.find_by(
        mode: mode,
        generated_on: Time.zone.today
      )
      if existing
        flash[:notice] = "今日の結果を表示しますね。"
        return redirect_to existing
      end
    end

    @tarot_result = build_member_result!

    redirect_to @tarot_result

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.first
    flash.now[:invalid_fortune_type] = params[:fortune_type]
    render "home/index", status: :unprocessable_entity

  rescue ActiveRecord::RecordNotUnique
    existing = current_user.tarot_results.find_by!(
      mode: mode,
      generated_on: Time.zone.today
    )
    redirect_to existing, notice: "今日はすでに占っています。"
  end

  def show
    @result_cards = @tarot_result.tarot_result_cards.order(:position)
  end

  def draw
    unless @tarot_result.draw_next_card!
      redirect_to @tarot_result, alert: "これ以上カードを引けません"
      return
    end

    text, ok = AiFortuneService.new(@tarot_result).call

    Rails.logger.info("[draw] AiFortuneService ok=#{ok} len=#{text.to_s.length} tarot_result_id=#{@tarot_result.id}")

    @tarot_result.update!(result_text: text) if ok

    redirect_to @tarot_result, notice: "カードを引きました（#{@tarot_result.tarot_result_cards.count}枚目）", status: :see_other
  end

  def regenerate
    msg = nil
    ok = false

    @tarot_result.with_lock do
      msg, ok = refresh_result_text!(@tarot_result)
    end

    if ok
      redirect_to @tarot_result, notice: "メッセージを更新しました"
    else
      redirect_to @tarot_result, alert: msg
    end
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
    current_user.tarot_results.create!(
      mode: params[:fortune_type].to_s,
      fortune_type: params[:fortune_type],
      emotion: params[:emotion],
      genre: params[:genre]
    )
  end

  def refresh_result_text!(tarot_result)
    new_text, ok = AiFortuneService.new(tarot_result).call
    return [new_text, false] unless ok

    combined =
      if tarot_result.result_text.present?
        "#{tarot_result.result_text}\n\n#{new_text}"
      else
        new_text
      end

    tarot_result.update!(result_text: combined)
    [new_text, true]
  end

  def set_tarot_result
    @tarot_result = TarotResult.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "結果が見つかりませんでした。もう一度占ってください。"
  end

  def daily_limit_enabled?
    !%w[0 false off].include?(ENV.fetch("DAILY_LIMIT_ENABLED", "true").to_s.downcase)
  end
end
