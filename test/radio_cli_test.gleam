import birdie
import gleam/string
import gleeunit
import player
import station

pub fn main() {
  gleeunit.main()
}

pub fn extract_now_playing_from_metadata_test() {
  "+----[ Meta data ]
|
| title: CHDN aac
| filename: 12
| genre: 
| now_playing: NF - Happy
|
+----[ Transmissão 0 ]
|
| Decoded bits per sample: 32
| Decoded channels: Estéreo
| Tipo: Áudio
| Formato decodificado: 32 bits float LE (f32l)
| Codificador: MPEG AAC Audio (mp4a)
| Taxa de amostragem: 44100 Hz
|
+----[ end of stream info ]"
  |> player.extract_now_playing_from_metadata
  |> string.inspect
  |> birdie.snap("extract_now_playing_from_metadata")
}

pub fn get_song_from_metadata_test() {
  "NF - Happy"
  |> station.get_song_from_metadata
  |> string.inspect
  |> birdie.snap("get_song_from_metadata")
}
