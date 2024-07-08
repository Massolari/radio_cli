import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/list
import gleam/string

pub type Song {
  Song(artist: String, title: String)
}

pub fn gospel_mix_decoder(
  json: Dynamic,
) -> Result(Song, List(dynamic.DecodeError)) {
  dynamic.decode1(
    fn(track: String) {
      let splitted =
        track
        |> string.split(" - ")
        |> list.filter_map(fn(part) {
          case int.parse(part) {
            Ok(_) -> Error(Nil)
            Error(_) ->
              case part {
                "Ao Vivo" -> Error(Nil)
                _ -> Ok(part)
              }
          }
        })

      case splitted {
        [artist, title] -> Song(artist, title)
        _ -> Song(artist: "", title: track)
      }
    },
    dynamic.field("currentTrack", of: dynamic.string),
  )(json)
}

pub fn christianrock_decoder(
  json: Dynamic,
) -> Result(Song, List(dynamic.DecodeError)) {
  dynamic.decode2(
    Song,
    dynamic.field("Artist", of: dynamic.string),
    dynamic.field("Title", of: dynamic.string),
  )(json)
}
