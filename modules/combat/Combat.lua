local RO = RO
RO.Combat = {}
local this = RO.Combat
local Combat = RO.Combat
Combat.Ping = {
    maxVal = 999}
Combat.identifier = ""

--========================================== LOCAL VARIABLES ===========================================================
local trackedStats = { "dmgD" , "healD", "buffs", "maneuver" }
local combatData = {}
local realCombatData = {}
local unprocessed  = {0,0,}
local sent = {0,0,0,0,}
local missingHealth = {}
local damageLabel
local Save
local maxVal = 999
local prefixDamage = 0
local prefixHealing = 4
local Move = false

--========================================== LOCAL FUNCTIONS ===========================================================


local function CombatDataToSortedList( tableToSort, i )
    local sortedList = {}
    for k,v in pairs(tableToSort) do
        local arg = {}
        for x,j in pairs(v) do
            table.insert(arg,j)
        end
        arg.name = k
        table.insert(sortedList,arg)
    end
    table.sort(sortedList, function(a, b) return a[i] > b[i]  end)
    return sortedList
end

local function GeneratePingData( num )
    local sendVal = 0
    local prefix
    local proc
    if(num == 1) then
        prefix = prefixDamage
    else
        prefix = prefixHealing
    end
    for i = 0, 3 do
        if(unprocessed[num] < ( maxVal * 10^i)) then
            prefix = prefix + i
            sendVal = math.floor(unprocessed[num] / 10^i)
            proc = sendVal * 10^i
            --d("sent: " .. proc .. " of " .. unprocessed[num])
            unprocessed[num] = unprocessed[num] - proc
            sent[num] = sent[num] + proc
            break
        end
    end
    local coord = prefix / RO.PING_FACTOR_1 + sendVal / RO.PING_FACTOR_4
    --d(coord)
    return coord
end


--=========================================== UTIL FUNCTIONS ===========================================================

function Combat.restorePos()
    RO_Combat:ClearAnchors()
    RO_Combat:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, RO.SavedVars.Combat.Offset[1], RO.SavedVars.Combat.Offset[2])
    RO_Combat:SetHidden(Save.LocalHide and Save.GlobalHide)
end

function Combat.savePos( self )
    Save.Offset = {self:GetLeft(),self:GetTop()}
end

function Combat.ToggleDamageVisLocal()
    Save.LocalHide = not Save.LocalHide
    RO_Combat:SetHidden( Save.LocalHide)
end

function Combat.Num(table)
    local num = 0
    for k,v in pairs(table) do
        num = num + v.amount
    end
    return num
end

function Combat.Sum(table)
    local sum = 0
    for k,v in pairs(table) do
        sum = sum + v.sum
    end
    return sum
end


function Combat.Print()
    local mapped = RO.Map(realCombatData,function(a) return Combat.Sum(a) end)
    for k,v in ipairs(mapped) do
        d(v .. "-" .. sent[k])
    end
end

function Combat.ToggleMove()
    Move = not Move
    if(Move) then
        d("Now moveable.")
    else
        d("Not moveable anymore.")
    end
    RO_Combat:SetMovable(Move)
    RO_Combat:SetMouseEnabled(Move)
end

function RO.Combat.ResetCombatData()
    realCombatData = {
        [1] = {},
        [2] = {},
        [3] = {},
    }
    combatData = {
    }
end


function Combat.NewCombat()
    local combat = {
        amount = 0,
        sum = 0,
        HandleCombat = function( self, hitValue )
            self.sum = self.sum + hitValue
            self.amount = self.amount + 1
        end
    }
    return combat
end


function Combat.NewBuff()
    local buff = {
        timestamp = 1 ,
        amount = 0,
        sum = 0,
        HandleEvent = function( self )
            self.sum = self.sum + 1
            local time = GetTimeStamp()

            if(self.timestamp ~= time ) then
                self.amount = self.amount + 1
                self.timestamp = time
            end
        end
    }
    return buff
end


--========================================= PUBLIC FUNCTIONS ===========================================================


function Combat.GeneratePingDataDummy()
    if(math.random(0,1) > 0.5) then
        return math.random(4,5)/10 + math.random(999)/10000
    else
        return math.random(0,1)/10 + math.random(999)/10000
    end
end

function Combat.Init()
    RO.RegisterForCombatEventNotification(this)
    --RaidOrganiser.Chat.RegisterPrefix("C",this)
    Save  = RO.SavedVars.Combat
    Combat.restorePos()
    table.insert(RO.ui, Combat)
    for i = 1, #trackedStats do
        realCombatData[i] = {}
    end
    damageLabel = RO.UI.DamageList("damageLabel", RO_Combat, {0,0}, 2)
end

function Combat.UpdateUI()
    damageLabel:Update(Combat.DataForDisplay())
end

function Combat.GetData()
    return combatData
end

function Combat.GeneratePingData()
    if(unprocessed[1] > unprocessed[2]) then
        return GeneratePingData(1)
    else
        return GeneratePingData(2)
    end
end

