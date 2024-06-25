import gleam/dynamic.{type Dynamic}
import gleam/fetch
import gleam/http/request
import gleam/javascript/promise
import gleam/result
import station.{type Station, ChristianRock, GospelMix}

pub type Song {
  Song(artist: String, title: String)
}

pub fn get(source: Station) {
  case source {
    ChristianRock -> get_christian_rock()
    GospelMix -> get_gospel_mix()
  }
}

fn get_christian_rock() {
  let assert Ok(request) =
    ChristianRock
    |> station.playing
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
  |> christianrock_decoder
  |> result.map_error(fn(_err) { fetch.InvalidJsonBody })
}

fn get_gospel_mix() {
  todo
}

fn christianrock_decoder(
  json: Dynamic,
) -> Result(Song, List(dynamic.DecodeError)) {
  dynamic.decode2(
    Song,
    dynamic.field("Artist", of: dynamic.string),
    dynamic.field("Title", of: dynamic.string),
  )(json)
}
