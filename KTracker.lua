local addonName, addon = ...
local L = addon.L
local utils = addon.utils

local _G = _G
_G["KTracker"] = addon

--
-- default addon options
--
local def = {
    -- maximum allowed groups, columns and rows
    maxGroups = 64,
    maxColumns = 8,
    maxRows = 7,
    -- account DB template
    DB = {sync = true, groups = {}},
    -- character DB template
    CharDB = {enabled = true, locked = false, groups = {}},
    -- default group template
    group = {
        enabled = true,
        name = "",
        spec = 0,
        columns = 4,
        rows = 1,
        hspacing = 0,
        vspacing = 0,
        scale = 2,
        combat = false,
        created = 0,
        icons = {},
        position = {},
        style = {}
    },
    -- default icon template
    icon = {
        enabled = false,
        name = "",
        type = "",
        subtype = "",
        when = 1,
        unit = "player",
        mine = false,
        timer = false,
        filepath = nil,
        effect = "none"
    },
    -- group parts, account's and character's.
    DBGroup = {
        name = "",
        columns = 4,
        rows = 1,
        created = 0,
        icons = {}
    },
    CharDBGroup = {
        enabled = false,
        hspacing = 0,
        vspacing = 0,
        scale = 2,
        spec = 0,
        combat = false,
        position = {},
        style = {}
    }
}

--
-- SavedVariables
--
KTrackerDB = {}
KTrackerCharDB = {}

--
-- simple title holder
--
local titleString = "|cfff58cbaKader|r|caaf49141Tracker|r"

--
-- whether we're using and cooldown addon
--
local hasOmniCC, hasElvUI

--
-- addon synchronization
--
local syncPrefix = "KaderTracker"
local syncHandlers = {}

-- placeholders
local holderGroup = "KTrackerGroup%d"
local holderIcon = "KTrackerGroup%dIcon%d"

--
-- textures to be used
--
local textures = {
    "Interface\\Icons\\INV_Misc_QuestionMark",
    "Interface\\Icons\\INV_Misc_PocketWatch_01"
}

local Group, Icon = {}, {}
local groups, numGroups = {}, 0
local minimapButton

local Icon_EffectTrigger, Icon_EffectReset

--
-- cache some globals
--
local tinsert, tremove = _G.table.insert, _G.table.remove
local pairs, ipairs = _G.pairs, _G.ipairs
local type, select = _G.type, _G.select
local find, format, gsub = _G.string.find, _G.string.format, _G.string.gsub
local tostring, tonumber = _G.tostring, _G.tonumber
local time, GetTime = _G.time, _G.GetTime
local GetBuildInfo = _G.GetBuildInfo

local IsAddOnLoaded, CreateFrame = _G.IsAddOnLoaded, _G.CreateFrame
local wipe = _G.wipe

local GetInventorySlotInfo = _G.GetInventorySlotInfo
local GetInventoryItemTexture = _G.GetInventoryItemTexture

local GetWeaponEnchantInfo = _G.GetWeaponEnchantInfo
local GetTotemInfo = _G.GetTotemInfo
local GetCursorPosition = _G.GetCursorPosition
local IsSpellInRange, IsUsableSpell = _G.IsSpellInRange, _G.IsUsableSpell

local UnitName, UnitClass, UnitGUID = _G.UnitName, _G.UnitClass, _G.UnitGUID
local UnitExists, UnitIsDead = _G.UnitExists, _G.UnitIsDead
local UnitAura, UnitReaction = _G.UnitAura, _G.UnitReaction
local UnitBuff, UnitDebuff = _G.UnitBuff, _G.UnitDebuff
local unitName = UnitName("player")

local GetSpellInfo = _G.GetSpellInfo
local GetSpellTexture = _G.GetSpellTexture
local GetSpellCooldown = _G.GetSpellCooldown

local GetItemInfo = _G.GetItemInfo
local GetItemCooldown = _G.GetItemCooldown

-- external libraries
local LBF = LibStub:GetLibrary("LibButtonFacade", true)
local LiCD = LibStub:GetLibrary("LibInternalCooldowns", true)

-- we override GetItemCooldown and use LibInternalCooldowns one:
if LiCD and LiCD.GetItemCooldown then
    GetItemCooldown = function(...)
        return LiCD:GetItemCooldown(...)
    end
end

--------------------------------------------------------------------------
-- AddOn initialization

local mainFrame, LoadDatabase = CreateFrame("Frame", "KTracker_EventFrame")
do
    --
    -- makes sure to properly setup or load database
    --
    function LoadDatabase()
        -- we fill the account's DB if empty.
        if utils.isEmpty(KTrackerDB) then
            utils.fillTable(KTrackerDB, def.DB)
        end

        -- we fill the character's DB if empty.
        if utils.isEmpty(KTrackerCharDB) then
            utils.fillTable(KTrackerCharDB, def.CharDB)
        end

        -- keep reference of addon enable and lock statuses
        addon.sync = KTrackerDB.sync
        addon.enabled = KTrackerCharDB.enabled
        addon.locked = KTrackerCharDB.locked

        -- minimap button
        if KTrackerCharDB.minimap == nil then
            KTrackerCharDB.minimap = true
        end
        addon.minimap = KTrackerCharDB.minimap

        if not addon.minimap then
            addon:HideMinimapButton()
        end

        -- this step is crucial. If the account has not groups
        -- or all groups were deleted we make sure to create
        -- the default group.
        if utils.isEmpty(KTrackerDB.groups) then
            local group = utils.deepCopy(def.group)
            group.name = L["Default Group"]
            group.enabled = true
            Group:Save(group)
        end

        -- check if the character has all groups added to his/her table
        Group:Check()
    end

    --
    -- addon's slash command handler
    --
    local function SlashCommandHandler(cmd)
        if cmd == "config" or cmd == "options" then
            addon:Config()
        elseif cmd == "reset" then
            StaticPopup_Show("KTRACKER_DIALOG_RESET")
        else
            addon:Toggle()
        end
        L_CloseDropDownMenus() -- always close them.
    end

    --
    -- handles main frame events
    --
    local function EventHandler(self, event, ...)
        -- on ADDON_LOADED event.
        if event == "ADDON_LOADED" then
            local name = ...
            if name:upper() == addonName:upper() then
                mainFrame:UnregisterEvent("ADDON_LOADED")
                mainFrame:RegisterEvent("PLAYER_LOGIN")
                mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
                mainFrame:RegisterEvent("CHAT_MSG_ADDON")

                LoadDatabase()

                SlashCmdList["KTRACKER"] = SlashCommandHandler
                SLASH_KTRACKER1, SLASH_KTRACKER2 = "/ktracker", "/kt"

                -- ButtonFacade calllback
                if LBF then
                    LBF:RegisterSkinCallback(addonName, addon.OnSkin, addon)
                end

                addon:Print(L["addon loaded"])
            end
        elseif event == "PLAYER_LOGIN" then
            mainFrame:RegisterEvent("PLAYER_TALENT_UPDATE")

            -- using a cooldown count?
            if OmniCC or CooldownCount or YarkoCooldowns or ElvUI then
                hasOmniCC = true
            end

            -- using ElvUI?
            if ElvUI then
                hasElvUI = true
            end

            addon:Initialize(true)
        elseif event == "PLAYER_ENTERING_WORLD" then
            mainFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
            addon:Initialize()
        elseif event == "PLAYER_TALENT_UPDATE" then
            -- addon messages
            addon:SetCurrentSpec()
            addon:Initialize()
        elseif event == "CHAT_MSG_ADDON" and addon.sync then
            local prefix, msg, channel, sender = ...

            if msg and prefix == syncPrefix and sender ~= unitName then
                local handler = syncHandlers[prefix]
                if handler and type(handler) == "function" then
                    handler(msg, channel, sender)
                end
            end
        end
    end

    -- register required event and script
    mainFrame:RegisterEvent("ADDON_LOADED")
    mainFrame:SetScript("OnEvent", EventHandler)
end

--
-- called when the addon needs to be initialized
--
function addon:Load()
    Group:Check()
    wipe(groups)
    for i = 1, def.maxGroups do
        Group:Load(i)
    end
    numGroups = #groups
end

--
-- toggle addon's locked/unlocked status
--
function addon:Toggle()
    PlaySound("UChatScrollButton")
    StaticPopup_Hide("KTRACKER_DIALOG_RESET")
    StaticPopup_Hide("KTRACKER_DIALOG_CLEAR")
    StaticPopup_Hide("KTRACKER_DIALOG_NAME")
    StaticPopup_Hide("KTRACKER_DIALOG_UNITNAME")
    StaticPopup_Hide("KTRACKER_DIALOG_SHARE_SEND")
    StaticPopup_Hide("KTRACKER_DIALOG_SHARE_RECEIVE")
    L_CloseDropDownMenus()
    KTrackerCharDB.locked = not KTrackerCharDB.locked
    self.locked = KTrackerCharDB.locked
    self:Initialize()
end

--
-- addon synchronization
--
function addon:Sync(msg, channel, target)
    if self.sync then
        utils.sync(syncPrefix, msg, channel, target)
    end
end

--
-- ButtonFacade skin handler
--
function addon:OnSkin(skin, glossAlpha, gloss, group, _, colors)
    local style

    if not utils.isEmpty(groups) then
        for k, v in pairs(groups) do
            if v.name == group then
                style = KTrackerCharDB.groups[v.created].style
                break
            end
        end
    end

    if style then
        style[1] = skin
        style[2] = glossAlpha
        style[3] = gloss
        style[4] = colors
    end
end

--------------------------------------------------------------------------
-- Groups functions

--
-- this function is useful and makes sure the character has
-- all groups references and options added to his/her table.
--
function Group:Check()
    local DBGroups = KTrackerDB.groups
    local CharDBGroups = KTrackerCharDB.groups

    -- hold the time we are doing the check.
    local checkTime = time()

    -- list of the groups that the current character
    -- doesn't have on his database.
    local checked = {}

    -- first step: delete groups that were probably deleted but
    -- their data accidentally remained in character's database
    local safe = {}
    for _, obj in ipairs(DBGroups) do
        for id, _ in pairs(CharDBGroups) do
            if obj.created == id then
                safe[id] = true
            end
        end
    end
    for id, _ in pairs(CharDBGroups) do
        if not safe[id] then
            CharDBGroups[id] = nil
        end
    end

    -- second step: add missing groups to character
    for _, obj in ipairs(DBGroups) do
        if obj.created == 0 then
            obj.created = checkTime
        end
        if not CharDBGroups[obj.created] then
            local group = checked[obj.created] or utils.deepCopy(def.CharDBGroup)
            CharDBGroups[obj.created] = group
        end
    end
end

--
-- creates a new group from the def table
--
function Group:Save(obj, id)
    -- are we updating and existing group?
    if id and KTrackerDB.groups[id] then
        local DB = KTrackerDB.groups[id]

        -- creation date:
        obj.created = DB.created or time()

        -- check character's database
        local db = KTrackerCharDB.groups[DB.created]
        if not db then
            KTrackerCharDB.groups[DB.created] = utils.deepCopy(def.CharDBGroup)
            KTrackerCharDB.groups[DB.created].enabled = true
            db = KTrackerCharDB.groups[DB.created]
        end

        -- we proceed to update
        for k, v in pairs(obj) do
            if def.DBGroup[k] ~= nil then
                DB[k] = v -- account
            end
            if def.CharDBGroup[k] ~= nil then
                db[k] = v -- character
            end
        end

        return true
    end

    -- creating a new group

    obj = obj or {}
    if type(obj) == "string" then
        obj = {name = obj}
    end

    -- creation date:
    obj.created = time()

    -- prepare account and character tables
    local DB, db = utils.deepCopy(def.DBGroup), utils.deepCopy(def.CharDBGroup)
    for k, v in pairs(obj) do
        if def.DBGroup[k] ~= nil then
            DB[k] = v -- account
        end
        if def.CharDBGroup[k] ~= nil then
            db[k] = v -- character
        end
    end

    -- fill the group with required number of icons
    local num = DB.columns * DB.rows
    for i = 1, num do
        if not DB.icons[i] then
            local icon = utils.deepCopy(def.icon)
            tinsert(DB.icons, i, icon)
        end
    end

    -- save the final results to tables.
    tinsert(KTrackerDB.groups, DB)
    KTrackerCharDB.groups[obj.created] = db
    return #KTrackerDB.groups
end

