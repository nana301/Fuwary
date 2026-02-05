class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  
  def index
    @tarot_result = TarotResult.new
    @emotions = %w[不安 迷い 悲しい 嬉しい 疲れた 前向き]
  end
end
