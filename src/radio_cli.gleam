import gleam/fetch
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/option.{type Option}
import gleam/string
import pink
import pink/attribute
import pink/hook
import player
import remote_data as rd
import song.{type Song}
import station

type Timer

@external(javascript, "./ffi.mjs", "setTimeout")
fn set_timeout(callback: fn() -> Nil, timeout: Int) -> Timer

@external(javascript, "./ffi.mjs", "clearTimeout")
fn clear_timeout(timer: Timer) -> Nil

pub fn main() {
  pink.render(app())
}

fn app() {
  use <- pink.component()

  let app = hook.app()
  let song = hook.state(rd.Loading)
  let timer = hook.state(option.None)
  let player =
    hook.state(
      station.ChristianRock
      |> station.stream
      |> player.new,
    )
  hook.input(
    fn(input, _key) {
      case input {
        " " ->
          player.value
          |> case player.is_playing(player.value) {
            True -> player.stop
            False -> player.play
          }
          |> player.set
        "q" | "Q" -> {
          player.quit(player.value)
          timer.value
          |> option.map(fn(timer) { clear_timeout(timer) })
          app.exit()
        }
        _ -> Nil
      }
    },
    True,
  )

  hook.effect(
    fn() {
      player.value
      |> player.play
      |> player.set
      get_song(song, timer)
      Nil
    },
    [],
  )

  pink.box(
    [
      attribute.flex_direction(attribute.FlexColumn),
      attribute.justify_content(attribute.ContentCenter),
      attribute.align_items(attribute.ItemsCenter),
      attribute.border_style(attribute.BorderRound),
      attribute.width(
        song.value
        |> rd.to_option
        |> option.map(fn(song) {
          int.max(song.title |> string.length, song.artist |> string.length)
          + 10
        })
        |> option.unwrap(50)
        |> attribute.Spaces,
      ),
      // attribute.Spaces(50)
      attribute.padding_x(4),
    ],
    [
      pink.box([attribute.height(attribute.Spaces(1))], [
        pink.text([], view_play_button(player.is_playing(player.value))),
      ]),
      view_song(song.value),
    ],
  )
}

fn view_play_button(is_playing: Bool) {
  case is_playing {
    True -> " "
    False -> " "
  }
}

fn view_song(song: rd.RemoteData(Song, String)) {
  let show_message = fn(attributes: List(attribute.Attribute), message: String) {
    pink.box(list.prepend(attributes, attribute.height(attribute.Spaces(2))), [
      pink.text([], message),
    ])
  }
  case song {
    rd.NotAsked -> show_message([], "Song not loaded")
    rd.Loading ->
      pink.text_nested([], [pink.spinner("dots"), pink.text([], " Loading")])
    rd.Failure(_) ->
      show_message([attribute.color("red")], "Failed to load song")
    rd.Success(song) ->
      pink.box(
        [
          attribute.flex_direction(attribute.FlexColumn),
          attribute.align_items(attribute.ItemsCenter),
        ],
        [
          pink.text([attribute.bold(True)], song.title),
          pink.text([], song.artist),
        ],
      )
  }
}

fn get_song(
  song_state: hook.State(rd.RemoteData(Song, String)),
  timer: hook.State(Option(Timer)),
) -> Nil {
  song.get(station.ChristianRock)
  |> promise.tap(fn(result_song) {
    case result_song {
      Ok(new_song) ->
        new_song
        |> rd.Success
        |> song_state.set
      Error(error) ->
        song_state.set(rd.Failure(
          "Failed to load song: " <> string.inspect(error),
        ))
    }
  })
  |> promise.rescue(fn(error) {
    song_state.set(rd.Failure("Failed to load song: " <> string.inspect(error)))
    Error(fetch.UnableToReadBody)
  })
  |> promise.tap(fn(_) {
    set_timeout(fn() { get_song(song_state, timer) }, 30_000)
    |> option.Some
    |> timer.set
  })

  Nil
}
