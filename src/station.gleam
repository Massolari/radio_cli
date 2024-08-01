import gleam/fetch
import gleam/http/request
import gleam/javascript/promise
import gleam/result
import song

pub type Station {
  ChristianHits
  ChristianRock
  GospelMix
  LofiGirl
  Melodia
}

pub fn to_string(station: Station) {
  case station {
    ChristianHits -> "Christian Hits"
    ChristianRock -> "Christian Rock"
    GospelMix -> "Gospel Mix"
    LofiGirl -> "Lofi Girl"
    Melodia -> "Radio Melodia"
  }
}

pub fn stream(station: Station) {
  case station {
    ChristianHits -> "https://listen.christianrock.net/stream/12/"
    ChristianRock -> "https://listen.christianrock.net/stream/11/"
    GospelMix -> "https://servidor33-3.brlogic.com:8192/live"
    LofiGirl ->
      "https://www.youtube.com/embed/jfKfPfyJRdk?origin=https%3A%2F%2Flofimusic.app&autoplay=1&modestbranding=1&disablekb=1&iv_load_policy=3&playsinline=1"
    Melodia -> "https://14543.live.streamtheworld.com/MELODIAFMAAC.aac"
  }
}

pub fn get_song(station: Station) {
  case station {
    ChristianHits -> get_christian_hits()
    ChristianRock -> get_christian_rock()
    GospelMix -> get_gospel_mix()
    LofiGirl ->
      LofiGirl
      |> get_no_song
      |> Ok
      |> promise.resolve
    Melodia -> get_melodia()
  }
}

fn get_christian_hits() {
  let assert Ok(request) =
    request.to("https://www.christianrock.net/iphonechdn.php")

  // Send the HTTP request to the server
  use response <- promise.try_await(
    request
    |> request.set_cookie("Saw2023CyberMonday", "Y")
    |> request.set_cookie("SawOctober2023Splash", "Y")
    |> request.set_cookie("SawFundraiser2023_0", "Y")
    |> request.set_cookie("SawFundraiser2023_2", "Y")
    |> request.set_cookie("SawFundraiser2023_3", "Y")
    |> request.prepend_header("accept", "application/json")
    |> request.prepend_header("host", "www.christianrock.net")
    |> request.prepend_header(
      "referer",
      "https://www.christianrock.net/player.php?site=CRDN",
    )
    |> request.prepend_header("X-Requested-With", "XMLHttpRequest")
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
    |> request.set_cookie("Saw2023CyberMonday", "Y")
    |> request.set_cookie("SawOctober2023Splash", "Y")
    |> request.set_cookie("SawFundraiser2023_0", "Y")
    |> request.set_cookie("SawFundraiser2023_2", "Y")
    |> request.set_cookie("SawFundraiser2023_3", "Y")
    |> request.prepend_header("accept", "application/json")
    |> request.prepend_header("host", "www.christianrock.net")
    |> request.prepend_header(
      "referer",
      "https://www.christianrock.net/player.php?site=CRDN",
    )
    |> request.prepend_header("X-Requested-With", "XMLHttpRequest")
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
    |> request.prepend_header("accept", "application/json")
    |> request.prepend_header("host", "d36nr0u3xmc4mm.cloudfront.net")
    |> request.prepend_header("X-Requested-With", "XMLHttpRequest")
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
