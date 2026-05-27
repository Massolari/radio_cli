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

pub fn get_song_from_metadata(metadata: String) -> Song {
  case string.split(metadata, " - ") {
    [artist, title] -> song.Song(artist:, title:)
    _ -> song.Song(artist: "Unknown", title: metadata)
  }
}
