--[[
    PlayerAnimLib by Kerkel
    Version 0
    TODO
    | RGON costume animation support akin to Hemoptysis
    | List player spritesheet paths
]]

local VERSION = 1

if PlayerAnimLib then
    if PlayerAnimLib.Internal.VERSION <= VERSION then
        PlayerAnimLib.Internal:ClearCallbacks()
    else
        return
    end
end

PlayerAnimLib = RegisterMod("PlayerAnimLib", 1)
PlayerAnimLib.Internal = {}
PlayerAnimLib.Internal.VERSION = VERSION
PlayerAnimLib.Internal.Callbacks = {}
PlayerAnimLib.Utility = {}

--#region Internal

---@type table<SkinColor, string>
PlayerAnimLib.Internal.COLOR_TO_SUFFIX = {
    [SkinColor.SKIN_PINK] = ".png",
    [SkinColor.SKIN_WHITE] = "_white.png",
    [SkinColor.SKIN_BLACK] = "_black.png",
    [SkinColor.SKIN_BLUE] = "_blue.png",
    [SkinColor.SKIN_RED] = "_red.png",
    [SkinColor.SKIN_GREEN] = "_green.png",
    [SkinColor.SKIN_GREY] = "_grey.png",
    [SkinColor.SKIN_SHADOW] = "_shadow.png",
}

---@type table<PlayerType, string>
PlayerAnimLib.Internal.PLAYER_TO_SKIN = {
    [PlayerType.PLAYER_ISAAC] = "gfx/characters/costumes/character_001_isaac.png",
    -- Todo
}

function PlayerAnimLib.Internal:ClearCallbacks()
    for _, v in ipairs(PlayerAnimLib.Internal.Callbacks) do
        PlayerAnimLib:RemoveCallback(v[1], v[3])
    end
end

function PlayerAnimLib.Internal:AddCallbacks()
    for _, v in ipairs(PlayerAnimLib.Internal.Callbacks) do
        PlayerAnimLib:AddPriorityCallback(v[1], v[2], v[3], v[4])
    end
end

---@param id ModCallbacks | any
---@param priority CallbackPriority | integer
---@param fn function
---@param filter any
function PlayerAnimLib.Internal:AddCallback(id, priority, fn, filter)
    PlayerAnimLib.Internal.Callbacks[#PlayerAnimLib.Internal.Callbacks + 1] = {id, priority, fn, filter}
end

---@param player EntityPlayer
function PlayerAnimLib.Internal:GetData(player)
    local data = player:GetData()

    data.__PAL = data.__PAL or {
        Default = "gfx/001.000_Player.anm2"
    }

    ---@class PALData
    ---@field Path string
    ---@field Anim string
    ---@field Loaded boolean
    ---@field Default string
    return data.__PAL
end

---@param player EntityPlayer
function PlayerAnimLib.Utility:GetSkinPath(player)
    return string.gsub(
        REPENTOGON and EntityConfig.GetPlayer(player:GetPlayerType()):GetSkinPath()
        or PlayerAnimLib.Internal.PLAYER_TO_SKIN[player:GetPlayerType()]
        or PlayerAnimLib.Internal.PLAYER_TO_SKIN[PlayerType.PLAYER_ISAAC],
        ".png",
        PlayerAnimLib.Internal.COLOR_TO_SUFFIX[player:GetBodyColor()]
    )
end

---@param player EntityPlayer
function PlayerAnimLib.Internal:Reload(player)
    local sprite = player:GetSprite()
    local path = PlayerAnimLib.Utility:GetSkinPath(player)

    for layer = PlayerSpriteLayer.SPRITE_GLOW, PlayerSpriteLayer.SPRITE_BACK do
        if layer ~= PlayerSpriteLayer.SPRITE_GHOST then
            sprite:ReplaceSpritesheet(layer, path)
        end
    end

    sprite:LoadGraphics()
end

---@param player EntityPlayer
---@param path string
function PlayerAnimLib.Internal:Load(player, path)
    player:GetSprite():Load(path, true)
    PlayerAnimLib.Internal:Reload(player)
end
--#endregion

--#region Utility

---@param player EntityPlayer
function PlayerAnimLib.Utility:GetDefaultAnm2(player)
    return PlayerAnimLib.Internal:GetData(player).Default
end
--#endregion

--#region Global

---@param player EntityPlayer
---@param path string
---@param anim string
function PlayerAnimLib:Play(player, path, anim)
    local data = PlayerAnimLib.Internal:GetData(player)

    data.Path = anim
    data.Anim = anim
    data.Loaded = true

    PlayerAnimLib.Internal:Load(player, path)

    player:PlayExtraAnimation(anim)
end

---@param player EntityPlayer
---@param path string
function PlayerAnimLib:SetDefaultAnm2(player, path)
    local data = PlayerAnimLib.Internal:GetData(player)

    data.Default = path

    if not data.Loaded then
        PlayerAnimLib.Internal:Load(player, path)
    end
end
--#endregion

---@param player EntityPlayer
PlayerAnimLib.Internal:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, CallbackPriority.LATE + 1, function (_, player)
    local data = PlayerAnimLib.Internal:GetData(player)

    if data.Loaded and (not player:GetSprite():IsPlaying(data.Anim) or player:IsExtraAnimationFinished()) then
        data.Path = nil
        data.Anim = nil
        data.Loaded = nil
        PlayerAnimLib.Internal:Load(player, data.Default)
    end
end)

PlayerAnimLib.Internal:AddCallbacks()
