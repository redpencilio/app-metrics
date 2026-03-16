defmodule Dispatcher do
  use Matcher
  define_accept_types []

  get "/metrics", _ do
    forward conn, [], "http://exporter:9100/metrics"
  end

  get "/container-metrics", _ do
    forward conn, [], "http://cadvisor:8080/metrics"
  end

  ## Rules below are for the cadvisor inteface which we do not make public by default
  # get "/static/*path", _ do
  #   forward conn, path, "http://cadvisor:8080/static/"
  # end

  # match "/api/*path", _ do
  #   forward conn, path, "http://cadvisor:8080/api/"
  # end

  # get "/containers/*path", _ do
  #   forward conn, path, "http://cadvisor:8080/containers/"
  # end

  # get "/docker/*path", _ do
  #   forward conn, path, "http://cadvisor:8080/docker/"
  # end

  match "/*_", %{ last_call: true } do
    send_resp( conn, 404, "Route not found or method not supported" )
  end
end
