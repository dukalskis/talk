import Config

servers =
  System.get_env("OTHER_SERVERS", "[]")
  |> Jason.decode!()
  |> Enum.map(fn [id, addr] -> {id, addr} end)

config :talk,
  port: System.get_env("PORT", "4000") |> String.to_integer(),
  server_id: System.get_env("SERVER_ID", "1"),
  servers: servers
