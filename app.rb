require "sinatra"
require "sinatra/reloader"
require "http"

# API Keys
gmap = ENV.fetch('GMAPS_KEY')
pirate = ENV.fetch('PIRATE_WEATHER_KEY')
openai = ENV.fetch('OPEN_AI_KEY')

get("/") do
  erb(:home)
end

# Weather 
get('/umbrella') do
  erb(:umbrella)
end

post('/process_umbrella') do
  @location = params.fetch('user_loc')
  @loc_sub = @location.gsub(" ", "+")

  # Get location data
  gmap_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{@loc_sub}&key=#{gmap}"

  gmap_response = HTTP.get(gmap_url)

  parsed_response = JSON.parse(gmap_response)

  @lat = parsed_response.dig("results", 0 , "geometry", "location", "lat")
  @lng = parsed_response.dig("results", 0 , "geometry" , "location", "lng")

  # Get weather data
  pirate_url = "https://api.pirateweather.net/forecast/#{pirate}/#{@lat},#{@lng}"

  pirate_response = HTTP.get(pirate_url)

  parsed_pirate_response = JSON.parse(pirate_response)

  @temp = parsed_pirate_response.dig("currently", "temperature")
  @summary = parsed_pirate_response.dig("hourly", "summary")

  precip_threshold = 0.10
  precip = false

  twelve_hours = parsed_pirate_response["hourly"].fetch("data")[1..12]

  twelve_hours.each do |precipPossible|
    probability = precipPossible.fetch("precipProbability")
    if probability >= precip_threshold
      precip = true
    end
  end

  @umbrella_required = precip ? "You might want to take an umbrella!" : "You probably won't need an umbrella."
  erb(:umbrella_results)
end


# Single AI message
get("/message") do
  erb(:single_chat)
end

post("/process_single_message") do
  @message = params.fetch("the_message")

  request_headers_hash = {
  "Authorization" => "Bearer #{openai}",
  "content-type" => "application/json"
}

request_body_hash = {
  "model" => "gpt-3.5-turbo",
  "messages" => [
    {
      "role" => "user",
      "content" => @message
    }
  ]
}

request_body_json = JSON.generate(request_body_hash)

raw_response = HTTP.headers(request_headers_hash).post(
  "https://api.openai.com/v1/chat/completions",
  :body => request_body_json
).to_s

@parsed_response = JSON.parse(raw_response)

erb(:message_results)
end

# Chat with multiple messages
get("/chat") do
  erb(:chat)
end

post("/add_message_to_chat") do

end

post("/clear_chat") do

end
