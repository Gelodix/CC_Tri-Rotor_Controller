local state = require("controller_files.state")
local basalt = require("basalt")
local peripherals = require("controller_files.peripherals")

local ui = {}

local main = basalt.getMainFrame()

function ui.setAutopilot (on --[[boolean]])
    if on and not state.autopilot.hasSetDestination then
        on = false
    end

    if on then
        state.ui.autopilotEnabled = on
        ui.buttonToggleAutoPilot:setText("Autopilot : ON"):setBackground(colors.green)
    else
        state.ui.autopilotEnabled = on
        ui.buttonToggleAutoPilot:setText("Autopilot : OFF"):setBackground(colors.red)
    end
end

function ui.setaltitudeController (on --[[boolean]])
    if on then
        state.ui.altitudeControllerEnabled = on
        ui.buttonToggleAltitudeControl:setText("Altitude control : ON"):setBackground(colors.green)
    else
        state.ui.altitudeControllerEnabled = on
        ui.buttonToggleAltitudeControl:setText("Altitude control : OFF"):setBackground(colors.red)
    end
end

local function cleanCoordinateInput(self)
    local value = self:getText()
    if value and type(value) == "string" then
        local cleanValue = value:gsub("[^%d%-]", "")
        local isNegative = (string.sub(cleanValue, 1, 1) == "-")

        cleanValue = cleanValue:gsub("-","")

        cleanValue = string.sub(cleanValue, 1, 5)

        if isNegative then
            cleanValue = "-" .. cleanValue
        end

        if value ~= cleanValue then
            self:setText(cleanValue)
        end
    end
end

main:addLabel():setPosition(2, 2):setText("Destination Coordinates : ")
main:addLabel():setPosition(2, 3):setText("X:")
main:addLabel():setPosition(13, 3):setText("Z:")
local labelCurrentAngle = main:addLabel():setPosition(2, 9):setText("Current angle : --")
local labelAimedAngle = main:addLabel():setPosition(2, 10):setText("Aimed angle : --")
local labelDestinationDistance = main:addLabel():setPosition(2, 11):setText("Destination Distance : --")


local inputDestinationX = main:addInput():setPosition(4, 3):setSize(8, 1)
local inputDestinationZ = main:addInput():setPosition(15, 3):setSize(8, 1)

inputDestinationX:onChange(cleanCoordinateInput)
inputDestinationZ:onChange(cleanCoordinateInput)

local function destinationInputsFilled()
    local xValue = inputDestinationX:getText()
    local zValue = inputDestinationZ:getText()
    
    return (tonumber(xValue) ~= nil and tonumber(zValue) ~= nil)
end

inputDestinationX:onKey(function(self, event, key)
    if key == keys.tab then
        inputDestinationZ:setFocus()
    end
end)

inputDestinationZ:onKey(function(self, event, key)
    if key == keys.tab then
        inputDestinationX:setFocus()
    end
end)



local function setDestination()
    if destinationInputsFilled() then
            state.autopilot.destinationX = tonumber(inputDestinationX:getText())
            state.autopilot.destinationZ = tonumber(inputDestinationZ:getText())
            inputDestinationX:setText("")
            inputDestinationZ:setText("")
            state.autopilot.hasSetDestination = true
    end
end

ui.buttonSetDestination = main:addButton():setPosition(2, 5):setSize(21, 3):setText("Set Coordinates"):onClick(setDestination)
inputDestinationX:onEnter(setDestination)
inputDestinationZ:onEnter(setDestination)


ui.buttonToggleAutoPilot = main:addButton():setPosition(2, 14):setSize(24, 3)
    :onClick(
    function()
        ui.setAutopilot(not state.ui.autopilotEnabled)
    end)

ui.setAutopilot(state.ui.autopilotEnabled)

-- labels to show important informations
local labelCurrentAltitude = main:addLabel():setPosition(27, 2):setText("Current altitude : --")
local labelAimedAltitude = main:addLabel():setPosition(27, 3):setText("Aimed altitude : " .. state.altitude.aimedAltitude)
local labelVerticalVelocity = main:addLabel():setPosition(27, 4):setText("Vertical speed : --")

-- input to change aimed altitude
main:addLabel():setPosition(27, 6):setText("New altitude :")
local inputAltitude = main:addInput():setPosition(27, 7):setSize(13, 1)

inputAltitude:onChange(function(self)
    local value = self:getText()
    if value and type(value) == "string" then
        local cleanValue = value:gsub("%D", "")

        cleanValue = string.sub(cleanValue, 1, 4)

        if value ~= cleanValue then
            self:setText(cleanValue)
        end
    end
end)

-- functions to save the altitude in the text input
local function confirmAltitude()
    local newAltitude = tonumber(inputAltitude:getText())
    if newAltitude then
        state.altitude.aimedAltitude = newAltitude
        labelAimedAltitude:setText("Aimed altitude : " .. newAltitude)
        inputAltitude:setText("")
    end
end

main:addButton():setPosition(41, 7):setSize(10, 1):setText("Confirm")
    :onClick(confirmAltitude)

inputAltitude:onEnter(confirmAltitude)
    
-- toggle button to enable/disable altitude control
ui.buttonToggleAltitudeControl = main:addButton():setPosition(27, 9):setSize(24, 3)
    :onClick(
    function()
        ui.setaltitudeController(not state.ui.altitudeControllerEnabled)
    end)

ui.setaltitudeController(state.ui.altitudeControllerEnabled)

-- toggle button to enable/disable autopilot


-- side task to update the labels
basalt.schedule(function()
    while true do
        if peripherals.altitude_sensor then
            labelCurrentAltitude:setText("Current altitude : " .. math.floor(peripherals.altitude_sensor.getHeight() - state.altitude.blockDifferentialBetweenSensorAndShipBottom))
            labelVerticalVelocity:setText("Vertical speed : " .. math.floor(peripherals.altitude_sensor.getVerticalSpeed()) .. "m/s")
        end 

        if destinationInputsFilled() then
            ui.buttonSetDestination:setBackground(colors.blue)
        else
            ui.buttonSetDestination:setBackground(colors.gray)
        end
        sleep(0.1)

        labelCurrentAngle:setText("Current angle : " .. state.sable.yaw)
        labelAimedAngle:setText("Aimed angle : " .. state.autopilot.aimedAngle)
        labelDestinationDistance:setText("Destination Distance : --")
    end
end)



function ui.run()
    basalt:run()
end

return ui