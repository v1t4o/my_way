name = "myway"
port 8080

environment "production"

RUN="/tmp/"

pidfile "#{RUN}/puma-#{name}.pid"
bind "unix://#{RUN}/puma-#{name}.sock"
state_path "#{RUN}/puma-#{name}.state"

tag name

workers 3
threads 1, 5

preload_app!