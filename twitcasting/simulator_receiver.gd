extends Node
## UDP receiver for local chat simulator testing.

signal message_received(username: String, message: String)

var _udp: PacketPeerUDP
const PORT := 19876

func _ready() -> void:
	_udp = PacketPeerUDP.new()
	var err := _udp.bind(PORT, "127.0.0.1")
	if err != OK:
		push_warning("SimulatorReceiver: Failed to bind UDP port %d" % PORT)
		_udp = null

func _process(_delta: float) -> void:
	if _udp == null:
		return
	while _udp.get_available_packet_count() > 0:
		var data := _udp.get_packet().get_string_from_utf8()
		# Format: "username\tmessage" or just "message"
		var parts := data.split("\t", true, 1)
		var username := "SimUser"
		var message := data
		if parts.size() >= 2:
			username = parts[0]
			message = parts[1]
		message_received.emit(username, message)

func _exit_tree() -> void:
	if _udp:
		_udp.close()
