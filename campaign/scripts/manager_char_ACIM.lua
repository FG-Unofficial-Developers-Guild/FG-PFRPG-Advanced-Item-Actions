local function addDamageToWeapon(nodeWeapon, aDamage, nBonus, sStat, nStatMult, aCritMult, sFinalDamageType, bIsCorrosive, bIsFlaming,
                                 bIsFrost, bIsShocking)
	local nodeDmgList = DB.createChild(nodeWeapon, 'damagelist');

	local function addWeaponDamage()
		local nodeDmg = DB.createChild(nodeDmgList);
		if aDamage[2] then
			DB.setValue(nodeDmg, 'dice', 'dice', aDamage[2].dice);
			DB.setValue(nodeDmg, 'bonus', 'number', nBonus + aDamage[2].mod);
		elseif aDamage[1] then
			DB.setValue(nodeDmg, 'dice', 'dice', aDamage[1].dice);
			DB.setValue(nodeDmg, 'bonus', 'number', nBonus + aDamage[1].mod);
		else
			DB.setValue(nodeDmg, 'bonus', 'number', nBonus);
		end

		if aCritMult[2] then
			DB.setValue(nodeDmg, 'critmult', 'number', aCritMult[2]);
		else
			DB.setValue(nodeDmg, 'critmult', 'number', aCritMult[1]);
		end

		DB.setValue(nodeDmg, 'stat', 'string', sStat);
		if sStat ~= '' then DB.setValue(nodeDmg, 'statmult', 'number', nStatMult); end

		DB.setValue(nodeDmg, 'type', 'string', sFinalDamageType);
	end

	addWeaponDamage();

	local aSpecialDmg = {};
	table.insert(aSpecialDmg, { dice = { 'd6' }, mod = 0 });
	if bIsCorrosive then addWeaponDamage(nodeDmgList, aSpecialDmg, 0, '', 1, { 0 }, 'acid'); end
	if bIsFlaming then addWeaponDamage(nodeDmgList, aSpecialDmg, 0, '', 1, { 0 }, 'fire'); end
	if bIsFrost then addWeaponDamage(nodeDmgList, aSpecialDmg, 0, '', 1, { 0 }, 'cold'); end
	if bIsShocking then addWeaponDamage(nodeDmgList, aSpecialDmg, 0, '', 1, { 0 }, 'electricity'); end
end

