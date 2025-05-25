defmodule Talk.Router do
  use Plug.Router
  require Logger

  alias Talk.MessageHandler

  plug(Plug.Parsers,
    parsers: [:json],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  post "/api/messages" do
    %{"from" => from, "to" => to, "message" => message} = conn.body_params
    Logger.info("Received message from #{from} to #{to}, message #{message}")

    case MessageHandler.handle(from, to, message) do
      :ok -> send_resp(conn, 200, "Delivered")
      {:error, reason} -> send_resp(conn, 500, "Error: #{inspect(reason)}")
    end
  end

  get "/ws" do
    WebSockAdapter.upgrade(conn, Talk.Websocket.Server, conn.params, [])
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
