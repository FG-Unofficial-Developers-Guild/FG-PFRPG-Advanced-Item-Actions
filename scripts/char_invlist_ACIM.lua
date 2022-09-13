--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local CLASS_NAME_ALCHEMIST = 'alchemist';
local CLASS_NAME_ANTIPALADIN = 'antipaladin';
local CLASS_NAME_ARCHANIST = 'archanist';
local CLASS_NAME_BARD = 'bard';
local CLASS_NAME_BLOODRAGER = 'bloodrager';
local CLASS_NAME_CLERIC = 'cleric';
local CLASS_NAME_DRUID = 'druid';
local CLASS_NAME_HUNTER = 'hunter';
local CLASS_NAME_INQUISITOR = 'inquisitor';
local CLASS_NAME_INVESTIGATOR = 'investigator';
local CLASS_NAME_MAGUS = 'magus';
local CLASS_NAME_ORACLE = 'oracle';
local CLASS_NAME_PALADIN = 'paladin';
local CLASS_NAME_RANGER = 'ranger';
local CLASS_NAME_SHAMAN = 'shaman';
local CLASS_NAME_SKALD = 'skald';
local CLASS_NAME_SORCERER = 'sorcerer';
local CLASS_NAME_SUMMONER = 'summoner';
local CLASS_NAME_WARPRIEST = 'warpriest';
local CLASS_NAME_WITCH = 'witch';
local CLASS_NAME_WIZARD = 'wizard';
local CLASS_NAME_ADEPT = 'adept';
local CLASS_NAME_BLACKGUARD = 'blackguard';
local CLASS_NAME_ASSASSIN = 'assassin';

local _sSpellset = 'spellset'

-- luacheck: globals inventoryChanged getSpellSet

local function usingExt(sExt) return StringManager.contains(Extension.getExtensions(), sExt); end

function getSpellSet(nodeChar, sItemSource)
	if nodeChar and sItemSource ~= '' then
		-- Debug.chat('getSpellSet', 'sItemSource', sItemSource);
		for _, nodeSpellSet in pairs(DB.getChildren(nodeChar, _sSpellset)) do
			-- Debug.chat(sItemSource, nodeSpellSet);
			if DB.getValue(nodeSpellSet, 'source_name') == sItemSource then return nodeSpellSet; end
		end
	end
end

local function trim_spell_key(string_spell_name)
	local tFormats = { ['Greater'] = false, ['Lesser'] = false, ['Communal'] = false, ['Mass'] = false };
	local tTrims = { ['Maximized'] = false, ['Heightened'] = false, ['Empowered'] = false, ['Quickened'] = false };

	-- remove tags from spell name
	for s, _ in pairs(tFormats) do
		if string_spell_name:gsub(', '  .. s, '') or string_spell_name:gsub(', '  .. s:lower(), '') then
			tTrims[s] = true
		end
	end
	for s, _ in pairs(tTrims) do
		if string_spell_name:gsub(', '  .. s, '') or string_spell_name:gsub(', '  .. s:lower(), '') then
			tTrims[s] = true
		end
	end

	-- remove certain sets of characters
	string_spell_name = string_spell_name:gsub('%u%u%u%u', '')
	string_spell_name = string_spell_name:gsub('%u%u%u', '')
	string_spell_name = string_spell_name:gsub('AP%d+', '')
	string_spell_name = string_spell_name:gsub('%u%u', '')
	string_spell_name = string_spell_name:gsub('.+:', '')
	string_spell_name = string_spell_name:gsub(',.+', '')
	string_spell_name = string_spell_name:gsub('%[.-%]', '')
	string_spell_name = string_spell_name:gsub('%(.-%)', '')
	string_spell_name = string_spell_name:gsub('%A+', '')

	-- remove uppercase D or M at end of name
	local number_name_end = string.find(string_spell_name, 'D', string.len(string_spell_name)) or
					                        string.find(string_spell_name, 'M', string.len(string_spell_name))
	if number_name_end then string_spell_name = string_spell_name:sub(1, number_name_end - 1) end

	-- convert to lower-case
	string_spell_name = string_spell_name:lower()

	-- append relevant tags to end of spell name
	for s, v in pairs(tFormats) do
		if tTrims[v] then
			string_spell_name = string_spell_name .. ', ' .. s
		end
	end

	return string_spell_name
