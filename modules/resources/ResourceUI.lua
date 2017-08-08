
local RaidOrganiser = RO

RaidOrganiser.ResUI = {}
local ResUI = RaidOrganiser.ResUI
local this = ResUI
local threshold = 110

local Save
local Move = false
local labelAmount = 2
local maxTrackSize = 24

local labels = {
    [1] = RO_ResourcesStam,
    [2] = RO_ResourcesMag,
}

local resourceBars = {}


local resourceLabels = {
    [1] = "stamina",
    [2] = "magicka",
}




local function FillResourceBar( resourceBar, arg)
    resourceBar:SetHidden(false)
    resourceBar:SetValue(arg.pct)
    resourceBar:SetName(RaidOrganiser.UnitDisplayNameFromTag(arg.tag))
end

local function DisplayResourceBars( sortedList, parent )
    for k = 1, #sortedList do
        local length = #sortedList[k]
        for i = 1, maxTrackSize do
            if(i <= length) then
                FillResourceBar(resourceBars[k][i], sortedList[k][i])
            else
                resourceBars[k][i]:SetHidden(true)
            end


        end
    end


end


local function DemandsTracking (tag)
    local x = RaidOrganiser.RoleCombinationToNumber(RaidOrganiser.GetGroupMemberRoles(tag))
    local stam = RaidOrganiser.SavedVars.roleInfo.resources[x].trackStam
    local mag = RaidOrganiser.SavedVars.roleInfo.resources[x].trackMag

    return stam, mag
end


-----------------------------------------------------
-- CALLED BY:  RO.Ult.UpdateUI
-----------------------------------------------------
-- Transform <ultimateData[tag] = {time, pct, number, label}> TO <sortedList[label] = {tag, pct, number}>
-----------------------------------------------------
local function ToSortedLabelList(resourceData)
    -- sortedList[i] will contain all data regarding ultimateLabel i with 1 <= i <= ULTIMATE_DISPLAY_AMOUNT
    local sortedList = {}
    sortedList[1] = {}
    sortedList[2] = {}

    --d(resourceData)

    -- Afterwards: sortedList[i] contains all the data - still unsorted
    for tag, v in pairs(resourceData) do

        -- filter old pings and pings from dead people out
        if GetTimeStamp() - v.time < 5 and not IsUnitDeadOrReincarnating(tag) then

            local stam, mag = DemandsTracking(tag)
       -- d(mag, stam)

            -- do we want to track Stam?
            if stam then
                local argStam = {tag = tag, pct = v.stam }
                table.insert(sortedList[1],argStam)
            end

            if mag then
                local argMag = {tag = tag, pct = v.mag }
                table.insert(sortedList[2],argMag)
            end

        end

    end

--[[
    -- sort each label so that small numbers get displayed first
    for i=1, labelAmount do
        -- if no ultimate to display for current label, set it to be an empty list to avoid issues with trying to iterate over nil
        if(sortedList[i] == nil) then sortedList[i] = {} end
        table.sort(sortedList[i],function(a, b) return a.pct > b.pct end)
    end

    --d(sortedList)--]]
    return sortedList


end

-----------------------------------------------------
-- CALLED BY:  EVENT_ADDON_LOADED => RO.OnAddonLoaded => RO.Init
-----------------------------------------------------
-- set up the UltimateUI
-----------------------------------------------------
function ResUI.Init()
    Save = RaidOrganiser.SavedVars.ResourceUI
    table.insert(RaidOrganiser.ui, ResUI)
    ResUI.restorePos()
    ResUI.InitResourceBars()


end

function ResUI.InitResourceBars()
    for k = 1, #labels do
        resourceBars[k] = {}
        for i = 1, maxTrackSize do
            resourceBars[k][i] = RaidOrganiser.UI.ResourceBar("ResourceBar"..k..","..i, labels[k], {0, (RaidOrganiser.UI.ResourceBarSettings.dimY+1)* (i - 1)}, "", resourceLabels[k]  )
           -- resourceBars[k][i]:SetHidden(true)
        end
    end
end

-----------------------------------------------------
-- CALLED BY:  EVENT_ADDON_LOADED => RO.OnAddonLoaded => RO.Init
-----------------------------------------------------
-- set up the UltimateUI
-----------------------------------------------------
function ResUI.SetupUI()

    for i=1, labelAmount  do
        resourceLabels[i]:SetText(RaidOrganiser.SavedVars.resourceNames[i])
    end

end

---------------------------------------------
-- CALLED BY: RO.UIHandler
---------------------------------------------
-- fills the ultimate
---------------------------------------------
function ResUI.UpdateUI()
    -- d("updateUI")
    local resourceData = RaidOrganiser.Resources.GetData()
    local sortedList = ToSortedLabelList(resourceData)


    if(resourceData == nil) then
        d("resource data nil")
        return
    end

    DisplayResourceBars(sortedList)

--[[
    for i=1, labelAmount do
        local w = labels[i]
        w:SetText(RaidOrganiser.SavedVars.resourceNames[i] .. "\n".. PrintListToLabel(labelList[i]))
    end
    --]]
end


function ResUI.savePos( self )
    Save.Offset = {self:GetLeft(),self:GetTop()}
end

function ResUI.restorePos()

    RO_Resources:ClearAnchors()
    RO_Resources:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, Save.Offset[1],Save.Offset[2])

end

function ResUI.ToggleMove()
    Move = not Move
    if(Move) then
        d("Now moveable.")
    else
        d("Not moveable anymore.")
    end

    RO_Resources:SetMovable(Move)
    RO_Resources:SetMouseEnabled(Move)

end






