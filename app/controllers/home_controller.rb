class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  
  def index
    @tarot_result = TarotResult.new
    @emotions = %w[不安 迷い 怒り 悲しみ 期待]
  end
end
