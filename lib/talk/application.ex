defmodule Talk.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:talk, :port)
    server_id = Application.fetch_env!(:talk, :server_id)
    servers = Application.fetch_env!(:talk, :servers)

    children = [
      {Registry, [keys: :unique, name: Talk.QueueRegistry]},
      {Registry, [keys: :unique, name: Talk.Websocket.ClientRegistry]},
      {Bandit, plug: Talk.Router, scheme: :http, port: port},
      {Talk.QueueSupervisor, []},
      {Talk.Websocket.ClientSupervisor, []},
      {Task, fn -> start_websocket_clients(servers) end}
    ]

    Logger.info("Starting server #{server_id}")

    opts = [strategy: :one_for_one, name: Talk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_websocket_clients(servers) do
    servers
    |> Enum.each(fn {client_server_id, client_server_addr} ->
      Talk.QueueSupervisor.start_child(client_server_id)
      Talk.Websocket.ClientSupervisor.start_child(client_server_id, client_server_addr)
    end)
  end
end
