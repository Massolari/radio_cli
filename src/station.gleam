import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/string
import song.{type Song}

pub type Station {
  ChristianHits
  ChristianRock
  GospelHits
  ChristianLofi
  Melodia
}

pub fn to_string(station: Station) {
  case station {
    ChristianHits -> "Christian Hits"
    ChristianLofi -> "Christian Lo-fi"
    ChristianRock -> "Christian Rock"
    GospelHits -> "Gospel Hits"
    Melodia -> "Melodia"
  }
}

pub fn stream(station: Station) {
  case station {
    ChristianHits -> "http://listen.christianrock.net/stream/12/"
    ChristianLofi ->
      "https://www.youtube.com/embed/qXPoj_VYb3U?si=ISaDfqexI9Ng6jPw"
    ChristianRock -> "http://listen.christianrock.net/stream/11/"
    GospelHits -> "http://servidor37-2.brlogic.com:7068/live"
    Melodia -> "https://24373.live.streamtheworld.com/MELODIAFMAAC.aac"
  }
}

pub fn get_song(
  station: Station,
) -> Promise(Result(#(Station, Song), fetch.FetchError)) {
  case station {
    ChristianHits -> get_christian_hits()
    ChristianLofi ->
      ChristianLofi
      |> get_no_song
      |> Ok
      |> promise.resolve
    ChristianRock -> get_christian_rock()
    GospelHits ->
      GospelHits
      |> get_no_song
      |> Ok
      |> promise.resolve
    Melodia -> get_melodia()
  }
  |> promise.map(result.map(_, fn(song) { #(station, song) }))
}

fn get_christian_hits() {
  let assert Ok(request) =
    request.to("https://www.christianrock.net/iphonechdn.php")

  // Send the HTTP request to the server
  use response <- promise.try_await(
    request
    |> fetch.send,
  )

  use json <- promise.map_try(fetch.read_json_body(response))

  json.body
  |> decode.run(song.christianrock_decoder())
  |> result.map_error(fn(_err) { fetch.InvalidJsonBody })
}

fn get_christian_rock() {
  let assert Ok(request) =
    request.to("https://www.christianrock.net/iphonecrdn.php")

  // Send the HTTP request to the server
  use response <- promise.try_await(
    request
    |> fetch.send,
  )

  use json <- promise.map_try(fetch.read_json_body(response))

  json.body
  |> decode.run(song.christianrock_decoder())
  |> result.map_error(fn(_err) { fetch.InvalidJsonBody })
}

fn get_melodia() {
  let assert Ok(request) =
    request.to(
      "https://np.tritondigital.com/public/nowplaying?mountName=MELODIAFMAAC&numberToFetch=1&eventType=track",
    )

  // Send the HTTP request to the server
  use response <- promise.try_await(
    request
    |> fetch.send,
  )

  use xml <- promise.map_try(fetch.read_text_body(response))

  xml.body
  |> song.melodia_decoder
  |> result.map_error(fn(_err) { fetch.UnableToReadBody })
}

fn get_no_song(station: Station) {
  song.Song(artist: to_string(station), title: "No song information available")
}

pub fn get_song_from_metadata(metadata: String) -> Song {
  case string.split(metadata, " - ") {
    [artist, title] -> song.Song(artist:, title:)
    _ -> song.Song(artist: "Unknown", title: metadata)
  }
}
