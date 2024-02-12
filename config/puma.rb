name = "myway"
port 8080

environment "production"

RUN="/tmp/"

pidfile "#{RUN}/puma-#{name}.pid"
bind "unix://#{RUN}/puma-#{name}.sock"
state_path "#{RUN}/puma-#{name}.state"

tag name

workers ENV.fetch("WEB_CONCURRENCY") { 3 }
threads 0, 5

preload_app!