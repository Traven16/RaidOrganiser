
local RO = RO

RO.ResUI = {}
local ResUI = RO.ResUI
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

RO.healthBars = {}
local healthBars = RO.healthBars


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
        healthBars[k] = healthBars[k] or {}
        local length = #sortedList[k]
        for i = 1, maxTrackSize do
            healthBars[k][i] = healthBars[k][i] or {}
            if(i <= length) then
                FillResourceBar(healthBars[k][i], sortedList[k][i])
            else
                healthBars[k][i]:SetHidden(true)
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
    Save = RO.SavedVars.ResourceUI
    table.insert(RO.ui, ResUI)
    ResUI.restorePos()
    ResUI.InitResourceBars()


end

function ResUI.InitResourceBars()
    local sizeX, sizeY = RO.UI.HpBarSet.sizeX, RO.UI.HpBarSet.sizeY

    for x = 1, sizeX do
        healthBars[x] = healthBars[x] or {}
        for y = 1, sizeY do
            healthBars[x][y] = healthBars[x][y] or {}
            healthBars[x][y] = RO.UI.HealthBar("Healthbar"..x..","..y,RO_ResourcesHP,{(RO.UI.HpBarSet.dimX+3)*x,(RO.UI.HpBarSet.dimY+3)*y})
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
        resourceLabels[i]:SetText(RO.SavedVars.resourceNames[i])
    end

end

--[[
function ResUI.UpdateUI()
    -- d("updateUI")
    local resourceData = RO.Resources.GetData()
    local sortedList = ToSortedLabelList(resourceData)


    if(resourceData == nil) then
        d("resource data nil")
        return
    end

    DisplayResourceBars(sortedList)


    for i=1, labelAmount do
        local w = labels[i]
        w:SetText(RaidOrganiser.SavedVars.resourceNames[i] .. "\n".. PrintListToLabel(labelList[i]))
    end
    --
end
--]]

function ResUI.UpdateUI()

    for tag,player in pairs(RO.Player.tag) do
        local id = tag:sub(6)
        local x = math.ceil(id / RO.UI.HpBarSet.sizeY)
        local y = (id % RO.UI.HpBarSet.sizeY)
        y = (y ~= 0)
                and y
                or RO.UI.HpBarSet.sizeY

        --d("id: " .. id .. ", x: " .. x .. ", y: " ..  y)
        if player.exists then
            healthBars[x][y]:Update(tag,player)
        else
            healthBars[x][y]:SetHidden(true)
        end



    end

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






