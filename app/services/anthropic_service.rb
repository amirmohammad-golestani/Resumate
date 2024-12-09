require 'net/http'
require 'ostruct'

class AnthropicService
  BASE_URL = "https://api.anthropic.com/v1/messages"
  API_KEY = Rails.application.credentials.dig(:claude, :api_key)

  def initialize(resume, job_description)
    @resume = resume
    @job_description = job_description
  end

  def polish_resume
    begin
      ai_response = request
      content = parse_json(ai_response)
    rescue JSON::ParserError => e
      raise "JSON Parsing Error: #{e.message}"
    rescue StandardError => e
      raise "Processing Error: #{e.message}"
    end
  end


  private

  def parse_json(ai_response)
    content = ai_response["content"].first["text"]
    json_match = content.match(/\{.*\}/m)
    if json_match
      JSON.parse(json_match[0], object_class: OpenStruct)
    else
      raise "Could not extract valid JSON from Claude's response"
    end
  rescue JSON::ParserError => e
    # Handle parsing errors if needed
    puts "Failed to parse JSON: #{e.message}"
    nil
  end

  def request
    uri = URI.parse(BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['x-api-key'] = API_KEY
    request['anthropic-version'] = '2023-06-01'
    request['Content-Type'] = 'application/json'

    message = {
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 4000,
      temperature: 1,
      system: system_prompt,
      messages: [
        {
          role: 'user',
          content: user_prompt(@resume, @job_description)
        }
      ]
    }
    request.body = message.to_json

    begin
      response = http.request(request)

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      else
        { error: "Request failed with status: #{response.code}", response: request.body}
      end
    rescue StandardError => e
      { error: "Request failed", details: e.message }
    end
  end

  def system_prompt
    <<~PROMPT
      You are a professional Resume analyzer. In order to train employees for new positions,
      the ideal resumes must be exist to setup goals for them. You will be given a current resume
      and new position job description and you will follow the instructions to build a new resume based on given inputs:
      1. VERY IMPORTANT: JUST CREATE a JSON OBJECT BASED ON THE GIVEN SCHEMA AND NOTHING MORE.
      2. Identify top 10 keywords from job description, and use them in summary or highlights in the resume.
      3. Transform work achievements into data-driven statements. Use the STAR (Situation-Task-Action-Result) method. Include an "impact rating" for each.
      4. Craft a (professional and general) resume label under 45 characters and also a compelling summary based on the job description under 100 words.
      5. Craft an unique resume file name for the refined resume without using the word "resume" less than 10 character.
      6. Craft a full cover letter without datetime based on the job description and resume (Please format the content with \\n for newlines and proper JSON escaping).
      schema:
      {
        "resume_filename": "",
        "resume_label": "",
        "personal_information": {
          "name": "",
          "summary": "",
          "email": "// if exists",
          "phone_number": "// if exists",
          "url": " // website or portfolio of the owner if it exists",
          "location": "//location of the owner if it exists",
        },
        "works": [{
          "company_name": "",
          "position": "",
          "location": ""
          "start_date": " // format of Month-code YYYY",
          "end_date": " // format Month-code YYYY ",
          "summary": " // add description or summary for the company around 30 words",
          "highlights": [
            // list of highlights,add more responsibilities based on the role.
          ]
        }],
        // Add This section if any project exists
        "projects": [// structure like this: {
          "name": "",
          "description": "",
          "highlights": [
            // list of highlights,add more responsibilities based on the role.
          ]
        }],
        "educations": [{
          "institution": "",
          "field: ""
          "degree": ""
          "start_date": "",
          "end_date": "",
        }],
        "skills": [// structure like this: {
          "category_name": "",
          "data": [
            // list of similar skills or tools mentioned in both resume and job description.
          ]
        }],
        "awards": [
          // list of awards if it exists
        ],
        "cover_letter": {
          "title": "",
          "content": ""
        }
      }
    PROMPT
  end

  def user_prompt(resume, job_description)
    <<~PROMPT
      Resume Content: """#{resume}""",
      Job description: """#{job_description}"""
    PROMPT
  end
end
