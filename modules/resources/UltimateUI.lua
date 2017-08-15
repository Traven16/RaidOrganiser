--============================================== DESCRIPTION ===========================================================
-- This module handles the displaying of Ultimate related UI
--=============================================== SETUP ================================================================
local RO = RO
RO.UltUI = {}
local UltUI = RO.UltUI
local this = UltUI

UltUI.inv = {}
--========================================== LOCAL VARIABLES ===========================================================
local Save
local Move = false
local ultimateBars = {}
local maxTrackSize = 12
local labels = {}
local notifier = {}
local icons = {}
--========================================== LOCAL FUNCTIONS ===========================================================
--- Transform ultimateData to sortedList
-- @param ultimateData handed from Ultimate
--
local function ToSortedLabelList(ultimateData)
    -- sortedList[i] will contain all data regarding ultimateLabel i with 1 <= i <= ULTIMATE_DISPLAY_AMOUNT
    local sortedList = {}
    local k = 0
    -- AFTERWARDS: sortedList[i] contains all the data - still UNSORTED
    for tag, v in pairs(ultimateData) do
        k = k+1
        local label
        -- don't show data if it's from a dead player or more than 5 seconds old
        if GetGameTimeMilliseconds() - v.time  < 5000 and not RO.IsUnitDeadOrReincarnating(tag) then
            local arg = {tag = tag, pct = v.pct, number = v.number, label = v.label, uptime = v.uptime }
            local label = v.label
            --d(label)
            if(label ~= nil) then
                if(sortedList[label] == nil) then sortedList[label] = {} end
                table.insert(sortedList[label], arg)
            end
        end
    end

    -- SORT each sublist
    -- AFTERWARDS: sortedList[i] is SORTED by primarily pct and secondarily number
    for i=1, Save.labelAmount do
        -- if no ultimate to display for current label, set it to be an empty list to avoid issues with trying to iterate over nil
        if(sortedList[i] == nil) then sortedList[i] = {} end
        table.sort(sortedList[i],
            function(a, b)
                if(a.pct == b.pct) then
                    if(a.uptime == b.uptime) then
                        return a.tag < b.tag
                    else
                        return a.uptime < b.uptime
                    end
                else
                    return a.pct > b.pct
                end
            end)
    end
    return sortedList
end

--- Fill a single Ultimate Bar
-- @param ultBar the ultiamte bar that you want to fill
-- @param arg = { tag , pct }
--
local function FillUltimateBar( ultBar , arg)
    ultBar:SetHidden(false)
    ultBar:SetValue(arg.pct)
    ultBar:SetName(RO.UnitDisplayNameFromTag(arg.tag))

end

--- Display all ultimate bars
-- @param sortedList = { {tag1, pct1}, {tag2, pct2}, ... }
-- @param parent
--
local function DisplayUltimateBars( sortedList )

    local s = "|cff0000"
    for k = 1, Save.labelAmount do
        local plus = false
        local count = 0
        local length = #sortedList[k]
        for i = 1, maxTrackSize do
            if(i <= length ) then
                if(sortedList[k][i].pct > 99) then
                    plus = true
                    count = count + 1
                end

                if(AreUnitsEqual("player", sortedList[k][i].tag)) then

                    if(RO.SavedVars.Settings.showNumber) then

                        if(plus) then
                            RO_UltNumber1:SetText("|c00ff00 #" .. i .. "|r")
                        else
                            RO_UltNumber1:SetText("|cffffff #" .. i .. "|r")
                        end
                    else
                        RO_UltNumber1:SetText("")
                    end
                end

                FillUltimateBar(ultimateBars[k][i], sortedList[k][i])
            else
                ultimateBars[k][i]:SetHidden(true)
            end
        end
        if count == 0 and RO.SavedVars.Settings.notify[k] then
            s = s .. string.upper(GetAbilityName(RO.SavedVars.Ultimate.ultimates[RO.SavedVars.Ultimate.added.id[k]].id) .. "\n")
        end

    end
    RO_UltNotify1:SetText(s)
    if(not IsUnitGroupLeader("player")) then
        RO_UltNotify1:SetHidden(true)
    end

