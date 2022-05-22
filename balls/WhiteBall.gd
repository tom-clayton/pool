extends RigidBody

signal power_changed
signal state_changed

export var RAY_DISTANCE = 2.5
export var POWER_RATE = 50
export var MAX_POWER = 150

const CUE_PLACER_RAY_LEN = 10

#const TWOPI = 2 * PI
#const ANG_VELOCITY = PI/8

enum {IDLE, AIMING, CUEING, RUNNING, LOCKED}
var state = AIMING

var aim
var power = 0
var count = 0

#var y_pos
#var last_y_pos
#var target

onready var camera = get_viewport().get_camera()
 
func _ready():
    #aim = PI
    $SightRayCast.enabled = true
    $SightRayCast.add_exception(self)
    $SightRayCast.add_exception(get_node("Ray"))
    $CuePlacer.enabled = true

func _process(delta):
    if state == IDLE or state == AIMING:
        var mousepos = get_viewport().get_mouse_position()       
        $CuePlacer.global_transform.origin = camera.project_ray_origin(mousepos)
        $CuePlacer.cast_to = camera.project_ray_normal(mousepos) * CUE_PLACER_RAY_LEN

        if $CuePlacer.is_colliding() and $CuePlacer.get_collider() == $CueArea:
            $Sight.set("visible", true)
            aim = $CuePlacer.get_collision_point().direction_to(global_transform.origin)
            aim.y = 0
            aim = aim.normalized()
            $Sight.look_at(global_transform.origin + aim, Vector3.UP)
            poll_raycast()
            if state == IDLE:
                state = AIMING
                emit_signal('state_changed', "Aiming")
        elif state == AIMING:
            $Sight.set("visible", false)
            state = IDLE
            emit_signal('state_changed', "Idle")
            
    if state == AIMING and Input.is_action_just_pressed("increase_power"):
            $CuePlacer.enabled = false
            state = CUEING
            emit_signal('state_changed', "Cueing")           
        
    if state == CUEING:
        if Input.is_action_pressed("increase_power"):  
            power += POWER_RATE * delta
            power = clamp(power, 0, MAX_POWER)
            emit_signal('power_changed', power)
            
        if Input.is_action_just_released("increase_power"):
            take_shot()
            power = 0
            emit_signal('power_changed', power)
            state = RUNNING
            emit_signal('state_changed', "Running")

func take_shot():
    $SightRayCast.enabled = false
    $Sight.set("visible", false)
    apply_impulse(Vector3(), aim * power * power)
    $Timer.start()

func poll_raycast(): 
        $SightRayCast.cast_to = aim * RAY_DISTANCE     
        var ray_length
        if $SightRayCast.get_collider():
            ray_length = global_transform.origin.distance_to($SightRayCast.get_collision_point())              
        else:
            ray_length = RAY_DISTANCE

        $Sight/Beam.mesh.set("height", ray_length)
        $Sight/Beam.set("translation", Vector3(0, 0, ray_length/-2))

func _on_Timer_timeout():
    if not get_linear_velocity().length_squared():
        set("rotation", Vector3(0, 0, 0))
        $SightRayCast.enabled = true
        $CuePlacer.enabled = true
        $Timer.stop()
        state = IDLE
        emit_signal('state_changed', "Idle")
    else:
        $Timer.start()