do
    --
    -- resize button OnMouseDown and OnMouseUp functions
    --
    local Sizer_OnMouseDown, Sizer_OnMouseUp

    do
        --
        -- handles group resizing
        --
        local function Sizer_OnUpdate(self)
            local uiScale = UIParent:GetScale()
            local f = self:GetParent()
            local cursorX, cursorY = GetCursorPosition(UIParent)

            -- calculate the new scale
            local newXScale =
                f.oldScale * (cursorX / uiScale - f.oldX * f.oldScale) /
                (self.oldCursorX / uiScale - f.oldX * f.oldScale)
            local newYScale =
                f.oldScale * (cursorY / uiScale - f.oldY * f.oldScale) /
                (self.oldCursorY / uiScale - f.oldY * f.oldScale)
            local newScale = math.max(0.6, newXScale, newYScale)
            f:SetScale(newScale)

            -- calculate new frame position
            local newX = f.oldX * f.oldScale / newScale
            local newY = f.oldY * f.oldScale / newScale
            f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
        end

        --
        -- called on OnMouseDown event
        --
        function Sizer_OnMouseDown(self, button)
            -- resize only if the addon is not locked
            if addon.locked then
                return
            end

            if button == "LeftButton" then
                local f = self:GetParent()
                f.oldScale = f:GetScale()
                self.oldCursorX, self.oldCursorY = GetCursorPosition(UIParent)
                f.oldX, f.oldY = f:GetLeft(), f:GetTop()
                self:SetScript("OnUpdate", Sizer_OnUpdate)
            end
        end

        --
        -- called on OnMouseUp event
        --
        function Sizer_OnMouseUp(self, button)
            self:SetScript("OnUpdate", nil)
            if addon.locked then
                return
            end

            -- Left button released? save scale
            if button == "LeftButton" then
                local f = self:GetParent()
                local id = f:GetID()
                local DB = KTrackerDB.groups[id]
                local db = KTrackerCharDB.groups[DB.created]
                if DB and db then
                    db.scale = f:GetScale()
                    Group:Load(id)
                end
            end
        end
    end

    do
        --
        -- hide all group icons before loading -- hotfix
        --
        local function ResetGroupIcons(id)
            local i = 1
            local btnName = format(holderIcon, id, i)
            local btn = _G[btnName]
            while btn ~= nil do
                btn:Hide()
                i = i + 1
                btnName = format(holderIcon, id, i)
                btn = _G[btnName]
            end
        end

        --
        -- load a group and draws it into screen
        --
        function Group:Load(id)
            -- make sure the the group exists
            if not KTrackerDB.groups[id] then
                return
            end
            ResetGroupIcons(id)
            local obj = utils.deepCopy(KTrackerDB.groups[id])

            local db = KTrackerCharDB.groups[obj.created]
            if db then
                utils.mixTable(obj, db)
                if obj.spacing then -- fix old spacing
                    obj.hspacing = obj.hspacing or obj.spacing
                    obj.vspacing = obj.vspacing or obj.spacing
                    db.spacing = nil
                end
            end
            utils.fillTable(obj, def.group)

            -- cache the group
            if not groups[id] then
                tinsert(groups, id, obj)
            end

            -- we create the group frame
            local groupName = format(holderGroup, id)
            local group = _G[groupName]
            if not group then
                group = CreateFrame("Frame", groupName, UIParent, "KTrackerGroupTemplate")
            end
            group:SetID(id)

            if LBF then
                LBF:Group(addonName, obj.name):Skin(unpack(obj.style))
            end

            -- set the group title
            group.title = _G[groupName .. "Title"]
            group.title:SetText(obj.name)

            -- hold group resize button
            group.sizer = _G[groupName .. "Resizer"]
            group.sizer:RegisterForClicks("AnyUp")
            local sizerTexture = _G[groupName .. "ResizerTexture"]
            sizerTexture:SetVertexColor(0.6, 0.6, 0.6)

            if addon.locked then
                local spec = addon:GetCurrentSpec()
                if obj.spec > 0 and obj.spec ~= spec then
                    obj.enabled = false
                end

                group.title:Hide()
                group.sizer:Hide()
            else
                group.title:Show()
                group.sizer:Show()

                -- set resize button tooltip and scripts.
                utils.setTooltip(group.sizer, L["Click and drag to change size."], nil, L["Resize"])
                group.sizer:SetScript("OnMouseDown", Sizer_OnMouseDown)
                group.sizer:SetScript("OnMouseUp", Sizer_OnMouseUp)
            end

            if obj.enabled then
                -- group's width and height
                local width, height = 36, 36

                -- draw icons
                for r = 1, obj.rows do
                    for c = 1, obj.columns do
                        local i = (r - 1) * obj.columns + c
                        local iconName = format(holderIcon, id, i)
                        local icon = _G[iconName] or CreateFrame("Button", iconName, group, "KTrackerIconTemplate")
                        icon:SetID(i)

                        if c > 1 then
                            icon:SetPoint("TOPLEFT", _G[groupName .. "Icon" .. (i - 1)], "TOPRIGHT", obj.hspacing, 0)

                            -- we set the group width from the first row only.
                            if r == 1 and c <= obj.columns then
                                width = width + 36 + obj.hspacing
                            end
                        elseif r > 1 and c == 1 then
                            icon:SetPoint(
                                "TOPLEFT",
                                _G[groupName .. "Icon" .. (i - obj.columns)],
                                "BOTTOMLEFT",
                                0,
                                -obj.vspacing
                            )

                            height = height + obj.vspacing + 36 -- increment the height
                        elseif i == 1 then
                            icon:SetPoint("TOPLEFT", group, "TOPLEFT")
                        end

                        -- we update the icon now
                        if not obj.enabled then
                            Icon:ClearScripts(icon)
                        end
                        -- add the name of the icon
                        icon.fname = iconName
                        Icon:Load(icon, id, i)

                        if LBF then
                            LBF:Group(addonName, obj.name):AddButton(icon)
                        else
                            _G[iconName .. "Icon"]:SetSize(36, 36)
                            icon:SetNormalTexture(nil)
                            icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                            icon:SetBackdrop(
                                {
                                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                    tile = true,
                                    tileSize = 2,
                                    edgeSize = 4,
                                    insets = {left = 0, right = 0, top = 0, bottom = 0}
                                }
                            )
                        end
                    end
                end

                -- we make sure to change group size in order to be fully
                -- clamped to screen, then we set its scale.
                group:SetSize(width, height)
                group:SetScale(obj.scale)

                -- we position the group only if it was moved
                if not utils.isEmpty(obj.position) then
                    group:ClearAllPoints()
                    group:SetPoint(
                        obj.position.point or "CENTER",
                        obj.position.relativeTo or UIParent,
                        obj.position.relativePoint or "CENTER",
                        obj.position.xOfs or 0,
                        obj.position.yOfs or 0
                    )
                end
            end

            -- register/unregister group events
            if obj.combat and obj.enabled and addon.locked then
                group:RegisterEvent("PLAYER_REGEN_ENABLED")
                group:RegisterEvent("PLAYER_REGEN_DISABLED")
                group:SetScript(
                    "OnEvent",
                    function(self, event)
                        if event == "PLAYER_REGEN_ENABLED" then
                            self:Hide()
                        elseif event == "PLAYER_REGEN_DISABLED" then
                            self:Show()
                        end
                    end
                )
                group:Hide()
            else
                group:UnregisterEvent("PLAYER_REGEN_ENABLED")
                group:UnregisterEvent("PLAYER_REGEN_DISABLED")
                group:SetScript("OnEvent", nil)
                utils.showHide(group, obj.enabled)
            end
        end
    end
end

--------------------------------------------------------------------------
-- Icons functions