end

local function SetupUltimateUI()
    for i=1, #labels do
        labels[i]:SetText("")
    end
end

--=========================================== UTIL FUNCTIONS ===========================================================

function UltUI.GetLabelForUlt(id)
    local inv = RO.Inverse(RO.SavedVars.Ultimate.added)
    return inv[GetAbilityIcon(RO.SavedVars.Ultimate.ultimates[id].id)]
end


function UltUI.savePos( self )
    Save.Offset = {self:GetLeft(),self:GetTop()}
end

function UltUI.savePosNumber( self )
    Save.Num.Offset = {self:GetLeft(),self:GetTop()}
end

-- currently not in use
function UltUI.Trigger()
    notifier:Trigger(10000)
    zo_callLater(UltUI.UpdateNotifier, 1000)
end

-- currently not in use
function UltUI.UpdateNotifier()
    notifier:UpdateCooldown()
    zo_callLater(UltUI.UpdateNotifier, 1000)
end

function UltUI.InitUltimateBars()
    local offset = 12
    for k = 1,#labels do
        icons[k] = RO.UI.Texture("RO_UltimateIcon"..k, labels[k], {(offset) / 2,0}, RO.SavedVars.Ultimate.added.icon[k], {RO.UI.UltBarSet.dimX-offset, 32})
        icons[k]:SetHidden((k > Save.labelAmount))

        ultimateBars[k] = {}
        for i = 1, maxTrackSize do
            labels[k]:ClearAnchors()
            labels[k]:SetAnchor(TOPLEFT, RO_Ultimate, TOPLEFT, (k-1)*(RO.UI.UltBarSet.dimX+5), 0)
            ultimateBars[k][i] = RO.UI.UltimateBar("UltimateBar"..k..","..i, labels[k], {0, (RO.UI.UltBarSet.dimY+3)* (i+0.6)}, "", RO.SavedVars.Ultimate.added.icon[k] )
            ultimateBars[k][i]:SetHidden(true)
        end
    end
    UltUI.inv = RO.Inverse(RO.SavedVars.Ultimate.added.icon)
end

function UltUI.restorePos()
    RO_Ultimate:ClearAnchors()
    RO_Ultimate:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, Save.Offset[1],Save.Offset[2])
    RO_UltNumber:ClearAnchors()
    RO_UltNumber:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,Save.Num.Offset[1], Save.Num.Offset[2])
end

function UltUI.ToggleMove()
    Move = not Move
    if(Move) then
        d("Now moveable.")
    else
        d("Not moveable anymore.")
    end
    RO_Ultimate:SetMovable(Move)
    RO_Ultimate:SetMouseEnabled(Move)
    RO_UltNumber:SetMovable(Move)
    RO_UltNumber:SetMouseEnabled(Move)
end

--========================================= PUBLIC FUNCTIONS ===========================================================

function UltUI.Init()
    Save = RO.SavedVars.UltimateUI
    table.insert(RO.ui, UltUI)
    table.insert(labels,RO_Ultimate1)
    table.insert(labels,RO_Ultimate2)
    table.insert(labels,RO_Ultimate3)
    table.insert(labels,RO_Ultimate4)
    table.insert(labels,RO_Ultimate5)
    table.insert(labels,RO_Ultimate6)

    UltUI.restorePos()
    UltUI.InitUltimateBars()
    SetupUltimateUI()
end

--
function UltUI.UpdateUI()
    local ultimateData = RO.Ultimate.GetData()
    if(ultimateData ~= nil) then
        DisplayUltimateBars(ToSortedLabelList(ultimateData))
    end
end

function UltUI.UltimateUsed(unitTag)
    notifier:Trigger()
end


