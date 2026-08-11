local peripherals = {}

peripherals.trans_left = peripheral.wrap("analog_transmission_4")
peripherals.trans_right = peripheral.wrap("analog_transmission_5")
peripherals.relay_base_controls = peripheral.wrap("redstone_relay_3")
peripherals.relay_back_rotors = peripheral.wrap("redstone_relay_6")
peripherals.altitude_sensor = peripheral.find("altitude_sensor")
peripherals.gimbal_sensor = peripheral.find("gimbal_sensor")

function peripherals.checkSetup()
    local error = false

    -- peripherals checks
    if not peripherals.trans_left then
        print("Error : no left transmission found")
        error = true
    end

    if not peripherals.trans_right then
        print("Error : no right transmission found")
        error = true
    end

    if not peripherals.relay_base_controls then
        print("Error : no base controls relay found")
        error = true
    end

    if not peripherals.relay_back_rotors then
        print("Error : no back controls relay found")
        error = true
    end

    if not peripherals.altitude_sensor then
        print("Error : no altitude sensor found")
        error = true
    end

    if not peripherals.gimbal_sensor then
        print("Error : no gimbal sensor found")
        error = true
    end

    if not sublevel then 
        print("Error : CC:Sable API missing")
        error = true
    end

    return not error
end

-- function to control Stepper Servo for the side rotors
function peripherals.setStepperServo(pinFwd, pinBwd, targetAngle)
    targetAngle = math.max(-15, math.min(15, targetAngle))

    if targetAngle > 0 then
        peripherals.relay_base_controls.setAnalogOutput(pinBwd, 0)
        peripherals.relay_base_controls.setAnalogOutput(pinFwd, targetAngle)
    elseif targetAngle < 0 then
        peripherals.relay_base_controls.setAnalogOutput(pinFwd, 0)
        peripherals.relay_base_controls.setAnalogOutput(pinBwd, math.abs(targetAngle))
    else
        peripherals.relay_base_controls.setAnalogOutput(pinFwd, 0)
        peripherals.relay_base_controls.setAnalogOutput(pinBwd, 0)
    end
end

return peripherals