local function addToWeaponDB(nodeItem)
	-- Parameter validation
	if string.lower(DB.getValue(nodeItem, 'type', '')) ~= 'weapon' then
		if string.lower(DB.getValue(nodeItem, 'subtype', '')) ~= 'shield' then
			return;
		elseif DB.getValue(nodeItem, 'damage', '') == '' then
			return;
		end
	end

	-- Get the weapon list we are going to add to
	local nodeChar = nodeItem.getChild('...');
	local nodeWeapons = nodeChar.createChild('weaponlist');
	if not nodeWeapons then return nil; end

	-- Set new weapons as equipped
	DB.setValue(nodeItem, 'carried', 'number', 1);

	-- Determine identification
	local nItemID = 0;
	if LibraryData.getIDState('item', nodeItem, true) then nItemID = 1; end

	-- Grab some information from the source node to populate the new weapon entries
	local sName;
	if nItemID == 1 then
		sName = DB.getValue(nodeItem, 'name', '');
	else
		sName = DB.getValue(nodeItem, 'nonid_name', '');
		if sName == '' then sName = Interface.getString('item_unidentified'); end
		sName = '** ' .. sName .. ' **';
	end
	local nBonus = 0;
	if nItemID == 1 then nBonus = DB.getValue(nodeItem, 'bonus', 0); end

	local nRange = DB.getValue(nodeItem, 'range', 0);
	local nAtkBonus = nBonus;

	local sSubType = string.lower(DB.getValue(nodeItem, 'subtype', ''));
	local bMelee = true;
	local bRanged = false;
	if string.find(sSubType, 'melee') or string.find(sSubType, 'shield') then
		bMelee = true;
		if nRange > 0 then bRanged = true; end
	elseif string.find(sSubType, 'ranged') then
		bMelee = false;
		bRanged = true;
	end

	local bDouble = false;
	local sProps = DB.getValue(nodeItem, 'properties', '');
	local sPropsLower = sProps:lower();
	if sPropsLower:match('double') then bDouble = true; end
	if nAtkBonus == 0 and (sPropsLower:match('masterwork') or sPropsLower:match('adamantine')) then nAtkBonus = 1; end
	local bTwoWeaponFight = false;
	if CharManager.hasFeat(nodeChar, 'Two-Weapon Fighting') then bTwoWeaponFight = true; end

	local aDamage = {};
	local sDamage = DB.getValue(nodeItem, 'damage', '');
	local aDamageSplit = StringManager.split(sDamage, '/');
	for _, vDamage in ipairs(aDamageSplit) do
		local diceDamage, nDamage = DiceManager.convertStringToDice(vDamage);
		table.insert(aDamage, { dice = diceDamage, mod = nDamage });
	end

	local sDamageType = DB.getValue(nodeItem, 'damagetype', ''):lower();
	local sFinalDamageType1;
	local sFinalDamageType2 = '';

	if bDouble then
		local aDoubleDamageTypes = StringManager.split(sDamageType, '/');
		if #aDoubleDamageTypes > 1 then
			sFinalDamageType1 = table.concat(ActionDamage.getDamageTypesFromString(aDoubleDamageTypes[1]:gsub(' and ', ','):gsub(' or ', ',')), ',');
			sFinalDamageType2 = table.concat(ActionDamage.getDamageTypesFromString(aDoubleDamageTypes[2]:gsub(' and ', ','):gsub(' or ', ',')), ',');
		else
			local aTempDamageTypes = ActionDamage.getDamageTypesFromString(sDamageType:gsub(' and ', ','):gsub(' or ', ','));
			local aDamageTypes = {};
			local aSharedDamageTypes = {};
			for _, sSubDamageType in ipairs(aTempDamageTypes) do
				if StringManager.contains({ 'bludgeoning', 'piercing', 'slashing' }, sSubDamageType) then
					table.insert(aDamageTypes, sSubDamageType);
				else
					table.insert(aSharedDamageTypes, sSubDamageType);
				end
			end
			local aCalcDamageType1 = { aDamageTypes[1] or '' };
			local aCalcDamageType2 = { aDamageTypes[2] or aDamageTypes[1] or '' };
			for _, sSubDamageType in ipairs(aSharedDamageTypes) do
				table.insert(aCalcDamageType1, sSubDamageType);
				table.insert(aCalcDamageType2, sSubDamageType);
			end
			sFinalDamageType1 = table.concat(aCalcDamageType1, ',')
			sFinalDamageType2 = table.concat(aCalcDamageType2, ',')
		end
	else
		sFinalDamageType1 = table.concat(ActionDamage.getDamageTypesFromString(sDamageType:gsub(' and ', ','):gsub(' or ', ',')), ',');
	end

	local aCritThreshold = { 20 };
	local aCritMult = { 2 };
	local sCritical = DB.getValue(nodeItem, 'critical', '');
	local aCrit = StringManager.split(sCritical, '/');
	local nThresholdIndex = 1;
	local nMultIndex = 1;
	for _, sCrit in ipairs(aCrit) do
		local sCritThreshold = string.match(sCrit, '(%d+)[%-–]20');
		if sCritThreshold then
			aCritThreshold[nThresholdIndex] = tonumber(sCritThreshold) or 20;
			nThresholdIndex = nThresholdIndex + 1;
		end

		local sCritMult = string.match(sCrit, 'x(%d)');
		if sCritMult then
			aCritMult[nMultIndex] = tonumber(sCritMult) or 2;
			nMultIndex = nMultIndex + 1;
		end
	end

	-- Get some character data to pre-fill weapon info
	local nBAB = DB.getValue(nodeChar, 'attackbonus.base', 0);
	local nAttacks = math.floor((nBAB - 1) / 5) + 1;
	if nAttacks < 1 then nAttacks = 1; end
	local sMeleeAttackStat = DB.getValue(nodeChar, 'attackbonus.melee.ability', '');
	local sRangedAttackStat = DB.getValue(nodeChar, 'attackbonus.ranged.ability', '');

	-- Get special properties of weapon.
	local function getSpecialProperties()
		local bIsAcid = (sPropsLower:match('corrosive'));
		local bIsFlaming = (sPropsLower:match('flaming') or sPropsLower:match('igniting'));
		local bIsFrost = (sPropsLower:match('frost') or sPropsLower:match('icy'));
		local bIsShocking = (sPropsLower:match('shock'));
		return bIsAcid, bIsFlaming, bIsFrost, bIsShocking;
	end

	local bIsCorrosive, bIsFlaming, bIsFrost, bIsShocking = getSpecialProperties();
	if bMelee then
		local nodeWeapon = nodeWeapons.createChild();
		if nodeWeapon then
			DB.setValue(nodeWeapon, 'isidentified', 'number', nItemID);
			DB.setValue(nodeWeapon, 'shortcut', 'windowreference', 'item', '....inventorylist.' .. nodeItem.getName());

			if bDouble then
				DB.setValue(nodeWeapon, 'name', 'string', sName .. ' (2H)');
			else
				DB.setValue(nodeWeapon, 'name', 'string', sName);
			end
			DB.setValue(nodeWeapon, 'type', 'number', 0);
			DB.setValue(nodeWeapon, 'properties', 'string', sProps);

			DB.setValue(nodeWeapon, 'attacks', 'number', nAttacks);
			DB.setValue(nodeWeapon, 'attackstat', 'string', sMeleeAttackStat);
			DB.setValue(nodeWeapon, 'bonus', 'number', nAtkBonus);

			DB.setValue(nodeWeapon, 'critatkrange', 'number', aCritThreshold[1]);

			local nStatMult = 1;
			if string.match(sSubType, 'two%phanded') then nStatMult = 1.5; end

			addDamageToWeapon(
							nodeWeapon, aDamage, nBonus, 'strength', nStatMult, aCritMult, sFinalDamageType1, bIsCorrosive, bIsFlaming, bIsFrost, bIsShocking
			);
		end
	end

	-- Double head 1
	if bMelee and bDouble then
		local nodeWeapon = nodeWeapons.createChild();
		if nodeWeapon then
			DB.setValue(nodeWeapon, 'isidentified', 'number', nItemID);
			DB.setValue(nodeWeapon, 'shortcut', 'windowreference', 'item', '....inventorylist.' .. nodeItem.getName());

			DB.setValue(nodeWeapon, 'name', 'string', sName .. ' (D1)');
			DB.setValue(nodeWeapon, 'type', 'number', 0);
			DB.setValue(nodeWeapon, 'properties', 'string', sProps);

			DB.setValue(nodeWeapon, 'attacks', 'number', nAttacks);
			DB.setValue(nodeWeapon, 'attackstat', 'string', sMeleeAttackStat);
			if bTwoWeaponFight then
				DB.setValue(nodeWeapon, 'bonus', 'number', nAtkBonus - 2);
			else
				DB.setValue(nodeWeapon, 'bonus', 'number', nAtkBonus - 4);
			end

			DB.setValue(nodeWeapon, 'critatkrange', 'number', aCritThreshold[1]);

			addDamageToWeapon(
							nodeWeapon, aDamage, nBonus, 'strength', 1, aCritMult, sFinalDamageType1, bIsCorrosive, bIsFlaming, bIsFrost, bIsShocking
			);
		end
	end

	-- Double head 2
	if bMelee and bDouble then
		local nodeWeapon = nodeWeapons.createChild();
		if nodeWeapon then
			DB.setValue(nodeWeapon, 'isidentified', 'number', nItemID);
			DB.setValue(nodeWeapon, 'shortcut', 'windowreference', 'item', '....inventorylist.' .. nodeItem.getName());

			DB.setValue(nodeWeapon, 'name', 'string', sName .. ' (D2)');
			DB.setValue(nodeWeapon, 'type', 'number', 0);
			DB.setValue(nodeWeapon, 'properties', 'string', sProps);

			DB.setValue(nodeWeapon, 'attacks', 'number', 1);
			DB.setValue(nodeWeapon, 'attackstat', 'string', sMeleeAttackStat);
			if bTwoWeaponFight then
				DB.setValue(nodeWeapon, 'bonus', 'number', nAtkBonus - 2);
			else
				DB.setValue(nodeWeapon, 'bonus', 'number', nAtkBonus - 8);
			end

			if aCritThreshold[2] then
				DB.setValue(nodeWeapon, 'critatkrange', 'number', aCritThreshold[2]);
			else
				DB.setValue(nodeWeapon, 'critatkrange', 'number', aCritThreshold[1]);
			end

			addDamageToWeapon(
							nodeWeapon, aDamage, nBonus, 'strength', 0.5, aCritMult, sFinalDamageType2, bIsCorrosive, bIsFlaming, bIsFrost, bIsShocking
			);
		end
	end

	if bRanged then
		local nodeWeapon = nodeWeapons.createChild();
		if nodeWeapon then
			DB.setValue(nodeWeapon, 'isidentified', 'number', nItemID);
			DB.setValue(nodeWeapon, 'shortcut', 'windowreference', 'item', '....inventorylist.' .. nodeItem.getName());

			DB.setValue(nodeWeapon, 'name', 'string', sName);
			DB.setValue(nodeWeapon, 'type', 'number', 1);
			DB.setValue(nodeWeapon, 'properties', 'string', sProps);
			DB.setValue(nodeWeapon, 'rangeincrement', 'number', nRange);

			DB.setValue(nodeWeapon, 'attacks', 'number', nAttacks);
			DB.setValue(nodeWeapon, 'attackstat', 'string', sRangedAttackStat);
			DB.setValue(nodeWeapon, 'bonus', 'number', nAtkBonus);

			DB.setValue(nodeWeapon, 'critatkrange', 'number', aCritThreshold[1]);

			local sNameLower = sName:lower();
			local sStat;
			if sNameLower:find('sling') ~= nil then
				sStat = 'strength';
			elseif (sNameLower:find('shortbow') or sNameLower:find('longbow')) and sNameLower:find('composite') then
				if sPropsLower:find('adaptive') then
					sStat = 'strength';
				else
					sStat = '';
				end
			elseif sNameLower:find('shortbow') ~= nil or sNameLower:find('longbow') ~= nil then
				sStat = '';
			elseif sNameLower:find('crossbow') or sNameLower:find('net') or sNameLower:find('blowgun') then
				sStat = '';
			else
				sStat = 'strength';
			end
			addDamageToWeapon(nodeWeapon, aDamage, nBonus, sStat, 1, aCritMult, sFinalDamageType1, bIsCorrosive, bIsFlaming, bIsFrost, bIsShocking);
		end
	end
