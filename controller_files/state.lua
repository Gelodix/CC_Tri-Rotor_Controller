local state = {
    control = {
        leftTargetAngle  = 0,
        rightTargetAngle = 0,
        throttle         = 0,
        leftThrottle     = 0,
        rightThrottle    = 0,
        boost            = false,
        backRotorStrength = 0,
        backRotorDirection = 0, --1 for upward, 0 for downward
    },
    ui = {
        autopilotEnabled = false,
        altitudeControllerEnabled = false,
    },
    altitude = {
        aimedAltitude = 60,
        heightDifferential = 16,
        accelarationStrength = 1.5,
        brakingStrength = 2.5,
        defaultThrustersStrength = 2,
        blockDifferentialBetweenSensorAndShipBottom = 7,
    },
    pitchState = {
        targetPitch = 5,
        kp = 0.8,
        kd = 0.7,
        backRotorRation = 1.2,
        minPressure = 0.1,
        deadband = 2.5,

        lastPitch = 0,
        lastTime = os.clock()
    },
    roll = {
        baseThreshold = 5,
        correctionLevel = 1,
        kd = 0.6,
        lastRoll = 1,
        lastTime = os.clock()
    },
    sable = {
        x = 0,
        y = 0,
        z = 0,
        
        yaw = 0,
        pitch = 0,
        roll = 0,

        yawOffset = 0,
        swapPitchAndRoll = false,
        invertPitch = false,
        invertRoll = true,
        

    },
    autopilot = {
        destinationX = 0,
        destinationZ = 0,
        destinationRadius = 100, -- in blocks 
        hasSetDestination = false,
        destinationDistance = 0,
        aimedAngle = 0,

        kpYaw = 0.08,
        kdYaw = 0.1,
        lastAngleError = 0,
        lastTime = os.clock(),
    },
}

return state