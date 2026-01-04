extends Node

const AUDIO_BG_MUSIC: String = "background_music"

const AUDIO_SHOOT_SFX: String = "shoot_sfx"

const AUDIO_BARREL_BOM_SFX: String = "barrel_bom_sfx"

var audio_resources: Dictionary = {}

var bg_audio_player: AudioStreamPlayer2D

var sfx_audio_players: Dictionary[String, AudioStreamPlayer2D] = {}

func _ready() -> void:
	audio_resources = {
		AUDIO_BG_MUSIC: preload('res://assets/audio/background-music.ogg'),
		AUDIO_SHOOT_SFX : preload('res://assets/audio/shoot_effect.ogg'),
		AUDIO_BARREL_BOM_SFX: preload('res://assets/audio/explosion_effect.ogg')
	}
	#region 背景音乐播放器设置
	bg_audio_player = AudioStreamPlayer2D.new()
	bg_audio_player.bus = &'Music'
	bg_audio_player.stream = audio_resources[AUDIO_BG_MUSIC]
	(bg_audio_player.stream as AudioStreamOggVorbis).loop = true
	bg_audio_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(bg_audio_player) #添加背景音乐播放器
	#endregion
	#region 音效播放器设置
	var shoot_audio_player = AudioStreamPlayer2D.new()
	shoot_audio_player.bus = &'SFX'
	shoot_audio_player.stream = audio_resources[AUDIO_SHOOT_SFX]
	shoot_audio_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(shoot_audio_player)
	sfx_audio_players[AUDIO_SHOOT_SFX] = shoot_audio_player
	
	var barrel_audio_player = AudioStreamPlayer2D.new()
	barrel_audio_player.bus = &'SFX'
	barrel_audio_player.stream = audio_resources[AUDIO_BARREL_BOM_SFX]
	barrel_audio_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(barrel_audio_player)
	sfx_audio_players[AUDIO_BARREL_BOM_SFX] = barrel_audio_player
	#endregion
	
	set_play_sounds(GlobalConfigs.sound_available) #设置声音播放

## 设置是否允许播放声音
func set_play_sounds(available: bool) -> void:
	if available:
		bg_audio_player.play()
	else: 
		bg_audio_player.stream_paused = bg_audio_player.playing
	GlobalConfigs.sound_available = available

## 获取是否允许声音播放
func get_play_sounds() -> bool:
	return GlobalConfigs.sound_available

## 播放射击音效
func play_shoot_sfx() -> void:
	if not get_play_sounds(): return
	sfx_audio_players[AUDIO_SHOOT_SFX].play()

## 播放油桶爆炸音效
func play_barrel_explosion() -> void:
	if not get_play_sounds(): return
	sfx_audio_players[AUDIO_BARREL_BOM_SFX].play()
