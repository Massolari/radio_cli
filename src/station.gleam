pub type Station {
  ChristianRock
  GospelMix
}

pub fn stream(station: Station) {
  case station {
    ChristianRock -> "https://listen.christianrock.net/stream/11/"
    GospelMix -> "https://servidor33-3.brlogic.com:8192/live?source=website"
  }
}

pub fn playing(station: Station) {
  case station {
    ChristianRock -> "https://www.christianrock.net/iphonecrdn.php"
    GospelMix ->
      "https://d36nr0u3xmc4mm.cloudfront.net/index.php/api/streaming/status/8192/2e1cbe43529055ddda74868d2db9ae98/SV4BR"
  }
}
