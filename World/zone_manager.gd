class_name ZoneManager
extends Node

enum Zone {
    StartZone,
    SwampZone,
    RuinsZone
}

static var instance: ZoneManager

var current_zone: Zone

func _ready() -> void:
    instance = self

func change_zone(zone: Zone):
    current_zone = zone