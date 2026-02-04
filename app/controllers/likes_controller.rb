class LikesController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!
  before_action :set_tarot_result

  def create
    current_user.likes.find_or_create_by!(tarot_result: @tarot_result)
    @tarot_result.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @tarot_result, status: :see_other }
    end
  end

  def destroy
    @like = current_user.likes.find_by(tarot_result: @tarot_result)

    if @like
      @like.destroy!
      @tarot_result.reload
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @tarot_result, status: :see_other }
    end
  end

  private

  def set_tarot_result
    @tarot_result = TarotResult.find(params[:tarot_result_id])
  end
end
