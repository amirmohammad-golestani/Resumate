class JobApplicationsController < ApplicationController

  helper_method :current_user

  def index
    @pagy, @job_applications = pagy(current_user.job_applications)
  end

  def show
  end

  def new
    @job_application = JobApplication.new
  end

  def create
    begin
      job_description = params[:job_description]
      resume = params[:resume]
      @job_application = JobApplication.new(user: current_user, job_description: job_description)
      @job_application.original_resume.attach(resume)

      if @job_application.save
        ResumeProcessorJob.perform_later(current_user, @job_application.id)
        redirect_to job_applications_path, notice: 'Application was successfully created.'
      else
        # Handle validation errors
        error_message = @job_application.errors.full_messages.join(', ')
        redirect_to job_applications_path, alert: error_message
      end
    rescue StandardError => e
      # Log the error
      Rails.logger.error("Error creating job application: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      redirect_to job_applications_path, alert: "Error: #{e.message}"
    end
  end
end
