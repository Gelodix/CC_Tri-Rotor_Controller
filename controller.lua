local controls = require("controller_files.controls")
local peripherals = require("controller_files.peripherals")
local ui = require("controller_files.ui")


if peripherals.checkSetup() then
    parallel.waitForAll(ui.run, controls.taskLogicAndInputs, controls.taskStabilizationLogic, controls.taskAutopilot, controls.taskActuators)
end