do
    --
    -- current selected icon and menu
    --
    local current, menu = {}

    --
    -- icon general, reactive and aura checkers
    ---
    local Icon_ReactiveCheck

    --
    -- opens the menu for the current icon
    --
    local Icon_OpenMenu
    do
        --
        -- icon menu list
        --
        local menuList, menu = {
            -- icon type --
            IconType = {
                {text = L["Cooldown"], arg1 = "type", arg2 = "cooldown", value = "spell"},
                {text = L["Buff or Debuff"], arg1 = "type", arg2 = "aura", value = "HELPFUL"},
                {text = L["Reactive spell or ability"], arg1 = "type", arg2 = "reactive", value = "spell"},
                {text = L["Temporary weapon enchant"], arg1 = "type", arg2 = "wpnenchant", value = "mainhand"},
                {text = L["Totem/non-MoG Ghoul"], arg1 = "type", arg2 = "totem", value = ""}
            },
            SpellType = {
                {text = L["Spell"], arg1 = "subtype", arg2 = "spell"},
                {text = L["Item"], arg1 = "subtype", arg2 = "item"},
                {text = L["Talent"], arg1 = "subtype", arg2 = "talent"}
            },
            AuraType = {
                {text = L["Buff"], arg1 = "subtype", arg2 = "HELPFUL"},
                {text = L["Debuff"], arg1 = "subtype", arg2 = "HARMFUL"}
            },
            WpnEnchantType = {
                {text = L["Main Hand"], arg1 = "subtype", arg2 = "mainhand"},
                {text = L["Off-Hand"], arg1 = "subtype", arg2 = "offhand"}
            },
            SpellWhen = {
                {text = L["Usable"], arg1 = "when", arg2 = 1},
                {text = L["Unusable"], arg1 = "when", arg2 = -1},
                {text = L["Always"], arg1 = "when", arg2 = 0}
            },
            TalentWhen = {
                {text = L["Off Cooldown"], arg1 = "when", arg2 = 1},
                {text = L["On Cooldown"], arg1 = "when", arg2 = -1},
                {text = L["Always"], arg1 = "when", arg2 = 0}
            },
            AuraWhen = {
                {text = L["Present"], arg1 = "when", arg2 = 1},
                {text = L["Absent"], arg1 = "when", arg2 = -1},
                {text = L["Always"], arg1 = "when", arg2 = 0}
            },
            Unit = {
                {text = L["Player"], arg1 = "unit", arg2 = "player"},
                {text = L["Target"], arg1 = "unit", arg2 = "target"},
                {text = L["Target's Target"], arg1 = "unit", arg2 = "targettarget"},
                {text = L["Focus"], arg1 = "unit", arg2 = "focus"},
                {text = L["Focus Target"], arg1 = "unit", arg2 = "focustarget"},
                {text = L["Pet"], arg1 = "unit", arg2 = "pet"},
                {text = L["Pet's Target"], arg1 = "unit", arg2 = "pettarget"},
                {disabled = true},
                {text = L["Party Unit"], hasArrow = true, value = "UnitParty"},
                {text = L["Arena Unit"], hasArrow = true, value = "UnitArena"},
                {disabled = true}
            },
            UnitParty = {
                {text = L:F("Party %d", 1), arg1 = "unit", arg2 = "party1"},
                {text = L:F("Party %d", 2), arg1 = "unit", arg2 = "party2"},
                {text = L:F("Party %d", 3), arg1 = "unit", arg2 = "party3"},
                {text = L:F("Party %d", 4), arg1 = "unit", arg2 = "party4"}
            },
            UnitArena = {
                {text = L:F("Arena %d", 1), arg1 = "unit", arg2 = "arena1"},
                {text = L:F("Arena %d", 2), arg1 = "unit", arg2 = "arena2"},
                {text = L:F("Arena %d", 3), arg1 = "unit", arg2 = "arena3"},
                {text = L:F("Arena %d", 4), arg1 = "unit", arg2 = "arena4"},
                {text = L:F("Arena %d", 5), arg1 = "unit", arg2 = "arena5"}
            }
        }

        --
        -- used for true and false values
        --
        local function Icon_OptionToggle()
            local g, i = current.group, current.icon
            local obj = KTrackerDB.groups[g].icons[i]
            if obj and obj[this.value] ~= nil then
                KTrackerDB.groups[g].icons[i][this.value] = this.checked
                local iconName = format(holderIcon, g, i)
                Icon:Load(_G[iconName], g, i)
            end
        end

        --
        -- used to set strings and numbers
        --
        local function Icon_OptionChoose(self, arg1, arg2)
            local g, i = current.group, current.icon
            local obj = KTrackerDB.groups[g].icons[i]
            -- double check the icon
            if obj and obj[arg1] ~= nil then
                KTrackerDB.groups[g].icons[i][arg1] = arg2
                if arg1 == "type" then
                    KTrackerDB.groups[g].icons[i].filepath = nil
                    if
                        this.value == "spell" or this.value == "talent" or this.value == "HELPFUL" or
                            this.value == "mainhand" or
                            this.value == "none"
                     then
                        KTrackerDB.groups[g].icons[i].subtype = this.value
                    end
                    L_CloseDropDownMenus()
                end
                local iconName = format(holderIcon, g, i)
                Icon:Load(_G[iconName], g, i)
                return
            end
            L_CloseDropDownMenus()
        end

        --
        -- clear the selected icon
        --
        local function Icon_OptionClear()
            local i, g = current.icon, current.group
            if KTrackerDB.groups[g].icons[i] then
                KTrackerDB.groups[g].icons[i] = utils.deepCopy(def.icon)
                local iconName = format(holderIcon, g, i)
                Icon:Load(_G[iconName], g, i)
            end
            L_CloseDropDownMenus()
        end

        --
        --  the main menu handler function
        --
        function Icon_OpenMenu(icon)
            if not icon then
                return
            end
            local i, g = icon:GetID(), icon:GetParent():GetID()
            local obj = KTrackerDB.groups[g].icons[i]
            if not obj then
                return
            end
            current.icon, current.group = i, g

            if addon.effects and not menuList.Effects then
                menuList.Effects = {
                    {
                        text = L["None"],
                        arg1 = "effect",
                        arg2 = "none"
                    }
                }
                for i, effect in ipairs(addon.effects) do
                    tinsert(
                        menuList.Effects,
                        i + 1,
                        {
                            text = effect.name,
                            arg1 = "effect",
                            arg2 = effect.id
                        }
                    )
                end
            end

            -- generate the menu
            if not menu then
                menu = CreateFrame("Frame", "KTrackerIconMenu")
            end
            menu.displayMode = "MENU"
            menu.initialize = function(self, level)
                local info = L_UIDropDownMenu_CreateInfo()
                level = level or 1

                if level >= 2 then
                    local tar = L_UIDROPDOWNMENU_MENU_VALUE
                    local menuItems = {}
                    if tar == "Unit" then
                        menuItems = utils.deepCopy(menuList.Unit)
                        tinsert(
                            menuItems,
                            {
                                text = L["Custom Unit"],
                                func = function()
                                    StaticPopup_Show("KTRACKER_DIALOG_UNITNAME", nil, nil, icon)
                                end
                            }
                        )
                    elseif menuList[tar] then
                        menuItems = utils.deepCopy(menuList[tar])
                    end

                    for _, v in ipairs(menuItems) do
                        info = utils.deepCopy(v)
                        info.checked = (v.arg2 and obj[v.arg1] == v.arg2)
                        info.func = v.func and v.func or Icon_OptionChoose
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)
                    end

                    return
                end

                -- display icon's name if set
                if obj.name and obj.name ~= "" then
                    local name
                    if obj.name:len() >= 24 then
                        name = obj.name:sub(0, 21) .. "..."
                    else
                        name = obj.name
                    end
                    info.text = name
                    info.isTitle = true
                    info.notCheckable = true
                    L_UIDropDownMenu_AddButton(info, level)
                    wipe(info)
                end

                -- let the player choose the name if the icon
                -- type is not set to weapon enchant.
                if obj.type ~= "wpnenchant" then
                    info.text = L["Choose Name"]
                    info.notCheckable = true
                    info.func = function()
                        StaticPopup_Show("KTRACKER_DIALOG_NAME")
                    end
                    L_UIDropDownMenu_AddButton(info, level)
                    wipe(info)
                end

                -- toggle icon enable status
                info.text = L["Enabled"]
                info.value = "enabled"
                info.checked = obj.enabled
                info.isNotRadio = true
                info.func = Icon_OptionToggle
                info.keepShownOnClick = true
                L_UIDropDownMenu_AddButton(info, level)
                wipe(info)

                -- icon type selection
                info.text = L["Icon Type"]
                info.value = "IconType"
                info.hasArrow = true
                info.notCheckable = true
                L_UIDropDownMenu_AddButton(info, level)
                wipe(info)

                -- in case no type is set
                if obj.type == "" then
                    info.text = L["More Options"]
                    info.disabled = true
                    info.notCheckable = true
                    L_UIDropDownMenu_AddButton(info)
                    wipe(info)
                else
                    -- icon effect (animation) -- not available for talents
                    if (obj.subtype ~= "talent") and (addon.effects and menuList.Effects) then
                        info.text = L["Icon Effect"]
                        info.value = "Effects"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)
                    end

                    info.disabled = true
                    L_UIDropDownMenu_AddButton(info)
                    wipe(info)

                    if obj.type == "cooldown" then
                        info.text = L["Cooldown Type"]
                        info.value = "SpellType"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show When"]
                        info.value = (obj.subtype == "spell") and "SpellWhen" or "TalentWhen"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show Timer"]
                        info.value = "timer"
                        info.checked = obj.timer
                        info.isNotRadio = true
                        info.func = Icon_OptionToggle
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)
                    elseif obj.type == "aura" then
                        info.text = L["Buff or Debuff"]
                        info.value = "AuraType"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Unit to Watch"]
                        info.value = "Unit"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show When"]
                        info.value = "AuraWhen"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show Timer"]
                        info.value = "timer"
                        info.checked = obj.timer
                        info.isNotRadio = true
                        info.func = Icon_OptionToggle
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Only Mine"]
                        info.value = "mine"
                        info.checked = icon.mine
                        info.isNotRadio = true
                        info.func = Icon_OptionToggle
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)
                    elseif obj.type == "reactive" then
                        info.text = L["Show When"]
                        info.value = "SpellWhen"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show Timer"]
                        info.value = "timer"
                        info.checked = obj.timer
                        info.isNotRadio = true
                        info.func = Icon_OptionToggle
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)
                    elseif obj.type == "wpnenchant" then
                        info.text = L["Weapon Slot"]
                        info.value = "WpnEnchantType"
                        info.hasArrow = true
                        info.notCheckable = true
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show When"]
                        info.value = "AuraWhen"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show Timer"]
                        info.value = "timer"
                        info.checked = obj.timer
                        info.isNotRadio = true
                        info.func = Icon_OptionToggle
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)
                    elseif obj.type == "totem" then
                        info.text = L["Unit"]
                        info.value = "Unit"
                        info.hasArrow = true
                        info.notCheckable = true
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show When"]
                        info.value = "AuraWhen"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Show Timer"]
                        info.value = "timer"
                        info.checked = obj.timer
                        info.isNotRadio = true
                        info.func = Icon_OptionToggle
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)
                    end
                end

                -- adding the clear settings button
                if (obj.name and obj.name ~= "") or obj.type ~= "" then
                    -- separator
                    info.disabled = true
                    L_UIDropDownMenu_AddButton(info)
                    wipe(info)

                    -- clear settings button
                    info.text = L["Clear Settings"]
                    info.func = Icon_OptionClear
                    info.notCheckable = true
                    L_UIDropDownMenu_AddButton(info)
                    wipe(info)
                end
            end

            L_ToggleDropDownMenu(1, nil, menu, "cursor", 0, 0)
        end
    end

    --
    -- handles icon's OnMouseDown event
    --
    local function Icon_OnMouseDown(self, button)
        if button == "LeftButton" then
            local f = self:GetParent()
            f:StartMoving()
        end
    end
    --
    -- hands icon's OnMouseUp event
    --
    local function Icon_OnMouseUp(self, button)
        -- opening the menu
        if button == "RightButton" then
            StaticPopup_Hide("KTRACKER_DIALOG_RESET")
            StaticPopup_Hide("KTRACKER_DIALOG_CLEAR")
            StaticPopup_Hide("KTRACKER_DIALOG_NAME")
            StaticPopup_Hide("KTRACKER_DIALOG_UNITNAME")
            StaticPopup_Hide("KTRACKER_DIALOG_SHARE_SEND")
            StaticPopup_Hide("KTRACKER_DIALOG_SHARE_RECEIVE")
            PlaySound("UChatScrollButton")
            Icon_OpenMenu(self)
        elseif button == "MiddleButton" then
            local parent = self:GetParent()
            local g, i = parent:GetID(), self:GetID()
            local DB = KTrackerDB.groups[g].icons[i]
            if DB then
                DB.enabled = not DB.enabled
                L_CloseDropDownMenus()
                Icon:Load(self, g, i)
            end
        elseif button == "LeftButton" then
            local f = self:GetParent()
            f:StopMovingOrSizing()

            local id = f:GetID()
            local DB = KTrackerDB.groups[id]
            if not DB then
                return
            end

            local db = KTrackerCharDB.groups[DB.created]
            if not db then
                return
            end

            local point, _, relativePoint, xOfs, yOfs = f:GetPoint()
            db.position.xOfs = xOfs
            db.position.yOfs = yOfs
            db.position.point = point
            db.position.relativePoint = relativePoint
            Group:Load(id)
        end
    end

    --
    -- called whenever an icon needs to be updated
    --
    function Icon:Load(icon, groupID, iconID)
        -- we make sure the icon frame exists.
        if not icon then
            return
        end

        -- hold the reference so we call later update the icon.
        local obj = KTrackerDB.groups[groupID].icons[iconID]
        -- we make sure to create the icon in case it was missing
        if not obj then
            KTrackerDB.groups[groupID].icons[iconID] = utils.deepCopy(def.icon)
            obj = KTrackerDB.groups[groupID].icons[iconID]
        end
        utils.mixTable(icon, obj)

        local iconName = icon:GetName()
        icon.texture = _G[iconName .. "Icon"]
        icon.stacks = _G[iconName .. "Stacks"]
        icon.cooldown = _G[iconName .. "Cooldown"]
        icon.coords = {groupID, iconID} -- used to alter database

        icon.stacks:Hide()
        icon.cooldown:Hide()

        -- icon transparency depends on when to use it
        if icon.when == 1 then
            icon.alphap = 1
            icon.alphan = 0
        elseif icon.when == 0 then
            icon.alphap = 1
            icon.alphan = 1
        elseif icon.when == -1 then
            icon.alphap = 0
            icon.alphan = 1
        else
            error(L:F("Alpha not assigned: %s", icon.name))
            icon.alphap = 1
            icon.alphan = 1
        end

        icon:Show()
        Icon:LoadTexture(icon)

        if addon.locked then
            icon:EnableMouse(0)
            icon:SetAlpha(icon.alphan)

            if icon.name == "" and icon.type ~= "wpnenchant" then
                icon.enabled = false
            end

            if icon.enabled then
                Icon:SetScripts(icon)
                Icon:Check(icon)
            else
                Icon:ClearScripts(icon)
                icon:Hide()
            end
        else
            icon:EnableMouse(1)
            icon:SetAlpha(icon.enabled and 1 or 0.4)
            Icon:ClearScripts(icon)
            icon.texture:SetVertexColor(1, 1, 1, 1)

            -- set icon tooltip and needed scripts
            utils.setTooltip(
                icon,
                {
                    L["Right-click for icon options."],
                    L["Left-click to move the group."],
                    L["Middle-click to enable/disable."],
                    L['Type "|caaf49141/kt config|r" for addon config']
                },
                nil,
                titleString
            )
            icon:SetScript("OnMouseDown", Icon_OnMouseDown)
            icon:SetScript("OnMouseUp", Icon_OnMouseUp)
        end
    end

    --
    -- pop up dialog that allows the user to set the name
    --
    StaticPopupDialogs["KTRACKER_DIALOG_NAME"] = {
        text = L[
            "Enter the name or ID of the spell. You can add multiple buffs or debuffs by separatig them with semicolons."
        ],
        button1 = SAVE,
        button2 = CANCEL,
        hasEditBox = true,
        hasWideEditBox = true,
        maxLetters = 254,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            local g, i = current.group, current.icon
            local obj = KTrackerDB.groups[g].icons[i]
            if not obj then
                self:Hide()
            end
            _G[self:GetName() .. "WideEditBox"]:SetText(obj.name)
            _G[self:GetName() .. "WideEditBox"]:SetFocus()
        end,
        OnHide = function(self)
            if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                ChatFrameEditBox:SetFocus()
            end
            _G[self:GetName() .. "WideEditBox"]:SetText("")
            _G[self:GetName() .. "WideEditBox"]:ClearFocus()
            wipe(current)
        end,
        OnAccept = function(self)
            local text = _G[self:GetName() .. "WideEditBox"]:GetText()
            local g, i = current.group, current.icon
            local obj = KTrackerDB.groups[g].icons[i]
            if obj then
                obj.name = text:trim()
                wipe(current)
                local iconName = format(holderIcon, g, i)
                Icon:Load(_G[iconName], g, i)
            end
            self:Hide()
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local text = _G[parent:GetName() .. "WideEditBox"]:GetText()
            local g, i = current.group, current.icon
            local obj = KTrackerDB.groups[g].icons[i]
            if obj then
                obj.name = text:trim()
                wipe(current)
                local iconName = format(holderIcon, g, i)
                Icon:Load(_G[iconName], g, i)
            end
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            wipe(current)
            self:GetParent():Hide()
        end
    }

    --
    -- pop up dialog that allows the user to set custom icon unit
    --
    StaticPopupDialogs["KTRACKER_DIALOG_UNITNAME"] = {
        text = L["Enter the unit name on which you want to track the aura."],
        button1 = SAVE,
        button2 = CANCEL,
        hasEditBox = true,
        maxLetters = 12,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self, icon)
            if icon then
                _G[self:GetName() .. "EditBox"]:SetText(icon.unit)
                _G[self:GetName() .. "EditBox"]:SetFocus()
            end
        end,
        OnHide = function(self)
            if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                ChatFrameEditBox:SetFocus()
            end
            _G[self:GetName() .. "EditBox"]:SetText("")
            _G[self:GetName() .. "EditBox"]:ClearFocus()
        end,
        OnAccept = function(self)
            local unit = _G[self:GetName() .. "EditBox"]:GetText():trim()
            if unit == "" then
                unit = "player"
            elseif not UnitExists(unit) then
                addon:PrintError(L["Could not find that unit."])
                return
            end
            local g, i = current.group, current.icon
            local obj = KTrackerDB.groups[g].icons[i]
            if obj then
                obj.unit = unit
                wipe(current)
                local iconName = format(holderIcon, g, i)
                Icon:Load(_G[iconName], g, i)
            end
            self:Hide()
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local unit = _G[parent:GetName() .. "EditBox"]:GetText()
            if unit == "" then
                unit = "player"
            elseif not UnitExists(unit) then
                addon:PrintError(L["Could not find that unit."])
                return
            end
            local g, i = current.group, current.icon
            local obj = KTrackerDB.groups[g].icons[i]
            if obj then
                obj.unit = unit
                wipe(current)
                local iconName = format(holderIcon, g, i)
                Icon:Load(_G[iconName], g, i)
            end
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            wipe(current)
            self:GetParent():Hide()
        end
    }
end

--
-- called whenever an icon needs to has its scripts removed
--
function Icon:ClearScripts(icon)
    if not icon then
        return
    end
    -- remove scripts
    icon:SetScript("OnEvent", nil)
    icon:SetScript("OnUpdate", nil)
    -- unregister events
    icon:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    icon:UnregisterEvent("ACTIONBAR_UPDATE_USABLE")
    icon:UnregisterEvent("BAG_UPDATE_COOLDOWN")
    icon:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    icon:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    icon:UnregisterEvent("PLAYER_TARGET")
    icon:UnregisterEvent("PLAYER_TARGET_CHANGED")
    icon:UnregisterEvent("PLAYER_TOTEM_UPDATE")
    icon:UnregisterEvent("UNIT_AURA")
    icon:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

--
-- simply changes the icon texture
--
function Icon:LoadTexture(icon)
    if not icon then
        return
    end

    local noTexture, texture

    if icon.type == "cooldown" or icon.type == "reactive" then
        noTexture = textures[1]

        if icon.subtype == "spell" or icon.subtype == "talent" then
            local name = addon:GetSpellNames(icon.name, true)
            texture = GetSpellTexture(name) or select(3, GetSpellInfo(icon.name))

            -- still no texture? Try with backup
            if not texture and LiCD.talentsRev[icon.name] then
                texture = select(3, GetSpellInfo(LiCD.talentsRev[icon.name]))
            end
        elseif icon.subtype == "item" then
            local name = addon:GetItemNames(icon.name, true)
            texture = name and select(10, GetItemInfo(name)) or textures[1]
        end
    elseif icon.type == "aura" then
        noTexture = textures[2]
        texture = icon.filepath

        if not texture and icon.name ~= "" then
            local name = addon:GetSpellNames(icon.name, true)
            texture = name and GetSpellTexture(name) or textures[1]
        end
    elseif icon.type == "wpnenchant" then
        noTexture = textures[1]

        local slot
        if icon.subtype == "mainhand" then
            slot = select(1, GetInventorySlotInfo("MainHandSlot"))
        elseif icon.subtype == "offhand" then
            slot = select(1, GetInventorySlotInfo("SecondaryHandSlot"))
        end
        texture = GetInventoryItemTexture("player", slot)
    elseif icon.type == "totem" then
        noTexture = textures[1]
        local name = addon:GetSpellNames(icon.name, true)
        texture = name and GetSpellTexture(name) or textures[1]
    end

    utils.setTexture(icon.texture, texture, noTexture, texture)
