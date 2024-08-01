import gleeunit
import gleeunit/should
import song.{Song}

pub fn main() {
  gleeunit.main()
}

pub fn melodia_decoder_test() {
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?><nowplaying-info-list><nowplaying-info mountName=\"MELODIAFMAAC\" timestamp=\"1722500576\" type=\"track\"><property name=\"cue_time_duration\"><![CDATA[409000]]></property><property name=\"cue_time_start\"><![CDATA[1722500576222]]></property><property name=\"cue_title\"><![CDATA[TUA GRAÇA ME BASTA]]></property><property name=\"track_artist_name\"><![CDATA[TRAZENDO A ARCA]]></property></nowplaying-info></nowplaying-info-list>"
  |> song.melodia_decoder
  |> should.equal(
    Ok(Song(artist: "TRAZENDO A ARCA", title: "TUA GRAÇA ME BASTA")),
  )
}
