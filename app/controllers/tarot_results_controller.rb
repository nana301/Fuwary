class TarotResultsController < ApplicationController
  before_action :set_tarot_result, only: %i[show draw]

  def create
    card = TarotCard.order("RANDOM()").first
    raise "TarotCard が存在しません。seed を確認してください" unless card

    @tarot_result = current_user&.tarot_results&.create!(
      fortune_type: params[:fortune_type],
      genre: params[:genre],
      emotion: params[:emotion]
    )

    create_card(@tarot_result, card)

    update_result_text_if_needed(@tarot_result)

    redirect_to @tarot_result
  end

  def draw
    tarot_result = TarotResult.find(params[:id])

    return redirect_to tarot_result unless tarot_result.can_draw_more?

    card = TarotCard.order("RANDOM()").first

    position = tarot_result.tarot_result_cards.count + 1

    tarot_result.tarot_result_cards.create!(
      tarot_card: card,
      position: position
    )

    if position == 3
      message = TarotService.new(tarot_result).summary_message
      tarot_result.update!(result_text: message)
    end

    redirect_to tarot_result
  end


  def show
    @tarot_result = TarotResult.find(params[:id])
    @result_cards = @tarot_result.tarot_result_cards.order(:position)
  end

  private

  def set_tarot_result
    @tarot_result = TarotResult.find(params[:id])
  end

  def create_card(tarot_result, card)
    tarot_result.tarot_result_cards.create!(
      tarot_card: card,
      position: tarot_result.tarot_result_cards.count + 1
    )
  end

  def update_result_text_if_needed(tarot_result)
    return unless tarot_result.tarot_result_cards.count == 3

    tarot_result.update!(
      result_text: TarotService.new(tarot_result).call
    )
  end
end
