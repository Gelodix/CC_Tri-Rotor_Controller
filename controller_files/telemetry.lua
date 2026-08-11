local state = require("controller_files.state")
local quaternion = require("quaternion")
local telemetry = {}

function telemetry.getTelemetry()
    while true do
        if sublevel then
            if sublevel.isInPlotGrid() then
                local pose = sublevel.getLogicalPose()

                if pose.position then
                    state.sable.x = pose.position.x
                    state.sable.y = pose.position.y
                    state.sable.z = pose.position.z
                end

                if pose.orientation and pose.orientation.v then
                    local q = quaternion.fromComponents(
                        pose.orientation.v.x,
                        pose.orientation.v.y,
                        pose.orientation.v.z,
                        pose.orientation.a
                    )
                    q:normalize()

                    local pitchRad, yawRad, rollRad = q:toEuler()

                    local rawPitchDeg = math.deg(pitchRad)
                    local rawYawDeg = math.deg(yawRad)
                    local rawRollDeg = math.deg(rollRad)

                    state.sable.yaw = (rawYawDeg + state.sable.yawOffset + 360) % 360

                    local finalPitch = rawPitchDeg
                    local finalRoll = rawRollDeg

                    if state.sable.swapPitchAndRoll then
                        finalPitch = rawRollDeg
                        finalRoll = rawPitchDeg
                    end

                    if state.sable.invertPitch then finalPitch = -finalPitch end
                    if state.sable.inveryRoll then finalRoll = -finalRoll end

                    state.sable.pitch = finalPitch
                    state.sable.roll = finalRoll


                end
            end
        end

        sleep(0.02)
    end

end

return telemetry