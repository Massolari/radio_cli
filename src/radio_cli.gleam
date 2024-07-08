import gleam/fetch
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/option.{type Option}
import gleam/string
import pink
import pink/attribute
import pink/hook
import player.{type Player}
import remote_data as rd
import song.{type Song}
import station.{type Station, ChristianRock, GospelMix}

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
  let selected_station = hook.state(GospelMix)
  let player =
    hook.state(
      selected_station.value
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
        "j" | "J" if selected_station.value != GospelMix -> {
          selected_station.set(GospelMix)

          change_station(GospelMix, player, song, timer)
        }

        "k" | "K" if selected_station.value != ChristianRock -> {
          selected_station.set(ChristianRock)

          change_station(ChristianRock, player, song, timer)
        }

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
      get_song(selected_station.value, song, timer)
      Nil
    },
    [],
  )

  pink.box([], [
    view_stations(selected_station),
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
          |> option.unwrap(20)
          |> attribute.Spaces,
        ),
        attribute.padding_x(4),
      ],
      [
        pink.box([attribute.height(attribute.Spaces(1))], [
          pink.text([], view_play_button(player.is_playing(player.value))),
        ]),
        view_song(song.value),
      ],
    ),
  ])
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
      pink.text_nested([], [
        pink.spinner("dots"),
        pink.text([attribute.height(attribute.Spaces(2))], " Loading\n"),
      ])
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

fn view_stations(station: hook.State(Station)) {
  let selected_attributes = fn(station_) {
    case station_ == station.value {
      True -> [attribute.bold(True), attribute.underline(True)]
      False -> []
    }
  }

  pink.box(
    [
      attribute.border_style(attribute.BorderRound),
      attribute.flex_direction(attribute.FlexColumn),
    ],
    [
      pink.text(
        selected_attributes(ChristianRock),
        station.to_string(ChristianRock),
      ),
      pink.text(selected_attributes(GospelMix), station.to_string(GospelMix)),
    ],
  )
}

// Helper

fn get_song(
  station: Station,
  song_state: hook.State(rd.RemoteData(Song, String)),
  timer: hook.State(Option(Timer)),
) -> Nil {
  station
  |> station.get_song
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
    set_timeout(fn() { get_song(station, song_state, timer) }, 30_000)
    |> option.Some
    |> timer.set
  })

  Nil
}

fn change_station(
  station: Station,
  player: hook.State(Player),
  song: hook.State(rd.RemoteData(Song, String)),
  timer: hook.State(Option(Timer)),
) {
  song.set(rd.Loading)
  player.quit(player.value)
  station
  |> station.stream
  |> player.new
  |> player.play
  |> player.set

  option.map(timer.value, clear_timeout)

  set_timeout(fn() { get_song(station, song, timer) }, 0)

  Nil
}
