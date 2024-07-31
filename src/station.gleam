import gleam/fetch
import gleam/http/request
import gleam/javascript/promise
import gleam/result
import song

pub type Station {
  ChristianRock
  ChristianHits
  GospelMix
  LofiGirl
}

pub fn to_string(station: Station) {
  case station {
    ChristianRock -> "Christian Rock"
    ChristianHits -> "Christian Hits"
    GospelMix -> "Gospel Mix"
    LofiGirl -> "Lofi Girl"
  }
}

pub fn stream(station: Station) {
  case station {
    ChristianRock -> "https://listen.christianrock.net/stream/11/"
    ChristianHits -> "https://listen.christianrock.net/stream/12/"
    GospelMix -> "https://servidor33-3.brlogic.com:8192/live"
    LofiGirl ->
      "https://www.youtube.com/embed/jfKfPfyJRdk?origin=https%3A%2F%2Flofimusic.app&autoplay=1&modestbranding=1&disablekb=1&iv_load_policy=3&playsinline=1"
  }
}

pub fn get_song(station: Station) {
  case station {
    ChristianRock -> get_christian_rock()
    ChristianHits -> get_christian_hits()
    GospelMix -> get_gospel_mix()
    LofiGirl ->
      LofiGirl
      |> get_no_song
      |> Ok
      |> promise.resolve
  }
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

fn get_no_song(station: Station) {
  song.Song(artist: to_string(station), title: "No song information available")
}