end

--
-- checks the icon
--
function Icon:Check(icon)
    if not icon then
        return
    -- reactive spells or cooldowns.
    elseif icon.type == "cooldown" or icon.type == "reactive" then
        local startTime, duration

        if icon.startTime and icon.duration then
            startTime, duration = icon.startTime, icon.duration
        else
            if icon.subtype == "spell" or icon.subtype == "talent" then
                icon.rname = addon:GetSpellNames(icon.name, true)
                startTime, duration, _ = GetSpellCooldown(icon.rname)
            elseif icon.subtype == "item" then
                icon.rname = addon:GetItemNames(icon.name, true)
                startTime, duration, _ = GetItemCooldown(icon.rname)
            end
        end

        if icon.rname and icon.timer and duration then
            if duration > 0 then
                CooldownFrame_SetTimer(icon.cooldown, startTime, duration, 1)
            else
                CooldownFrame_SetTimer(icon.cooldown, 0, 0, 0)
            end
        end
    
    -- auras: buffs and debuffs
    elseif icon.type == "aura" and UnitExists(icon.unit) then
        local auras = addon:GetSpellNames(icon.name, nil, true)
        local i, name, hasAura

        local filter = icon.subtype .. (icon.mine and "|PLAYER" or "")

        for i, name in ipairs(auras) do
            local spellId, spellName
            if tonumber(name) ~= nil then
                spellId = tonumber(name)
                spellName = select(1, GetSpellInfo(spellId))
            else
                spellName = name:trim()
            end

            local _name, _, _icon, _count, _, _duration, _expires, _, _, _, _spellId =
                UnitAura(icon.unit, spellName, nil, filter)

            if _name then
                -- we have used the ID? we need to be precise
                -- if spellId and (_name:lower() ~= spellName:lower()) then
                if spellId then
                    if spellId == _spellId then
                        icon.duration = _duration
                        icon.rname = spellName
                        hasAura = true
                    else
                        -- the idea here is to go through all unit's auras one by one
                        -- grab the info and compare it to what we have.
                        for x = 1, 40 do
                            local _n, _, _i, _c, _, _d, _e, _, _, _, _s = UnitAura(icon.unit, x, nil, filter)

                            -- if we have a proper aura and it is exactly the one
                            -- we are looking for, aka same id, we use it.
                            if (_n and _s) and (spellId == _s) then
                                _name, _icon, _count = _n, _i, _c
                                _duration, _expires = _d, _e
                                icon.duration = _d
                                icon.rname = _n
                                hasAura = true
                                break -- no need to go further
                            end
                        end
                    end
                elseif _name:lower() == spellName:lower() then
                    icon.duration = _duration
                    icon.rname = _name
                    hasAura = true
                end

                if hasAura then
                    if icon.texture:GetTexture() ~= _icon then
                        icon.texture:SetTexture(_icon)
                        KTrackerDB.groups[icon.coords[1]].icons[icon.coords[2]].filepath = _icon
                    end

                    icon:SetAlpha(icon.alphap)
                    icon.texture:SetVertexColor(1, 1, 1, 1)

                    if _count > 1 then
                        icon.stacks:SetText(_count)
                        icon.stacks:Show()
                    else
                        icon.stacks:Hide()
                    end

                    if icon.timer and not UnitIsDead(icon.unit) then
                        CooldownFrame_SetTimer(icon.cooldown, _expires - _duration, _duration, 1)
                    end
                end
            end
        end

        if not hasAura then
            icon:SetAlpha(icon.alphan)

            if icon.alphap == 1 and icon.alphan == 1 then
                icon.texture:SetVertexColor(1, 0.35, 0.35, 1)
            end

            icon.stacks:Hide()

            if icon.timer then
                CooldownFrame_SetTimer(icon.cooldown, 0, 0, 0)
            end

            icon.duration = 0
            icon.rname = auras[1]
        end
    
    -- weapon enchants
    elseif icon.type == "wpnenchant" then
        local now = GetTime()
        local duration = 0
        local hasMHEnchant, mhExpiration, mhCharges, hasOHEnchant, ohExpiration, ohCharges = GetWeaponEnchantInfo()

        if icon.subtype == "mainhand" and hasMHEnchant then
            icon:SetAlpha(icon.alphap)

            if mhCharges > 0 then
                icon.stacks:SetText(mhCharges)
                icon.stacks:Show()
            else
                icon.stacks:SetText("")
                icon.stacks:Hide()
            end

            duration = mhExpiration / 1000
        elseif icon.subtype == "offhand" and hasOHEnchant then
            icon:SetAlpha(icon.alphap)

            if ohCharges > 0 then
                icon.stacks:SetText(ohCharges)
                icon.stacks:Show()
            else
                icon.stacks:SetText("")
                icon.stacks:Hide()
            end

            duration = ohExpiration / 1000
        else
            icon:SetAlpha(icon.alphan)
        end

        if icon.timer and duration > 0 then
            icon.texture:SetVertexColor(1, 1, 1, 1)
            CooldownFrame_SetTimer(icon.cooldown, now, duration, 1)
        elseif icon.timer then
            icon.texture:SetVertexColor(1, 0.35, 0.35, 1)
            CooldownFrame_SetTimer(icon.cooldown, 0, 0, 0)
        end

        icon.duration = duration
    
    -- totems
    elseif icon.type == "totem" then
        local totems = addon:GetSpellNames(icon.name)
        local found, texture, rname
        local startTime, duration = 0, 0
        local precise = GetTime()

        for i = 1, 4 do
            local haveTotem, totemName, totemStartTime, totemDuration, totemTexture = GetTotemInfo(i)
            for i, name in ipairs(totems) do
                local spellName = select(1, GetSpellInfo(name))
                if totemName and totemName:find(name) then
                    found, texture, rname = true, totemTexture, name

                    startTime = ((precise - totemStartTime) > 1) and totemStartTime + 1 or precise
                    duration = totemDuration

                    found = true
                    break
                end
            end
        end

        icon.rname = rname
        icon.duration = duration

        if found then
            icon:SetAlpha(icon.alphap)
            icon.texture:SetVertexColor(1, 1, 1, 1)

            if icon.timer then
                CooldownFrame_SetTimer(icon.cooldown, startTime, duration, 1)
            end
        else
            icon:SetAlpha(icon.alphan)
            if icon.alphan == 1 and icon.alphap == 1 then
                icon.texture:SetVertexColor(1, 0.35, 0.35, 1)
            end
            CooldownFrame_SetTimer(icon.cooldown, 0, 0, 0)
        end
    
    -- if none of the above.
    else
        icon:SetAlpha(icon.alphan)

        -- stop the cooldown.
        if icon.timer then
            CooldownFrame_SetTimer(icon.cooldown, 0, 0, 0)
        end

        if icon.alphap == 1 and icon.alphan == 1 then
            icon.texture:SetVertexColor(1, 0.35, 0.35, 1)
        end
    end
end

