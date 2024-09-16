import gleam/fetch
import gleam/http/request
import gleam/javascript/promise.{type Promise}
import gleam/result
import song.{type Song}

pub type Station {
  ChristianHits
  ChristianRock
  GospelMix
  ChristianLofi
  Melodia
}

pub fn to_string(station: Station) {
  case station {
    ChristianHits -> "Christian Hits"
    ChristianLofi -> "Christian Lo-fi"
    ChristianRock -> "Christian Rock"
    GospelMix -> "Gospel Mix"
    Melodia -> "Melodia"
  }
}

pub fn stream(station: Station) {
  case station {
    ChristianHits -> "https://listen.christianrock.net/stream/12/"
    ChristianLofi -> "https://www.youtube.com/embed/-YJmGR2tD0k"
    ChristianRock -> "https://listen.christianrock.net/stream/11/"
    GospelMix -> "https://servidor33-3.brlogic.com:8192/live"
    Melodia -> "https://14543.live.streamtheworld.com/MELODIAFMAAC.aac"
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
    GospelMix -> get_gospel_mix()
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
  |> song.christianrock_decoder
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
  |> song.christianrock_decoder
  |> result.map_error(fn(_err) { fetch.InvalidJsonBody })
}

fn get_gospel_mix() {
  let assert Ok(request) =
    request.to(
      "https://d36nr0u3xmc4mm.cloudfront.net/index.php/api/streaming/status/8192/2e1cbe43529055ddda74868d2db9ae98/SV4BR",
    )

  // Send the HTTP request to the server
  use response <- promise.try_await(
    request
    |> fetch.send,
  )

  use json <- promise.map_try(fetch.read_json_body(response))

  json.body
  |> song.gospel_mix_decoder
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
