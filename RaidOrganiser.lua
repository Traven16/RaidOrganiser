RO = {}
local this = RO

--=============================================== VARIABLES ============================================================
RO.name = "RaidOrganiser"
RO.version = 19

RO.MODE_ULTIMATE_PING = 0
RO.MODE_DAMAGE_PING = 1

local notifyOnGroupChange = {}
local notifyOnMapPing = {}
local notifyOnCombatEvent = {}
local enableDummies = false

-- All UIs have to add themselves into this list upon Init.
RO.ui = {}
RO.debug = false
RO.SavedVars = nil
RO.player = {}
RO.inverseUlts = {}
RO.invAdded = {}
local dummies = {}
local dummyCap = 21
local ultimates = {}
-- Timer for refreshing the UI
local REFRESH_UI_TIMER = 200

--============================================ SAVED VARIABLES =========================================================
RO.defaultValues = {
   ultimateNames = {
       [1] = "STORM",
       [2] = "NEGATE",
       [3] = "HEALING",
       [4] = "SLEET",
       [5] = "METEOR",
   },
    resourceNames = {
        [1] = "STAMINA: ",
        [2] = "MAGICKA: ",
    },
    nicknames = {},
    autoLabel = true,
    ultimateLabel = 1,
    ultimateCost = 200,
    autoUltimate = true,

    Ultimate = {
        allUltimates = {},
        picked = 1,
        diff = {},
        ultimates = {
            -- all possible ultimates. Names get stored seperatedly so that it's possible to change different names for certain ultimates
            [1]  = { ["id"] = 33679, ["name"] = "Ferocious Leap",},
            [2]  = { ["id"] = 34021, ["name"] = "Standard of Might",},
            [3]  = { ["id"] = 33987, ["name"] = "Shifting Standard",},
            [4]  = { ["id"] = 19982, ["name"] = "Magma Armor",},
            [5]  = { ["id"] = 37518, ["name"] = "Death Stroke",},
            [6]  = { ["id"] = 37713, ["name"] = "Veil of Blades",},
            [7]  = { ["id"] = 36207, ["name"] = "Soul Tether",},
            [8]  = { ["id"] = 30538, ["name"] = "Summon Storm Atronach",},
            [9]  = { ["id"] = 29844, ["name"] = "Negate Magic",},
            [10] = { ["id"] = 30354, ["name"] = "Overload",},
            [11] = { ["id"] = 23784, ["name"] = "Radial Sweep",},
            [12] = { ["id"] = 24063, ["name"] = "Nova",},
            [13] = { ["id"] = 27396, ["name"] = "Rite of Passage",},
            [14] = { ["id"] = 85985, ["name"] = "Feral Guardian",},
            [15] = { ["id"] = 85807, ["name"] = "Healing Thicket",},
            [16] = { ["id"] = 86112, ["name"] = "Sleet Storm",},
            [17] = { ["id"] = 86586, ["name"] = "Rapid Fire",},
            [18] = { ["id"] = 86515, ["name"] = "Fiery Rage",},
            [19] = { ["id"] = 86540, ["name"] = "Eye of Flame",},
            [20] = { ["id"] = 86370, ["name"] = "Lacerate",},
            [21] = { ["id"] = 86322, ["name"] = "Shield Wall",},
            [22] = { ["id"] = 86425, ["name"] = "Panacea",},
            [23] = { ["id"] = 86295, ["name"] = "Berserker Rage",},
            [24] = { ["id"] = 42566, ["name"] = "Dawnbreaker",},
            [25] = { ["id"] = 42467, ["name"] = "Meteor",},
            [26] = { ["id"] = 46529, ["name"] = "War Horn",},
            [27] = { ["id"] = 46609, ["name"] = "Barrier",},
            [28] = { ["id"] = 41926, ["name"] = "Clouding Swarm",},
            [29] = { ["id"] = 41937, ["name"] = "Devouring Swarm",},
            [30] = { ["id"] = 43093, ["name"] = "Soul Strike",},
        },
        added = {
            icon = {},
            id = {},},},
    UltimateUI = {
        Num = {
            Offset = {1020,554},},
        Offset = {683,725},},
    ResourceUI = {
        Offset = {500,75},
        Hide = false,},
    Combat = {
        Offset = {1620, 144 },
        LocalHide = false,
        GlobalHide = false,},
    UltUI = {
        ultTextures = {
            [1] = "esoui/art/icons/ability_destructionstaff_013_a.dds",
            [2] = "esoui/art/icons/ability_sorcerer_monsoon.dds",
            [3] = "esoui/art/icons/ability_templar_rite_of_passage.dds",
            [4] = "esoui/art/icons/ability_warden_006.dds",
            [5] = "esoui/art/icons/ability_mageguild_005.dds", },},
    Settings = {
        showCharged = true,
        showNumber = true,
        notify = {
            [1] = false,
            [2] = false,
            [3] = false,
            [4] = false,
            [5] = false,
            [6] = false,
        },
    },
}

