local state = require("controller_files.state")
local peripherals = require("controller_files.peripherals")

local controls = {}

-- main computer inputs
local IN_JOY_FWD = "top"
local IN_JOY_BWD = "bottom"
local IN_JOY_LEFT = "left"
local IN_JOY_RIGHT = "right"

local IN_LEVER_POS = "front"
local IN_BOOST_BTN = "back"

-- base controls relay outputs
local OUT_L_SERVO_FWD = "front"
local OUT_L_SERVO_BWD = "back"

local OUT_R_SERVO_FWD = "left"
local OUT_R_SERVO_BWD = "right"

local OUT_THRUSTER = "top"

-- back rotor controls relay outputs
local OUT_TRANSMISSION = "front"
local OUT_UPWARD_ROTOR = "left"
local OUT_DOWNWARD_ROTOR = "right"

function controls.taskStabilizationLogic()

    while true do
        local currentTime = os.clock()

        if state.control.throttle > 0 then
            local dtP = currentTime - state.pitchState.lastTime

            if dtP <= 0 then dtP = 0.05 end

            local currentPitch = state.sable.pitch

            local airPressure = peripherals.altitude_sensor.getAirPressure()
            if airPressure < state.pitchState.minPressure then
                airPressure = state.pitchState.minPressure
            end

            local pitchRate = (currentPitch - state.pitchState.lastPitch) / dtP

            local predictedPitch = currentPitch + (pitchRate * state.pitchState.kd) 

            local pitchError = state.pitchState.targetPitch - predictedPitch

            local compensatedSignal = 0

            if pitchError > state.pitchState.deadband then
                local baseControlSignal = (pitchError - state.pitchState.deadband) * state.pitchState.kp
                compensatedSignal = (baseControlSignal * state.pitchState.backRotorRation) / airPressure
            elseif pitchError < -state.pitchState.deadband then
                local baseControlSignal = (pitchError + state.pitchState.deadband) *state.pitchState.kp
                compensatedSignal = (baseControlSignal * state.pitchState.backRotorRation) / airPressure
            end


            state.pitchState.lastPitch = currentPitch
            state.pitchState.lastTime = currentTime

            if compensatedSignal > 0 then
                state.control.backRotorDirection = 1
            else 
                state.control.backRotorDirection = 0
            end

            local absSignal = math.abs(compensatedSignal)
            local finalSignal = math.floor(absSignal)

            state.control.backRotorStrength = math.max(0, math.min(15, finalSignal))
        else
            state.control.backRotorStrength = 0
        end

        currentTime = os.clock()
        local dtR = currentTime - state.roll.lastTime
        
        if dtR <= 0 then dtR = 0.05 end

        local currentRoll = state.sable.roll

        local rollRate = (currentRoll - state.roll.lastRoll) / dtR

        local predictedRoll = currentRoll + (rollRate * state.roll.kd)

        state.roll.lastRoll = currentRoll
        state.roll.lastTime = currentTime

        local leftPower = state.control.throttle
        local rightPower = state.control.throttle

        if state.control.throttle > 0 then
            local dynamicThreshold = state.roll.baseThreshold * (15 / state.control.throttle)

            if predictedRoll > dynamicThreshold then
                leftPower = leftPower - state.roll.correctionLevel
            elseif predictedRoll < -dynamicThreshold then
                rightPower = rightPower - state.roll.correctionLevel
            end
        end

        state.control.leftThrottle = math.max(0, leftPower)
        state.control.rightThrottle = math.max(0, rightPower)

        sleep(0.05)
    end
end

function controls.taskAutopilot()
    while true do
        if state.autopilot.hasSetDestination then
            local dx = state.autopilot.destinationX - state.sable.x
            local dz = state.autopilot.destinationZ - state.sable.z
            state.autopilot.destinationDistance = math.sqrt(dx^2 + dz^2)

            local angleRad  = math.atan2(dz, dx)
            state.autopilot.aimedAngle = (math.deg(angleRad) + 360) % 360
        end
        sleep(0.05)
    end
end

function controls.taskLogicAndInputs()
    while true do
        if not state.autopilot.hasSetDestination then
            state.ui.autopilotEnabled = false
        end

        local pitch = 0
        local yaw = 0

        if state.ui.autopilotEnabled then
            local distance = state.autopilot.destinationDistance

            if distance <= state.autopilot.destinationRadius then
                pitch = 0
                yaw = 0
                state.control.boost = false
                state.ui.autopilotEnabled = false
            else
                local brakingDistance = 500
                local maxPitch = 10

                if distance > brakingDistance then
                    pitch = maxPitch
                    state.control.throttle = 0
                    state.control.boost = true
                else
                    state.control.boost = false
                    local remainingDistance = distance - state.autopilot.destinationRadius
                    local brackingMargin = brakingDistance - state.autopilot.destinationRadius
                    local approachRatio = math.max(0, remainingDistance/brackingMargin)

                    pitch = maxPitch * approachRatio
                end

                local currentAngle = state.sable.yaw
                local targetAngle = state.autopilot.aimedAngle
                local angleError = (targetAngle - currentAngle + 180) % 360 - 180

                local kpYaw = 0.3
                yaw = angleError * kpYaw
                yaw = math.max(-15, math.min(15, yaw))
            end

            pitch = 10
            yaw = 0
            state.control.throttle = 3
            state.control.boost = false
        else
            local fwdVal = rs.getAnalogInput(IN_JOY_FWD)
            local bwdVal = rs.getAnalogInput(IN_JOY_BWD)
            pitch = fwdVal - bwdVal

            local rightVal = rs.getAnalogInput(IN_JOY_RIGHT)
            local leftVal = rs.getAnalogInput(IN_JOY_LEFT)
            yaw = rightVal - leftVal

            state.control.throttle = (15 - rs.getAnalogInput(IN_LEVER_POS))
            state.control.boost = rs.getInput(IN_BOOST_BTN)
        end

        state.control.leftTargetAngle = pitch - yaw
        state.control.rightTargetAngle = pitch + yaw

        sleep(0)
    end
end

function controls.taskActuators()
    while true do
        peripherals.setStepperServo(OUT_L_SERVO_FWD, OUT_L_SERVO_BWD, state.control.leftTargetAngle)
        peripherals.setStepperServo(OUT_R_SERVO_FWD, OUT_R_SERVO_BWD, state.control.rightTargetAngle)

        if peripherals.trans_left and peripherals.trans_right then
            peripherals.trans_left.setSignal(state.control.leftThrottle)
            peripherals.trans_right.setSignal(state.control.rightThrottle)
        end

        peripherals.relay_base_controls.setOutput(OUT_THRUSTER, state.control.boost)

        if state.control.backRotorDirection == 1 then
            peripherals.relay_back_rotors.setOutput(OUT_UPWARD_ROTOR, true)
            peripherals.relay_back_rotors.setOutput(OUT_DOWNWARD_ROTOR, false)
        else
            peripherals.relay_back_rotors.setOutput(OUT_DOWNWARD_ROTOR, true)
            peripherals.relay_back_rotors.setOutput(OUT_UPWARD_ROTOR, false)
        end

        peripherals.relay_back_rotors.setAnalogOutput(OUT_TRANSMISSION, 15 - state.control.backRotorStrength)

        sleep(0.05)
    end
end

return controls