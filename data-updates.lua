local constants = require("constants")
local helper = require("helper")

--[[
TODO:
* Scaling increase modes: linear/exponential
* waypoints - lock multiplier at certain points
* Individual science pack multipliers - need different numbers of each science pack at each point
    * Maybe also a multiplier for research unit duration? So a 60 second research might become a 120 second research.
]]

local initialMultiplier = settings.startup[constants.settings.initialMultiplier].value
local finalMultiplier = settings.startup[constants.settings.finalMultiplier].value
local finalTech = settings.startup[constants.settings.finalTechnology].value
local skipInitialTriggerTechs = settings.startup[constants.settings.skipInitialTriggerTechs].value
if finalTech ~= "" and not data.raw["technology"][finalTech] then
    error(string.format("Final technology '%s' does not exist.", finalTech))
end
log(string.format("Final technology: '%s'", finalTech))

local depthTable = {}

local function addTechnology(technology)
    if depthTable[technology.name] == nil then
        local depth = 0
        if (technology.prerequisites) then
            local maxPrerequisiteDepth = -1
            for _, prerequisiteName in pairs(technology.prerequisites) do
                addTechnology(data.raw["technology"][prerequisiteName])
                maxPrerequisiteDepth = math.max(maxPrerequisiteDepth, depthTable[prerequisiteName])
            end
            if not skipInitialTriggerTechs or (technology.unit or maxPrerequisiteDepth >= 0) then
                depth = math.max(maxPrerequisiteDepth+1, depth)
            else
                depth = -1
            end
        elseif skipInitialTriggerTechs and not technology.unit then
            depth = -1
        end
        depthTable[technology.name] = depth
    end
end

for _, technology in pairs(data.raw["technology"]) do
    addTechnology(technology)
end
log(serpent.block(depthTable))

local maxDepth = helper.reduceTable(depthTable, math.max, 1)
if finalTech ~= "" then
    maxDepth = depthTable[finalTech]
    if maxDepth == 0 then
        error(string.format("Final technology '%s' cannot be a starting technology (must have at least 1 prerequisite technology)!", finalTech))
    end
end
local mults = {}
for i = 0, maxDepth, 1 do
    mults[i] = initialMultiplier*math.pow(finalMultiplier/initialMultiplier, i/maxDepth)
end
for techName, depth in pairs(depthTable) do
    depth = math.min(depth, maxDepth)
    local tech = data.raw["technology"][techName]
    if tech.unit then
        local mult = mults[depth]
        if tech.unit.count then
            tech.unit.count = math.ceil(tech.unit.count*mult)
            log(string.format("%s: %d", tech.name, tech.unit.count))
        else
            tech.unit.count_formula = string.format("%d*(%s)", mult, tech.unit.count_formula)
        end
    end
end