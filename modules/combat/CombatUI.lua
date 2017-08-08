local RaidOrganiser = RO
RaidOrganiser.CombatUI = {}

local damageLabels = {
    [1] = RO_CombatDamage,
    [2] = RO_CombatHealing,
}

---
-- @param damageData damageData[playertag] = {time, damage, healing}
-- @return labelText[1] = {pl
local function CreateLabelText ( damageData )

end

---
--
function RaidOrganiser.CombatUI:UpdateUI()

    local damageData = RaidOrganiser.Combat.GetData()
    RaidOrganiser.CombatUI:UpdateHealingUI(damageData)
    RaidOrganiser.CombatUI:UpdateDamageUI(damageData)




end

function RaidOrganiser.CombatUI:UpdateDamageUI(combatData)
    local label = "Damage:"

    for tag, data in spairs(damageData,
        function(t,a,b)
            local dmg1, _ = unpack(t[a])
            local dmg2, _ = unpack(t[b])
            return dmg1 > dmg2
        end) do
            local damage, healing = unpack(data)
            label = label .. "\n" .. GetUnitName[tag] .. ": " .. damage
    end
end

function RaidOrganiser.CombatUI:UpdateHealingUI(combatData)
    local label = "Damage:"

    for tag, data in spairs(damageData,
        function(t,a,b)
            local _, heal1 = unpack(t[a])
            local _, heal2 = unpack(t[b])
            return heal1 > heal2
        end) do
        local damage, healing = unpack(data)
        label = label .. "\n" .. GetUnitName[tag] .. ": " .. healing
    end
end

