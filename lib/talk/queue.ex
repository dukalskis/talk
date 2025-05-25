defmodule Talk.Queue do
  use GenServer
  require Logger

  ## Client

  def start_link(client_server_id) do
    GenServer.start_link(__MODULE__, [], name: via(client_server_id))
  end

  def put(client_server_id, value) do
    GenServer.cast(via(client_server_id), {:put, value})
  end

  def pop_all(client_server_id) do
    GenServer.call(via(client_server_id), :pop_all)
  end

  ## Server (callbacks)

  @impl true
  def init(_init_args) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:put, value}, state) do
    {:noreply, [value | state]}
  end

  @impl true
  def handle_call(:pop_all, _from, state) do
    {:reply, Enum.reverse(state), []}
  end

  ## Private

  defp via(client_server_id) do
    {:via, Registry, {Talk.QueueRegistry, client_server_id}}
  end
end
