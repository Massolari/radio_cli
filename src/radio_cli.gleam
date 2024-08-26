import gleam/fetch
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/option.{type Option}
import gleam/string
import pink
import pink/app
import pink/attribute
import pink/hook
import pink/state.{type State}
import player.{type Player}
import plinth/javascript/console
import plinth/javascript/global
import remote_data as rd
import song.{type Song}
import station.{
  type Station, ChristianHits, ChristianRock, GospelMix, LofiGirl, Melodia,
}
import zip_list.{type ZipList}

/// Time in milliseconds to wait before fetching the current song again
const get_song_frequency = 30_000

pub fn main() {
  console.clear()
  pink.render(app())
}

fn app() {
  use <- pink.component()

  let app = app.get()
  let song = state.init(rd.Loading)
  let timer = state.init(option.None)
  let stations =
    state.init(
      zip_list.new([], ChristianRock, [
        ChristianHits,
        GospelMix,
        LofiGirl,
        Melodia,
      ]),
    )
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
              False -> player.play
            }
          })

        "j" -> state.set_with(stations, zip_list.next_warp)

        "G" -> state.set_with(stations, zip_list.last)

        "k" -> state.set_with(stations, zip_list.previous_warp)

        "g" -> state.set_with(stations, zip_list.first)

        "\r" -> {
          let station =
            stations
            |> state.get
            |> zip_list.current

          case station == state.get(selected) {
            True -> Nil
            False -> {
              state.set(selected, station)

              station
              |> change_station(player, song, timer)
            }
          }
        }

        "q" | "Q" -> {
          player
          |> state.get
          |> player.quit

          timer
          |> state.get
          |> option.map(fn(timer) { global.clear_timeout(timer) })

          app.exit(app)
        }
        _ -> Nil
      }
    },
    True,
  )

  hook.effect(
    fn() {
      state.set_with(player, player.play)

      selected
      |> state.get
      |> get_song(song, timer)

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

fn view_player(song: State(rd.RemoteData(Song, String)), player: State(Player)) {
  let song_value = state.get(song)

  pink.box(
    [
      attribute.flex_direction(attribute.FlexColumn),
      attribute.justify_content(attribute.ContentCenter),
      attribute.align_items(attribute.ItemsCenter),
      attribute.border_style(attribute.BorderRound),
      attribute.width(
        case song_value {
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
        pink.text(
          [],
          view_play_button(
            player
            |> state.get
            |> player.is_playing,
          ),
        ),
      ]),
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
  let station_list = [
    ChristianRock,
    ChristianHits,
    GospelMix,
    LofiGirl,
    Melodia,
  ]

  pink.box(
    [
      attribute.border_style(attribute.BorderRound),
      attribute.flex_direction(attribute.FlexColumn),
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
  let cursor = fn(station_) {
    case station_ == zip_list.current(state.get(stations)) {
      True -> "> "
      False -> "  "
    }
  }

  let selected_attributes = fn(station_) {
    case station_ == state.get(selected) {
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
  song_state: State(rd.RemoteData(Song, String)),
  timer: State(Option(global.TimerID)),
) -> Nil {
  station
  |> station.get_song
  |> promise.tap(fn(result_song) {
    case result_song {
      Ok(new_song) ->
        new_song
        |> rd.Success
        |> state.set(song_state, _)
      Error(error) ->
        state.set(
          song_state,
          rd.Failure("Failed to load song: " <> string.inspect(error)),
        )
    }
  })
  |> promise.rescue(fn(error) {
    state.set(
      song_state,
      rd.Failure("Failed to load song: " <> string.inspect(error)),
    )
    Error(fetch.UnableToReadBody)
  })
  |> promise.tap(fn(_) {
    global.set_timeout(get_song_frequency, fn() {
      get_song(station, song_state, timer)
    })
    |> option.Some
    |> state.set(timer, _)
  })

  Nil
}

fn change_station(
  station: Station,
  player: State(Player),
  song: State(rd.RemoteData(Song, String)),
  timer: State(Option(global.TimerID)),
) {
  state.set(song, rd.Loading)
  player
  |> state.get
  |> player.quit

  station
  |> station.stream
  |> player.new
  |> player.play
  |> state.set(player, _)

  timer
  |> state.get
  |> option.map(global.clear_timeout)

  global.set_timeout(0, fn() { get_song(station, song, timer) })

  Nil
}
