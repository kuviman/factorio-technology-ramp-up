
local function tintSpecificLayers(layers, tintLayers, tint)
    for _, layerIndex in pairs(tintLayers) do
        layers[layerIndex].tint = tint
        layers[layerIndex].hr_version.tint = tint
    end
end

local function tintAnimation(animation, tintLayers, tint)
    if animation.layers then
        tintSpecificLayers(animation.layers, tintLayers, tint)
    else
        animation.tint = tint
        if animation.hr_version then
            tintAnimation(animation.hr_version, tintLayers, tint)
        end
    end
end

local function tintPossible4Way(animation, tintLayers, tint)
    if animation.north then
        for _, direction in pairs(animation) do
            tintAnimation(direction, tintLayers, tint)
        end
    else
        tintAnimation(animation, tintLayers, tint)
    end
end

local function tintAnimations(prototype, tintLayers, tint)
    local targetAnimations4WayKeys = {
        "animation",
        "idle_animation",
    }
    local targetAnimationKeys = {
        "arm_02_right_animation",
        "arm_01_back_animation",
        "arm_03_front_animation"
    }
    for _, animationKey in pairs(targetAnimations4WayKeys) do
        if prototype[animationKey] then
            tintPossible4Way(prototype[animationKey], tintLayers, tint)
        end
    end
    for _, animationKey in pairs(targetAnimationKeys) do
        if prototype[animationKey] then
            -- log(serpent.block(prototype[animationKey]))
            tintAnimation(prototype[animationKey], tintLayers, tint)
        end
    end
end

local function tintSprite(sprite, tintLayers, tint)
    if sprite.layers then
        tintSpecificLayers(sprite.layers, tintLayers, tint)
    else
        if sprite.hr_version then
            tintSprite(sprite.hr_version, tintLayers, tint)
        end
        sprite.tint = tint
    end
end

local function tintSprites(prototype, tintLayers, tint)
    local spriteKeys = {
        -- "hole_sprite", -- Might need these, need to test the rocket silo
        -- "hole_light_sprite",
        "door_front_sprite",
        "door_back_sprite",
        "base_day_sprite",
        "base_front_sprite",
        "base_night_sprite",
    }
    for _, spriteKey in pairs(spriteKeys) do
        if prototype[spriteKey] then
            -- log(serpent.block(prototype[spriteKey]))
            tintSprite(prototype[spriteKey], tintLayers, tint)
        end
    end
end

local function tintIcon(prototype, tint)
    prototype.icons = {
        {
            icon = prototype.icon,
            tint = tint
        }
    }
    prototype.icon = nil
end

local exports = {
    tintPossible4Way = tintPossible4Way,
    tintAnimation = tintAnimation,
    tintAnimations = tintAnimations,
    tintSprites = tintSprites,
    tintIcon = tintIcon
}

return exports