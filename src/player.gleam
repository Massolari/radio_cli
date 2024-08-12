import gleam/option.{type Option, None, Some}
import gleam/result
import plinth/node/child_process.{type ChildProcess}
import plinth/node/stream

pub opaque type Player {
  Player(url: String, is_playing: Bool, process: Option(ChildProcess))
}

pub fn new(url: String) {
  Player(url:, is_playing: False, process: None)
}

pub fn play(player: Player) {
  let new_process = case player.process {
    None -> child_process.spawn("vlc", ["-I", "rc", player.url])
    Some(process) -> {
      let _ =
        process
        |> child_process.stdin
        |> result.map(stream.write(_, "play\n"))

      process
    }
  }

  Player(..player, is_playing: True, process: Some(new_process))
}

pub fn stop(player: Player) {
  player.process
  |> option.map(fn(process) {
    process
    |> child_process.stdin
    |> result.map(stream.write(_, "stop\n"))
  })

  Player(..player, is_playing: False)
}

pub fn is_playing(player: Player) -> Bool {
  player.is_playing
}

pub fn quit(player: Player) {
  player.process
  |> option.map(fn(process) { child_process.kill(process) })

  player
}
