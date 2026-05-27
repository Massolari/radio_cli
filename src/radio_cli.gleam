import birl
import birl/duration
import gleam/int
import gleam/list
import gleam/string
import pink
import pink/app
import pink/attribute
import pink/hook
import pink/state.{type State}
import player.{type Player}
import plinth/javascript/console
import plinth/javascript/global
import plinth/node/process
import remote_data as rd
import song.{type Song}
import station.{
  type Station, ChristianHits, ChristianLofi, ChristianRock, GospelHits, Melodia,
}
import zip_list.{type ZipList}

@external(javascript, "./ffi.mjs", "setInterval")
fn set_interval(time: Int, handler: fn() -> Nil) -> global.TimerID

@external(javascript, "./ffi.mjs", "clearInterval")
fn clear_interval(timer: global.TimerID) -> Nil

const first_station = ChristianRock

const rest_stations = [ChristianHits, ChristianLofi, GospelHits, Melodia]

pub fn main() {
  console.clear()
  pink.render(app())
}

fn app() {
  use <- pink.component()

  let app = app.get()
  let song = state.init(rd.Loading)
  let counter = state.init(0)
  let song_last_updated = state.init(birl.now())
  let stations = state.init(zip_list.new([], first_station, rest_stations))
  let selected: State(Station) =
    stations
    |> state.get
    |> zip_list.current
    |> state.init

  let player: State(Player) =
    selected
    |> state.get
    |> station.stream
    |> player.new
    |> state.init

  hook.input(
    fn(input, _key) {
      case input {
        " " ->
          state.set_with(player, fn(player_value) {
            player_value
            |> case player.is_playing(player_value) {
              True -> player.stop
              False -> player.resume
            }
          })

        "j" -> state.set_with(stations, zip_list.next_wrap)

        "J" -> {
          let next_stations =
            stations
            |> state.get
            |> zip_list.next_wrap

          state.set(stations, next_stations)
          state.set(selected, zip_list.current(next_stations))
        }

        "G" -> state.set_with(stations, zip_list.last)

        "k" -> state.set_with(stations, zip_list.previous_wrap)

        "K" -> {
          let previous_stations =
            stations
            |> state.get
            |> zip_list.previous_wrap

          state.set(stations, previous_stations)
          state.set(selected, zip_list.current(previous_stations))
        }

        "g" -> state.set_with(stations, zip_list.first)

        "r" -> {
          state.set(song, rd.Loading)
          let _ = get_song(player:, song:, song_last_updated:)
          Nil
        }

        "R" -> state.set_with(player, player.restart)

        "\r" -> {
          let station =
            stations
            |> state.get
            |> zip_list.current

          case station == state.get(selected) {
            True -> Nil
            False -> state.set(selected, station)
          }
        }

        "q" | "Q" -> {
          player
          |> state.get
          |> player.quit

          app.exit(app)
          process.exit(0)
          Nil
        }
        _ -> Nil
      }
    },
    True,
  )

  hook.effect_clean(
    fn() {
      state.set_with(player, player.resume)

      get_song(player:, song:, song_last_updated:)

      let timer_id =
        set_interval(1000, fn() { state.set_with(counter, int.add(_, 1)) })

      fn() { clear_interval(timer_id) }
    },
    [],
  )

  hook.effect(
    fn() {
      let _ = get_song(player:, song:, song_last_updated:)
      Nil
    },
    [
      state.get(counter),
    ],
  )

  hook.effect(
    fn() {
      let _ = change_station(selected, player, song, song_last_updated)
      Nil
    },
    [state.get(selected)],
  )

  pink.box([], [
    view_stations(selected, stations),
    //
    view_player(song, player),
  ])
}

fn view_player(
  song: State(rd.RemoteData(Song, String)),
  player: State(Player),
) {
  let song_value = state.get(song)

  pink.box(
    [
      attribute.flex_direction(attribute.FlexColumn),
      attribute.justify_content(attribute.ContentCenter),
      attribute.align_items(attribute.ItemsCenter),
      attribute.border_style(attribute.BorderSingle),
      attribute.min_width(20),
      attribute.width(
        case song_value {
          rd.NotAsked -> 20
          rd.Loading -> 20
          rd.Success(song) ->
            song.title
            |> string.length
            |> int.max(string.length(song.artist))
            |> int.add(6)
            |> int.max(20)
          rd.Failure(error) -> string.length(error)
        }
        |> attribute.Spaces,
      ),
      attribute.padding_x(2),
    ],
    [
      pink.text(
        [],
        view_play_button(
          player
          |> state.get
          |> player.is_playing,
        ),
      ),
      view_song(song_value),
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

fn view_stations(selected: State(Station), stations: State(ZipList(Station))) {
  let station_list = [first_station, ..rest_stations]

  pink.box(
    [
      attribute.border_style(attribute.BorderSingle),
      attribute.flex_direction(attribute.FlexColumn),
      attribute.padding_right(1),
    ],
    list.map(station_list, fn(station) {
      view_station(station, selected, stations)
    }),
  )
}

fn view_station(
  station: Station,
  selected: State(Station),
  stations: State(ZipList(Station)),
) {
  let cursor = case station == zip_list.current(state.get(stations)) {
    True -> "> "
    False -> "  "
  }

  let selected_attributes = case station == state.get(selected) {
    True -> [attribute.bold(True), attribute.underline(True)]
    False -> []
  }

  pink.text_nested([], [
    pink.text([], cursor),
    pink.text(selected_attributes, station.to_string(station)),
  ])
}

// Helper

fn get_song(
  player player: State(Player),
  song song_state: State(rd.RemoteData(Song, String)),
  song_last_updated song_last_updated: State(birl.Time),
) -> Nil {
  let metadata_song = player.get_now_playing(state.get(player))
  case metadata_song {
    Ok(metatada) -> {
      metatada
      |> station.get_song_from_metadata
      |> rd.Success
      |> state.set(song_state, _)

      state.set(song_last_updated, birl.now())
    }
    Error(_) -> {
      let difference = birl.difference(birl.now(), state.get(song_last_updated))

      case duration.blur_to(difference, duration.Second) >= 30 {
        False -> Nil
        True -> {
          state.set(song_state, rd.Failure("Unable to get song information"))

          state.set(song_last_updated, birl.now())
        }
      }
    }
  }
}

fn change_station(
  station: State(Station),
  player: State(Player),
  song: State(rd.RemoteData(Song, String)),
  song_last_updated: State(birl.Time),
) {
  state.set(song, rd.Loading)

  player
  |> state.set_with(player.play(_, station.stream(state.get(station))))

  get_song(player:, song:, song_last_updated:)
}
