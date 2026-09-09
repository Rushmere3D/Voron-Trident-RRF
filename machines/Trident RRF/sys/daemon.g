; /sys/daemon.g
; Background tracking thread for chamber heat soak, LED gradients, and Console Logging

; --- 1. State Check ---
if !exists(global.soak_active)
    M99
if global.soak_active = false
    M99

; SAFETY: Instantly deactivate if the printer starts an actual print job
if state.status = "processing"
    set global.soak_active = false
    M106 P0 S0              ; Turn off part fan to let slicer take over control
    M99

; --- 2. Increment Failsafe Timer ---
set global.soak_timer_loops = global.soak_timer_loops + 1

; --- 3. Check Timeout Failsafe ---
if global.soak_timer_loops >= global.soak_max_loops
    echo "🚨 ERROR: Chamber heat soak timed out before hitting target temperature! Aborting safely."
    set global.soak_active = false
    set global.soak_ready = false
    M140 S0                 ; Shut off bed heater for safety
    M106 P0 S0              ; Shut off part fan safely
    M150 E1 R255 U0 B0 S8 F0 ; Turn entire frame flashing Red to indicate error state
    M99

; --- 4. Read Sensors ---
; !!! CHANGE THE '2' BELOW to match your chamber's M308 S slot number !!!
var current_chamber = sensors.analog[2].lastReading

; --- 5. Dynamic LED Gradient & Progress Mapping ---
var base_temp = 20.0
var temp_span = global.soak_target - var.base_temp
if var.temp_span <= 0.0
    set var.temp_span = 1.0

var progress = (var.current_chamber - var.base_temp) / var.temp_span
if var.progress < 0.0
    set var.progress = 0.0
if var.progress > 1.0
    set var.progress = 1.0

var red_val = floor(var.progress * 255.0)
var blue_val = floor((1.0 - var.progress) * 255.0)

M150 E1 R{var.red_val} U0 B{var.blue_val} S8 F0

; --- 6. LIVE CONSOLE LOGGING BLOCK ---
; Loops run every 10 seconds. We print to the console every 3 loops (30 seconds)
if mod(global.soak_timer_loops, 3) = 0
    ; Calculate remaining time in minutes (loops remaining * 10 seconds / 60 seconds)
    var loops_left = global.soak_max_loops - global.soak_timer_loops
    var mins_left = floor((var.loops_left * 10) / 60)
    var secs_left = mod(var.loops_left * 10, 60)
    
    ; Format the text data block neatly
    echo "🌡️ [Chamber Soak] Temp: " ^ var.current_chamber ^ "°C / Target: " ^ global.soak_target ^ "°C | Progress: " ^ floor(var.progress * 100.0) ^ "% | Timeout remaining: " ^ var.mins_left ^ "m " ^ var.secs_left ^ "s"

; --- 7. Check Success Condition ---
if var.current_chamber >= global.soak_target
    echo "✅ SUCCESS: Chamber target temperature met! Background thread disengaged."
    set global.soak_active = false
    set global.soak_ready = true
    M106 P0 S0              ; Turn off part cooling fan safely
    M150 E1 R0 U255 B0 S8 F0 ; Flash case lights Green to notify you
    M99
