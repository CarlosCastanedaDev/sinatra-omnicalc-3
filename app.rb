require "sinatra"
require "sinatra/reloader"
require "http"

# API Keys
gmap = ENV.fetch('GMAPS_KEY')
pirate = ENV.fetch('PIRATE_WEATHER_KEY')

get("/") do
  erb(:home)
end

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
