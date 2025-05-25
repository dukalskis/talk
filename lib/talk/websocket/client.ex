defmodule Talk.Websocket.Client do
  use GenServer
  require Logger

  ## Client

  def start_link(client_server_id, client_server_addr) do
    GenServer.start_link(__MODULE__, {client_server_id, client_server_addr},
      name: via(client_server_id)
    )
  end

  def send_frame(client_server_id, frame) do
    GenServer.cast(via(client_server_id), {:send_frame, frame})
  end

  def send_text(client_server_id, text) do
    GenServer.cast(via(client_server_id), {:send_frame, {:text, text}})
  end

  def send_binary(client_server_id, binary) do
    GenServer.cast(via(client_server_id), {:send_frame, {:binary, binary}})
  end

  def stop(client_server_id) do
    GenServer.stop(via(client_server_id))
  end

  ## Server (callbacks)

  @impl true
  def init({client_server_id, client_server_addr}) do
    %URI{
      scheme: scheme,
      host: host,
      port: port,
      path: path
    } = URI.parse(client_server_addr)

    scheme = String.to_atom(scheme)

    state = %{
      conn: nil,
      websocket: nil,
      ref: nil,
      sceme: scheme,
      host: host,
      port: port,
      path: path,
      status: nil,
      headers: nil,
      client_server_id: client_server_id
    }

    send(self(), :connect)

    {:ok, state}
  end

  @impl true
  def handle_info(:connect, state) do
    %{
      sceme: scheme,
      host: host,
      port: port,
      path: path
    } = state

    case Mint.HTTP.connect(:http, host, port, protocols: [:http1]) do
      {:ok, conn} ->
        case Mint.WebSocket.upgrade(scheme, conn, path, []) do
          {:ok, conn, ref} ->
            {:noreply, %{state | conn: conn, ref: ref}}

          {:error, conn, reason} ->
            Mint.HTTP.close(conn)
            {:stop, {:upgrade_failed, reason}, state}
        end

      {:error, _reason} ->
        Logger.info("Connection failed")
        schedule_connect()
        {:noreply, state}
    end
  end

  def handle_info(:heartbeat, state) do
    send_frame(state.client_server_id, {:ping, ""})
    schedule_heartbeat()
    {:noreply, state}
  end

  def handle_info(message, state) do
    case Mint.WebSocket.stream(state.conn, message) do
      {:ok, conn, responses} ->
        state = %{state | conn: conn}
        state = Enum.reduce(responses, state, &handle_response/2)
        {:noreply, state}

      {:error, conn, reason, _responses} ->
        Logger.info("WebSocket error: #{inspect(reason)}")
        {:stop, reason, %{state | conn: conn}}

      :unknown ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:send_frame, frame}, %{websocket: websocket} = state) when websocket != nil do
    case Mint.WebSocket.encode(websocket, frame) do
      {:ok, websocket, data} ->
        case Mint.WebSocket.stream_request_body(state.conn, state.ref, data) do
          {:ok, conn} ->
            Logger.info("Sent: #{inspect(frame)}")
            {:noreply, %{state | conn: conn, websocket: websocket}}

          {:error, conn, reason} ->
            Logger.info("Failed to send message: #{inspect(reason)}")
            {:noreply, %{state | conn: conn}}
        end

      {:error, websocket, reason} ->
        Logger.info("Failed to encode message: #{inspect(reason)}")
        {:noreply, %{state | websocket: websocket}}
    end
  end

  def handle_cast({:send, _message}, state) do
    Logger.info("WebSocket not ready yet")
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.info("Terminate")

    if state.conn do
      Mint.HTTP.close(state.conn)
    end
  end

  ## Private

  defp handle_response({:status, ref, status}, %{ref: ref} = state) do
    Logger.info("WebSocket upgrade status: #{status}")
    %{state | status: status}
  end

  defp handle_response({:headers, ref, headers}, %{ref: ref} = state) do
    Logger.info("WebSocket upgrade headers: #{inspect(headers)}")
    %{state | headers: headers}
  end

  defp handle_response({:done, ref}, %{ref: ref} = state) do
    case Mint.WebSocket.new(state.conn, ref, state.status, state.headers) do
      {:ok, conn, websocket} ->
        schedule_heartbeat()
        Logger.info("WebSocket connection established!")
        %{state | conn: conn, websocket: websocket}

      {:error, conn, reason} ->
        Logger.info("Failed to establish WebSocket: #{inspect(reason)}")
        %{state | conn: conn}
    end
  end

  defp handle_response({:data, ref, data}, %{ref: ref, websocket: websocket} = state)
       when websocket != nil do
    case Mint.WebSocket.decode(websocket, data) do
      {:ok, websocket, frames} ->
        Enum.each(frames, &handle_frame/1)
        %{state | websocket: websocket}

      {:error, websocket, reason} ->
        Logger.info("Failed to decode WebSocket frame: #{inspect(reason)}")
        %{state | websocket: websocket}
    end
  end

  defp handle_response({:error, ref, reason}, %{ref: ref} = state) do
    Logger.info("WebSocket error: #{inspect(reason)}")
    state
  end

  defp handle_response(response, state) do
    Logger.info("Unhandled response: #{inspect(response)}")
    state
  end

  defp handle_frame({:text, text}) do
    Logger.info("Received: #{text}")
  end

  defp handle_frame({:binary, data}) do
    Logger.info("Received binary: #{inspect(data)}")
  end

  defp handle_frame({:close, code, reason}) do
    Logger.info("WebSocket closed: #{code} - #{reason}")
  end

  defp handle_frame(frame) do
    Logger.info("Received frame: #{inspect(frame)}")
  end

  defp schedule_connect do
    Process.send_after(self(), :connect, 1_000)
  end

  defp schedule_heartbeat do
    Process.send_after(self(), :heartbeat, 30_000)
  end

  defp via(client_server_id) do
    {:via, Registry, {Talk.Websocket.ClientRegistry, client_server_id}}
  end
end