end

function onInit()

	local function onCharItemDelete(nodeItem)
		CharManager.removeFromArmorDB(nodeItem);
		CharManager.removeFromWeaponDB(nodeItem);

		local function removeFromSpellDB()
			local sItemType = DB.getValue(nodeItem, 'type', ''):lower();
			if sItemType == 'potion' or sItemType == 'wand' or sItemType == 'scroll' then
				local nodeSpellSet = InvManagerACIM.getSpellSet(DB.getChild(nodeItem, '...'), nodeItem.getPath());
				if nodeSpellSet then DB.deleteNode(nodeSpellSet); end
			end
		end

		removeFromSpellDB();
	end

	local function onCharItemAdd(nodeItem)
		DB.setValue(nodeItem, 'carried', 'number', 1);
		DB.setValue(nodeItem, 'showonminisheet', 'number', 1);

		if (string.lower(DB.getValue(nodeItem, 'type', '')) == 'goods and services') and StringManager.contains(
						{ 'mounts and related gear', 'transport', 'spellcasting and services' }, string.lower(DB.getValue(nodeItem, 'subtype', ''))
		) then DB.setValue(nodeItem, 'carried', 'number', 0); end

		CharManager.addToArmorDB(nodeItem);
		addToWeaponDB(nodeItem);

		InvManagerACIM.inventoryChanged(DB.getChild(nodeItem, '...'), nodeItem);
	end

	ItemManager.setCustomCharAdd(onCharItemAdd);
	ItemManager.setCustomCharRemove(onCharItemDelete);
end
