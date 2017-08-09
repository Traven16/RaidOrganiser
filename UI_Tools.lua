local RO = RO

RO.UI = {}
local UI = RO.UI
local this = RO.UI
UI.ResourceBarSettings = {
    dimX = 100,
    dimY = 25,
}

UI.UltBarSet = {
    dimX = 105,
    dimY = 25,
    iconW = 25,
    iconH = 25,
    threshold = 0,
}

UI.UltNotifier = {

    iconW = 50,
    iconH = 50,
    dimX = 100,
    dimY = 30,
}

UI.DmgSet = {

    nameW = 35,
    dmgW = 70,
    cellHeight = 19



}



UI.resourceColors = {
    magicka = {0.15, 0.45, 1 ,0.5},
    stamina = {0,1,0,0.25},
    ultimateUp = {0.2,1,0,0.5 },
    ultimate = {1,1,1,0.5}
}

local function printSortedListToString(table)

    local string = ""
    for k,v in ipairs(table) do
        string = string .. v .. "\n"
    end

    return string
end

local function Texture (name, parent, offset, file, size)
    if(name == nil or name == "") then return end

    local texture = _G[name]
    if ( texture == nil ) then texture = WINDOW_MANAGER:CreateControl( name , parent , CT_TEXTURE ) end

    texture:SetWidth(size[1])
    texture:SetHeight(size[2])
    texture:ClearAnchors()
    texture:SetAnchor( TOPLEFT, parent, TOPLEFT, offset[1], offset[2] )
    texture:SetHidden(false)
    texture:SetTexture(file)


    return texture


end

local function Backdrop ( name, parent, offset, size, edgecolor, centercolor)
    if(name == nil or name == "") then return end

    local back = _G[name]
    if ( back == nil ) then back = WINDOW_MANAGER:CreateControl( name , parent , CT_BACKDROP ) end

    back:SetDimensions(size[1], size[2])
    back:ClearAnchors()
    back:SetAnchor( TOPLEFT, parent, TOPLEFT, offset[1]-1, offset[2]-1 )
    back:SetHidden(false)
    back:SetEdgeTexture("", 8,1,0)
    back:SetEdgeColor(unpack(edgecolor))
    back:SetCenterColor(unpack(centercolor))




    return back

end

local function Statusbar (name, parent, color, offset, size )
    if(name == nil or name == "") then return end

    local bar = _G[name]
    if ( bar == nil ) then bar = WINDOW_MANAGER:CreateControl( name , parent , CT_STATUSBAR ) end

    bar:SetDimensions(size[1],size[2])
    bar:ClearAnchors()
    bar:SetAnchor( TOPLEFT, parent, TOPLEFT, offset[1], offset[2] )
    bar:SetHidden(false)
    bar:SetMinMax(0,100)
    bar:SetColor( unpack(color) )

    return bar
end



local function CustomLabel(name, parent, text, offset, anchor,font)
    if(name == nil or name == "") then return end



    local label = _G[name]
    if ( label == nil ) then label = WINDOW_MANAGER:CreateControl( name , parent , CT_LABEL ) end

    local distance = 5

    label:ClearAnchors()
    label:SetAnchor( anchor, parent, anchor, offset[1], offset[2])
    label:SetFont( font )
    label:SetText( text )
    label:SetHidden( false )


    return label

end

local function Label (name, parent, text, offset, anchor)

    return CustomLabel(name,parent,text,offset,anchor,"ZoFontGame")

end



function UI.ResourceBar( name, parent, offset, playerName , resourceType)
    if(name == nil or name == "") then return end

    local resourceBar = {
        --back = Backdrop(name.."Backdrop", parent, offset, {UI.ResourceBarSettings.dimX +2, UI.ResourceBarSettings.dimY +2},{UI.resourceColors[resourceType][1],UI.resourceColors[resourceType][2],UI.resourceColors[resourceType][3],1}),
        back = Backdrop(name.."Backdrop", parent, offset, {UI.ResourceBarSettings.dimX +2, UI.ResourceBarSettings.dimY +2},{0,0,0,1}, {0,0,0,0.5}),
        bar = Statusbar(name.."StatusBar" , parent , UI.resourceColors[resourceType], offset, {UI.ResourceBarSettings.dimX,UI.ResourceBarSettings.dimY}),
       -- pctLabel = Label(name.."PctLabel", parent, " ", {offset[1] + UI.ResourceBarSettings.dimX - 32, offset[2] + 1} , TOPLEFT),
        nameLabel = CustomLabel(name.."NameLabel", parent, playerName, {offset[1] + 4, offset[2] + 1}, TOPLEFT,"ZoFontWinH4"),


        SetValue = function ( self, value)
            self.bar:SetValue( value )
            --self.pctLabel:SetText( value )
        end,
        SetHidden = function (self, state)
            self.bar:SetHidden(state)
            self.nameLabel:SetHidden(state)
            --self.pctLabel:SetHidden(state)
            self.back:SetHidden(state)

        end,
        SetName = function (self, name)
            self.nameLabel:SetText(name)
        end,

    }



    return resourceBar;


