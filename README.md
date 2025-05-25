# Talk

## Setup

Install Elixir and Erlang. For local app development, the [asdf](https://asdf-vm.com/) solution has been used; refer to the Elixir and Erlang versions in the `.tool-versions` file.

## Why this project?

The app was created as a [homework](https://illustrious-eye-feb.notion.site/Elixir-technical-interview-task-1f37e1a1478c804182cfc67dcf05b381).

## About

All requirements are implemented, except for a secure connection between the servers. The WebSocket provides a connection between the servers.

The implementation is more of a proof of concept, of course, there are many things that could be improved for a production.

## Use

```
PORT=4000 SERVER_ID=1 OTHER_SERVERS='[["2", "ws://localhost:4001/ws"]]' mix run --no-halt
PORT=4001 SERVER_ID=2 OTHER_SERVERS='[["1", "ws://localhost:4000/ws"]]' mix run --no-halt
```

```
curl -X POST localhost:4000/api/messages   -H "content-type: application/json"   -d '{"from":"1-alice", "to":"2-bob", "message":"Hello Bob"}'
```
