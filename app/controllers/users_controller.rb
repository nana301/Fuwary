class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @profile = @user.profile
  end
end