end


--[[
    Currently not used (or I forgot to update this comment).
    Supposed to display an symbol of the ultimate when it's used
 ]]
function UI.UltimateNotificationSystem(name, parent)

    local ultNotify = {

        timerList = {},

        UpdateTimer = function(self)
            for k,v in pairs(self.timerList) do
                v:UpdateCooldown()
            end
        end,

        NewTimer = function(self, texture)

        end
    }
end

--[[
-- Part of the Ultimate Notfication System (see above)
 ]]
function UI.UltimateNotifier(name, parent, offset, texture)
    local dn = {
        timer = 0,
        icon = Texture(name.."Texture", parent, offset, texture, {UI.UltNotifier.iconW,UI.UltNotifier.iconH}),
        back = Backdrop(name.."Backdrop", parent , {offset[1],offset[2]}, {UI.UltNotifier.iconW + 2,UI.UltNotifier.iconH + 2},{0,0,0,1},{0,0,0,0.4}),
        --bar = Statusbar(name.."StatusBar" , parent , UI.resourceColors.ultimate, {offset[1] + UI.UltNotifier.iconW, offset[2]}, {UI.UltNotifier.dimX - UI.UltNotifier.iconW, UI.UltNotifier.dimY}),
        timerLabel = CustomLabel(name.."Timer", parent, "", {offset[1] + 4, offset[2] + 1}, TOPLEFT,"ZoFontWinH4"),

        Trigger = function(self, time)
            self:SetHidden(false)
            self:SetTimer(time)
            self:UpdateCooldown()
        end,

        SetTimer = function(self, time)
            self.timer = GetGameTimeMilliseconds() + time
            self.timerLabel:SetText(RO.round(time/1000))
        end,

        UpdateCooldown = function(self)
            local time = GetGameTimeMilliseconds()
            if(self.timer > time ) then
                self.timerLabel:SetText(RO.round((self.timer - time)/1000))
            else
                self:SetHidden(true)
            end
        end,

        SetHidden = function(self, state)
            self.icon:SetHidden(state)
            self.back:SetHidden(state)
            --self.bar:SetHidden(state)
            self.timerLabel:SetHidden(state)
        end


    }
    dn:SetHidden(true)
    dn.icon:SetDrawLayer(1)
    dn.icon:SetColor(1,1,1,0.7)

    return dn

end

function RO.d()
    d(1)
end

--[[
    Displays a single Ultimate up-status
 ]]
function UI.UltimateBar (name, parent, offset, playerName, texture)
    if(name == nil or name == "") then return end

    local ultimateBar = {
        comps = {},
        icon = Texture(name.."Texture", parent, offset, texture, {UI.UltBarSet.iconW,UI.UltBarSet.iconH}),
        back = Backdrop(name.."Backdrop", parent , offset, {UI.UltBarSet.dimX+2, UI.UltBarSet.dimY+2},{0,0,0,1},{0,0,0,0.5}),
        bar = Statusbar(name.."StatusBar" , parent , UI.resourceColors.ultimate, {offset[1] + UI.UltBarSet.iconW, offset[2]}, {UI.UltBarSet.dimX - UI.UltBarSet.iconW, UI.UltBarSet.dimY}),
        --pctLabel = CustomLabel(name.."PctLabel", parent, " ", {offset[1] + UI.UltBarSet.dimX - 32, offset[2] + 1} , TOPLEFT, "ZoFontWinH4"),


        nameLabel = CustomLabel(name.."NameLabel", parent, playerName, {offset[1] + UI.UltBarSet.iconW + 4, offset[2] + 1}, TOPLEFT,"ZoFontWinH4"),



        SetValue = function ( self, value)
            --self.pctLabel:SetText(value)
            self.bar:SetValue( value )
            if(value < UI.UltBarSet.threshold) then
                self:SetHidden(true)
            else
                self:SetHidden(false)
            end
            if(value >= 100) then
                self.bar:SetColor(unpack(UI.resourceColors.ultimateUp))
            else
                self.bar:SetColor(unpack(UI.resourceColors.ultimate))
            end

        end,
        SetHidden = function (self, state)
            self.bar:SetHidden(state)
            self.nameLabel:SetHidden(state)
            --self.pctLabel:SetHidden(state)
            self.back:SetHidden(state)
            self.icon:SetHidden(state)
        end,
        SetName = function (self, name)
            self.nameLabel:SetText( name )
        end,

    }

    ultimateBar.icon:SetDrawLayer(1)
    ultimateBar.icon:SetColor(1,1,1,1)



    return ultimateBar;
