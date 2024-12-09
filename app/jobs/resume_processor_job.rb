require './app/services/anthropic_service'
require './app/services/pdf_parser_service'
require './app/services/resume_builder_service'

class ResumeProcessorJob < ApplicationJob
  queue_as :default

  def perform(current_user, job_application_id)

    job_application = JobApplication.find(job_application_id)
    job_application.update(status: :processing)

    begin
      temp_file = Tempfile.new(['original_resume', '.pdf'], binmode: true)
      temp_file.write(job_application.original_resume.download)
      resume_content = PdfParserService.new(temp_file).extract_content
      new_resume_content = AnthropicService.new(resume_content, job_application.job_description).polish_resume
      puts new_resume_content
      new_job_application = ResumeBuilderService.new(new_resume_content).generate_resume_and_cover_letter
      begin
        resume_file = Tempfile.new([new_job_application.resume_filename, '.pdf'], binmode: true)
        cover_letter_file = Tempfile.new([new_job_application.cover_letter_filename, '.pdf'], binmode: true)
        resume_file.write(new_job_application.pdf)
        cover_letter_file.write(new_job_application.cover_letter)
        resume_file.rewind
        cover_letter_file.rewind
        job_application.transaction do
          job_application.refined_resume.attach(
            io: resume_file,
            filename: new_job_application.resume_filename,
            content_type: "application/pdf"
          )
          job_application.cover_letter.attach(
            io: cover_letter_file,
            filename: new_job_application.cover_letter_filename,
            content_type: "application/pdf"
          )
          job_application.update!(
            title: new_job_application.job_application_title,
            status: :completed
          )
        end

      ensure
        temp_file.close
        temp_file.unlink
        resume_file.close
        resume_file.unlink
        cover_letter_file.close
        cover_letter_file.unlink
      end
    rescue StandardError => e
      Rails.logger.error "Error occurred: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      job_application.update(
        status: :failed,
      )
    end
  end
end
