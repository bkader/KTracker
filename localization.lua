local _, addon = ...

local _G = _G
local setmetatable = _G.setmetatable
local tostring, format = _G.tostring, _G.string.format
local rawset, rawget = _G.rawset, _G.rawget

local L = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, value == true and key or value)
    end,
    __index = function(self, key)
        return key
    end
})

-- Quick usage of string.format
-- @param line the line to print
-- @param ...
-- @return returns the formatted
function L:F(line, ...)
    line = L[line]
    return format(line, ...)
end

addon.L = L

--
-- copy the lines below, uncomment and edit them to localize.
--

-- L["|cffffd700Left-Click|r to lock/unlock."] = true
-- L["|cffffd700Right-Click|r to access settings."] = true
-- L["|cffffd700Shift+Click|r to move."] = true
-- L["|cffffd700Alt+Click|r for free drag and drop."] = true

-- L["Default Group"] = true
-- L["addon loaded"] = true

-- L["Resize"] = true
-- L["Click and drag to change size."] = true

-- L["Right-click for icon options."] = true
-- L["Left-click to move the group."] = true
-- L["Middle-click to enable/disable."] = true
-- L['Type "|caaf49141/kt config|r" for addon config'] = true

-- L["Choose Name"] = true
-- L["Enter the name or ID of the spell. You can add multiple buffs or debuffs by separatig them with semicolons."] = true

-- L["Enabled"] = true

-- L["Icon Type"] = true
-- L["Cooldown"] = true
-- L["Buff or Debuff"] = true
-- L["Reactive spell or ability"] = true
-- L["Temporary weapon enchant"] = true
-- L["Totem/non-MoG Ghoul"] = true

-- L["Cooldown Type"] = true
-- L["Spell"] = true
-- L["Item"] = true
-- L["Talent"] = true

-- L["Buff"] = true
-- L["Debuff"] = true

-- L["Show Timer"] = true
-- L["Only Mine"] = true

-- L["Weapon Slot"] = true
-- L["Main Hand"] = true
-- L["Off-Hand"] = true

-- L["Show When"] = true
-- L["Usable"] = true
-- L["Unusable"] = true
-- L["Always"] = true
-- L["Present"] = true
-- L["Absent"] = true

-- L["Unit to Watch"] = true
-- L["Player"] = true
-- L["Target"] = true
-- L["Target's Target"] = true
-- L["Focus"] = true
-- L["Focus Target"] = true
-- L["Pet"] = true
-- L["Pet's Target"] = true
-- L["Party Unit"] = true
-- L["Arena Unit"] = true
-- L["Arena %d"] = true
-- L["Party %d"] = true
-- L["Enter the unit name on which you want to track the aura."] = true

-- L["Animation Effect"] = true
-- L["None"] = true
-- L["Pulse"] = true
-- L["Shine"] = true

-- L["More Options"] = true
-- L["Clear Settings"] = true

-- L["Edit"] = true
-- L["Duplicate"] = true
-- L["Share"] = true
-- L["Group Status"] = true
-- L["Combat"] = true
-- L["Icons"] = true
-- L["Position"] = true

-- L["Lock"] = true
-- L["Unlock"] = true

-- L["Group Name"] = true
-- L["Talents Spec"] = true
-- L["Both"] = true
-- L["Primary"] = true
-- L["Secondary"] = true
-- L["Columns"] = true
-- L["Rows"] = true
-- L["Spacing"] = true
-- L["Spacing V"] = true
-- L["Spacing H"] = true
-- L["Enable Group"] = true
-- L["Only in Combat"] = true

-- L["The group name is required"] = true
-- L["You have reached the maximum allowed groups number"] = true

-- L["Size"] = true
-- L["Spec"] = true

-- L["Enable Sync"] = true
-- L["Check this you want to enable group sharing."] = true

-- L["Minimap Button"] = true
-- L["Check this you want show the minimap button."] = true

-- L["|caaf49141%s|r : Are you sure you want to delete this group?"] = true
-- L["|caaf49141%s|r : Are you sure you want to clear all icons?"] = true
-- L["You are about to reset everything, all groups, icons and their settings will be deleted. \nDo you want to continue?"] = true
-- L["Enter the name of the character to share the group with, or leave empty to share it with your party/raid members."] = true
-- L["%s wants to share a group of icons with you. Do you want to import it?"] = true