end



function UI.DamageList(name, parent, offset, size)
    if(name == nil or name == "") then return end

    local damage = {
        back = Backdrop(name.."Backdrop", parent, offset, {2*UI.DmgSet.nameW + 2*UI.DmgSet.dmgW, UI.DmgSet.cellHeight*size},{0,0,0,0.4},{0,0,0,0.3}),
        damageLabel = CustomLabel(name.."dmglabel", parent, "", {offset[1]+3, offset[2]}, TOPLEFT,"ZoFontGameSmall"),
        healingLabel = CustomLabel(name.."heallabel", parent, "", {offset[1]+UI.DmgSet.dmgW + UI.DmgSet.nameW, offset[2]}, TOPLEFT,"ZoFontGameSmall"),
        damageVal = CustomLabel(name.."damageVal", parent, "", {offset[1]+3 + UI.DmgSet.nameW, offset[2]}, TOPLEFT,"ZoFontGameSmall"),
        healingVal = CustomLabel(name.."healingVal", parent, "", {offset[1]+ UI.DmgSet.nameW*2 + UI.DmgSet.dmgW, offset[2]}, TOPLEFT,"ZoFontGameSmall"),


        Update = function(self, damageNames, damageValues, healingNames, healingValues)
            self:SetSize(#damageValues)
            self.damageLabel:SetText(printSortedListToString(damageNames))
            self.healingLabel:SetText(printSortedListToString(healingNames))
            self.damageVal:SetText(printSortedListToString(damageValues))
            self.healingVal:SetText(printSortedListToString(healingValues))
        end,

        SetSize = function(self, size)
            self.back:SetDimensions(2*UI.DmgSet.nameW + 2*UI.DmgSet.dmgW, UI.DmgSet.cellHeight*size)
        end,

        SetHidden = function(self,state)
            self.back:SetHidden(state)
            self.damageLabel:SetHidden(state)
            self.healingLabel:SetHidden(state)
            self.damageVal:SetHidden(state)
            self.healingVal:SetHidden(state)
        end


    }

    return damage

end

function UI.UltSys(control, length)

   local ultsys = {

       component = {

           -- list of labelsys
           ultgroup = {}

       },

       -- upon Update, notifty all labels about each player
        Update = function(self,playerlist)
            for player in playerlist do
                for ultgroup in pairs(self.component.ultgroup) do
                    ultgroup:ProcessPlayer(player)
                end
            end

        -- update all ultgroups
            for ultgroup in pairs(self.component.ultgroup) do
                ultgroup:Update()
            end

        end,

    }


end

function UI.UltGroup()
    local labelsys = {
        component = {
            -- list of labels
            bars = {},
            tracked = {},
            list = {}
        },
        ProcessPlayer = function(self,player)
        -- check if player belongs to this ultgroup
            if self.component.tracked[player.Ult.id] then
                self.component.list:insert(player)
            end
        end,
        Update = function(self)
            -- sort list
            self.component.list:sort(
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
                end
            )
            -- Update the bars
            for k,bar in ipairs(self.component.bars) do
                bar:Update(self.component.list[k])
            end
        end
    }
    return labelsys
end

function UI.UltBar(name, parent,offset)

    if(name == nil or name == "") then return end

    local ultimateBar = {
        comps = {
            icon = Texture(name.."Texture", parent, offset, texture, {UI.UltBarSet.iconW,UI.UltBarSet.iconH}),
            back = Backdrop(name.."Backdrop", parent , offset, {UI.UltBarSet.dimX+2, UI.UltBarSet.dimY+2},{0,0,0,1},{0,0,0,0.5}),
            bar = Statusbar(name.."StatusBar" , parent , UI.resourceColors.ultimate, {offset[1] + UI.UltBarSet.iconW, offset[2]}, {UI.UltBarSet.dimX - UI.UltBarSet.iconW, UI.UltBarSet.dimY}),
            --pctLabel = CustomLabel(name.."PctLabel", parent, " ", {offset[1] + UI.UltBarSet.dimX - 32, offset[2] + 1} , TOPLEFT, "ZoFontWinH4"),
        },
        nameLabel = CustomLabel(name.."NameLabel", parent, playerName, {offset[1] + UI.UltBarSet.iconW + 4, offset[2] + 1}, TOPLEFT,"ZoFontWinH4"),
        SetValue = function ( self, value)
            --self.pctLabel:SetText(value)
            self.bar:SetValue( value )
            if(value < UI.UltBarSet.threshold) then
                self:SetHidden(true)
            else
                self:SetHidden(false)
            end
            if(value >= 100) then
                self.bar:SetColor(unpack(UI.resourceColors.ultimateUp))
            else
                self.bar:SetColor(unpack(UI.resourceColors.ultimate))
            end

        end,
        SetHidden = function (self, state)
            self.bar:SetHidden(state)
            self.nameLabel:SetHidden(state)
            --self.pctLabel:SetHidden(state)
            self.back:SetHidden(state)
            self.icon:SetHidden(state)
        end,
        SetName = function (self, name)
            self.nameLabel:SetText( name )
        end,

    }
    ultimateBar.icon:SetDrawLayer(1)
    ultimateBar.icon:SetColor(1,1,1,1)

    return ultimateBar;
end


function RO.CreateSettingsWindow()
    local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")

    local panelData = {
        type = "panel",
        name = "RaidOrganiser",
        displayName = "RaidOrganiser",
        author = "Sanct",
        slashCommand = "/ro_settings",
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local cntrlOptionsPanel = LAM2:RegisterAddonPanel("RO_Settings", panelData)

    local optionsData = {
        {
            type = "header",
            name = "General Settings",
        },
        {
            type = "checkbox",
            name = "Count charged Ultimates",
            tooltip = "Display above each group of Ultimates how many Ultimates of this type are ready.",
            getFunc = function() return RO.SavedVars.Settings.showCharged end,
            setFunc = function(value) RO.SavedVars.Settings.showCharged = not RO.SavedVars.Settings.showCharged end,
        },
        {
            type = "checkbox",
            name = "Show your Ultimate number",
            tooltip = "Display your position in the list for your selected Ultimate.",
            getFunc = function() return RO.SavedVars.Settings.showNumber end,
            setFunc = function(value) RO.SavedVars.Settings.showNumber = not RO.SavedVars.Settings.showNumber end,
        },
        {
            type = "checkbox",
            name = "Show damage/healing numbers",
            tooltip = "Display the healing and damage values",
            getFunc = function() return not RO.SavedVars.Combat.LocalHide end,
            setFunc = function(value) RO.Combat.ToggleDamageVisLocal() end,
        },
        {
            type = "header",
            name = "Ultimates Settings",
        },
        {
            type = "description",
            text = "Select your Ultimate here:",
        },
        {
            type = "iconpicker",
            name = "Your ultimate",
            choices = RO.Map(RO.SavedVars.Ultimate.ultimates,function(a) return GetAbilityIcon(a.id) end),
            choicesTooltips = RO.Map(RO.SavedVars.Ultimate.ultimates,function(a) return GetAbilityName(a.id) end),
            getFunc = function() return GetAbilityIcon(RO.SavedVars.Ultimate.ultimates[RO.SavedVars.Ultimate.picked].id) end,
            setFunc = function(str)
                RO.SavedVars.Ultimate.picked = RO.Ultimate.IconLinkToId(str)
                RO.UltUI.InitUltimateBars()
            end,
            maxColumns = 7,
            visibleRows = 10,
            iconSize = 40,
        },
        {
            type = "description",
            text =  "Select which Ultimates should be displayed on which position from left to right. \n" ..
                    "WARNING: Picking the same Ultimate for 2 different positions will bug out"

        },
    }
---[[
    for i=1,6 do
        optionsData[#optionsData +1] = {
            type = "iconpicker",
            name = "Ultimate "..i,
            choices = RO.Map(RO.SavedVars.Ultimate.ultimates,function(a) return GetAbilityIcon(a.id) end),
            choicesTooltips = RO.Map(RO.SavedVars.Ultimate.ultimates,function(a) return GetAbilityName(a.id) end),
            getFunc = function() return RO.SavedVars.Ultimate.added.icon[i] end,
            setFunc = function(str)
                RO.SavedVars.Ultimate.added.icon[i] = str
                RO.SavedVars.Ultimate.added.id[i] = RO.Ultimate.IconLinkToId(RO.SavedVars.Ultimate.added.icon[i])
                RO.UltUI.InitUltimateBars()
            end,
            maxColumns = 7,
            visibleRows = 10,
            iconSize = 40,
            width = "half"
        }
        optionsData[#optionsData +1] = {
            type = "checkbox",
            name = "Notify if Ultimate not up",
            tooltip = "Show notficiation if an Ultimate isn't charged.",
            getFunc = function() return RO.SavedVars.Settings.notify[i] end,
            setFunc = function(value) RO.SavedVars.Settings.notify[i] = not RO.SavedVars.Settings.notify[i] end,
            width = "half"
        }
    end
    --]]
    LAM2:RegisterOptionControls("RO_Settings", optionsData)
end