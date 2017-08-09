--============================================== DESCRIPTION ===========================================================
-- This module
--
--=============================================== SETUP ================================================================

local RO = RO

RO.Player = {}
local Player = RO.Player

Player.list = {}

--========================================== LOCAL VARIABLES ===========================================================


--========================================== LOCAL FUNCTIONS ===========================================================


--========================================= PUBLIC FUNCTIONS ===========================================================

function Player.New(tag)
    local player = {
        attribut = {
            unitTag = tag,
            missingHealth = 0,
            ultId = 0,
            ultPct = 0,
            dmg = 0,
            heal = {},
            pingtime = 0
        },
        health = {
            max = nil,
            current = nil,
            desyncMax = nil,
            recentMax = nil,
        },
    }
    local current, max, _ = GetPowerType(tag,POWERTYPE_HEALTH)

    player.health.max = max
    player.health.current = current
    player.health.desyncMax = max
    player.health.recentMax = current

end

function Player.SetDesync()
    for key, player in pairs(Player.list) do
        player.health.desyncMax = player.health.recentMax
        player.health.recentMax = player.health.current
    end






end

function Player.Init()

    for i = 1, GetGroupSize() do
        local tag = "group"..i
        local name = GetRawUnitName(tag)
        Player.list[name] = Player.New(tag)
    end

end

--
function Player.Join()
    for i = 1, GetGroupSize() do
        local tag = "group"..i
        local name = GetRawUnitName(tag)
        if not Player.list[name] then
            Player.list[name] = Player.New(tag)
        end
    end
    Player.UpdateTags()
end

function Player.Leave(name)
    Player.list[name] = nil
    Player.UpdateTags()
end

function Player.UpdateTags()
    for i = 1, GetGroupSize() do
        local tag = "group"..i
        local name = GetRawUnitName(tag)
        Player.list[name].attribut.unitTag = tag
    end
end