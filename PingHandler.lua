--============================================== DESCRIPTION ===========================================================
-- The PingHandler manages data exchange via Map Pings.
-- Each Ping encodes 8 digits of data (2 coordinates between 0 and 0.9999). For easy use, I set it up in a way that both
-- coordinates gets used by 1 module each.
--
-- In order to use the PingHandler for a module, that module has to have functions:
-- (1)GeneratePingData() ( returning x: 0 < x < 1 ): Encrypt whatever data you want to encrypt in this function
-- and (2)ProcessPingData() (no return): Decrypt the data again
--=============================================== SETUP ================================================================
local RO = RO

RO.Ping = {}
local this = RO.Ping
local Ping = RO.Ping

-- don't change these
RO.PING_FACTOR_4 = 10000
RO.PING_FACTOR_3 = RO.PING_FACTOR_4 / 10
RO.PING_FACTOR_2 = RO.PING_FACTOR_3 / 10
RO.PING_FACTOR_1 = RO.PING_FACTOR_2 / 10
Ping.disabled = false
Ping.PING_DELAY = 1000
Ping.modules = {}
--========================================== LOCAL VARIABLES ===========================================================
-- if a module requests to send a custom ping this variable gets set to a number representing the requested ping.
-- 1 = Ultimate used
local customPingRequested = {}
local cheatFilter = {}
--========================================== LOCAL FUNCTIONS ===========================================================

--========================================= PUBLIC FUNCTIONS ===========================================================

-- Initialize the PingHandler.
function Ping.Init()
    Ping.modules[1] = RO.Ultimate
    Ping.modules[2] = RO.Combat
    this.SendAutoPing()
end

--TODO: SendCustomPing() -> send a ping when user presses button, don't send next AutoPing
function Ping.SendCustomPing()
    local req = customPingRequested:remove(1)
    local data1 = 0.0000
    local data2 = req / RO.PING_FACTOR_4
    PingMap(MAP_PIN_TYPE_PING,MAP_TYPE_LOCATION_CENTERED,data1, data2)
    if(customPingRequested[1] == nil) then
        zo_callLater(Ping.SendAutoPing, Ping.PING_DELAY)
    else
        zo_callLater(Ping.SendCustomPing, Ping.PING_DELAY)
    end
end

-- Core Function of the Ping Handler. Once initialized send a Ping every PING_DELAY.
function Ping.SendAutoPing()
    --d(("Send Ping: [" .. data1 .. " | " .. data2 .. "]"))
    local data1 = Ping.modules[1].GeneratePingData()
    local data2 = Ping.modules[2].GeneratePingData()
    -- store previous map
    local ind = GetCurrentMapIndex()
    SetMapToMapListIndex(14)
    -- ping on cyro map
    PingMap(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, data1, data2)
    -- restore previous map
    SetMapToMapListIndex(ind)

    if(customPingRequested[1] == nil) then
        zo_callLater(Ping.SendAutoPing, Ping.PING_DELAY)
    else
        zo_callLater(Ping.SendCustomPing, Ping.PING_DELAY)
    end
end

--[[    Only have 2 positions to display pct (0 <= pct <= 100), so calculate -1 => -1 <= pct-1 <= 99
        Get rid of pct-1 < 0 by taking max(pct-1,0).
        Loss of precision for pct = 0 but this case is irrelevant because pct = 0 is equivalent to pct = 1 ]]
function Ping.CryptPct ( pct )
    return math.max( math.min(math.floor(pct),100) - 1, 0 )
end

function Ping.RealPct (pct)
    return pct+1
end

--[[    Gets a num < 100 with num = x*10 + y.
        Return x, y ]]
function Ping.SplitDecimal_2 ( coord )
    if(coord < 99) then
        -- xy / 10 = x.y
        coord = coord / RO.PING_FACTOR_1
        local data1 = math.floor(coord)
        local data2 = coord % 1 * RO.PING_FACTOR_1
        return RO.round(data1), RO.round(data2)
    end

end

--[[    IN: Coordinate with 4 decimal places: 0.xxyy
        OUT: 2 original numbers: xx, yy
        Used by modules ]]
function Ping.SplitDecimal_4( ultCoord )
    -- 0.xxyy * 100 = xx.yy
    ultCoord = ultCoord * RO.PING_FACTOR_2
    -- math.floor(xx.yy) = xx
    local val1 = math.floor(ultCoord)
    -- xx.yy % 1 = 0.yy => 0.yy * 100 = yy
    local val2 = ultCoord % 1 * RO.PING_FACTOR_2

    return RO.round(val1), RO.round(val2)
end

function Ping.OnGroupChange(eventCode, unitTag, dps,healer,tank)
    return
end

function Ping.OnCustomPing( tag , data)
    if data == 1 then
        RO.UltUI.UsedUltimate(tag)
    elseif data == 2 then
    end
end

--[[
    Gets called when a MapPing happens.
 ]]
function Ping.OnPing(event, etype, pingtype, playertag, offsetx, offsety, islocalplayerowner)

    -- for some reason sometimes you get pings from unitTag: waypoint
    if(playertag == "waypoint") then return end
    -- ignore [0|0]
    if(offsetx == offsety and offsetx == 0) then --[[d(playertag)]] return end
    -- filter custom pings
    if(offsetx == 0) then
        Ping.OnCustomPing(playertag, offsety * RO.PING_FACTOR_4)
        return
    end
    local time = GetGameTimeMilliseconds()
    local name = RO.UnitDisplayNameFromTag(playertag)

    cheatFilter[name] = cheatFilter[name] or 0
    -- filter MapPings that happen outside of the normal Ping-Rate
    local timediff = time - Ping.PING_DELAY - cheatFilter[name] + 30
    if(timediff  < 0 ) then
        --d("error " .. name .. ": " .. timediff )
        return
    else
        RO.DebugPrint("update")
        cheatFilter[name] = time
    end

    local ultCoord = RO.round(offsetx,4)
    local combatCoord = RO.round(offsety,4)

    --d("<-- [".. ultCoord .. " | " .. combatCoord .. "]")
    Ping.modules[1].ProcessPingData(playertag,ultCoord)
    Ping.modules[2].ProcessPingData(playertag,combatCoord)


end
