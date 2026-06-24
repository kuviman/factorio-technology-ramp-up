local insertTable, reduce, stringToArray

local function copy_prototype(type, internal_name)
    return table.deepcopy(data.raw[type][internal_name])
end

local function generate_item(name, base_item)
    item = table.deepcopy(data.raw["item"][base_item])
    item.name = name
    item.place_result = name
    data:extend{item}
end

local function joinInternalNames(name, suffix)
    return name.."-"..suffix
end

local function makeModIDJoiner(modID)
    return function(suffix)
        return joinInternalNames(modID, suffix)
    end
end

local function makeLocalisationString(type, name)
    return type.."-name."..name
end

local function simpleStringHash(str)
    return reduce(stringToArray(str), function(a, b) return bit32.band(bit32.bxor(a*string.byte(b), 0xFFFFFFFF-(5-1)), 0xFFFFFFFF) end, 0)
end

-- TECHNOLOGY

local function isMachineUnlockedByTechnologySimple(machine, technology)
    if technology.effects then
        for _, modifier in pairs(technology.effects) do
            if modifier.type == "unlock-recipe" and modifier.recipe == machine.name then
                return true
            end
        end
    end
    return false
end

local function addRecipeToTech(recipe, technology)
    insertTable(technology.effects, {
        type = "unlock-recipe",
        recipe = recipe.name
    })
end

local function addRecipesToTechnologies(recipes, matchFunc)
    local nTechs = 0
    local function addIfMatch(techData)
        if matchFunc(techData) and techData.effects then
            for _, recipe in pairs(recipes) do
                addRecipeToTech(recipe, techData)
            end
            nTechs = nTechs + 1
        end
    end
    for _, technology in pairs(data.raw["technology"]) do
        if technology.normal or technology.expensive then
            if technology.normal then
                addIfMatch(technology.normal)
            end
            if technology.expensive then
                addIfMatch(technology.expensive)
            end
        else
            if technology.name == "electronics" then
                technology.effects = {}
            end
            addIfMatch(technology)
        end
    end
    return nTechs
end

-- ENERGY

local function splitEnergyOrPower(value)
    local index = string.find(value, "%D")
    if index then
        local magnitude = string.sub(value, 1, index-1)
        log(magnitude)
        local unit = string.sub(value, index)
        return {
            magnitude=tonumber(magnitude),
            unit=unit
        }
    else
        error("Could not split magnitude and unit from energy/power value: "..value)
    end
end

local function multiplyEnergy(energy, factor)
    local splitEnergy = splitEnergyOrPower(energy)
    return splitEnergy.magnitude*factor..splitEnergy.unit
end

--

local function rotateAnimationsCCW(animations)
    local north = animations.north
    animations.north = animations.east
    animations.east = animations.south
    animations.south = animations.west
    animations.west = north
end

local function rotateAnimationsCW(animations)
    local north = animations.north
    animations.north = animations.west
    animations.west = animations.south
    animations.south = animations.east
    animations.east = north
end

-- BOX

local function makeTile(pos)
    local newTile = {
        left_top = {
            x = math.floor(pos.x),
            y = math.floor(pos.y),
        },
        right_bottom = {
            x = math.floor(pos.x)+1,
            y = math.floor(pos.y)+1,
        }
    }
    return newTile
end

local function makeBox(pos, size)
    local newBox = {
        left_top = {
            x = pos.x-size/2,
            y = pos.y-size/2
        },
        right_bottom = {
            x = pos.x+size/2,
            y = pos.y+size/2
        }
    }
    return newBox
end

local function snapBoxToGrid(box)
    local newBox = {
        left_top = {
            x = math.floor(box.left_top.x),
            y = math.floor(box.left_top.y)
        },
        right_bottom = {
            x = math.ceil(box.right_bottom.x),
            y = math.ceil(box.right_bottom.y)
        }
    }
    return newBox;
end

local function padBox(box, padding)
    local newBox = {
        left_top = {
            x = box.left_top.x-padding,
            y = box.left_top.y-padding
        },
        right_bottom = {
            x = box.right_bottom.x+padding,
            y = box.right_bottom.y+padding
        }
    }
    return newBox;
end

local function selectionToCollision(selectionBox)
    local padding = 0.3
    return {
        {selectionBox[1][1]+padding, selectionBox[1][2]+padding},
        {selectionBox[2][1]-padding, selectionBox[2][2]-padding}
    }
end

local function isBoxInBoundsOnEitherAxis(testBox, otherBox)
    return (testBox.left_top.x >= otherBox.left_top.x and testBox.right_bottom.x <= otherBox.right_bottom.x)
        or (testBox.left_top.y >= otherBox.left_top.y and testBox.right_bottom.y <= otherBox.right_bottom.y)
end

local function areBoxesAxiallyAdjacent(boxA, boxB)
    return (boxA.left_top.x == boxB.right_bottom.x or boxA.right_bottom.x == boxB.left_top.x
            or boxA.left_top.y == boxB.right_bottom.y or boxA.right_bottom.y == boxB.left_top.y)
