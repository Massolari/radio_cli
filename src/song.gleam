import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Song {
  Song(artist: String, title: String)
}

pub fn gospel_mix_decoder() -> decode.Decoder(Song) {
  use track <- decode.field("currentTrack", decode.string)
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
  |> decode.success
}

pub fn christianrock_decoder() -> decode.Decoder(Song) {
  use artist <- decode.field("Artist", decode.string)
  use title <- decode.field("Title", decode.string)
  decode.success(Song(artist, title))
}

pub fn melodia_decoder(xml: String) -> Result(Song, String) {
  use #(title, rest) <- result.try(get_melodia_xml_data("cue_title", xml))
  use #(artist, _) <- result.map(get_melodia_xml_data("track_artist_name", rest))

  Song(artist:, title:)
}

fn get_melodia_xml_data(
  name: String,
  xml: String,
) -> Result(#(String, String), String) {
  xml
  |> string.split(name <> "\"><![CDATA[")
  |> list.last
  |> result.map_error(fn(_) { "Could not get " <> name })
  |> result.try(fn(from_title_chunk) {
    string.split_once(from_title_chunk, "]]")
    |> result.map_error(fn(_) { "Could not get " <> name })
  })
}
