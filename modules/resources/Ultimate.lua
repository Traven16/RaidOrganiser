--============================================== DESCRIPTION ===========================================================
-- This module handles the backend of everything related to Ultimates

--=============================================== SETUP ================================================================
local RO = RO

RO.Ultimate = {}
local this = RO.Ultimate
local Ultimate = RO.Ultimate

local Save

--========================================== LOCAL VARIABLES ===========================================================
local ultimateData = { }
local current = 0

local number = 1
local selectedUltimate = 1

local ultimates = {
    [1] = {name = "Eye of Flame", info = {SKILL_TYPE_WEAPON,5,1}, duration = 9000},
    [2] = {name = "Negate", info = {SKILL_TYPE_CLASS,2,1}, duration = 9000},
    [3] = {name = "Healing Ultimate", info = {SKILL_TYPE_CLASS,3,1}, duration = 9000},
    [4] = {name = "Sleet Storm", info = {SKILL_TYPE_GUILD,2,1}, duration = 9000},

}

--========================================== LOCAL FUNCTIONS ===========================================================


--=========================================== UTIL FUNCTIONS ===========================================================

-- RETURNS: Custom Id of the icon.
-- This DOES NOT return the ingame abilityId. To get that, call RO.SavedVars.Ultimate.ultimates[ customId ]
function Ultimate.IconLinkToId(link)
    for k,v in pairs(Save.ultimates) do
        if GetAbilityIcon(v.id) == link then
            return k
        end
    end
end

-- Find all Ultimates and their IDs. Currently only the highest rank of each Ultimate gets saved. Currently not used for anything. Might aswell keep it tho
-- incase it might be useful later.
-- >> I stole most of this functions code from sirinsidiator's sidTools <<
function Ultimate.FindAllUltimateIds()
    local ultimates = {}
    local MAX_ABILITY_ID = 90000
    local id, count, throttle = 0, MAX_ABILITY_ID, 1000

    local function DoGenerate()
        for i = id, id + throttle - 1 do
            if(DoesAbilityExist(i)) then
                local name = GetAbilityName(i)
                local passive = IsAbilityPassive(i) and "passive" or "active"
                local cost, resType = GetAbilityCost(i)
                -- only continue if ability is an ultimate
                if(resType == POWERTYPE_ULTIMATE) then
                    -- is ultimate actual ability
                    if(GetAbilityDescriptionHeader(i) ~= "") or (GetAbilityDescription(i) ~= "") then
                        ultimates[name] = ultimates[name] or {}
                        table.insert(ultimates[name] , i)
                    end
                end
            end
        end

        if id > count then
            local i = 1
            for k,v in RO.pairsKeySorted(ultimates, function(a,b) return a < b end) do
                if( table.getn(v) == 4) then
                    local arg = {name = k,id = v[4]}
                    table.insert(RO.SavedVars.Ultimate.allUltimates, arg)
                end
            end
            d(RO.SavedVars.Ultimate.allUltimates)

        else
            id = id + throttle
            zo_callLater(DoGenerate,10)
        end
    end
    DoGenerate()
end

--========================================= PUBLIC FUNCTIONS ===========================================================


function Ultimate.GetData()
    local ultimateData = {}
    for name,player in pairs(RO.Player.list) do
        ultimateData[name] = player.ultimate
    end
    return ultimateData

end

function Ultimate.GeneratePingDataDummy(ult,current)
    local pct = RO.Ping.CryptPct(current)
    return RO.SavedVars.Ultimate.added.id[ult] / RO.PING_FACTOR_2 + (pct/ RO.PING_FACTOR_4)
end

-- Encodes ultimate Number and pct as float: 0.xxyy so that xx = number and yy = pct
function Ultimate.GeneratePingData()
    local id = RO.SavedVars.Ultimate.picked
    local cost = GetAbilityCost(Save.ultimates[id].id)
    local pct = RO.Ping.CryptPct(current*100/cost)
    return id / RO.PING_FACTOR_2 + pct / RO.PING_FACTOR_4
end


function Ultimate.ProcessPingData(playertag, ultCoord)
    --d("process")
    local time = GetTimeStamp()
    local id, pct = RO.Ping.SplitDecimal_4( ultCoord )
    if(id > #Save.ultimates or id < 1) then
        return
    end

    local label = RO.UltUI.inv[GetAbilityIcon(Save.ultimates[id].id)] or 0
    pct = RO.Ping.RealPct(pct)

    local name = GetRawUnitName(playertag)
    RO.Player.list[name]:UpdateUltimate(label,pct)
--[[
    if ( ultimateData[playertag] == nil) then ultimateData[playertag] = {time = nil, pct = nil, number = nil, ultimate = nil, uptime = nil} end
    local uptime = ultimateData[playertag].uptime

    uptime = pct >= 100 and time or nil
    ultimateData[playertag] = {time = time, pct = pct, ultimate = label, uptime = uptime }
    if(ultimateData[playertag].uptime == nil) then
        --d("WRONG UPTIME")
    end
    --]]
end

-- This gets called only if powerType == POWERTYPE_ULTIMATE
function Ultimate.OnPowerUpdate( eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax )
    -- double check anyway
    if( not powerType == POWERTYPE_ULTIMATE ) then return end
    if( not AreUnitsEqual(unitTag,"player")) then return end
    current = powerValue
end


function Ultimate.Init()
    --RO.RegisterForGroupChangeNotification(this)
    Save = RO.SavedVars.Ultimate
end


