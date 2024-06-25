import gleam/option.{type Option, None, Some}

type ChildProcess {
  ChildProcess(kill: fn() -> Nil, stdin: Stdin)
}

type Stdin {
  Stdin(write: fn(String) -> Nil)
}

@external(javascript, "./player_ffi.mjs", "spawn_")
fn spawn(command: String, arguments: List(String)) -> ChildProcess

pub opaque type Player {
  Player(url: String, is_playing: Bool, process: Option(ChildProcess))
}

pub fn new(url: String) {
  Player(url: url, is_playing: False, process: None)
}

pub fn play(player: Player) {
  let new_process = case player.process {
    None -> spawn("vlc", ["-I", "rc", player.url])
    Some(process) -> {
      process.stdin.write("play\n")
      process
    }
  }

  Player(..player, is_playing: True, process: Some(new_process))
}

pub fn stop(player: Player) {
  player.process
  |> option.map(fn(process) { process.stdin.write("stop\n") })

  Player(..player, is_playing: False)
}

pub fn is_playing(player: Player) -> Bool {
  player.is_playing
}

pub fn quit(player: Player) {
  player.process
  |> option.map(fn(process) { process.kill() })

  player
}
