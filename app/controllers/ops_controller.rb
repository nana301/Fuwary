class OpsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def status
    return head :forbidden unless authorized?

    render json: {
      tarot_cards: TarotCard.count,
      major: TarotCard.where(arcana: "major").count
    }
  end

  def seed
    return head :forbidden unless authorized?

    if TarotCard.count > 0
      render json: { ok: true, message: "already seeded", tarot_cards: TarotCard.count }, status: 200
      return
    end

    Rails.application.load_seed

    render json: {
      ok: true,
      tarot_cards: TarotCard.count,
      major: TarotCard.where(arcana: "major").count
    }, status: 200
  end

  private

  def authorized?
    Rails.env.production? &&
      ActiveSupport::SecurityUtils.secure_compare(
        request.headers["X-OPS-TOKEN"].to_s,
        ENV.fetch("OPS_TOKEN", "")
      )
  end
end
