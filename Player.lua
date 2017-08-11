--============================================== DESCRIPTION ===========================================================
-- This module
--
--=============================================== SETUP ================================================================

local RO = RO

RO.Player = {}
local Player = RO.Player

Player.list = {}

--========================================== LOCAL VARIABLES ===========================================================

local DESYNC_TIMER = 20000

--========================================== LOCAL FUNCTIONS ===========================================================


--========================================= PUBLIC FUNCTIONS ===========================================================

function Player.New(tag)
    local player = {
        attribut = {
            unitTag = tag,
            missingHealth = 0,
            ultLabel = 0,
            ultPct = 0,
            dmg = 0,
            heal = {},
            pingtime = 0},
        ultimate = {
            label = 0,
            pct = 0,
            time = 0,
            uptime = nil,
        },
        health = {
            max = nil,
            current = nil,
            desyncMax = nil,
            recentMax = nil,
            time = nil,},
        combat = {
            damage = RO.Combat.NewCombat(),
            healing = RO.Combat.NewCombat(),
        },
        UpdateHealth = function(self, powerValue)
            self.health.time = GetGameTimeMilliseconds()
            self.health.current = powerValue
            self.recentMax = math.max(self.health.recentMax, powerValue)
            -- if new health is higher than what we assume
            self.desyncMax = math.max(self.health.desyncMax, powerValue)
        end,
        UpdateUltimate = function(self,label,pct)
            self.ultimate.label = label
            self.ultimate.pct = pct
            self.ultimate.time = GetGameTimeMilliseconds()
            self.ultimate.uptime = pct >= 100
                                    and (self.ultimate.uptime ~= nil
                                        or self.ultimate.time)
                                    or nil

        end
    }
    local current, max, _ = GetPowerType(tag,POWERTYPE_HEALTH)
    player.health.max = max
    player.health.current = current
    player.health.desyncMax = max
    player.health.recentMax = current
    return player
end

function Player.UpdateDesynch()
    for key, player in pairs(Player.list) do
        player.health.desyncMax = player.health.recentMax
        player.health.recentMax = player.health.current
    end

    zo_callLater(Player.UpdateDesynch(),DESYNC_TIMER)
end

--TODO: Remove this and update function in Combat
function Combat.OnPowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
    local time = GetGameTimeMilliseconds()
    -- filter only health updates
    if(powerType == POWERTYPE_HEALTH) then
        local name = GetRawUnitName(unitTag)
        Player.list[name]:UpdateHealth(powerValue)
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