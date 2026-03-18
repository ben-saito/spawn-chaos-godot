extends Resource
## Data definition for an enemy type.

@export var key: String
@export var display_name: String          # Japanese name
@export var hp: int
@export var speed: float
@export var damage: int
@export var size: int                     # pixels
@export var cost: int                     # point cost to spawn / XP on kill
@export var color: Color = Color.WHITE
@export var flying: bool = false
@export var split_on_death: bool = false
@export var split_into: String = ""       # enemy key to split into
@export var split_count: int = 0