function Combat.ProcessPingData(unitTag, combatCoord)
    local playertag = RO.UnitDisplayNameFromTag(unitTag)
    -- make sure we don't acces nil values
    if (combatData[playertag] == nil) then
        combatData[playertag] = {}
    end
    if(combatData[playertag][1] == nil) then
        combatData[playertag][1] = 0
    end
    if(combatData[playertag][2] == nil) then
        combatData[playertag][2] = 0
    end

    local d1, d2 = RO.Ping.SplitDecimal_4(combatCoord)
    local prefix , d12 = RO.Ping.SplitDecimal_2(d1)

    if(prefix == nil) then
        return
    end

    local pos
    if ( prefix >= prefixHealing ) then
        prefix = prefix - prefixHealing
        pos = 2
    else
        pos = 1
    end

    local val = 10^prefix * (d12*100 + d2)

    combatData[playertag][pos] = combatData[playertag][pos] + val

end


function Combat.GenerateChatData()
   -- d("called")
    local chatMessage = ""
    local num
    -- should be equal, however if it isn't, take the lower of the two to avoid sending unimportant information
    num = math.min(#realCombatData, #trackedStats)

    -- AFTERWARDS: chatMessage contains all
    for i=1, 2 do
        chatMessage = chatMessage .. RO.Chat.GenerateCode(Combat.Sum(realCombatData[i])) .. seperatorChar
    end

    for i=3, num do
        chatMessage = chatMessage .. RO.Chat.GenerateCode(Combat.Num(realCombatData[i])) ..  seperatorChar
    end

    return chatMessage
end



--- Processes the Combat related data of a chat message
-- @param message COMBAT-RELATED data - filter before calling this methode (has the form #code1#code2#code3#...)
--
function Combat.ProcessChatData( unitTag, message )
   -- d("combatData")
    local start = 1
    local codes = {}

    -- AFTERWARDS: codes contains all codes from the originial message in order of their appearance
    -- i iterates over each char in the message
    for i=1, #message do
        -- If we get too much data, ignore everything that comes after the final Seperator and break the loop
        if #codes == #trackedStats then
            break
        end

        --If current char is a Seperator, we save the substring between the last start-point and our current (position - 1) (don't want to add the Seperator)
        if(string.byte(message,i) == seperatorNum) then
            table.insert(codes, string.sub(message,start,i-1))

            -- mark the next position as next start point and next index
            start = i+1
        end
        --otherwise we look at the next char
    end

    for i,k in ipairs(codes) do

        codes[i] = RO.Chat.ProcessCode(k)

    end
   d(codes)

    -- Save the data in our combatData table
    combatData[unitTag] = codes

end



function Combat.DataForDisplay()

    local sortedDamage = CombatDataToSortedList(combatData, 1)
    local sortedHealing = CombatDataToSortedList(combatData, 2)
    local damageNames = {}
    local damageValues = {}
    local healingNames = {}
    local healingValues = {}

    for k,v in ipairs(sortedDamage) do
        table.insert(damageNames,v.name)
        table.insert(damageValues,v[1])
    end

    for k,v in ipairs(sortedHealing) do
        table.insert(healingNames,v.name)
        table.insert(healingValues,v[2])
    end

    return damageNames, damageValues, healingNames, healingValues


end

function Combat.DataString(i)
    local number = tonumber(i)
    local s = ""
    for j, k in ipairs(CombatDataToSortedList(combatData, number)) do
        if(k[number] ~= nil) then
            s = s .. k.name .. ": " .. k[number] .. " \n"
        end
    end
    return s
end

function Combat.PrintData( i )
    StartChatInput(Combat.DataString(i), CHAT_CHANNEL_PARTY, nil)
end


function Combat.OnPowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
    -- filter only health updates
    if(powerType == POWERTYPE_HEALTH) then
        if(unitTag:sub(1,5) == "group") then
            missingHealth[GetRawUnitName(unitTag)] = powerMax - powerValue
            --d(missingHealth)
            --RO.Player.list[GetRawUnitName(unitTag)].missingHealth = powerMax - powerValue
        end
    end
end

function Combat.OnCombatEvent(code, result, isError, abilityName, graphic, actionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType,log,sourceUnitID, targetUnitID, abilityID)
    if (result == ACTION_RESULT_DAMAGE) or (result == ACTION_RESULT_CRITICAL_DAMAGE) or (result == ACTION_RESULT_DOT_TICK) or (result == ACTION_RESULT_DOT_TICK_CRITICAL) then
        if(sourceName == targetName) then return end
        if(realCombatData[1][abilityName] == nil) then
            realCombatData[1][abilityName] = Combat.NewCombat()
        end
        unprocessed[1] = unprocessed[1] + hitValue
        realCombatData[1][abilityName]:HandleCombat(hitValue)
    end

    if (result == ACTION_RESULT_HEAL) or (result == ACTION_RESULT_CRITICAL_HEAL) or (result == ACTION_RESULT_HOT_TICK) or (result == ACTION_RESULT_HOT_TICK_CRITICAL) then
        if(missingHealth[targetName] == nil) then
            return
        else
            hitValue = math.min(missingHealth[targetName], hitValue)
        end
        if(realCombatData[2][abilityName] == nil) then
            realCombatData[2][abilityName] = Combat.NewCombat()
        end
        unprocessed[2] = unprocessed[2] + hitValue
        realCombatData[2][abilityName]:HandleCombat(hitValue)
    end
end





function Combat.PrintBuffs(name, started, ending, slot, stack, iconFile, type, effecttype, abilityType,statusEffectType,abilityId, canClickOff, castByPlayer)
    d(name .. ", " .. abilityType .. " , " .. (ending - GetGameTimeMilliseconds()/1000) .. " , " .. abilityId .. " , " .. statusEffectType .. " , " .. type)
end




