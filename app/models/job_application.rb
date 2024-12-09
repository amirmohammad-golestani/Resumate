class JobApplication < ApplicationRecord
  default_scope { order(created_at: :desc) }
  
  belongs_to :user
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending
  validates :original_resume, presence: true
  validates :job_description, presence: true
  has_one_attached :original_resume
  has_one_attached :refined_resume
  has_one_attached :cover_letter
  
  after_update_commit -> {
    broadcast_replace_later_to(
      "user-#{user_id}-job_applications",
      target: "job_application-#{id}",
      partial: "job_applications/job_application",
      locals: { job_application: self }
    )
  }
end
