--[[
    PlayerAnimLib by Kerkel
    Version 0
    TODO: RGON costume animation support akin to Hemoptysis
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

function PlayerAnimLib.Internal:ClearCallbacks()
    for _, v in ipairs(PlayerAnimLib.Internal.Callbacks) do
        PlayerAnimLib:RemoveCallback(v[1], v[2])
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
function PlayerAnimLib.Internal:Reload(player)
    player:ChangePlayerType(player:GetPlayerType())
end

---@param player EntityPlayer
---@param path string
function PlayerAnimLib.Internal:Load(player, path)
    local sprite = player:GetSprite()

    sprite:Load(path, true)

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
PlayerAnimLib.Internal:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, CallbackPriority.LATE, function (_, player)
    local data = PlayerAnimLib.Internal:GetData(player)

    if data.Loaded and player:IsExtraAnimationFinished() then
        data.Path = nil
        data.Anim = nil
        data.Loaded = nil
        PlayerAnimLib.Internal:Load(player, data.Default)
    end
end)

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

PlayerAnimLib.Internal:AddCallbacks()