--========================================== LOCAL FUNCTIONS ===========================================================


-- PapaCrown
local function OnPlayerActivated()
    SetFloatingMarkerInfo(MAP_PIN_TYPE_GROUP, 64, "EsoUI/Art/Compass/groupleader.dds")
end

--=========================================== UTIL FUNCTIONS ===========================================================

-- Check wether tag belongs to a real unit or to a dummy
function RO.IsRealTag( tag )
    return not (tag:sub(1,4) == "test")
end

-- returns inverse table (oldTable[k] = v => newTable[v] = k)
function RO.Inverse(someTable)
    local newTable = {}
    for k,v in pairs(someTable) do
        newTable[v] = k
    end
    return newTable
end

-- returns all values from someTable that aren't a value in anotherTable
function RO.Difference(someTable, anotherTable)
    local someInverse = RO.Inverse(someTable)
    local anotherInverse = RO.Inverse(anotherTable)
    local newTable = {}
    for k,v in pairs(someInverse) do
        if anotherInverse[k] == nil then
            table.insert(newTable,k)
        end
    end
    return newTable
end

-- Map function
function RO.Map(table,func)
    local newTable = {}
    for k,v in pairs(table) do
        newTable[k] = func(v)
    end
    return newTable
end

-- round to numDecimalPlaces
function RO.round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- substract all words from a sentence
function RO.split(sentence)
    local words = {}
    for word in string.gmatch(sentence, "%a+") do
        table.insert(words,word)
    end
    return words
end

-- Allows the user to setup custom nicknames for people in the raid that will be used instead
function RO.UnitDisplayNameFromTag(tag)
    local displayName = GetUnitDisplayName(tag)
    --
    return RO.IsRealTag(tag)
            and ((displayName ~= nil)
                    and RO.SavedVars.nicknames[displayName]
                    or string.sub(displayName,2,6))
            or tag
end

-- Interpretes PlayerRoles as binary number and returns the value
function RO.RoleCombinationToNumber (isDPS, isHeal, isTank)
    local comb = ((isTank and 4 or 0) + (isHeal and 2 or 0) + (isDPS and 1 or 0))
    return comb == 0
            and 8
            or comb
end