end

local function trim_spell_name(string_spell_name)
	string_spell_name = string_spell_name:lower();
	-- check for potentional double brackets like in 'wand (magic missile (3rd))'
	string_spell_name = string_spell_name:gsub('%b()', '')
	string_spell_name = string_spell_name:gsub('%W', '');
	string_spell_name = string_spell_name:gsub('heightened', '');

	return string_spell_name
end

local function getSpellFromItemName(sItemName)
	local tLoadedModules;

	local function getLoadedModules()
		tLoadedModules = {};
		local tAllModules = Module.getModules();
		for _,sModuleName in ipairs(tAllModules) do
			local tModuleData = Module.getModuleInfo(sModuleName);
			if tModuleData.loaded then
				tLoadedModules[#tLoadedModules+1] = tModuleData.name;
			end
		end
	end

	local function findSpellNode(sSpellName)
		local nodeSpellFast = DB.findNode('spelldesc.' .. trim_spell_key(sSpellName) .. '@*');
		if nodeSpellFast then
			return nodeSpellFast;
		end

		sSpellName = trim_spell_name(sSpellName);
		getLoadedModules();
		for _,sModuleName in ipairs(tLoadedModules) do
			local nodeSpellModule = DB.findNode('reference.spells' .. '@' .. sModuleName);
			if nodeSpellModule then
				for _,nodeSpell in pairs(nodeSpellModule.getChildren()) do
					local sModuleSpellName = DB.getValue(nodeSpell, 'name', '');
					if sModuleSpellName ~= '' then
						if trim_spell_name(sModuleSpellName) == sSpellName then
							return nodeSpell;
						end
					end
				end
			end
		end
	end

	local function getSpellBetweenParentheses()
		local string_spell_name = sItemName:match('%b()');
		if string_spell_name then
			return string_spell_name:sub(2, -2);
		end
	end

	local function getSpellAfterOf()
		sItemName = sItemName:gsub('%[.+%]', '')
		local _, j = sItemName:find('of ');
		if j then
			return sItemName:sub(j);
		end
	end

	if sItemName and sItemName ~= '' then
		local sSpellName = getSpellBetweenParentheses();
		if sSpellName then
			return findSpellNode(sSpellName);
		else
			return findSpellNode(getSpellAfterOf())
		end
	end
end

local function onItemChanged(nodeField)
	local nodeChar = DB.getChild(nodeField, '....');
	if ActorManager.resolveActor(nodeChar) then
		local nodeItem = nodeField.getParent();
		inventoryChanged(nodeChar, nodeItem, nodeField);
	end
end

local function addSpell(nodeSource, nodeSpellClass, nLevel)
	-- Validate
	if not nodeSource or not nodeSpellClass or not nLevel then return nil; end

	-- Create the new spell entry
	local nodeTargetLevelSpells = nodeSpellClass.createChild('levels.level' .. nLevel .. '.spells');
	if not nodeTargetLevelSpells then return nil; end
	local nodeNewSpell = nodeTargetLevelSpells.createChild();
	if not nodeNewSpell then return nil; end

	-- Copy the spell details over
	DB.copyNode(nodeSource, nodeNewSpell);

	-- Convert the description field from module data
	SpellManager.convertSpellDescToString(nodeNewSpell);

	local nodeParent = nodeTargetLevelSpells.getParent();
	if nodeParent then
		-- Set the default cost for points casters
		local nCost = tonumber(string.sub(nodeParent.getName(), -1)) or 0;
		if nCost > 0 then nCost = ((nCost - 1) * 2) + 1; end
		DB.setValue(nodeNewSpell, 'cost', 'number', nCost);

		-- If spell level not visible, then make it so.
		local sAvailablePath = '....available' .. nodeParent.getName();
		local nAvailable = DB.getValue(nodeTargetLevelSpells, sAvailablePath, 1);
		if nAvailable <= 0 then DB.setValue(nodeTargetLevelSpells, sAvailablePath, 'number', 1); end
	end

	-- Parse spell details to create actions
	if DB.getChildCount(nodeNewSpell, 'actions') == 0 then
		SpellManager.parseSpell(nodeNewSpell);
	else -- bmos adding Kel's tag parsing
		local nodeActions = nodeNewSpell.getChild('actions');
		if nodeActions then
			local nodeAction = nodeActions.getChildren();
			if nodeAction then
				for _, v in pairs(nodeAction) do
					if DB.getValue(v, 'type') == 'cast' then
						if SpellManager.addTags then SpellManager.addTags(nodeNewSpell, v) end -- luacheck: globals SpellManager.addTags
						DB.setValue(v, 'usereset', 'string', 'consumable') -- bmos setting spell as consumable (no reset on rest)
					end
				end
			end
		end
	end

	return nodeNewSpell;
end

local function getCasterLevelByClass(sClassName, sSpellClassLevel)
	if sSpellClassLevel == '0' or sSpellClassLevel == '1' then return 1; end
	local sLowerClassName = sClassName:lower();
	if StringManager.contains(
					{
						CLASS_NAME_ALCHEMIST, CLASS_NAME_ANTIPALADIN, CLASS_NAME_BARD, CLASS_NAME_BLOODRAGER, CLASS_NAME_HUNTER, CLASS_NAME_INQUISITOR,
      CLASS_NAME_INVESTIGATOR, CLASS_NAME_MAGUS, CLASS_NAME_PALADIN, CLASS_NAME_RANGER, CLASS_NAME_SKALD, CLASS_NAME_SUMMONER,
      CLASS_NAME_WARPRIEST,
					}, sLowerClassName
	) then
		return (tonumber(sSpellClassLevel) - 1) * 3 + 1;
	elseif StringManager.contains({ CLASS_NAME_ARCHANIST, CLASS_NAME_ORACLE, CLASS_NAME_SORCERER }, sLowerClassName) then
		return tonumber(sSpellClassLevel) * 2;
	elseif StringManager.contains(
					{ CLASS_NAME_CLERIC, CLASS_NAME_DRUID, CLASS_NAME_SHAMAN, CLASS_NAME_WITCH, CLASS_NAME_WIZARD }, sLowerClassName
	) then
		return (tonumber(sSpellClassLevel) - 1) * 2 + 1;
	elseif StringManager.contains({ CLASS_NAME_ADEPT }, sLowerClassName) then
		return (tonumber(sSpellClassLevel) - 1) * 4;
	elseif StringManager.contains({ CLASS_NAME_BLACKGUARD, CLASS_NAME_ASSASSIN }, sLowerClassName) then
		return tonumber(sSpellClassLevel) * 2 - 1;
	end
	return nil;
end

local bAnnnounced = false
local function getUsesAvailable(nodeItem, bWand)
	local nUsesAvailable;
	if bWand then

		local function getWandCharges()
			local nFieldCharges = DB.getValue(nodeItem, 'charge', 0);
			local sName = DB.getValue(nodeItem, 'name', '');
			local sCharges = sName:match('%d+%s+charges');
			if sCharges then
				local nNameCharges = tonumber(sCharges:match('%d+'));
				if (nNameCharges and (nFieldCharges ~= 0)) then
					if (nFieldCharges < nNameCharges) then return nFieldCharges; end
				elseif usingExt('FG-PFRPG-Enhanced-Items') and (nNameCharges and (nFieldCharges == 0)) then
					DB.removeHandler('charsheet.*.inventorylist.*.charge', 'onUpdate', onItemChanged)
					DB.setValue(nodeItem, 'charge', 'number', nNameCharges); -- write charges from name to database node 'charge'
					sName = sName:gsub(sCharges, ''):gsub('%[%]', ''); -- trim charges from name
					DB.setValue(nodeItem, 'name', 'string', StringManager.trim(sName)); -- write trimmed name back to database node 'name'
					DB.addHandler('charsheet.*.inventorylist.*.charge', 'onUpdate', onItemChanged)
					return nNameCharges;
				else
					return nNameCharges;
				end
			end
			return nFieldCharges;
		end

		nUsesAvailable = getWandCharges();
		if nUsesAvailable == 0 then
			if not bAnnnounced then
				ChatManager.SystemMessage(
								string.format(
												'%s has no remaining charges listed. Please check it for accuracy.', DB.getValue(nodeItem, 'name', 'This wand')
								)
				)
				bAnnnounced = true
			end
			nUsesAvailable = 50
		end
	else
		nUsesAvailable = nodeItem.getChild('count').getValue();
	end
	return nUsesAvailable
end

function inventoryChanged(nodeChar, nodeItem, nodeTrigger)
	if not (nodeChar and nodeItem) then return; end

	if DB.getValue(nodeItem, 'isidentified') == 0 then return; end

	local sItemType = string.lower(DB.getValue(nodeItem, 'type', ''));
	local bPotion = sItemType:match('potion')
	local bWand = sItemType:match('wand')
	local bScroll = sItemType:match('scroll')
	if not (bPotion or bWand or bScroll) then return; end

	local bAdvancedItem -- boolean value to be true if item is an equipped wand/spell/scroll

	local nUsesAvailable = getUsesAvailable(nodeItem, bWand);

	local sItemName = nodeItem.getChild('name').getValue();

	local nodeSpell = getSpellFromItemName(sItemName);
	if not nodeSpell then return; end

	local function getSpellLevel()
		if not nodeSpell then return 0; end
		local nSpellLevel = 0;
		local sSpellLevelField = DB.getValue(nodeSpell, 'level', '');
		local nLowestCasterLevel = 0;
		if sSpellLevelField ~= '' then
			local aSpellClassChoices = StringManager.split(sSpellLevelField, ',');
			for _, sSpellClassChoice in ipairs(aSpellClassChoices) do
				local sComboClassName, sSpellClassLevel = sSpellClassChoice:match('(.*) (%d)');
				if sComboClassName then
					local aClassChoices = StringManager.split(sComboClassName, '/', true);
					for _, sClassChoice in ipairs(aClassChoices) do
						local nCasterLevel = getCasterLevelByClass(sClassChoice, sSpellClassLevel);
						if nCasterLevel ~= nil and (nLowestCasterLevel == 0 or nCasterLevel < nLowestCasterLevel) then
							nLowestCasterLevel = nCasterLevel;
							nSpellLevel = tonumber(sSpellClassLevel);
						end
					end
				end
			end
		end
		return nSpellLevel, nLowestCasterLevel;
	end

	local nSpellLevel, nMinCasterLevel = getSpellLevel();

	local function getCL()
		if not nodeItem then return 0; end
		local nCL = DB.getValue(nodeItem, 'cl', 0);
		local sName = DB.getValue(nodeItem, 'name', '');
		local sCL = sName:match('%pCL%s*(%d+)%p');
		if sCL then
			local nNameCL = tonumber(sCL);
			if nNameCL then
				DB.setValue(nodeItem, 'cl', 'number', nNameCL); -- write CL from name to database node 'cl'
			end
			return nNameCL or nCL;
		end
		return nCL;
	end

	local nCL = getCL();
	if nCL < nMinCasterLevel then nCL = nMinCasterLevel; end

	local nCarried = DB.getValue(nodeItem, 'carried', 1)

	local nodeSpellSet = getSpellSet(nodeChar, nodeItem.getPath());
	if nodeSpellSet then

		local function updateUsesRemaining()
			local function writeUses(fieldName)
				-- don't update a field that triggered this code to be run
				if not (nodeTrigger and nodeTrigger.getPath():match('.+%.inventorylist%..+%.' .. fieldName)) then
					DB.removeHandler('charsheet.*.inventorylist.*.' .. fieldName, 'onUpdate', onItemChanged);
					local nodeSpellLevel = DB.getChild(nodeSpellSet, 'levels.level' .. nSpellLevel);
					local nUsesRemaining = DB.getValue(nodeSpellSet, 'availablelevel' .. nSpellLevel, 0) - DB.getValue(nodeSpellLevel, 'totalcast', 0);
					DB.setValue(nodeItem, fieldName, 'number', nUsesRemaining);
					DB.addHandler('charsheet.*.inventorylist.*.' .. fieldName, 'onUpdate', onItemChanged);
				end
			end

			if bWand then
				if usingExt('FG-PFRPG-Enhanced-Items') then
					writeUses('charge')
				end
			else
				writeUses('count')
			end
		end
		updateUsesRemaining()

		if nCarried ~= 2 then

			local function removeSpellClass()
				if nodeItem and nodeSpellSet and nSpellLevel then
					DB.deleteNode(nodeSpellSet);
				end
			end

			removeSpellClass();
		else

			local function updateSpellSet()
				if nodeSpellSet and nUsesAvailable > 0 and nSpellLevel >= 0 and nSpellLevel <= 9 then
					DB.setValue(nodeSpellSet, 'availablelevel' .. nSpellLevel, 'number', nUsesAvailable);
				end
			end

			updateSpellSet();

			bAdvancedItem = true;
		end
	elseif nCarried == 2 then

		local function addSpellset()
			if not nodeChar or not nodeSpell or sItemName == '' or nodeItem.getPath() == '' or nSpellLevel < 0 or nSpellLevel > 9 then return; end
			local nodeNewSpellClass = nodeChar.createChild(_sSpellset).createChild();
			if nodeNewSpellClass then
				DB.setValue(nodeNewSpellClass, 'label', 'string', sItemName);
				DB.setValue(nodeNewSpellClass, 'castertype', 'string', 'spontaneous');
				DB.setValue(nodeNewSpellClass, 'availablelevel' .. nSpellLevel, 'number', nUsesAvailable);
				DB.setValue(nodeNewSpellClass, 'source_name', 'string', nodeItem.getPath());
				DB.setValue(nodeNewSpellClass, 'cl', 'number', nCL);
				DB.setValue(nodeChar, 'spellmode', 'string', 'standard');
				local nodeNew = addSpell(nodeSpell, nodeNewSpellClass, nSpellLevel);
				if nodeNew then
					for _, nodeAction in pairs(DB.getChildren(nodeNew, 'actions')) do
						if DB.getValue(nodeAction, 'type', '') == 'cast' then DB.setValue(nodeAction, 'usereset', 'string', 'consumable'); end
					end
				end
			end
		end

		addSpellset();
	end
	return bAdvancedItem
end

function onInit()
	DB.addHandler('charsheet.*.inventorylist.*.isidentified', 'onUpdate', onItemChanged);
	DB.addHandler('charsheet.*.inventorylist.*.carried', 'onUpdate', onItemChanged);
	DB.addHandler('charsheet.*.inventorylist.*.count', 'onUpdate', onItemChanged);
	if usingExt('FG-PFRPG-Enhanced-Items') then DB.addHandler('charsheet.*.inventorylist.*.charge', 'onUpdate', onItemChanged); end
	if usingExt('Advanced Charsheet') then _sSpellset = 'itemspellset'; end
end

function onClose()
	DB.removeHandler('charsheet.*.inventorylist.*.isidentified', 'onUpdate', onItemChanged);
	DB.removeHandler('charsheet.*.inventorylist.*.carried', 'onUpdate', onItemChanged);
	DB.removeHandler('charsheet.*.inventorylist.*.count', 'onUpdate', onItemChanged);
	if usingExt('FG-PFRPG-Enhanced-Items') then DB.removeHandler('charsheet.*.inventorylist.*.charge', 'onUpdate', onItemChanged); end
end