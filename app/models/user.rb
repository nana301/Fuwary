class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_one :profile, dependent: :destroy
  has_many :tarot_results, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_tarot_results, through: :likes, source: :tarot_result

  after_create :create_profile!

  private

  def create_profile!
    build_profile.save!
  end
end
