local helper = require("helper")

local modID = "technology-ramp-up"
local makeID = helper.makeModIDJoiner(modID)
log(makeID("test"))

local exports = {
    modID = modID,
    settings = {
        initialMultiplier = makeID("initial-multiplier"),
        finalMultiplier = makeID("final-multiplier"),
        finalTechnology = makeID("final-technology"),
        skipInitialTriggerTechs = makeID("skip-initial-triggers")
    }
}

return exports