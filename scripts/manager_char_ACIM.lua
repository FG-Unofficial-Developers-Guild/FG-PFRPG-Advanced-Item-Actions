--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals ItemManager.isWeapon ItemManager.isShield

-- Get special properties of weapon.
local function getSpecialProperties(nodeWeapon)
	local tProps = {}

	local aProps = {
		['acid'] = { 'corrosive', 'acid' },
		['fire'] = { 'flaming', 'igniting' },
		['cold'] = { 'frost', 'icy' },
		['electricity'] = { 'shock' },
	}

	local sPropsLower = DB.getValue(nodeWeapon, 'properties', ''):lower()
	for s, t in pairs(aProps) do
		for _, ss in pairs(t) do
			if sPropsLower:match(ss) then table.insert(tProps, s) end
		end
	end

	return tProps
end

-- runs provided function on each nodeWeapon matching the provided nodeItem
local function addEnergyDamage(nodeItem)
	local sPath = nodeItem.getPath()
	for _, vWeapon in pairs(DB.getChildren(nodeItem.getChild('...'), 'weaponlist')) do
		local _, sRecord = DB.getValue(vWeapon, 'shortcut', '', '')
		if sRecord == sPath then
			local nodeDmgList = DB.createChild(vWeapon, 'damagelist')
			for _, s in pairs(getSpecialProperties(vWeapon)) do
				local nodeDmg = DB.createChild(nodeDmgList)
				DB.setValue(nodeDmg, 'dice', 'dice', { 'd6' })
				DB.setValue(nodeDmg, 'bonus', 'number', 0)
				DB.setValue(nodeDmg, 'type', 'string', s)
			end
		end
	end
end

local addToWeaponDB_old
local function addToWeaponDB_new(nodeItem)
	local sType, sSubtype

	-- temporarily override type and subtype of shields to
	-- make the native function interpret them as melee weapons
	if ItemManager.isShield(nodeItem) then
		sType = DB.getValue(nodeItem, 'type', '')
		sSubtype = DB.getValue(nodeItem, 'subtype', '')
		DB.setValue(nodeItem, 'type', 'string', 'Weapon')
		DB.setValue(nodeItem, 'subtype', 'string', 'melee')
	end

	-- add weapon to weaponlist via ruleset native function
	addToWeaponDB_old(nodeItem)

	-- revert type and subtype
	if sType and sSubtype then
		DB.setValue(nodeItem, 'type', 'string', sType)
		DB.setValue(nodeItem, 'subtype', 'string', sSubtype)
	end

	-- add extra d6 energy damage if appropriate
	addEnergyDamage(nodeItem)
end

local onCharItemDelete_old
local function onCharItemDelete_new(nodeItem, ...)
	onCharItemDelete_old(nodeItem, ...)

	local sItemType = DB.getValue(nodeItem, 'type', ''):lower()
	if sItemType == 'potion' or sItemType == 'wand' or sItemType == 'scroll' then
		local nodeSpellSet = InvManagerACIM.getSpellSet(DB.getChild(nodeItem, '...'), nodeItem.getPath())
		if nodeSpellSet then DB.deleteNode(nodeSpellSet) end
	end
end

local onCharItemAdd_old
local function onCharItemAdd_new(nodeItem, ...)
	onCharItemAdd_old(nodeItem, ...)

	InvManagerACIM.inventoryChanged(nodeItem.getChild('...'), nodeItem)
end

-- Reset consumables on rest
local resetSpells_old
local function resetSpells_new(nodeCaster, ...)
	if ActorManager.isPC(nodeCaster) then
		for _, nodeItem in pairs(DB.getChildren(nodeCaster, 'inventorylist')) do
			if InvManagerACIM.inventoryChanged(nodeCaster, nodeItem) then
				local nCarried = DB.getValue(nodeItem, 'carried', 1)
				DB.setValue(nodeItem, 'carried', 'number', 1)
				if OptionsManager.isOption('AIA_UnequipOnRest', 'disabled') then DB.setValue(nodeItem, 'carried', 'number', nCarried) end
			end
		end
	end
	resetSpells_old(nodeCaster, ...)
end

function onInit()
	OptionsManager.registerOption2('AIA_UnequipOnRest', false, 'option_header_game', 'option_label_AIA_unequip_on_rest', 'option_entry_cycler', {
		labels = 'option_val_off',
		values = 'disabled',
		baselabel = 'option_val_on',
		baseval = 'enabled',
		default = 'enabled',
	})

	addToWeaponDB_old = CharManager.addToWeaponDB
	CharManager.addToWeaponDB = addToWeaponDB_new

	onCharItemDelete_old = CharManager.onCharItemDelete
	CharManager.onCharItemDelete = onCharItemDelete_new
	ItemManager.setCustomCharRemove(onCharItemDelete_new)

	onCharItemAdd_old = CharManager.onCharItemAdd
	CharManager.onCharItemAdd = onCharItemAdd_new
	ItemManager.setCustomCharAdd(onCharItemAdd_new)

	resetSpells_old = SpellManager.resetSpells
	SpellManager.resetSpells = resetSpells_new
end
