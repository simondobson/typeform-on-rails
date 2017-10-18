require 'json'

class TypeformRequest
  def initialize(form_id)
    args = {
      method: :get,
      url: "https://api.typeform.com/forms/#{form_id}"
    }
    request(args)
  end

  def request(args = {})
    RestClient::Request.execute(args) { |r| @response = r }
  end

  def success?
    @response.code == 200
  end

  def json
    JSON.parse(@response, symbolize_names: true)
  end

  def blocks
    json[:fields]
  end
end
