; M557 X20:230 Y30:240 S20     ; Define grid for mesh bed compensation, origin in bed centre P=Number of points per axis
G29 S2                       ; Disable mesh bed compensation
M98 P"/macros/wipe_nozzle"   ; Clean nozzles
M98 P"/macros/sb_leds." S"meshing"      ; Turn Stealthburner LEDs Green
M98 P"/sys/homez.g"          ; Home Z
G1 Z6                        ; To avoid backlash move to point higher than start of calibration
M558.1 K0 S1.7               ; Calibrate probe
G1 Z6                        ; Move up at end of calibration
G29 S0 K0                    ; Scan the bed and create mesh