function RO.GetGroupMemberRoles(tag)
    return RO.IsRealTag(tag)
            and GetGroupMemberRoles(tag)
            or unpack(dummies[tonumber(tag:sub(5,#tag))].roles)
end

function RO.IsUnitDeadOrReincarnating(tag)
    return RO.IsRealTag(tag)
            and IsUnitDeadOrReincarnating(tag)
            or false
end

function RO.DebugPrint(arg)
    if(RO.debug) then
        d(arg)
    end
end

--========================================= PUBLIC FUNCTIONS ===========================================================

-- Initialise everything
function RO.Init()
    RO.SavedVars = ZO_SavedVars:NewAccountWide("RaidOrganiser_SavedVars", RO.version, "global", RO.defaultValues)
    EVENT_MANAGER:UnregisterForEvent(EVENT_ADD_ON_LOADED)

    RO.CreateSettingsWindow()
    RO.UltUI.Init()
    RO.Ultimate.Init()
    RO.Combat.Init()
    RO.Resources.Init()
    RO.ResUI.Init()
    RO.Ping.Init()
    RO.Chat.Init()
    for i = 0, dummyCap do
        dummies[i] = RO.NewDummy(i)
    end
    RO.UIHandler()
end

-- Update all UI Elements repeadetly
function RO.UIHandler()
    -- if dummies are enabled
    if(enableDummies) then
        for i = 1, dummyCap do
            dummies[i]:SendPing()
        end
    end

    -- update UI Elements
    for i,v in pairs(RO.ui) do
        v.UpdateUI()
    end
    -- repeat later
    zo_callLater(RO.UIHandler, REFRESH_UI_TIMER)
end

-- notify all modules that want to get notified on GroupChange
function RO.RegisterForGroupChangeNotification( module )
    table.insert(notifyOnGroupChange, module)
end

-- notify all modules that want to get notified on CombatEvent
function RO.RegisterForCombatEventNotification( module )
    table.insert(notifyOnCombatEvent, module)
end

--      return a new dummy.
--      Enable dummies ingame with /ro_dummies. Reloadui to disable again.
function RO.NewDummy(num)
    local dummy = {
        roles = {math.random() > 0.5, math.random() > 0.5, math.random() > 0.5 },
        name = "Player " .. num,
        mag = 100,
        stam = 100,
        id = math.random(1,6),
        ult = 50,
        num = math.random(4),
        tag = "test"..num,
        ultgain = math.random(1,3),
        SendPing = function(self)
            RO.Ping.OnPing(_, _, _, self.tag, RO.Ultimate.GeneratePingDataDummy(self.id, self.ult), RO.Combat.GeneratePingDataDummy(), _)
            self:Update()
        end,
        Update = function(self)
            self.mag = math.max(self.mag + (math.random(0,4) - 2.05),0)
            self.stam = math.max(self.stam + (math.random(0,4) - 2.05),0)
            if(self.ult == 100) then
                if(math.random() < 0.01) then
                    self.ult = 0
                end
            end
            self.ult =  math.min(self.ult + self.ultgain,100)
        end,}
    return dummy
end


--============================================ EVENT HANDLING  =========================================================

-- TODO: overthink this method
function RO.RegisterEvents()
    EVENT_MANAGER:RegisterForEvent(RO.name, EVENT_MAP_PING, RO.OnPing)
    EVENT_MANAGER:RegisterForEvent(RO.name, EVENT_COMBAT_EVENT, RO.OnCombatEvent)
    EVENT_MANAGER:AddFilterForEvent(RO.name,EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, 1)
end

function RO.OnCombatEvent(...)
    for i, v in pairs(notifyOnCombatEvent) do
        v.OnCombatEvent(...)
    end
end

function RO.OnChatMessage( code, channel, from, text, isCustomerService, fromDisplayName)
    if(channel == CHAT_CHANNEL_PARTY) then
        RO.Chat.ProcessMessage(fromDisplayName, text)
    end
end

function RO.OnPowerUpdate( eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
    if(powerType == POWERTYPE_HEALTH) then RO.Combat.OnPowerUpdate( eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax ) end
    if(powerType == POWERTYPE_ULTIMATE) then RO.Ultimate.OnPowerUpdate( eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax ) end
end


-- Unregister and prompt init
function RO.OnAddonLoaded(_, addonName)
    if(RO.name == addonName) then
        EVENT_MANAGER:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        RO.RegisterEvents()
        RO.Init()
    end
end

function RO.OnPing(...)
    RO.Ping.OnPing(...)
end

function RO.OnGroupChange(...)
    --d(notifyOnGroupChange)
    for i, v in pairs(notifyOnGroupChange) do
        v.OnGroupChange(...)

    end
end

--========================================== SLASH COMMANDS ============================================================

-- Generate a chat message (USED FOR DEBUG ONLY)
SLASH_COMMANDS["/ro_generate"] =
function()
    RO.Chat.SendMessage()
end

-- Process a chat message (USED FOR DEBUG ONLY)
SLASH_COMMANDS["/ro_process"] = function(extra)
    RO.Chat.ProcessMessage("player", extra)
end

-- Process a chat message (USED FOR DEBUG ONLY)
SLASH_COMMANDS["/ro_test"] = function(extra)
    local time1 = GetGameTimeMilliseconds()
    for i=1,20 do
        for j=1, 100 do
            d(i .. " + " .. j)
            dummies[1]:SendPing()
        end
    end
    local time2 = GetGameTimeMilliseconds() - time1
    d(time2)
end

-- Setup a nickname for player. All UIs will display the nickname instead of the display name
SLASH_COMMANDS["/ro_nick"] = function(args)
    local words = RO.split(args)
    RO.SavedVars.nicknames[words[1]] = words[2]
    d((words[1] .. " => " .. words[2]))
end

-- toggle moveability of all ultimate related UIs
SLASH_COMMANDS["/ro_moveult"] = function()
    RO.UltUI.ToggleMove()
end

-- toggle moveability of all resource related UIs
SLASH_COMMANDS["/ro_moveres"] = function()
    RO.ResUI.ToggleMove()
end

-- print component i
SLASH_COMMANDS["/ro_print"] = function( i )
    if(IsUnitGroupLeader("player")) then
        RO.Combat.PrintData( i )
    end
end

-- enable dummies
SLASH_COMMANDS["/ro_dummies"] = function()
    enableDummies = not enableDummies
end

-- toggle visibility of resource related UI
SLASH_COMMANDS["/ro_hideres"] =
function()
    RO.SavedVars.ResourceUI.Hide = not RO.SavedVars.ResourceUI.Hide
    RO_Resources:SetHidden(RO.SavedVars.ResourceUI.Hide)
end

-- toggle moveability of all damage related UIs
SLASH_COMMANDS["/ro_movedmg"] =
function()
    RO.Combat.ToggleMove()
end

-- toggle visibility of damage related UI
SLASH_COMMANDS["/ro_hidedmg"] =
function()
    RO.Combat.ToggleDamageVisibility()
end


--============================================ EVENTS ==================================================================


EVENT_MANAGER:RegisterForEvent(RO.name,EVENT_ADD_ON_LOADED, RO.OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(RO.name, EVENT_GROUP_MEMBER_ROLES_CHANGED, RO.OnGroupChange)
EVENT_MANAGER:RegisterForEvent(RO.name, EVENT_CHAT_MESSAGE_CHANNEL, RO.OnChatMessage)
EVENT_MANAGER:RegisterForEvent(RO.name, EVENT_POWER_UPDATE, RO.OnPowerUpdate)
EVENT_MANAGER:RegisterForEvent(RO.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)