local controls = require("controller_files.controls")
local peripherals = require("controller_files.peripherals")
local telemetry = require("controller_files.telemetry")
local ui = require("controller_files.ui")


if peripherals.checkSetup() then
    parallel.waitForAll(ui.run, telemetry.getTelemetry, controls.taskLogicAndInputs, controls.taskStabilizationLogic, controls.taskAutopilot, controls.taskActuators)
end