do
    -- list of aura events
    local auraEvents = {
        SPELL_AURA_APPLIED = true,
        SPELL_AURA_APPLIED_DOSE = true,
        SPELL_AURA_BROKEN = true,
        SPELL_AURA_BROKEN_SPELL = true,
        SPELL_AURA_REFRESH = true,
        SPELL_AURA_REMOVED = true,
        SPELL_AURA_REMOVED_DOSE = true,
        SPELL_ENERGIZE = true -- for talents internal cooldowns
    }

    -- list of other events to check
    local otherEvents = {
        ACTIONBAR_UPDATE_COOLDOWN = true,
        ACTIONBAR_UPDATE_USABLE = true,
        PLAYER_REGEN_DISABLED = true,
        PLAYER_REGEN_ENABLED = true,
        PLAYER_TOTEM_UPDATE = true
    }

    --
    -- handles icons OnEvent event
    --
    local function Icon_OnEvent(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local e = select(2, ...)
            if auraEvents[e] then
                local destGUID = select(6, ...)
                if destGUID == UnitGUID(self.unit) then
                    local id, name = select(9, ...)
                    if self.name:find(id) or self.name:find(name) then
                        -- add spell id if found - hotfix
                        if e == "SPELL_ENERGIZE" and LiCD and LiCD.talents[id] then
                            self.startTime, self.duration = GetTime(), LiCD.cooldowns[id]
                        end
                        Icon:Check(self)
                    end
                end
            end
        elseif otherEvents[event] then
            Icon:Check(self)
        elseif event == "UNIT_AURA" then
            local unit = select(1, ...)
            if UnitExists(unit) then
                Icon:Check(self)
            else
                local name = select(1, UnitName(unit))
                if name:lower() == self.unit:lower() then
                    Icon:Check(self)
                end
            end
        elseif event == "BAG_UPDATE_COOLDOWN" then
            Icon:Check(self)
        elseif event == "UNIT_INVENTORY_CHANGED" and select(1, ...) == "player" then
            Icon:Check(self)
        elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
            Icon:Check(self)
        elseif event == "UNIT_TARGET" and select(1, ...) == "target" then
            Icon:Check(self)
        end
    end

    --
    -- handles icons OnUpdate event
    --
    local function Icon_OnUpdate(self, elapsed)
        if utils.update(self, self:GetName(), 0.1, elapsed) then
            if self.rname and self.type == "cooldown" then
                -- buffs and debuffs
                -- item cooldown
                if self.subtype == "item" then
                    -- spell cooldown
                    local _, duration, _ = GetItemCooldown(self.rname)
                    local onGCD = addon:GetGCD()

                    if duration then
                        if duration == 0 or onGCD == duration then
                            self:SetAlpha(self.alphap)
                            Icon_EffectTrigger(self)
                        elseif duration > 0 and onGCD ~= duration then
                            self:SetAlpha(self.alphan)
                            Icon_EffectReset(self)
                        end
                    end
                elseif self.subtype == "spell" then
                    -- talent cooldown
                    local startTime, duration, _ = GetSpellCooldown(self.rname)
                    local onGCD = (addon:GetGCD() == duration and duration > 0)
                    local usable, noMana = IsUsableSpell(self.rname)
                    local inRange = IsSpellInRange(self.rname, self.unit)
                    local _, _, _, _, _, _, _, minRange, maxRange = GetSpellInfo(self.rname)
                    if not maxRange or inRange == nil then
                        inRange = 1
                    end

                    if duration then
                        if (duration == 0 or onGCD) and inRange == 1 and not noMana then
                            self.texture:SetVertexColor(1, 1, 1, 1)
                            self:SetAlpha(self.alphap)
                            Icon_EffectTrigger(self)
                        elseif (duration == 0 or onGCD) and self.alphap == 1 then
                            self.texture:SetVertexColor(0.35, 0.35, 0.35, 1)
                            self:SetAlpha(self.alphap)
                        else
                            self.texture:SetVertexColor(1, 1, 1, 1)
                            self:SetAlpha(self.alphan)
                            Icon_EffectReset(self)
                        end
                    else
                        self:SetAlpha(self.alphan)
                    end
                elseif self.subtype == "talent" and LiCD.talentsRev[self.rname] then
                    local startTime = self.startTime or 0
                    local duration = (startTime == 0) and 0 or LiCD.cooldowns[LiCD.talentsRev[self.rname]]

                    -- should we reset the cooldown? we reset the timer.
                    -- because the cooldown duration depends on the its start time
                    -- all we have to do is to set the latter to 0.
                    if (duration > 0) and (GetTime() - startTime >= duration) then
                        -- is the spell on cooldown?
                        self.startTime = 0
                    elseif duration > 0 then
                        self:SetAlpha(self.alphan)
                    else
                        self:SetAlpha(self.alphap)
                    end
                end
            elseif self.rname and self.type == "aura" and UnitExists(self.unit) then
                -- reactive spell
                local animate

                if self.subtype == "HARMFUL" then
                    local reaction = UnitReaction("player", self.unit)
                    if reaction and reaction <= 4 then
                        animate = (self.when >= 0 and self.duration == 0)
                    else
                        animate = (self.when >= 0 and self.duration > 0)
                    end
                elseif self.subtype == "HELPFUL" then
                    animate = (self.duration <= 60)
                end

                if animate then
                    addon:TriggerEffect(self.cooldown, self.effect)
                end
            elseif self.rname and self.type == "reactive" then
                -- weapon enchants and totems
                -- item cooldown
                local startTime, duration, _ = GetSpellCooldown(self.rname)
                local usable, noMana = IsUsableSpell(self.rname)
                local inRange = IsSpellInRange(self.rname, self.unit)
                local _, _, _, _, _, _, _, minRange, maxRange = GetSpellInfo(self.rname)
                if not maxRange or inRange == nil then
                    inRange = 1
                end

                if usable then
                    if inRange and not noMana then
                        self.texture:SetVertexColor(1, 1, 1, 1)
                        self:SetAlpha(self.alphap)
                        Icon_EffectTrigger(self)
                    elseif not inRange or noMana then
                        self.texture:SetVertexColor(0.35, 0.35, 0.35, 1)
                        self:SetAlpha(self.alphap)
                    else
                        self.texture:SetVertexColor(1, 1, 1, 1)
                        self:SetAlpha(self.alphan)
                        Icon_EffectReset(self)
                    end
                else
                    self:SetAlpha(self.alphan)
                end
            elseif self.type == "wpnenchant" or (self.rname and self.type == "totem") then
                local animate = (self.when <= 0 and self.duration == 0)

                if animate then
                    addon:TriggerEffect(self.cooldown, self.effect)
                end
            end
        end
    end

    --
    -- sets icon scripts and events
    --
    function Icon:SetScripts(icon)
        if not icon then
            return
        end
        icon:SetScript("OnEvent", Icon_OnEvent)
        icon:SetScript("OnUpdate", Icon_OnUpdate)

        if icon.type == "totem" then
            icon:RegisterEvent("PLAYER_TOTEM_UPDATE")
        elseif icon.type == "wpnenchant" then
            icon.cooldown:SetReverse(true)
            icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
        elseif icon.type == "aura" then
            icon.cooldown:SetReverse(true)
            icon:RegisterEvent("UNIT_AURA")
            if icon.unit == "target" then
                icon:RegisterEvent("PLAYER_TARGET_CHANGED")
            elseif icon.unit == "focus" then
                icon:RegisterEvent("PLAYER_FOCUS_CHANGED")
            elseif icon.unit == "targettarget" then
                icon:RegisterEvent("PLAYER_TARGET_CHANGED")
                icon:RegisterEvent("UNIT_TARGET")
                icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            end
        elseif icon.type == "cooldown" or icon.type == "reactive" then
            icon.cooldown:SetReverse(false)
            if icon.subtype == "spell" or icon.subtype == "talent" then
                icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- hotfix
                icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
                icon:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
            elseif icon.subtype == "item" then
                icon:RegisterEvent("BAG_UPDATE_COOLDOWN")
            end
        end
    end
end

--------------------------------------------------------------------------
-- Talents functions

do
    -- holds the character's spec
    local spec

    --
    -- caches the character's spec
    --
    function addon:SetCurrentSpec()
        spec = GetActiveTalentGroup()
    end

    --
    -- returns the character's current spec
    --
    function addon:GetCurrentSpec()
        if not spec then
            self:SetCurrentSpec()
        end
        return spec
    end
end

--------------------------------------------------------------------------
-- Spells functions

do
    --
    -- list of terms that can be used by the user to the track
    -- multiple buffs or debuffs
    --
    local equivalents = {
        Bleeding = "Pounce Bleed;Rake;Rip;Lacerate;Rupture;Garrote;Savage Rend;Rend;Deep Wound",
        DontMelee = "Berserk;Evasion;Shield Wall;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish",
        FaerieFires = "Faerie Fire;Faerie Fire (Feral)",
        ImmuneToMagicCC = "Divine Shield;Ice Block;The Beast Within;Beastial Wrath;Cyclone;Banish",
        ImmuneToStun = "Divine Shield;Ice Block;The Beast Within;Beastial Wrath;Icebound Fortitude;Hand of Protection;Cyclone;Banish",
        Incapacitated = "Gouge;Maim;Repentance;Reckless Charge;Hungering Cold",
        MeleeSlowed = "Rocket Burst;Infected Wounds;Judgements of the Just;Earth Shock;Thunder Clap;Icy Touch",
        MovementSlowed = "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Frost Trap Aura;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion",
        Stunned = "Reckless Charge;Bash;Maim;Pounce;Starfire Stun;Intimidation;Impact;Hammer of Justice;Stun;Blackout;Kidney Shot;Cheap Shot;Shadowfury;Intercept;Charge Stun;Concussion Blow;War Stomp",
        StunnedOrIncapacitated = "Gouge;Maim;Repentance;Reckless Charge;Hungering Cold;Bash;Pounce;Starfire Stun;Intimidation;Impact;Hammer of Justice;Stun;Blackout;Kidney Shot;Cheap Shot;Shadowfury;Intercept;Charge Stun;Concussion Blow;War Stomp",
        VulnerableToBleed = "Mangle (Cat);Mangle (Bear);Trauma",
        WoTLKDebuffs = "71204;71237;71289;72293;72410;72219;72551;72552;72553;69279;69674;72272;72273;73020;70447;70672;70911;74118;74119;72999;71822;70867;70923;71267;71340;70873;70106;69762;69766;70128;70126;70337;69409;73797;73798;74453;74367;74562;74792"
    }

    --
    -- splits the names of spells if separated using semicolons.
    --
    local function SplitNames(str, item, strict)
        local list = {}

        if strict == nil then
            strict = false
        end

        if (str:find(";") ~= nil) then
            list = {strsplit(";", str)}
        else
            list = {str}
        end

        if not strict then
            local i, name
            for i, name in ipairs(list) do
                if tonumber(name) ~= nil then
                    list[i] = (item == "item") and GetItemInfo(name) or GetSpellInfo(name)
                end
            end
        end
        return list
    end

    --
    -- returns a single or a list of spells names
    --
    function addon:GetSpellNames(str, first, strict)
        local list = SplitNames(equivalents[str] or str, nil, strict)

        if first then
            return list[1]
        end

        return list
    end

    --
    -- returns a single or a list of item names
    --
    function addon:GetItemNames(str, first, strict)
        local list = SplitNames(str, "item", strict)
        return first and list[1] or list
    end

    --
    -- returns the global cooldown if the player using an instant cast spell
    --
    function addon:GetGCD()
        local ver = select(4, GetBuildInfo())
        local spells

        if ver >= 30000 then
            spells = {
                ROGUE = GetSpellInfo(1752), -- sinister strike
                PRIEST = GetSpellInfo(139), -- renew
                DRUID = GetSpellInfo(774), -- rejuvenation
                WARRIOR = GetSpellInfo(6673), -- battle shout
                MAGE = GetSpellInfo(168), -- frost armor
                WARLOCK = GetSpellInfo(1454), -- life tap
                PALADIN = GetSpellInfo(1152), -- purify
                SHAMAN = GetSpellInfo(324), -- lightning shield
                HUNTER = GetSpellInfo(1978), -- serpent sting
                DEATHKNIGHT = GetSpellInfo(45462) -- plague strike
            }
        else
            spells = {
                ROGUE = GetSpellInfo(1752), -- sinister strike
                PRIEST = GetSpellInfo(139), -- renew
                DRUID = GetSpellInfo(774), -- rejuvenation
                WARRIOR = GetSpellInfo(6673), -- battle shout
                MAGE = GetSpellInfo(168), -- frost armor
                WARLOCK = GetSpellInfo(1454), -- life tap
                PALADIN = GetSpellInfo(1152), -- purify
                SHAMAN = GetSpellInfo(324), -- lightning shield
                HUNTER = GetSpellInfo(1978) -- serpent sting
            }
        end
        local _, unitClass = UnitClass("player")
        return select(2, GetSpellCooldown(self:GetSpellNames(spells[unitClass], true)))
    end
end

--------------------------------------------------------------------------
-- Animations functions

do
    --
    -- holds the list of already animated spell icons
    --
    local animated = {}

    --
    -- used to trigger icons animation
    --
    function Icon_EffectTrigger(icon)
        if icon and not animated[icon:GetName()] then
            addon:TriggerEffect(icon.cooldown, icon.effect)
            animated[icon:GetName()] = true
        end
    end

    --
    -- resets the icon's animation
    --
    function Icon_EffectReset(icon)
        if icon and animated[icon:GetName()] then
            animated[icon:GetName()] = nil
        end
    end
    --
    -- register a new animation effect
    -- TODO: work more on it.
    --
    function addon:RegisterEffect(effect)
        if not self:GetEffect(effect.id) then
            self.effects = self.effects or {}
            tinsert(self.effects, effect)
        end
    end

    --
    -- retrieves an previously registered effect
    --
    function addon:GetEffect(id)
        if self.effects then
            for _, effect in ipairs(self.effects) do
                if effect.id == id then
                    return effect
                end
            end
        end
    end

    --
    -- triggers an animation effect
    --
    function addon:TriggerEffect(cooldown, id)
        local effect = self:GetEffect(id)
        if effect then
            effect:Run(cooldown)
        end
    end

    -- --------------- glow effect --------------- --

    do
        --
        -- we create the glow table first
        --
        local Glow = utils.newClass("Frame")

        function Glow:New(parent)
            local f = self:Bind(CreateFrame("Frame", nil, parent))
            f:SetAllPoints(parent)
            f:SetToplevel(true)
            f:Hide()

            f.animation = f:CreateGlowAnimation()
            f:SetScript("OnHide", f.OnHide)

            local icon = f:CreateTexture(nil, "OVERLAY")
            icon:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Stealable]])
            icon:SetPoint("TOPLEFT", -7, 7)
            icon:SetPoint("BOTTOMRIGHT", 6, -6)
            icon:SetBlendMode("ADD")

            return f
        end

        do
            local function animation_OnFinished(self)
                local parent = self:GetParent()
                if parent:IsShown() then
                    parent:Hide()
                end
            end

            function Glow:CreateGlowAnimation()
                local g = self:CreateAnimationGroup()
                g:SetLooping("REPEAT")
                g:SetScript("OnFinished", animation_OnFinished)

                local a1 = g:CreateAnimation("Alpha")
                a1:SetChange(-1)
                a1:SetDuration(.2)
                a1:SetOrder(1)

                local a2 = g:CreateAnimation("Alpha")
                a2:SetChange(1)
                a2:SetDuration(.2)
                a2:SetOrder(2)

                return g
            end
        end

        function Glow:OnHide()
            self.animation:Finish()
            self:Hide()
        end

        function Glow:Start(texture)
            if not self.animation:IsPlaying() then
                self:Show()
                self.animation:Play()
            end
        end

        -- register the effect
        do
            local glows =
                setmetatable(
                {},
                {
                    __index = function(t, k)
                        local f = Glow:New(k)
                        t[k] = f
                        return f
                    end
                }
            )

            addon:RegisterEffect {
                id = "glow",
                name = L["Glow"],
                Run = function(self, cooldown)
                    local p = cooldown:GetParent()
                    if p then
                        glows[p]:Start()
                    end
                end
            }
        end
    end

    -- --------------- pulse effect --------------- --

    do
        --
        -- we create the pulse table first
        --
        local Pulse = utils.newClass("Frame")

        function Pulse:New(parent)
            local f = self:Bind(CreateFrame("Frame", nil, parent))
            f:SetAllPoints(parent)
            f:SetToplevel(true)
            f:Hide()

            f.animation = f:CreatePulseAnimation()
            f:SetScript("OnHide", f.OnHide)

            local icon = f:CreateTexture(nil, "OVERLAY")
            icon:SetPoint("CENTER")
            icon:SetBlendMode("ADD")
            icon:SetAllPoints(f)
            f.icon = icon

            return f
        end

        do
            --
            -- trigger by the end of the animation
            --
            local function animation_OnFinished(self)
                local parent = self:GetParent()
                utils.hide(parent)
            end

            --
            -- creates the pulse animation
            --
            function Pulse:CreatePulseAnimation()
                local g = self:CreateAnimationGroup()
                g:SetLooping("NONE")
                g:SetScript("OnFinished", animation_OnFinished)

                local grow = g:CreateAnimation("scale")
                grow:SetScale(1.5, 1.5)
                grow:SetOrigin("CENTER", 0, 0)
                grow:SetDuration(0.2)
                grow:SetOrder(1)

                local shrink = g:CreateAnimation("scale")
                shrink:SetScale(-1.5, -1.5)
                shrink:SetOrigin("CENTER", 0, 0)
                shrink:SetDuration(0.2)
                shrink:SetOrder(2)

                return g
            end
        end

        --
        -- handles animation hide
        --
        function Pulse:OnHide()
            self.animation:Finish()
            self:Hide()
        end

        --
        -- starts the animation
        --
        function Pulse:Start(texture)
            if not self.animation:IsPlaying() then
                local icon = self.icon
                local r, g, b = icon:GetVertexColor()
                icon:SetVertexColor(r, g, b, 0.7)
                icon:SetTexture(texture:GetTexture())
                -- fix the texture coordinates for a better look.
                if not LBF then
                    icon:SetTexCoord(0.089, 0.9, 0.09, 0.9)
                end
                self:Show()
                self.animation:Play()
            end
        end

        --
        -- we now register the pulse effect
        --
        do
            local pulses =
                setmetatable(
                {},
                {
                    __index = function(t, k)
                        local f = Pulse:New(k)
                        t[k] = f
                        return f
                    end
                }
            )

            local function getTexture(frame)
                if not frame then
                    return
                end

                local icon = frame.icon or frame.texture
                if not icon then
                    local name = frame:GetName()
                    icon = _G[name .. "Icon"] or _G[name .. "Texture"]
                end

                if icon and (icon.GetNormalTexture or icon.GetTexture) then
                    return icon
                end
            end

            -- finish
            addon:RegisterEffect {
                id = "pulse",
                name = L["Pulse"],
                Run = function(self, cooldown)
                    local p = cooldown:GetParent()
                    local texture = getTexture(p)
                    if texture then
                        pulses[p]:Start(texture)
                    end
                end
            }
        end
    end

    -- --------------- shine effect --------------- --

    do
        --
        -- we create the shine table first
        --
        local Shine = utils.newClass("Frame")

        function Shine:New(parent)
            local f = self:Bind(CreateFrame("Frame", nil, parent))
            f:SetAllPoints(parent)
            f:SetToplevel(true)
            f:Hide()

            f.animation = f:CreateShineAnimation()
            f:SetScript("OnHide", f.OnHide)

            local icon = f:CreateTexture(nil, "OVERLAY")
            icon:SetPoint("CENTER")
            icon:SetBlendMode("ADD")
            icon:SetAllPoints(f)
            icon:SetTexture("Interface\\Cooldown\\star4")

            return f
        end

        do
            local function animation_OnFinished(self)
                local parent = self:GetParent()
                if parent:IsShown() then
                    parent:Hide()
                end
            end

            function Shine:CreateShineAnimation()
                local g = self:CreateAnimationGroup()
                g:SetLooping("NONE")
                g:SetScript("OnFinished", animation_OnFinished)

                local startAlpha = g:CreateAnimation("Alpha")
                startAlpha:SetChange(-1)
                startAlpha:SetDuration(0)
                startAlpha:SetOrder(0)

                local grow = g:CreateAnimation("Scale")
                grow:SetOrigin("CENTER", 0, 0)
                grow:SetScale(2, 2)
                grow:SetDuration(0.2)
                grow:SetOrder(1)

                local brighten = g:CreateAnimation("Alpha")
                brighten:SetChange(1)
                brighten:SetDuration(0.2)
                brighten:SetOrder(1)

                local shrink = g:CreateAnimation("Scale")
                shrink:SetOrigin("CENTER", 0, 0)
                shrink:SetScale(-2, -2)
                shrink:SetDuration(0.2)
                shrink:SetOrder(2)

                local fade = g:CreateAnimation("Alpha")
                fade:SetChange(-1)
                fade:SetDuration(0.2)
                fade:SetOrder(2)

                return g
            end
        end

        function Shine:OnHide()
            self.animation:Finish()
            self:Hide()
        end

        function Shine:Start(texture)
            if not self.animation:IsPlaying() then
                self:Show()
                self.animation:Play()
            end
        end

        -- register the effect
        do
            local shines =
                setmetatable(
                {},
                {
                    __index = function(t, k)
                        local f = Shine:New(k)
                        t[k] = f
                        return f
                    end
                }
            )

            addon:RegisterEffect {
                id = "shine",
                name = L["Shine"],
                Run = function(self, cooldown)
                    local p = cooldown:GetParent()
                    if p then
                        shines[p]:Start()
                    end
                end
            }
        end
    end
