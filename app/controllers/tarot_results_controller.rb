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

   mode = params[:fortune_type].to_s
    existing = current_user.tarot_results.find_by(mode: mode, generated_on: Time.zone.today)
    if existing
      flash[:notice] = "今日の結果を表示しますね。"
      return redirect_to existing
    end

    @tarot_result = build_member_result!

    draw_next_card!(@tarot_result)

    refresh_result_text!(@tarot_result)

      redirect_to @tarot_result

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.first
    flash.now[:invalid_fortune_type] = params[:fortune_type]
    render "home/index", status: :unprocessable_entity

  rescue ActiveRecord::RecordNotUnique
    existing = current_user.tarot_results.find_by!(mode: mode, generated_on: Time.zone.today)
    redirect_to existing, notice: "今日はすでに占っています。"
  end

  def show
    @result_cards = @tarot_result.tarot_result_cards.order(:position)
  end

  def draw
    @tarot_result.with_lock do
      return redirect_to @tarot_result unless @tarot_result.can_draw_more?

      new_card = draw_next_card!(@tarot_result)
      refresh_result_text!(@tarot_result)

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
