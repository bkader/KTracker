--[[
Thanks a lot for your help on translating the addon.

Translator: Farusa199 (Staryandros on CurseForge)
Translator URI:
- http://forum.warmane.com/member.php?username=Farusa199
- https://www.curseforge.com/members/staryandros/projects

]]
if GetLocale() ~= "ruRU" then
    return
end
local _, addon = ...
local L = addon.L

L["|cffffd700Left-Click|r to lock/unlock."] = "|cffffd700Левый клик|r заблокировать/разблокировать."
L["|cffffd700Right-Click|r to access settings."] = "|cffffd700Правый клик|r открыть настройки."
L["|cffffd700Shift+Click|r to move."] = "|cffffd700Shift+клик|r переместить."
L["|cffffd700Alt+Click|r for free drag and drop."] = "|cffffd700Alt+клик|r свободное перемещение."

L["Default Group"] = "Стандартная группа"
L["addon loaded"] = "Аддон загружен"

L["Resize"] = "Изменить размер"
L["Click and drag to change size."] = "Кликнуть и перетаскивать для изменения размера."

L["Right-click for icon options."] = "|cffffd700Правый клик|r для настройки иконки."
L["Left-click to move the group."] = "|cffffd700Левый клик|r для перемещения группы."
L["Middle-click to enable/disable."] = "|cffffd700Клик средней кнопкой|r для включения/отключения."
L['Type "|caaf49141/kt config|r" for addon config'] = 'Наберите "|caaf49141/kt config|r"в чат, что бы открыть настройки аддона'

L["Choose Name"] = "Ввести название"
L["Enter the name or ID of the spell. You can add multiple buffs or debuffs by separatig them with semicolons."] = "Введите имя или ID заклинания/предмета/баффа/дебаффа для отслеживания. Можно добавить несколько баффов/дебаффов, разделяя их ';'"

L["Enabled"] = "Включен"

L["Icon Type"] = "Тип иконки"
L["Cooldown"] = "Перезарядка"
L["Buff or Debuff"] = "Бафф или дебафф"
L["Reactive spell or ability"] = "Активное заклинание или способность"
L["Temporary weapon enchant"] = "Временные чары для оружия"
L["Totem/non-MoG Ghoul"] = "Тотем/не-ПВ вурдалак"

L["Cooldown Type"] = "Тип перезарядки"
L["Spell"] = "Заклинание"
L["Item"] = "Предмет"
L["Talent"] = "Талант"
L["Buff"] = "Бафф"
L["Debuff"] = "Дебафф"

L["Show Timer"] = "Показывать таймер"
L["Only Mine"] = "Только мои"

L["Weapon Slot"] = "Слот оружия"
L["Main Hand"] = "Правая рука"
L["Off-Hand"] = "Левая рука"

L["Show When"] = "Показывать когда"
L["Off Cooldown"] = "Нет кулдауна"
L["On Cooldown"] = "Есть кулдаун"
L["Usable"] = "Доступно"
L["Unusable"] = "Недоступно"
L["Always"] = "Всегда"
L["Present"] = "Присутствует"
L["Absent"] = "Отсутсвует"

L["Unit to Watch"] = "На ком отслеживать"
L["Player"] = "Игрок"
L["Target"] = "Цель"
L["Target's Target"] = "Цель цели"
L["Focus"] = "Фокус"
L["Focus Target"] = "Цель фокуса"
L["Pet"] = "Питомец"
L["Pet's Target"] = "Цель питомца"
L["Party Unit"] = "Группа"
L["Arena Unit"] = "Арена"
L["Arena %d"] = "Арена %d"
L["Party %d"] = "Группа %d"
L["Custom Unit"] = "Свой вариант"
L["Enter the unit name on which you want to track the aura."] = "Введите имя игрока, на котором вы хотите отслеживать ауру."

L["Icon Effect"] = "Анимация"
L["None"] = "Нет"
L["Glow"] = "Свечение"
L["Pulse"] = "Пульсация"
L["Shine"] = "Сияние"

L["More Options"] = "Другие возможности"
L["Clear Settings"] = "Очистить настройки"

L["Edit"] = "Изменить"
L["Duplicate"] = "Дубликат"
L["Share"] = "Поделиться"
L["Group Status"] = "Статус группы"
L["Combat"] = "Бой"
L["Icons"] = "Иконка"
L["Position"] = "Позиция"

L["Lock"] = "Заблокировать"
L["Unlock"] = "Разблокировать"

L["Group Name"] = "Имя группы"
L["Talents Spec"] = "Спек"
L["Both"] = "Оба"
L["Primary"] = "Основной"
L["Secondary"] = "Вторичный"
L["Columns"] = "Столбцы"
L["Rows"] = "Строки"
L["Spacing"] = "Отступ"
L["Spacing V"] = "Отсутп по высоте"
L["Spacing H"] = "Отсутп по ширине"
L["Enable Group"] = "Группа включена"
L["Only in Combat"] = "Только в бою"

L["The group name is required"] = "Требуется имя группы"
L["You have reached the maximum allowed groups number"] = "Вы достигли максимально допустимое число групп"

L["Size"] = "Размер"
L["Spec"] = "Спек"

L["Enable Sync"] = "Синхронизация"
L["Check this you want to enable group sharing."] = "Включите этот параметр, чтобы включить передачу групп другим персонажам или участникам группы/рейда"

L["Minimap Button"] = "Кнопка"
L["Check this you want show the minimap button."] = "Отметьте, чтобы показывать кнопку у мини-карты."

L["|caaf49141%s|r : Are you sure you want to delete this group?"] = "|caaf49141%s|r : Вы уверены, что хотите удалить эту группу?"
L["|caaf49141%s|r : Are you sure you want to clear all icons?"] = "|caaf49141%s|r : Вы уверены, что хотите очистить все настройки иконок?"
L["You are about to reset everything, all groups, icons and their settings will be deleted. \nDo you want to continue?"] = "Вы собираетесь сбросить все, все группы, значки и их настройки будут удалены. \nПродолжить?"
L["Enter the name of the character to share the group with, or leave empty to share it with your party/raid members."] = "Введите имя персонажа или оставьте пустым для обмена с вашими членами группы/рейда."
L["%s wants to share a group of icons with you. Do you want to import it?"] = "%s хочет поделиться с вами настройками. Импортировать их?"