end

--------------------------------------------------------------------------
-- Cooldown count functions

do
    local Cooldown_SetTimer, Cooldown_OnUpdate

    do
        -- table of cooldown font options
        local fontOptions = {
            face = _G.STANDARD_TEXT_FONT,
            size = 18,
            scales = {1.3, 1.2, .8, .6}
        }

        -- list of counters and their frames
        local counters, counterFrames = {}, {}
        local ceil, floor = _G.math.ceil, _G.math.floor

        --
        -- used to return the final text to display as well
        -- as the color used for it.
        --
        local function Cooldown_GetTimeFormat(timeleft)
            local str1, str2
            local color = {1, 1, 1, 1}

            if timeleft >= 86400 then
                str1 = format("%d", ceil(timeleft / 86400))
                str2 = str1 .. ((strlen(str1) > 2 and "\n") or "") .. "d"
                color = {0.7, 0.7, 0.7, 1}
            elseif timeleft >= 3600 then
                str1 = format("%d", ceil(timeleft / 3600))
                str2 = str1 .. ((strlen(str1) > 2 and "\n") or "") .. "h"
                color = {0.7, 0.7, 0.7, 1}
            elseif timeleft >= 60 then
                str1 = format("%d", ceil(timeleft / 60))
                str2 = str1 .. ((strlen(str1) > 2 and "\n") or "") .. "m"
                color = {1, 1, 1, 1}
            else
                local s = ceil(timeleft)
                str1 = format("%d", s)
                str2 = str1
                color = {1, 1, 0, 1}

                if s <= 5.5 then
                    color = {1, 0, 0, 1}
                end
            end
            return str2, strlen(str1), color
        end

        --
        -- used to draw the final cooldown frame
        --
        local function Cooldown_DrawCooldown(frame)
            local text, len, color = frame.text, frame.length, frame.color
            if len > 4 then
                len = 4
            end
            frame:SetScale(fontOptions.scales[len] * (frame.cooldown:GetParent():GetWidth() / ActionButton1:GetWidth()))
            local counterText = _G[frame:GetName() .. "Text"]
            utils.setText(counterText, frame.text)
            counterText:SetTextColor(unpack(frame.color))
        end

        --
        -- handle font visual formatting
        --
        local function Cooldown_UpdateFont(fname)
            local frame, text = _G[fname], _G[fname .. "Text"]
            text:SetShadowOffset(1, -1)
            text:SetFont(fontOptions.face, fontOptions.size, "OUTLINE")

            -- dram the the cooldown if visible and it has a time left
            if frame:IsVisible() and frame.timeleft then
                frame.text, frame.length, frame.color = Cooldown_GetTimeFormat(frame.timeleft)
                Cooldown_DrawCooldown(frame)
            end
        end

        --
        -- this function is hooked to all actions bars including
        -- all icons created by our addon.
        --
        function Cooldown_SetTimer(self, start, duration, enable)
            if self.mark == 0 then
                return
            end

            local name = self:GetName()

            if not self.mark then
                if not name then
                    self.mark = 0
                    return
                end

                self.mark =
                    (((self:GetParent():GetWidth() >= 28 or self:GetParent():GetParent():GetName() == "WatchFrameLines") and
                    1) or
                    0)
            end

            if self.mark == 1 then
                local fname = "KTrackerCooldown" .. name .. "Timer"

                if start > 0 and duration > 1.5 and enable > 0 then
                    if not _G[fname] then
                        local special = (ButtonFacade or Bartender4)

                        local frame =
                            CreateFrame("Frame", fname, ((not special) and self) or nil, "KTrackerCooldownTemplate")
                        frame:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0)

                        if special then
                            frame:SetFrameStrata(self:GetParent():GetFrameStrata())
                        end

                        frame:SetFrameLevel(self:GetFrameLevel() + 5)
                        frame:SetToplevel(true)
                        frame.cooldown = self
                        self.counter = frame

                        self:HookScript(
                            "OnShow",
                            function(self)
                                self.counter:Show()
                            end
                        )
                        self:HookScript(
                            "OnHide",
                            function(self)
                                self.counter:Hide()
                            end
                        )

                        tinsert(counterFrames, fname)
                        Cooldown_UpdateFont(fname)
                        frame:Show()
                    end

                    -- cache the counter
                    counters[name] = {
                        start = start,
                        duration = duration - 1,
                        enable = enable
                    }
                else
                    utils.setText(_G[fname .. "Text"], "")
                    counters[name] = nil
                end
            end
        end

        --
        -- attached to addon's main frame in order to handle
        -- spells and icons cooldown timers.
        --
        function Cooldown_OnUpdate(self, elapsed)
            if utils.update(self, "KTracker_EventFrame", 0.1, elapsed) then
                local currentTime = GetTime()
                for k, v in pairs(counters) do
                    local timeleft = v.start + v.duration - currentTime

                    local fname = "KTrackerCooldown" .. k .. "Timer"
                    local counter = _G[fname]
                    local counterText = _G[fname .. "Text"]
                    counter.timeleft = timeleft

                    if timeleft > 0 and v.enable > 0 then
                        if _G[k]:IsVisible() then
                            counter.text, counter.length, counter.color = Cooldown_GetTimeFormat(timeleft)

                            if counter.text ~= counterText:GetText() then
                                Cooldown_DrawCooldown(counter)
                            end
                        else
                            utils.setText(counterText, "")
                        end
                    else
                        counters[k] = nil
                        utils.setText(counterText, "")
                    end
                end
            end
        end
    end

    do
        -- a flag so we don't hook twice
        local hooked = false

        --
        -- called to check if the player is already using a cooldown
        -- count addon or not. If he is not/she is not, we set our own
        --
        function addon:Initialize(all)
            if not hooked then
                hooked = true
                -- implement our cooldown count:
                if not hasOmniCC then
                    hooksecurefunc("CooldownFrame_SetTimer", Cooldown_SetTimer)
                    mainFrame:SetScript("OnUpdate", Cooldown_OnUpdate)
                end
            end
            if not all then
                self:Load()
            end
        end
    end
end

--------------------------------------------------------------------------
-- minimap button

do
    local menu, dragMode
    local abs, sqrt = _G.math.abs, _G.math.sqrt

    --
    -- handles the minimap button moving
    --
    local function MoveButton(self)
        local centerX, centerY = Minimap:GetCenter()
        local x, y = GetCursorPosition()
        x, y = x / self:GetEffectiveScale() - centerX, y / self:GetEffectiveScale() - centerY

        if dragMode == "free" then
            self:ClearAllPoints()
            self:SetPoint("CENTER", x, y)
        else
            centerX, centerY = abs(x), abs(y)
            centerX, centerY =
                (centerX / sqrt(centerX ^ 2 + centerY ^ 2)) * 80,
                (centerY / sqrt(centerX ^ 2 + centerY ^ 2)) * 80
            centerX = x < 0 and -centerX or centerX
            centerY = y < 0 and -centerY or centerY
            self:ClearAllPoints()
            self:SetPoint("CENTER", centerX, centerY)
        end
    end

    --
    -- button OnMouseDown
    --
    local function Minimap_OnMouseDown(self, button)
        if IsAltKeyDown() then
            dragMode = "free"
            self:SetScript("OnUpdate", MoveButton)
        elseif IsShiftKeyDown() then
            dragMode = nil
            self:SetScript("OnUpdate", MoveButton)
        end
    end

    --
    -- button OnMouseUp
    --
    local function Minimap_OnMouseUp(self, button)
        self:SetScript("OnUpdate", nil)
    end

    --
    -- button OnClick
    --
    local function Minimap_OnClick(self, button)
        if IsShiftKeyDown() or IsAltKeyDown() then
            return
        elseif button == "RightButton" then
            addon:Config()
        elseif button == "LeftButton" then
            addon:Toggle()
        end
    end

    --
    -- called OnLoad the minimap button
    --
    function addon:OnLoadMinimap(btn)
        if not btn then
            return
        end
        minimapButton = btn
        minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        minimapButton:SetUserPlaced(true)
        minimapButton:SetScript("OnMouseDown", Minimap_OnMouseDown)
        minimapButton:SetScript("OnMouseUp", Minimap_OnMouseUp)
        minimapButton:SetScript("OnClick", Minimap_OnClick)
        utils.setTooltip(
            minimapButton,
            {
                L["|cffffd700Left-Click|r to lock/unlock."],
                L["|cffffd700Right-Click|r to access settings."],
                L["|cffffd700Shift+Click|r to move."],
                L["|cffffd700Alt+Click|r for free drag and drop."]
            },
            nil,
            titleString
        )
    end

    --
    -- toggles Minimap button visibility
    --
    function addon:ToggleMinimapButton()
        KTrackerCharDB.minimap = not KTrackerCharDB.minimap
        self.minimap = KTrackerCharDB.minimap
        utils.showHide(minimapButton, self.minimap)
    end

    --
    -- hide the minimap button
    --
    function addon:HideMinimapButton()
        utils.hide(minimapButton)
    end
end

--------------------------------------------------------------------------
-- Config Frame

