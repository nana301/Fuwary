class TarotResultsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[create show draw]
  before_action :set_tarot_result, only: %i[show draw]
  before_action :authorize_tarot_result!, only: %i[show draw]

  def authorize_tarot_result!
    return if @tarot_result.user_id.nil?

    unless user_signed_in? && @tarot_result.user_id == current_user.id
      redirect_to new_user_session_path, alert: "ログインが必要です"
    end
  end

  def create
    if guest_today?
      today = Time.zone.today.to_s

      if session[:guest_today_date] == today && session[:guest_today_tarot_result_id].present?
        tr = TarotResult.find_by(id: session[:guest_today_tarot_result_id])
        return redirect_to(tr, notice: "今日の結果を表示しますね。", status: :see_other) if tr
      end

      build_guest_today_and_store!

      session[:guest_today_date] = today
      session[:guest_today_tarot_result_id] = @tarot_result.id

      return redirect_to @tarot_result, status: :see_other
    end

    require_login_for_member_fortunes!
    return unless user_signed_in?

    mode = fortune_type_param.to_s

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

    result = @tarot_result.draw_next_card!

    case result
    when :no_card
      redirect_to root_path, alert: "カードが準備できていません（seed未投入の可能性）", status: :see_other
      return
    when :limit
      redirect_to @tarot_result, alert: "これ以上カードを引けません", status: :see_other
      return
    end

    msg, ok = refresh_result_text!(@tarot_result)
    flash[:alert] = msg unless ok

    redirect_to @tarot_result, status: :see_other
    return

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.first
    render "home/index", status: :unprocessable_entity
  end

  def show
    @result_cards = @tarot_result.tarot_result_cards.order(:position)
  end

  def draw
    result = @tarot_result.draw_next_card!

    case result
    when :limit
      redirect_to @tarot_result, alert: "これ以上カードを引けません", status: :see_other
      return
    when :no_card
      redirect_to @tarot_result, alert: "カードが準備できていません（seed未投入の可能性）", status: :see_other
      return
    end

    msg, ok = refresh_result_text!(@tarot_result)

    if ok
      redirect_to @tarot_result, notice: "カードを引きました", status: :see_other
    else
      redirect_to @tarot_result, alert: msg, status: :see_other
    end
  end

  private

  def fortune_type_param
    params[:fortune_type].presence || params.dig(:tarot_result, :fortune_type).presence
  end

  def guest_today?
    fortune_type_param == "today" && !user_signed_in?
  end

  def build_guest_today_and_store!
    @tarot_result = TarotResult.create!(
      user: nil,
      fortune_type: "today",
      mode: "today",
      generated_on: Time.zone.today
    )

    result = @tarot_result.draw_next_card!

    case result
    when :limit
      raise "これ以上カードを引けません"
    when :no_card
      raise "カードが準備できていません（seed未投入の可能性）"
    end

    msg, ok = refresh_result_text!(@tarot_result)
    raise msg unless ok
  end

  def draw_card!
    TarotCard.where(arcana: "major").order(Arel.sql("RANDOM()")).first
  end

  def require_login_for_member_fortunes!
    redirect_to new_user_session_path, alert: "ログインが必要です" unless user_signed_in?
  end

  def build_member_result!
    current_user.tarot_results.create!(
      mode: fortune_type_param.to_s,
      fortune_type: fortune_type_param,
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
    redirect_to root_path, alert: "結果が見つかりませんでした。"
  end

  def daily_limit_enabled?
    !%w[0 false off].include?(ENV.fetch("DAILY_LIMIT_ENABLED", "true").to_s.downcase)
  end
end
