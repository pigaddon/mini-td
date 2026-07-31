extends Node
## 全局音效播放器。限制同时播放数量，避免后期塔多时卡死。

const MAX_PLAYERS := 10

var _active: int = 0


func play(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null or _active >= MAX_PLAYERS:
		return
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	_active += 1
	player.finished.connect(func() -> void:
		_active = max(0, _active - 1)
		player.queue_free()
	)
	player.play()


func play_varied(
	stream: AudioStream,
	volume_db: float = 0.0,
	pitch_min: float = 0.92,
	pitch_max: float = 1.08
) -> void:
	play(stream, volume_db, randf_range(pitch_min, pitch_max))
