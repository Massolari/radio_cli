import gleam/fetch
import gleam/http/request
import gleam/io
import gleam/javascript/promise
import gleam/result
import song

pub type Station {
  ChristianRock
  GospelMix
}

pub fn to_string(station: Station) {
  case station {
    ChristianRock -> "Christian Rock"
    GospelMix -> "Gospel Mix"
  }
}

pub fn stream(station: Station) {
  case station {
    ChristianRock -> "https://listen.christianrock.net/stream/11/"
    GospelMix -> "https://servidor33-3.brlogic.com:8192/live"
  }
}

pub fn playing(station: Station) {
  case station {
    ChristianRock -> "https://www.christianrock.net/iphonecrdn.php"
    GospelMix ->
      "https://d36nr0u3xmc4mm.cloudfront.net/index.php/api/streaming/status/8192/2e1cbe43529055ddda74868d2db9ae98/SV4BR"
  }
}

pub fn get_song(station: Station) {
  case station {
    ChristianRock -> get_christian_rock()
    GospelMix -> get_gospel_mix()
  }
}

fn get_christian_rock() {
  let assert Ok(request) =
    ChristianRock
    |> playing
    |> request.to

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
    GospelMix
    |> playing
    |> request.to

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
