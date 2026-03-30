defmodule Dispatcher do
  use Matcher
  define_accept_types []

  get "/metrics", _ do
    forward conn, [], "http://exporter:9100/metrics"
  end

  get "/container-metrics", _ do
    forward conn, [], "http://docker-metrics/metrics"
  end

  match "/*_", %{ last_call: true } do
    send_resp( conn, 404, "Route not found or method not supported" )
  end
end
