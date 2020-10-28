if GetLocale() ~= "frFR" then
    return
end
local _, addon = ...
local L = addon.L

L["|cffffd700Left-Click|r to lock/unlock."] = "|cffffd700Clic gauche|r pour verrouiller/déverrouiller."
L["|cffffd700Right-Click|r to access settings."] = "|cffffd700Clic droit|r pour accéder aux paramètres."
L["|cffffd700Shift+Click|r to move."] = "|cffffd700Shift+Clic|r pour déplacer."
L["|cffffd700Alt+Click|r for free drag and drop."] = "|cffffd700Alt+Clic|r pour un déplacement libre."

L["Default Group"] = "Groupe par défaut"
L["addon loaded"] = "addon chargé"

L["Resize"] = "Redimensionner"
L["Click and drag to change size."] = "Cliquez et faites glisser pour changer la redimensionner."

L["Right-click for icon options."] = "Cliquez avec le bouton droit pour les options d'icône."
L["Left-click to move the group."] = "Cliquez avec le bouton gauche pour déplacer le groupe."
L["Middle-click to enable/disable."] = "Cliquez avec le bouton du milieu pour activer/désactiver."
L['Type "|caaf49141/kt config|r" for addon config'] = 'Tapez "|caaf49141/kt config|r" pour la configuration de l\'addon'

L["Choose Name"] = "Choisissez le nom"
L["Enter the name or ID of the spell. You can add multiple buffs or debuffs by separatig them with semicolons."] = "Saisissez le nom ou l'ID du sort. Vous pouvez ajouter plusieurs buffs ou debuffs en les séparant par des points-virgules."

L["Enabled"] = "Activé(e)"

L["Icon Type"] = "Type d'icône"
L["Cooldown"] = "Temps de recharge"
L["Buff or Debuff"] = "Buff ou Debuff"
L["Reactive spell or ability"] = "Sort ou capacité réactive"
L["Temporary weapon enchant"] = "Enchantement d'arme temporaire"
L["Totem/non-MoG Ghoul"] = "Totem/Goule non-MoG"

L["Cooldown Type"] = "Type de temps de recharge"
L["Spell"] = "Sort"
-- L["Item"] = true

-- L["Buff"] = true
-- L["Debuff"] = true

L["Show Timer"] = "Afficher le temps"
L["Only Mine"] = "Uniquement le mien"

L["Weapon Slot"] = "Emplacement d'arme"
L["Main Hand"] = "Main droite"
L["Off-Hand"] = "Main gauche"

L["Show When"] = "Quand afficher"
L["Usable"] = "Utilisable"
L["Unusable"] = "Inutilisable"
L["Always"] = "Toujours"
L["Present"] = "Présent"
L["Absent"] = "Absent"

L["Unit to Watch"] = "Unité à surveiller"
L["Player"] = "Joueur"
L["Target"] = "Cible"
L["Target's Target"] = "Cible de la cible"
-- L["Focus"] = true
-- L["Focus Target"] = true
L["Pet"] = "Familier"
L["Pet's Target"] = "Cible du familier"
L["Party Unit"] = "Groupe"
L["Arena Unit"] = "Arène"
L["Arena %d"] = "Ennemi %d"
L["Party %d"] = "Membre %d"
L["Enter the unit name on which you want to track the aura."] = "Entrez le nom de l'unité sur laquelle vous souhaitez suivre l'aura."

L["Animation Effect"] = "Animation"
L["None"] = "Aucun"
L["Pulse"] = "Impulsion"
L["Shine"] = "Éclat"

L["More Options"] = "Plus d'options"
L["Clear Settings"] = "Effacer les paramètres"

L["Edit"] = "Éditer"
L["Duplicate"] = "Dupliquer"
L["Share"] = "Partager"
L["Group Status"] = "Statut du groupe"
L["Combat"] = "combat"
L["Icons"] = "Icônes"
L["Position"] = "Position"

L["Lock"] = "Verrouiller"
L["Unlock"] = "Déverrouiller"

L["Group Name"] = "Nom de groupe"
L["Talents Spec"] = "Spécialisation"
L["Both"] = "Les deux"
L["Primary"] = "Primaire"
L["Secondary"] = "Secondaire"
L["Columns"] = "Colonnes"
L["Rows"] = "Lignes"
L["Spacing"] = "Espacement"
L["Spacing V"] = "Espacement V"
L["Spacing H"] = "Espacement H"
L["Enable Group"] = "Activer le groupe"
L["Only in Combat"] = "Uniquement en combat"

L["The group name is required"] = "Le nom du groupe est requis"
L["You have reached the maximum allowed groups number"] = "Vous avez atteint le nombre maximum de groupes autorisés"

L["Size"] = "Taille"
L["Spec"] = "Spec"

L["Enable Sync"] = "Synchronisation"
L["Check this you want to enable group sharing."] = "Cochez cette option pour activer le partage de groupe."

L["Minimap Button"] = "Mini Bouton"
L["Check this you want show the minimap button."] = "Cochez cette case pour afficher le bouton de la mini-carte."

L["|caaf49141%s|r : Are you sure you want to delete this group?"] = "|caaf49141%s|r : Voulez-vous vraiment supprimer ce groupe?"
L["|caaf49141%s|r : Are you sure you want to clear all icons?"] = "|caaf49141%s|r : Voulez-vous vraiment effacer toutes les icônes?"
L["You are about to reset everything, all groups, icons and their settings will be deleted. \nDo you want to continue?"] = "Vous êtes sur le point de tout réinitialiser, tous les groupes, icônes et leurs paramètres seront supprimés. \nVoulez-vous continuer?"
L["Enter the name of the character to share the group with, or leave empty to share it with your party/raid members."] = "Entrez le nom du personnage ou laissez vide pour le partager avec les membres de votre groupe/raid."
L["%s wants to share a group of icons with you. Do you want to import it?"] = "%s souhaite partager un groupe d'icônes avec vous. Voulez-vous l'importer?"
