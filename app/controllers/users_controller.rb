class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      redirect_to job_applications_path, notice: 'Account created!'
    else
      puts @user.errors.full_messages.join("\n")
      redirect_to new_user_path, alert: @user.errors.full_messages.join("\n")
    end
  end

  private
  
  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
