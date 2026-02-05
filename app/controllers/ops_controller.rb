class OpsController < ActionController::Base
  skip_forgery_protection

  def status
    return head :unauthorized unless authorized?

    render json: {
      tarot_cards: TarotCard.count,
      tarot_results: TarotResult.count
    }
  end

  def seed
    return head :unauthorized unless authorized?

    if TarotCard.exists?
      render json: { ok: true, message: "already seeded", tarot_cards: TarotCard.count }, status: 200
      return
    end

    Rails.application.load_seed
    render json: { ok: true, tarot_cards: TarotCard.count, major: TarotCard.where(arcana: "major").count }, status: 200
  end

  private

  def authorized?
    token = request.headers["X-OPS-TOKEN"].to_s
    expected = ENV["OPS_TOKEN"].to_s
    return false if token.empty? || expected.empty?

    ActiveSupport::SecurityUtils.secure_compare(token, expected)
  end
end
