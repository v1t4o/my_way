require './my_way'

# Sinatra (optional) config
enable :logging, :static

configure :production do
  disable :logging
end

run Sinatra::Application