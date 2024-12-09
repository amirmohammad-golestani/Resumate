class ResumeBuilderService
  def initialize resume
    @resume = resume
  end

  def generate_resume_and_cover_letter
    resume = Grover.new(render_resume_template).to_pdf
    cover_letter = Grover.new(render_cover_letter_template).to_pdf
    RefinedResume.new(resume, cover_letter, @resume["resume_filename"], @resume["resume_filename"], "cover_letter_#{@resume["resume_filename"]}")
  end

  private

  def render_resume_template
    puts @resume
    template_path = Rails.root.join('app', 'lib', 'resume_templates', 'main.html.erb')
    template = File.read(template_path)
    ERB.new(template).result(binding)
  end

  def render_cover_letter_template
    template_path = Rails.root.join('app', 'lib', 'cover_letter_templates', 'main.html.erb')
    template = File.read(template_path)
    ERB.new(template).result(binding)
  end
end

class RefinedResume
  attr_accessor :pdf, :cover_letter, :job_application_title, :resume_filename, :cover_letter_filename

  def initialize(pdf, cover_letter, job_application_title, resume_filename, cover_letter_filename)
    @pdf = pdf
    @cover_letter = cover_letter
    @job_application_title = job_application_title
    @resume_filename = resume_filename
    @cover_letter_filename = cover_letter_filename
  end
end
