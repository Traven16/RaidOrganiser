local RaidOrganiser = RO

RaidOrganiser.Resources = {}
local Resources = RaidOrganiser.Resources
local this = Resources
local resourceData = { }


---------------------------------
---- PUBLIC FUNCTIONS -----------
---------------------------------
function Resources.GetData()
    return resourceData
end

function Resources.Init()

end

function Resources.GeneratePingDataDummy(stam, mag)
    return (RaidOrganiser.Ping.CryptPct(stam) / RaidOrganiser.PING_FACTOR_2) + (RaidOrganiser.Ping.CryptPct(mag) / RaidOrganiser.PING_FACTOR_4)
end


function Resources.GeneratePingData()
    local stamina, maxStam , _ = GetUnitPower("player", POWERTYPE_STAMINA)
    local magicka, maxMag, _ = GetUnitPower("player", POWERTYPE_MAGICKA)

    local stam = RaidOrganiser.Ping.CryptPct(stamina*100 / maxStam)
    local mag = RaidOrganiser.Ping.CryptPct(magicka*100 / maxMag)

local s = "stam: " .. stam .. ", mag: " .. mag
    --d(s)

    return (stam / RaidOrganiser.PING_FACTOR_2) + (mag / RaidOrganiser.PING_FACTOR_4)

end

function Resources.ProcessPingData( playertag, resCoord )
    local stam, mag =  RaidOrganiser.Ping.SplitDecimal_4( resCoord )
local s = "stam: " .. stam

    stam = RaidOrganiser.Ping.RealPct(stam)

    mag = RaidOrganiser.Ping.RealPct(mag)
    resourceData[playertag] = {time = GetTimeStamp(), stam = stam, mag = mag }
    --d(resourceData[playertag].stam)
end


function Resources.OnGroupChange()
    return
end

function Resources.FilterCommand( extra )
    d(extra)
    if ( extra == "" or extra == "help") then
        d(help)
    end

end

SLASH_COMMANDS["/ro_resourcefilter"] = RaidOrganiser.Resources.FilterCommand