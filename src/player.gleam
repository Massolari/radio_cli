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

pub fn play(player: Player, url: String) {
  let new_process = {
    use process <- run_if_process_exists(player)
    let _ = send_process_command(process, "clear\n")
    let _ = send_process_command(process, "add " <> url <> "\n")
    let _ = send_process_command(process, "play\n")

    process
  }

  Player(url:, is_playing: True, process: Some(new_process))
}

pub fn resume(player: Player) {
  let new_process = {
    use process <- run_if_process_exists(player)
    let _ = send_process_command(process, "play\n")

    process
  }

  Player(..player, is_playing: True, process: Some(new_process))
}

pub fn stop(player: Player) {
  send_command(player, "stop\n")

  Player(..player, is_playing: False)
}

pub fn is_playing(player: Player) -> Bool {
  player.is_playing
}

pub fn quit(player: Player) {
  send_command(player, "quit\n")
  player.process
  |> option.map(fn(process) { child_process.kill(process) })

  player
}

pub fn restart(player: Player) {
  quit(player)

  player.url
  |> new
  |> resume
}

fn send_command(player: Player, command: String) {
  option.map(player.process, send_process_command(_, command))
}

fn send_process_command(process: ChildProcess, command: String) {
  process
  |> child_process.stdin
  |> result.map(stream.write(_, command))
}

fn run_if_process_exists(player: Player, f: fn(ChildProcess) -> ChildProcess) {
  case player.process {
    None -> child_process.spawn("vlc", ["-I", "rc", player.url])
    Some(process) -> f(process)
  }
}
