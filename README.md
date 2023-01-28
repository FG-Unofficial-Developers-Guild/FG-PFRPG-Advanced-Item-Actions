[![Build FG-Usable File](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Advanced-Item-Actions/actions/workflows/create-ext.yml/badge.svg)](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Advanced-Item-Actions/actions/workflows/create-ext.yml) [![Luacheck](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Advanced-Item-Actions/actions/workflows/luacheck.yml/badge.svg)](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Advanced-Item-Actions/actions/workflows/luacheck.yml)

# PFRPG Advanced Item Actions
This extension changes the way items are added to a characters inventory. In particular what happens when you do.
If the item added is a wand, potion or scroll and is equipped it will generate an action item for it in the action tab. It will look up the spell from the item name that is within parentheses. For example: "Wand (Cure Light Wounds)" will create a spell class caster level 1 and have 50 uses of level spells.
You can also now use the format "Wand of Cure Light Wounds" or "Potion of Cure Light Wounds" or "Scroll of Cure Light Wounds".
This also works with the Enhanced Items v4 extension to keep track of charges.
For potions, wands, and scrolls to work, you need to have a module loaded that has the spell in it and the spell description's "level" field must contain a list of classes and associated spell levels in the official PFRPG format.

Shields also have the ability to do damage as well as have ac associated with them. With this they now get an action item generated for them for shield bash. This means you no longer need to have 2 items for a shield if your character does shield bash. This shield bash is only created if your shield items have damage linked to them, which you can only do using community modules or the [Enhanced Items extension](https://github.com/FG-Unofficial-Developers-Guild/FG-PFRPG-Enhanced-Items).

If the item is a weapon and and has flaming, flaming burst, igniting, frost, icy burst, corrosive, corrosive burst, shock and shocking burst in the properties it will generate the bonus 1d6 damage as part of the weapon.

To override the caster level of an item, change the item name before equipping it.
For example: Scroll of Cure Light Wounds (CL 5)

To override the remaining charges of a wand, change the item name before equipping it.
For example: Wand of Cure Light Wounds [13 charges]

Originally created by [rmilmine](https://www.fantasygrounds.com/forums/member.php?215591-rmilmine).

# Compatibility
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) 4.3.0 4.3.3 (2023-02-21).
