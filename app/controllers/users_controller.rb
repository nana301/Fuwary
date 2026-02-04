class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @profile = current_user.profile
    @tab = params[:tab].presence_in(%w[history likes]) || "history"

    if @tab == "history"
      @tarot_results = current_user.tarot_results
        .order(created_at: :desc)
        .page(params[:page])
        .per(10)
    else
      @liked_results = current_user.liked_tarot_results
        .order(created_at: :desc)
        .page(params[:page])
        .per(10)
    end
  end
end
