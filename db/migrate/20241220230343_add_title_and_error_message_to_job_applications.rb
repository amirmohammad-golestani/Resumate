class AddTitleAndErrorMessageToJobApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :job_applications, :title, :string
    add_column :job_applications, :error_message, :string
  end
end
