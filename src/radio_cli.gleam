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
import station.{type Station, ChristianRock, GospelMix, LofiGirl}
import zip_list.{type ZipList}

/// Time in milliseconds to wait before fetching the current song again
const get_song_frequency = 30_000

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
  let stations =
    hook.state(zip_list.new([], ChristianRock, [GospelMix, LofiGirl]))
  let selected = hook.state(zip_list.current(stations.value))
  let player =
    hook.state(
      selected.value
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
        "j" ->
          stations.value
          |> zip_list.next_warp
          |> stations.set

        "J" ->
          stations.value
          |> zip_list.last
          |> stations.set

        "k" ->
          stations.value
          |> zip_list.previous_warp
          |> stations.set

        "K" ->
          stations.value
          |> zip_list.first
          |> stations.set

        "\r" -> {
          let station = zip_list.current(stations.value)

          case station == selected.value {
            True -> Nil
            False -> {
              selected.set(station)
              station
              |> change_station(player, song, timer)
            }
          }
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

      get_song(selected.value, song, timer)
      Nil
    },
    [],
  )

  pink.box([], [
    view_stations(selected, stations),
    //
    view_player(song, player),
  ])
}

fn view_player(
  song: hook.State(rd.RemoteData(Song, String)),
  player: hook.State(Player),
) {
  pink.box(
    [
      attribute.flex_direction(attribute.FlexColumn),
      attribute.justify_content(attribute.ContentCenter),
      attribute.align_items(attribute.ItemsCenter),
      attribute.border_style(attribute.BorderRound),
      attribute.width(
        case song.value {
          rd.NotAsked -> 20
          rd.Loading -> 20
          rd.Success(song) ->
            int.max(song.title |> string.length, song.artist |> string.length)
            + 10
          rd.Failure(error) -> string.length(error) + 10
        }
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
      pink.text_nested([], [
        pink.spinner("dots"),
        pink.text([attribute.height(attribute.Spaces(2))], " Loading\n"),
      ])
    rd.Failure(error) -> show_message([attribute.color("red")], error)
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

fn view_stations(
  selected: hook.State(Station),
  stations: hook.State(ZipList(Station)),
) {
  pink.box(
    [
      attribute.border_style(attribute.BorderRound),
      attribute.flex_direction(attribute.FlexColumn),
    ],
    [
      view_station(ChristianRock, selected, stations),
      view_station(GospelMix, selected, stations),
      view_station(LofiGirl, selected, stations),
    ],
  )
}

fn view_station(
  station: Station,
  selected: hook.State(Station),
  stations: hook.State(ZipList(Station)),
) {
  let cursor = fn(station_) {
    case station_ == zip_list.current(stations.value) {
      True -> "> "
      False -> "  "
    }
  }

  let selected_attributes = fn(station_) {
    case station_ == selected.value {
      True -> [attribute.bold(True), attribute.underline(True)]
      False -> []
    }
  }

  pink.text_nested([], [
    pink.text([], cursor(station)),
    pink.text(selected_attributes(station), station.to_string(station)),
  ])
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
    set_timeout(
      fn() { get_song(station, song_state, timer) },
      get_song_frequency,
    )
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
