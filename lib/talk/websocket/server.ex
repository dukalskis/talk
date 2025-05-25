defmodule Talk.Websocket.Server do
  require Logger

  @behaviour WebSock

  @impl true
  def init(_params) do
    {:ok, nil}
  end

  @impl true
  def handle_in({payload, opcode: :binary}, state) do
    {from, to, message} = :erlang.binary_to_term(payload)

    Logger.info("Got binary: from:#{from} to:#{to} message:#{message}")

    Talk.MessageHandler.write_to_file(to, from, message)
    {:ok, state}
  end

  def handle_in({payload, opcode: :text}, state) do
    Logger.info("Got: #{payload}")
    {:ok, state}
  end

  @impl true
  def handle_info(_, state), do: {:ok, state}

  @impl true
  def terminate(_, _), do: :ok
end
