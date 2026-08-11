local controls = require("controller.controls")
local peripherals = require("controller.peripherals")
local telemetry = require("controller.telemetry")
local ui = require("controller.ui")


if peripherals.checkSetup() then
    parallel.waitForAll(ui.run, telemetry.getTelemetry, controls.taskLogicAndInputs, controls.taskStabilizationLogic, controls.taskAutopilot, controls.taskActuators)
end