end

local function isBoxContained(innerBox, outerBox)
    return (innerBox.left_top.x >= outerBox.left_top.x and innerBox.right_bottom.x <= outerBox.right_bottom.x)
        and (innerBox.left_top.y >= outerBox.left_top.y and innerBox.right_bottom.y <= outerBox.right_bottom.y)
end

-- TABLE

local function listKeys(table)
    local keys = {}
    local nKeys = 0
    for k, v in pairs(table) do
        keys[nKeys] = k
        nKeys = nKeys+1
    end
    return keys
end

local function listValues(table)
    local vals = {}
    for _, val in pairs(table) do
        insertTable(vals, val)
    end
    return vals
end

local function makeLookupTable(table)
    local lookup = {}
    for _, v in pairs(table) do
        lookup[v] = true;
    end
    return lookup;
end

local function filterTable(func, table)
    local newTable = {};
    for k, v in pairs(table) do
        if func(v) then
            newTable[k] = v;
        end
    end
    return newTable;
end

local function mapTable(func, table)
    local newTable = {};
    for k, v in pairs(table) do
        newTable[k] = func(v);
    end
    return newTable;
end

function insertTable(table, item)
    table[table_size(table)+1] = item;
end

local function getValueOrDefault(table, key, default)
    if not table[key] then
        table[key] = default
    end
    return table[key]
end

function reduce(table, operator, initial)
    local aggregateValue = initial
    for _, value in ipairs(table) do
        aggregateValue = operator(aggregateValue, value)
    end
    return aggregateValue
end

local function reduceTable(table, operator, initial)
    local aggregateValue = initial
    for _, value in pairs(table) do
        aggregateValue = operator(aggregateValue, value)
    end
    return aggregateValue
end

local function sum(table, initial)
    return reduce(table, function (a, b) return a+b; end, 0)
end

-- Copies a table of values, and fills in any missing values from a default table
local function mergeTableWithDefault(info, default)
    local newObj = table.deepcopy(default)
    for key, value in pairs(info) do
        newObj[key] = table.deepcopy(value)
    end
    return newObj
end

function stringToArray(str)
    local arr = {}
    for i = 1, #str, 1 do
        table.insert(arr, string.sub(str, i, i))
    end
    return arr
end

-- POSITION/DIRECTION

local cardinalDirectionTable = {}
cardinalDirectionTable[defines.direction.north] = {x=0, y=1}
cardinalDirectionTable[defines.direction.south] = {x=0, y=-1}
cardinalDirectionTable[defines.direction.east] = {x=1, y=0}
cardinalDirectionTable[defines.direction.west] = {x=-1, y=0}

local rotationTable = {
    [defines.direction.north] = defines.direction.east,
    [defines.direction.east] = defines.direction.south,
    [defines.direction.south] = defines.direction.west,
    [defines.direction.west] = defines.direction.north
}

local function offsetPosition(position, direction, amount)
    local offsetVector = cardinalDirectionTable[direction]
    return {
        x = position.x + offsetVector.x*amount,
        y = position.y + offsetVector.y*amount
    }
end

local function rotateDirectionClockwise(direction)
    return rotationTable[direction]
end

local function isNorthSouth(direction)
    return direction == defines.direction.north or direction == defines.direction.south
end

-- ======== --

local exports = {
    copy_prototype = copy_prototype,
    generate_item = generate_item,
    joinInternalNames = joinInternalNames,
    makeModIDJoiner = makeModIDJoiner,
    makeLocalisationString = makeLocalisationString,
    simpleStringHash = simpleStringHash,

    isMachineUnlockedByTechnologySimple = isMachineUnlockedByTechnologySimple,
    addRecipeToTech = addRecipeToTech,
    addRecipesToTechnologies = addRecipesToTechnologies,
    
    splitEnergyOrPower = splitEnergyOrPower,
    multiplyEnergy = multiplyEnergy,

    rotateAnimationsCCW = rotateAnimationsCCW,
    rotateAnimationsCW = rotateAnimationsCW,
    
    makeTile = makeTile,
    makeBox = makeBox,
    snapBoxToGrid = snapBoxToGrid,
    padBox = padBox,
    selectionToCollision = selectionToCollision,
    isBoxInBoundsOnEitherAxis = isBoxInBoundsOnEitherAxis,
    areBoxesAxiallyAdjacent = areBoxesAxiallyAdjacent,
    isBoxContained = isBoxContained,

    listKeys = listKeys,
    listValues = listValues,
    makeLookupTable = makeLookupTable,
    filterTable = filterTable,
    mapTable = mapTable,
    insertTable = insertTable,
    getValueOrDefault = getValueOrDefault,
    mergeTableWithDefault = mergeTableWithDefault,
    reduce = reduce,
    reduceTable = reduceTable,
    sum = sum,
    stringToArray = stringToArray,

    offsetPosition = offsetPosition,
    rotateDirectionClockwise = rotateDirectionClockwise,
    isNorthSouth = isNorthSouth
}

return exports