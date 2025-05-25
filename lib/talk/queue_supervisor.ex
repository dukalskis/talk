defmodule Talk.QueueSupervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(client_server_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      %{
        id: Talk.Queue,
        start: {Talk.Queue, :start_link, [client_server_id]},
        restart: :permanent
      }
    )
  end
end
