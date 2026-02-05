class OpsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :verify_ops_token!

  def status
    render json: {
      tarot_cards: TarotCard.count,
      tarot_results: TarotResult.count
    }
  end

  def seed
    Rails.application.load_seed
    render json: { ok: true }
  end

  private

  def verify_ops_token!
    token = request.headers["X-OPS-TOKEN"]
    unless ActiveSupport::SecurityUtils.secure_compare(
      token.to_s,
      ENV.fetch("OPS_TOKEN")
    )
      head :unauthorized
    end
  end
end