do
    --
    -- config table, ui frame and frame name
    --
    local Config = {}
    local UIFrame, frameName

    --
    -- required locals
    --
    local LocalizeUIFrame, localized
    local updateInterval, UpdateUIFrame = 0.05
    local FetchGroups, SaveGroup, fetched
    local FillFields, ResetFields

    --
    -- objects used to hold Temporary data or default data
    --
    local tempObj, defObj = {},
        {
            id = "",
            enabled = true,
            name = "",
            spec = 0,
            columns = 4,
            rows = 1,
            hspacing = 0,
            vspacing = 0,
            combat = false,
            created = 0
        }

    --
    -- useful flags to update the frame
    --
    local isEdit, currentId, validId

    --
    -- frame input fields
    --
    local newID, newName, newSpec, newCols, newRows
    local newHSpacing, newHSpacingBox
    local newVSpacing, newVSpacingBox
    local newEnabled, newCombat

    --
    -- frame buttons
    --
    local btnSave, btnCancel
    local btnReset, btnLock, btnSync, btnMinimap
    local btnColumnsLeft, btnColumnsRight
    local btnRowsLeft, btnRowsRight

    --
    -- used to fill frame fields when the user wants
    -- to modify an existing group of icons
    --
    do
        local function GroupsUnlockhighlight(except)
            for i, _ in ipairs(groups) do
                if except and except == i then
                    _G[frameName .. "GroupBtn" .. i]:LockHighlight()
                else
                    _G[frameName .. "GroupBtn" .. i]:UnlockHighlight()
                end
            end
        end

        function FillFields(obj)
            if obj then
                ResetFields()

                GroupsUnlockhighlight(newID:GetNumber())

                newName:SetText(obj.name)
                newCols:SetText(obj.columns)
                newRows:SetText(obj.rows)
                newHSpacing:SetValue(obj.hspacing or 0)
                newVSpacing:SetValue(obj.vspacing or 0)
                newEnabled:SetChecked(obj.enabled)
                newCombat:SetChecked(obj.combat)

                -- spec
                if obj.spec == 1 then
                    L_UIDropDownMenu_SetText(newSpec, L["Primary"])
                elseif obj.spec == 2 then
                    L_UIDropDownMenu_SetText(newSpec, L["Secondary"])
                else
                    L_UIDropDownMenu_SetText(newSpec, L["Both"])
                end
                isEdit = true
            end
        end

        --
        -- called after saving fields to reset them
        --
        function ResetFields()
            tempObj = utils.deepCopy(defObj)
            newName:SetText("")
            newName:ClearFocus()
            L_UIDropDownMenu_SetText(newSpec, L["Both"])
            newCols:SetText(tempObj.columns)
            newRows:SetText(tempObj.rows)
            newHSpacingBox:SetNumber(0)
            newVSpacingBox:SetNumber(0)
            newHSpacingBox:ClearFocus()
            newVSpacingBox:ClearFocus()
            newHSpacing:SetValue(tempObj.hspacing)
            newVSpacing:SetValue(tempObj.vspacing)
            newEnabled:SetChecked(tempObj.enabled)
            newCombat:SetChecked(tempObj.combat)
            GroupsUnlockhighlight()
        end
    end

    --
    -- handles the edit/save button actions
    --
    function SaveGroup()
        -- name is required though...
        if tempObj.name == "" then
            addon:PrintError(L["The group name is required"])
            return
        end

        -- we'll see if maxGroups should be changed or not
        if numGroups >= def.maxGroups then
            addon:PrintError(L["You have reached the maximum allowed groups number"])
            ResetFields()
            return
        end

        Group:Save(tempObj, tempObj.id)

        -- we reset fields, reload the addon then the list
        ResetFields()
        addon:Initialize()
        fetched, isEdit = false, false
        newID:SetNumber(0)
    end

    do
        --
        -- called whenever the groups list requires update
        --
        local function ResetList()
            local index = 1
            local btn = _G[frameName .. "GroupBtn" .. index]
            while btn ~= nil do
                btn:Hide()
                index = index + 1
                btn = _G[frameName .. "GroupBtn" .. index]
            end
        end

        do
            local Group_OpenMenu, menu
            local current = 0
            do
                local function Group_OptionToggle()
                    local DB = KTrackerDB.groups[current]
                    if DB then
                        local db = KTrackerCharDB.groups[DB.created]
                        if db then
                            db[this.value] = this.checked
                            addon:Initialize()
                            fetched, isEdit = false, false
                            return
                        end
                    end
                    L_CloseDropDownMenus()
                end

                local function Group_OptionChoose(self, arg1)
                    local DB = KTrackerDB.groups[current]
                    if DB then
                        local db = KTrackerCharDB.groups[DB.created]
                        local success = false
                        if db[this.value] ~= nil then
                            db[this.value] = arg1
                            if this.value == "position" then
                                db.scale = def.CharDBGroup.scale
                                local fname = format(holderGroup, current)
                                local f = _G[fname]
                                f:ClearAllPoints()
                                f:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
                            end
                            success = true
                        end

                        if success then
                            addon:Initialize()
                            fetched, isEdit = false, false
                            return
                        end
                    end
                    L_CloseDropDownMenus()
                end

                function Group_OpenMenu(self)
                    local id = self:GetID()
                    local DB = KTrackerDB.groups[id]
                    if not DB then
                        return
                    end
                    local db = KTrackerCharDB.groups[DB.created]
                    if not db then
                        return
                    end
                    current = id

                    if not menu then
                        menu = CreateFrame("Frame", "KTrackerGroupMenu")
                    end

                    menu.displayMode = "MENU"
                    menu.initialize = function(self, level)
                        local info = L_UIDropDownMenu_CreateInfo()
                        level = level or 1

                        if level == 2 then
                            if L_UIDROPDOWNMENU_MENU_VALUE == "spec" then
                                info.text = L["Both"]
                                info.checked = (db.spec == 0)
                                info.value = "spec"
                                info.arg1 = 0
                                info.func = Group_OptionChoose
                                L_UIDropDownMenu_AddButton(info, level)
                                wipe(info)

                                info.text = L["Primary"]
                                info.checked = (db.spec == 1)
                                info.value = "spec"
                                info.arg1 = 1
                                info.func = Group_OptionChoose
                                L_UIDropDownMenu_AddButton(info, level)
                                wipe(info)

                                info.text = L["Secondary"]
                                info.checked = (db.spec == 2)
                                info.value = "spec"
                                info.arg1 = 2
                                info.func = Group_OptionChoose
                                L_UIDropDownMenu_AddButton(info, level)
                                wipe(info)
                            elseif L_UIDROPDOWNMENU_MENU_VALUE == "reset" then
                                info.text = L["Icons"]
                                info.func = function()
                                    StaticPopup_Show("KTRACKER_DIALOG_CLEAR", DB.name, nil, id)
                                end
                                L_UIDropDownMenu_AddButton(info, level)
                                wipe(info)

                                info.text = L["Position"]
                                info.value = "position"
                                info.arg1 = {}
                                info.func = Group_OptionChoose
                                L_UIDropDownMenu_AddButton(info, level)
                                wipe(info)
                            end
                            return
                        end

                        info.text = DB.name
                        info.isTitle = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Edit"]
                        info.notCheckable = true
                        info.func = function()
                            local obj = utils.deepCopy(DB)
                            utils.mixTable(obj, db)
                            newID:SetNumber(id)
                            FillFields(obj)
                        end
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = DELETE
                        info.notCheckable = true
                        info.func = function()
                            StaticPopup_Show("KTRACKER_DIALOG_DELETE", DB.name, nil, id)
                        end
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Duplicate"]
                        info.notCheckable = true
                        info.func = function()
                            -- copy group and complete missing data
                            local group = utils.deepCopy(def.group)
                            utils.mixTable(group, DB)
                            utils.mixTable(group, db)

                            -- set few key things before proceeding
                            group.created = nil
                            group.icons = utils.deepCopy(DB.icons)
                            group.position = utils.deepCopy(db.position)
                            group.style = utils.deepCopy(db.style)

                            -- save and load the group if succeeded
                            local id = Group:Save(group)
                            if id then
                                Group:Load(id)
                                fetched, isEdit = false, false
                            end
                        end
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        if addon.sync then
                            info.text = L["Share"]
                            info.notCheckable = true
                            info.func = function()
                                StaticPopup_Show("KTRACKER_DIALOG_SHARE_SEND", nil, nil, id)
                            end
                            L_UIDropDownMenu_AddButton(info, level)
                            wipe(info)
                        end

                        info.disabled = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Group Status"]
                        info.isTitle = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Enabled"]
                        info.checked = db.enabled
                        info.value = "enabled"
                        info.func = Group_OptionToggle
                        info.keepShownOnClick = true
                        info.isNotRadio = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Combat"]
                        info.checked = db.combat
                        info.value = "combat"
                        info.func = Group_OptionToggle
                        info.keepShownOnClick = true
                        info.isNotRadio = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = L["Talents Spec"]
                        info.value = "spec"
                        info.hasArrow = true
                        info.notCheckable = true
                        info.keepShownOnClick = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.disabled = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)

                        info.text = RESET
                        info.value = "reset"
                        info.hasArrow = true
                        info.notCheckable = true
                        L_UIDropDownMenu_AddButton(info, level)
                        wipe(info)
                    end

                    L_ToggleDropDownMenu(1, nil, menu, "cursor", 0, 0)
                end
            end

            local function Group_OnClick(self, button)
                if button == "RightButton" then
                    Group_OpenMenu(self)
                elseif button == "MiddleButton" then
                    local id = self:GetID()
                    local DB = KTrackerDB.groups[id]
                    if not DB then
                        return
                    end
                    local db = KTrackerCharDB.groups[DB.created]
                    if db then
                        db.enabled = not db.enabled
                        addon:Initialize()
                        fetched, isEdit = false, false
                    end
                end
            end

            --
            -- fetches all groups and put then on the list
            --
            function FetchGroups()
                if not groups or fetched then
                    return
                end
                ResetList()

                _G[frameName .. "CountLabel"]:SetText(L:F("Groups: %d/%d", numGroups, def.maxGroups))

                local scrollFrame = _G[frameName .. "ScrollFrame"]
                local scrollChild = _G[frameName .. "ScrollFrameScrollChild"]
                scrollChild:SetHeight(scrollFrame:GetHeight())
                scrollChild:SetWidth(scrollFrame:GetWidth())

                local height = 0
                local num = #groups

                for i = num, 1, -1 do
                    local group = groups[i]
                    local btnName = frameName .. "GroupBtn" .. i
                    local btn =
                        _G[btnName] or CreateFrame("Button", btnName, scrollChild, "KTrackerGroupButtonTemplate")
                    btn:Show()
                    btn:SetID(i)
                    btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -height)
                    btn:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
                    height = height + btn:GetHeight()

                    -- Set data
                    _G[btnName .. "ID"]:SetText(i)
                    _G[btnName .. "Name"]:SetText(group.name)
                    _G[btnName .. "Size"]:SetText(group.columns .. "x" .. group.rows)

                    local spec = L["Both"]
                    if group.spec > 0 then
                        spec = (group.spec == 1) and L["Primary"] or L["Secondary"]
                    end
                    _G[btnName .. "Spec"]:SetText(spec)

                    utils.setTextIf(_G[btnName .. "Combat"], YES, NO, group.combat)
                    utils.setTextIf(_G[btnName .. "Enabled"], YES, NO, group.enabled)

                    btn:SetScript("OnClick", Group_OnClick)
                end

                fetched = true
            end
        end
    end

    do
        --
        -- simple dummy function that sets text of the spec menu
        --
        local function ChooseSpec()
            local specs = {L["Both"], L["Primary"], L["Secondary"]}
            L_UIDropDownMenu_SetText(newSpec, specs[this.value + 1])
        end

        --
        -- initializes the spec dropdown menu
        --
        local function InitializeSpecDropdown(self, level)
            L_UIDropDownMenu_JustifyText(self, "LEFT")
            if level == 1 then
                local info = L_UIDropDownMenu_CreateInfo()

                -- both specs
                info.text = L["Both"]
                info.value = 0
                info.func = ChooseSpec
                info.notCheckable = true
                L_UIDropDownMenu_AddButton(info)
                wipe(info)

                -- primary
                info.text = L["Primary"]
                info.value = 1
                info.func = ChooseSpec
                info.notCheckable = true
                L_UIDropDownMenu_AddButton(info)
                wipe(info)

                -- Secondary
                info.text = L["Secondary"]
                info.value = 2
                info.func = ChooseSpec
                info.notCheckable = true
                L_UIDropDownMenu_AddButton(info)
                wipe(info)

                return
            end
        end

        do
            local function ColumnsLeft_OnClick(self, button)
                tempObj.columns = tempObj.columns - 1
                if tempObj.columns <= 0 then
                    tempObj.columns = 1
                end
                newCols:SetText(tempObj.columns)
            end

            local function ColumnsRight_OnClick(self, button)
                tempObj.columns = tempObj.columns + 1
                if tempObj.columns >= def.maxColumns then
                    tempObj.columns = def.maxColumns
                end
                newCols:SetText(tempObj.columns)
            end

            local function RowsLeft_OnClick(self, button)
                tempObj.rows = tempObj.rows - 1
                if tempObj.rows <= 0 then
                    tempObj.rows = 1
                end
                newRows:SetText(tempObj.rows)
            end

            local function RowsRight_OnClick(self, button)
                tempObj.rows = tempObj.rows + 1
                if tempObj.rows >= def.maxRows then
                    tempObj.rows = def.maxRows
                end
                newRows:SetText(tempObj.rows)
            end

            local function SpacingBox_OnEnterPressed(self)
                local value = self:GetNumber()
                if value >= 250 then
                    value = 250
                end
                if self:GetName():find("HSpacing") ~= nil then
                    newHSpacing:SetValue(value)
                else
                    newVSpacing:SetValue(value)
                end
                self:ClearFocus()
            end

            local function SyncBtn_OnClick(self)
                KTrackerDB.sync = (self:GetChecked() == 1)
                addon.sync = KTrackerDB.sync
                L_CloseDropDownMenus()
            end

            local function MinimapBtn_OnClick(self)
                addon:ToggleMinimapButton()
                L_CloseDropDownMenus()
            end

            --
            -- this function is called only once on loading.
            -- it simply localizes the frame and registers some
            -- required elements.
            --
            function LocalizeUIFrame()
                if localized then
                    return
                end

                -- hold frame form inputs
                newID = _G[frameName .. "ID"]
                newName = _G[frameName .. "Name"]
                newSpec = _G[frameName .. "SpecDropDown"]
                newCols = _G[frameName .. "ColumnsText"]
                newRows = _G[frameName .. "RowsText"]
                newHSpacing = _G[frameName .. "HSpacing"]
                newVSpacing = _G[frameName .. "VSpacing"]
                newHSpacingBox = _G[frameName .. "HSpacingValue"]
                newVSpacingBox = _G[frameName .. "VSpacingValue"]
                newEnabled = _G[frameName .. "Enabled"]
                newCombat = _G[frameName .. "Combat"]

                L_UIDropDownMenu_Initialize(newSpec, InitializeSpecDropdown, nil, 1)

                -- frame buttons
                btnSave = _G[frameName .. "SaveBtn"]
                btnCancel = _G[frameName .. "CancelBtn"]
                btnReset = _G[frameName .. "ResetBtn"]
                btnLock = _G[frameName .. "LockBtn"]

                btnColumnsLeft = _G[frameName .. "ColumnsLeft"]
                btnColumnsRight = _G[frameName .. "ColumnsRight"]
                btnRowsLeft = _G[frameName .. "RowsLeft"]
                btnRowsRight = _G[frameName .. "RowsRight"]

                if GetLocale() ~= "enUS" and GetLocale() ~= "enGB" then
                    btnLock:SetText(L["Lock"])
                    _G[frameName .. "NameLabel"]:SetText(L["Group Name"])
                    _G[frameName .. "SpecLabel"]:SetText(L["Talents Spec"])
                    _G[frameName .. "ColumnsLabel"]:SetText(L["Columns"])
                    _G[frameName .. "RowsLabel"]:SetText(L["Rows"])
                    _G[frameName .. "HSpacingLabel"]:SetText(L["Spacing H"])
                    _G[frameName .. "VSpacingLabel"]:SetText(L["Spacing V"])
                    _G[frameName .. "EnabledLabel"]:SetText(L["Enable Group"])
                    _G[frameName .. "CombatLabel"]:SetText(L["Only in Combat"])
                    _G[frameName .. "HeaderSize"]:SetText(L["Size"])
                    _G[frameName .. "HeaderSpec"]:SetText(L["Spec"])
                    _G[frameName .. "HeaderCombat"]:SetText(L["Combat"])
                    _G[frameName .. "HeaderEnabled"]:SetText(L["Enabled"])
                end

                _G[frameName .. "Title"]:SetText(
                    "|cfff58cbaK|r|caaf49141Tracker|r - Made with love by |cfff58cbaKader|r (|cffffffffNovus Ordo|r @ |cff996019Warmane|r-Icecrown)"
                )

                -- prepare our temporary group object
                tempObj = utils.deepCopy(defObj)
                newCols:SetText(tempObj.columns)
                newRows:SetText(tempObj.rows)

                -- left and right columns buttons functions
                btnColumnsLeft:SetScript("OnClick", ColumnsLeft_OnClick)
                btnColumnsRight:SetScript("OnClick", ColumnsRight_OnClick)
                btnRowsLeft:SetScript("OnClick", RowsLeft_OnClick)
                btnRowsRight:SetScript("OnClick", RowsRight_OnClick)

                -- name and spacing on enter processed
                newName:SetScript("OnEnterPressed", SaveGroup)
                newHSpacingBox:SetScript("OnEnterPressed", SpacingBox_OnEnterPressed)
                newVSpacingBox:SetScript("OnEnterPressed", SpacingBox_OnEnterPressed)

                -- buttons scripts
                btnSave:SetScript("OnClick", SaveGroup)
                btnCancel:SetScript("OnClick", ResetFields)
                btnReset:SetScript(
                    "OnClick",
                    function(self)
                        StaticPopup_Show("KTRACKER_DIALOG_RESET")
                    end
                )

                -- Sync button
                local syncName = frameName .. "SyncBtn"
                btnSync = _G[syncName]
                _G[syncName .. "Text"]:SetText(L["Enable Sync"])
                utils.setTooltip(
                    btnSync,
                    L["Check this you want to enable group sharing."],
                    "ANCHOR_CURSOR",
                    L["Enable Sync"]
                )
                btnSync:SetScript("OnClick", SyncBtn_OnClick)

                -- Minimap button
                local mmbName = frameName .. "MinimapBtn"
                btnMinimap = _G[mmbName]
                _G[mmbName .. "Text"]:SetText(L["Minimap Button"])
                utils.setTooltip(
                    btnMinimap,
                    L["Check this you want show the minimap button."],
                    "ANCHOR_CURSOR",
                    L["Minimap Button"]
                )
                btnMinimap:SetScript("OnClick", MinimapBtn_OnClick)

                localized = true
            end
        end
    end

    --
    -- handles the config frame OnUpdate event
    --
    function UpdateUIFrame(self, elapsed)
        if utils.update(self, self:GetName(), updateInterval, elapsed) then
            FetchGroups()
            btnSync:SetChecked(addon.sync)
            btnMinimap:SetChecked(addon.minimap)

            -- group id
            local id = newID:GetNumber()
            tempObj.id = (id > 0) and id or nil

            -- disable few things
            tempObj.name = newName:GetText():trim()
            local hasObject = (tempObj.name ~= "")

            -- spec
            if tempObj.name == "" then
                L_UIDropDownMenu_DisableDropDown(newSpec)
            else
                L_UIDropDownMenu_EnableDropDown(newSpec)
            end

            local spec = L_UIDropDownMenu_GetText(newSpec)
            if spec == L["Primary"] then
                tempObj.spec = 1
            elseif spec == L["Secondary"] then
                tempObj.spec = 2
            else
                L_UIDropDownMenu_SetText(newSpec, L["Both"])
                tempObj.spec = 0
            end

            tempObj.columns = tonumber(newCols:GetText())
            tempObj.rows = tonumber(newRows:GetText())
            tempObj.hspacing = newHSpacing:GetValue()
            tempObj.vspacing = newVSpacing:GetValue()

            if not newHSpacingBox:HasFocus() then
                newHSpacingBox:SetText(tempObj.hspacing)
            end
            if not newVSpacingBox:HasFocus() then
                newVSpacingBox:SetText(tempObj.vspacing)
            end

            tempObj.enabled = (newEnabled:GetChecked() == 1)
            tempObj.combat = (newCombat:GetChecked() == 1)

            -- columns and rows
            newCols:SetText(tempObj.columns)
            newRows:SetText(tempObj.rows)

            -- change lock/unlock button text.
            utils.setTextIf(btnLock, L["Unlock"], L["Lock"], addon.locked)

            -- enable/disable or show/hide items.
            if hasObject then
                newHSpacingBox:Show()
                newVSpacingBox:Show()
                btnSave:Enable()
                btnCancel:Enable()
                newEnabled:Enable()
                newCombat:Enable()
                utils.enableDisable(btnColumnsLeft, tempObj.columns > 1)
                utils.enableDisable(btnColumnsRight, tempObj.columns < def.maxColumns)
                utils.enableDisable(btnRowsLeft, tempObj.rows > 1)
                utils.enableDisable(btnRowsRight, tempObj.rows < def.maxRows)
            else
                newHSpacingBox:Hide()
                newVSpacingBox:Hide()
                btnSave:Disable()
                btnCancel:Disable()
                newEnabled:Disable()
                newCombat:Disable()
                btnColumnsLeft:Disable()
                btnColumnsRight:Disable()
                btnRowsLeft:Disable()
                btnRowsRight:Disable()
            end
        end
    end

    --
    -- called when the configuration frame loads the first time
    --
    function addon:ConfigOnLoad(frame)
        if not frame then
            return
        end
        UIFrame = frame
        frameName = frame:GetName()
        frame:RegisterForDrag("LeftButton")
        LocalizeUIFrame()
        frame:SetScript("OnUpdate", UpdateUIFrame)
        frame:SetScript("OnHide", ResetFields)
        utils.hide(frame)
        tinsert(UISpecialFrames, frameName)
    end

    --
    -- toggles the configuration frame
    --
    function addon:Config()
        utils.toggle(UIFrame)
    end

    --
    -- delete a group pop up dialog
    --
    StaticPopupDialogs["KTRACKER_DIALOG_DELETE"] = {
        text = L["|caaf49141%s|r : Are you sure you want to delete this group?"],
        button1 = DELETE,
        button2 = CANCEL,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self, id)
            utils.highlight(_G[frameName .. "GroupBtn" .. id], true)
        end,
        OnHide = function(self, id)
            utils.highlight(_G[frameName .. "GroupBtn" .. id], false)
        end,
        OnAccept = function(self, id)
            if id and KTrackerDB.groups[id] then
                local DB = KTrackerDB.groups[id]
                if DB then
                    local groupName = format(holderGroup, id)
                    utils.hide(_G[groupName])
                    tremove(KTrackerDB.groups, id)
                    KTrackerCharDB.groups[DB.created] = nil
                    fetched, isEdit = false, false
                    addon:Initialize()
                end
            end
            self:Hide()
        end
    }

    --
    -- clear all group icons pop up dialog
    --
    StaticPopupDialogs["KTRACKER_DIALOG_CLEAR"] = {
        text = L["|caaf49141%s|r : Are you sure you want to clear all icons?"],
        button1 = YES,
        button2 = CANCEL,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self, id)
            utils.highlight(_G[frameName .. "GroupBtn" .. id], true)
        end,
        OnHide = function(self, id)
            utils.highlight(_G[frameName .. "GroupBtn" .. id], false)
        end,
        OnAccept = function(self, id)
            if id and KTrackerDB.groups[id] then
                L_CloseDropDownMenus()
                wipe(KTrackerDB.groups[id].icons)
                addon:Initialize()
                fetched, isEdit = false, false
            end
            self:Hide()
        end
    }

    --
    -- reset all addon to default
    --
    StaticPopupDialogs["KTRACKER_DIALOG_RESET"] = {
        text = L[
            "You are about to reset everything, all groups, icons and their settings will be deleted. \nDo you want to continue?"
        ],
        button1 = YES,
        button2 = CANCEL,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnAccept = function(self)
            -- wipe tables?
            wipe(KTrackerDB)
            wipe(KTrackerCharDB)
            wipe(groups)

            -- hide groups
            for i = 1, def.maxGroups do
                local groupName = format(holderGroup, i)
                utils.hide(_G[groupName])
            end
            LoadDatabase()
            addon:Initialize()
            fetched, isEdit = false, false
            self:Hide()
        end
    }

    --
    -- synchronization handler
    --
    do
        --
        -- holds messages per character
        --
        local data = {}

        --
        -- send new group dialog
        --
        local function ProcessShare(id, channel, target)
            local DB = KTrackerDB.groups[id]

            -- double check
            if not DB then
                return
            end

            local str = "GroupStart\t" .. id .. "\t" .. DB.name .. "\t" .. DB.columns .. "\t" .. DB.rows
            addon:Sync(str, channel, target)

            local num = DB.columns * DB.rows
            for i = 1, num do
                local icon = DB.icons[i]
                local msg = "GroupIcon\t" .. id .. "\t" .. icon.name .. "\t" .. tostring(icon.enabled)
                msg = msg .. "\t" .. icon.type .. "\t" .. icon.subtype .. "\t" .. tostring(icon.when)
                msg = msg .. "\t" .. icon.unit .. "\t" .. tostring(icon.mine) .. "\t" .. tostring(icon.timer)
                msg = msg .. "\t" .. icon.effect
                addon:Sync(msg, channel, target)

                -- final icon? Tell to stop
                if i == num then
                    addon:Sync("GroupEnd\t" .. id .. "\t" .. DB.name, channel, target)
                end
            end
        end

        --
        -- handles all sync actions
        --
        local function SyncHandler(msg, channel, sender)
            if not msg then
                return
            end

            local command, other = strsplit("\t", msg, 2)

            -- sending share request
            if command == "GroupShare" and other:trim() ~= "" then
                local str = sender .. "\t" .. other
                StaticPopup_Show("KTRACKER_DIALOG_SHARE_RECEIVE", sender, nil, str)
                return
            end

            -- accepting the group
            if command == "GroupAccept" and other:trim() ~= "" then
                local id = tonumber(other)
                for i, obj in ipairs(KTrackerDB.groups) do
                    if i == id then
                        ProcessShare(id, "WHISPER", sender)
                        break
                    end
                end
                return
            end

            -- receiving a new group:
            if command == "GroupStart" then
                local id, name, columns, rows = strsplit("\t", other, 4)
                columns, rows = tonumber(columns), tonumber(rows)

                data = data or {}
                data[sender] = data[sender] or {}
                data[sender][id] = data[sender][id] or {}

                local group = utils.deepCopy(def.DBGroup)
                group.id = nil
                group.name = name
                group.enabled = true
                group.columns = columns
                group.rows = rows

                data[sender][id] = group
                return
            end

            -- receiving group icons
            if command == "GroupIcon" then
                -- we make sure the player started sending.
                if not data[sender] then
                    return
                end

                local id, name, enabled, iconType, subtype, when, unit, mine, timer, effect = strsplit("\t", other, 10)

                if not data[sender][id] then
                    return
                end

                local icon = utils.deepCopy(def.icon)
                icon.enabled = (enabled == "true")
                icon.name = name
                icon.type = iconType
                icon.subtype = subtype
                icon.when = tonumber(when)
                icon.unit = unit
                icon.mine = (mine == "true")
                icon.timer = (timer == "true")
                icon.effect = effect

                tinsert(data[sender][id].icons, icon)
                return
            end

            if command == "GroupEnd" then
                local id, name = strsplit("\t", other, 2)
                if not id then
                    return
                end
                if data and (not data[sender] or not data[sender][id]) then
                    return
                end

                Group:Save(data[sender][id])
                wipe(data[sender])

                addon:PrintSuccess(L:F('"%s" group successfully imported.', name))

                addon:Initialize()
                fetched, isEdit = false, false
                return
            end
        end

        syncHandlers[syncPrefix] = SyncHandler

        --
        -- prompt dialog to share group
        --
        StaticPopupDialogs["KTRACKER_DIALOG_SHARE_SEND"] = {
            text = L[
                "Enter the name of the character to share the group with, or leave empty to share it with your party/raid members."
            ],
            button1 = SEND_LABEL,
            button2 = CANCEL,
            hasEditBox = true,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            OnShow = function(self, id)
                utils.highlight(_G[frameName .. "GroupBtn" .. id], true)
                _G[self:GetName() .. "EditBox"]:SetFocus()
            end,
            OnHide = function(self, id)
                utils.highlight(_G[frameName .. "GroupBtn" .. id], false)
                local box = _G[self:GetName() .. "WideEditBox"]
                box:SetText("")
                box:ClearFocus()
            end,
            OnAccept = function(self, id)
                local target = _G[self:GetName() .. "EditBox"]:GetText():trim()
                local channel = "WHISPER"
                if target == "" then
                    channel, target = nil, nil
                end
                if KTrackerDB.groups[id] then
                    addon:Sync("GroupShare\t" .. id, channel, target)
                end
                self:Hide()
            end,
            EditBoxOnEnterPressed = function(self, id)
                local target = _G[self:GetName()]:GetText():trim()
                local channel, data = "WHISPER", ""
                if target == "" then
                    channel, target = nil, nil
                end
                if KTrackerDB.groups[id] then
                    addon:Sync("GroupShare\t" .. id, channel, target)
                end
                self:GetParent():Hide()
            end,
            EditBoxOnEscapePressed = function(self)
                self:SetText("")
                self:ClearFocus()
                self:GetParent():Hide()
            end
        }

        --
        -- prompt dialog to ask share permission
        --
        StaticPopupDialogs["KTRACKER_DIALOG_SHARE_RECEIVE"] = {
            text = L["%s wants to share a group of icons with you. Do you want to import it?"],
            button1 = ACCEPT,
            button2 = CANCEL,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            OnAccept = function(self, str)
                if str then
                    local sender, id = strsplit("\t", str)
                    id = tonumber(id)
                    if sender and id > 0 then
                        addon:Sync("GroupAccept\t" .. id, "WHISPER", sender)
                    end
                end
                self:Hide()
            end
        }
    end
end
