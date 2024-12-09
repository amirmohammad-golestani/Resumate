class PdfParserService
  def initialize pdf
    @pdf = pdf
  end

  def extract_content
    content = ""
    begin
      reader = PDF::Reader.new(@pdf)
      reader.pages.each do |page|
        content += page.text + "\n"
      end
      content.strip
      rescue PDF::Reader::MalformedPDFError => e
        raise "Invalid PDF format: #{e.message}"
      rescue StandardError => e
        raise "Error extracting PDF content: #{e.message}"
    end
  end
end
