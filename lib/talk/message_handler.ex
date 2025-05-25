defmodule Talk.MessageHandler do
  def handle(from, to, message) do
    [to_server_id, _to_user] = String.split(to, "-", parts: 2)
    server_id = Application.fetch_env!(:talk, :server_id)

    if to_server_id == server_id do
      write_to_file(to, from, message)
    else
      payload = :erlang.term_to_binary({from, to, message})
      Talk.Websocket.Client.send_binary(to_server_id, payload)
    end
  end

  def write_to_file(user_id, from, message) do
    line = "#{from}: #{message}\n"
    File.write("./user_data/#{user_id}.txt", line, [:append, :utf8])
  end
end
