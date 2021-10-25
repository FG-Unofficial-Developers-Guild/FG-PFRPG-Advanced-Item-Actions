local CLASS_NAME_ALCHEMIST = "alchemist";
local CLASS_NAME_ANTIPALADIN	= "antipaladin";
local CLASS_NAME_ARCHANIST = "archanist";
local CLASS_NAME_BARD = "bard";
local CLASS_NAME_BLOODRAGER = "bloodrager";
local CLASS_NAME_CLERIC = "cleric";
local CLASS_NAME_DRUID = "druid";
local CLASS_NAME_HYUNTER = "hunter";
local CLASS_NAME_INQUISITOR = "inquisitor";
local CLASS_NAME_INVESTIGATOR = "investigator";
local CLASS_NAME_MAGUS = "magus";
local CLASS_NAME_ORACLE = "oracle";
local CLASS_NAME_PALADIN = "paladin";
local CLASS_NAME_RANGER = "ranger";
local CLASS_NAME_SHAMAN = "shaman";
local CLASS_NAME_SKALD = "skald";
local CLASS_NAME_SORCERER = "sorcerer";
local CLASS_NAME_SUMMONER = "summoner";
local CLASS_NAME_WARPRIEST = "warpriest";
local CLASS_NAME_WITCH = "witch";
local CLASS_NAME_WIZARD = "wizard";
local CLASS_NAME_ADEPT = "adept";
local CLASS_NAME_BLACKGUARD = "blackguard";
local CLASS_NAME_ASSASSIN = "assassin";

local function usingKelrugemExt()
	return (StringManager.contains(Extension.getExtensions(), "Full OverlayPackage") or
			StringManager.contains(Extension.getExtensions(), "Full OverlayPackage with alternative icons") or
			StringManager.contains(Extension.getExtensions(), "Full OverlayPackage with other icons"));
end

local function usingEnhancedItems()
	return StringManager.contains(Extension.getExtensions(), "FG-PFRPG-Enhanced-Items");
end

local function getWandCharges(nodeItem)
	if not nodeItem then
		return 0;
	end
	local nFieldCharges = DB.getValue(nodeItem, "charge", 0);
	local sName = DB.getValue(nodeItem, "name", '');
	local sCharges = sName:match("%p%d+%scharges%p");
	sCharges = sName:match("%d+%scharges");
	if sCharges then
		local nNameCharges = tonumber(sCharges:match("%d+"));
		if (nNameCharges and (nFieldCharges ~= 0)) then
			if (nFieldCharges < nNameCharges) then
				return nFieldCharges;
			end
		elseif usingEnhancedItems() and (nNameCharges and (nFieldCharges == 0)) then
			DB.setValue(nodeItem, "charge", 'number', nNameCharges);				-- write charges from name to database node "charge"
			sName = sName:gsub(sCharges, ''); sName = sName:gsub('%[%]', '');		-- trim charges from name
			DB.setValue(nodeItem, "name", 'string', StringManager.trim(sName));		-- write trimmed name back to database node "name"
			return nNameCharges;
		else
			return nNameCharges;
		end
	end
	return nFieldCharges;
end

function getSpellSet(nodeChar, sItemSource)
	if nodeChar and sItemSource ~= "" then
		--Debug.chat("getSpellSet", "sItemSource", sItemSource);
		for _,nodeSpellSet in pairs(DB.getChildren(nodeChar, "spellset")) do
			if DB.getValue(nodeSpellSet, "source_name") == sItemSource then
				return nodeSpellSet;
			end
		end
	end
end

local function trim_spell_name(string_spell_name)
	local string_spell_name_lower = string_spell_name:lower()
	local is_greater = (string.find(string_spell_name_lower, ', greater') ~= nil)
	local is_lesser = (string.find(string_spell_name_lower, ', lesser') ~= nil)
	local is_communal = (string.find(string_spell_name_lower, ', communal') ~= nil)
	local is_mass = (string.find(string_spell_name_lower, ', mass') ~= nil)
	local is_maximized = (string.find(string_spell_name_lower, 'maximized') ~= nil)
	local is_empowered = (string.find(string_spell_name_lower, 'empowered') ~= nil)
	local is_quickened = (string.find(string_spell_name_lower, 'quickened') ~= nil)

	-- remove tags from spell name
	if is_greater then
		string_spell_name = string_spell_name:gsub(', greater', '')
		string_spell_name = string_spell_name:gsub(', Greater', '')
	end
	if is_lesser then
		string_spell_name = string_spell_name:gsub(', lesser', '')
		string_spell_name = string_spell_name:gsub(', Lesser', '')
	end
	if is_communal then
		string_spell_name = string_spell_name:gsub(', communal', '')
		string_spell_name = string_spell_name:gsub(', Communal', '')
	end
	if is_mass then
		string_spell_name = string_spell_name:gsub(', mass', '')
		string_spell_name = string_spell_name:gsub(', Mass', '')
	end
	if is_maximized then
		string_spell_name = string_spell_name:gsub('maximized', '')
		string_spell_name = string_spell_name:gsub('Maximized', '')
	end
	if is_empowered then
		string_spell_name = string_spell_name:gsub('empowered', '')
		string_spell_name = string_spell_name:gsub('Empowered', '')
	end
	if is_quickened then
		string_spell_name = string_spell_name:gsub('quickened', '')
		string_spell_name = string_spell_name:gsub('Quickened', '')
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
	number_name_end = string.find(string_spell_name, 'D', string.len(string_spell_name)) or string.find(string_spell_name, 'M', string.len(string_spell_name))
	if number_name_end then string_spell_name = string_spell_name:sub(1, number_name_end - 1) end

	-- convert to lower-case
	string_spell_name = string_spell_name:lower()

	-- append relevant tags to end of spell name
	if is_greater then
		string_spell_name = string_spell_name .. 'greater'
	end
	if is_lesser then
		string_spell_name = string_spell_name .. 'lesser'
	end
	if is_communal then
		string_spell_name = string_spell_name .. 'communal'
	end
	if is_mass then
		string_spell_name = string_spell_name .. 'mass'
	end

	return string_spell_name
end

local function getSpellBetweenParenthesis(sItemName)
	local string_spell_name = sItemName:match("%b()");
	if string_spell_name then
		string_spell_name = string_spell_name:sub(2,-2);
		string_spell_name = trim_spell_name(string_spell_name)
		
		return string_spell_name
	end
end

local function getSpellAfterOf(sItemName)
	local sItemName = sItemName:gsub('%[.+%]', '')
	local i, j = sItemName:find("of ");
	if j ~= nil then
		local string_spell_name = sItemName:sub(j);
		string_spell_name = trim_spell_name(string_spell_name)

		return string_spell_name
	end
end

local function findSpellNode(sSpellName)
	return (DB.findNode("spelldesc." .. sSpellName .."@*") or
			DB.findNode("spelldesc.category." .. sSpellName .."@*") or
			DB.findNode("spell." .. sSpellName .. "@*") or
			DB.findNode("spell.category." .. sSpellName .. "@*") or
			DB.findNode("reference.spells." .. sSpellName .. "@*") or
			DB.findNode("reference.spells.category." .. sSpellName .. "@*"));
end

local function getSpellFromItemName(sItemName)
	-- Debug.chat("getSpellFromItemName", sItemName);
	if sItemName and sItemName ~= "" then
		local sSpellName = getSpellBetweenParenthesis(sItemName);
		-- Debug.chat("getSpellFromItemName.sSpellName.()", sSpellName);
		if sSpellName then
			local nodeSpell = findSpellNode(sSpellName);
			if not nodeSpell then
				sSpellName = getSpellAfterOf(sItemName);
				if sSpellName then
					nodeSpell = findSpellNode(sSpellName);
				end
			end
			return nodeSpell;
		else
			local sSpellName = getSpellAfterOf(sItemName);
			-- Debug.chat("getSpellFromItemName.sSpellName.of", sSpellName);
			if sSpellName then
				return findSpellNode(sSpellName);
			end
		end
	end
	return nil;
end

local function removeSpellClass(nodeItem, nodeSpellSet, nSpellLevel)
	if nodeItem and nodeSpellSet and nSpellLevel then
		local sItemType = string.lower(DB.getValue(nodeItem, "type"));
		if sItemType == "wand" then
			local nodeSpellLevel = DB.getChild(nodeSpellSet, "levels.level" .. nSpellLevel);
			local nTotalCast = DB.getValue(nodeSpellLevel, "totalcast", 0);
			local nAvailable = DB.getValue(nodeSpellSet, "availablelevel" .. nSpellLevel, 0);
			if usingEnhancedItems() then
				DB.removeHandler("charsheet.*.inventorylist.*.charge", "onUpdate", onItemChanged);
				if DB.getValue(nodeItem, "charge") ~= (nAvailable - nTotalCast) then
					DB.setValue(nodeItem, "charge", "number", nAvailable - nTotalCast);
				end
				DB.addHandler("charsheet.*.inventorylist.*.charge", "onUpdate", onItemChanged);
			end
		end
		DB.deleteNode(nodeSpellSet);
	end
end

local function updateSpellSet(nodeSpellSet, nUsesAvailable, nSpellLevel)
	if nodeSpellSet and nUsesAvailable > 0 and nSpellLevel >= 0 and nSpellLevel <= 9 then
		if DB.getValue(nodeSpellSet, "availablelevel" .. nSpellLevel) ~= nUsesAvailable then
			DB.setValue(nodeSpellSet, "availablelevel" .. nSpellLevel, "number", nUsesAvailable);
		end
	end
end

local function addSpell(nodeSource, nodeSpellClass, nLevel)
	-- Validate
	if not nodeSource or not nodeSpellClass or not nLevel then
		return nil;
	end
	
	-- Create the new spell entry
	local nodeTargetLevelSpells = nodeSpellClass.createChild("levels.level" .. nLevel .. ".spells");
	if not nodeTargetLevelSpells then
		return nil;
	end
	local nodeNewSpell = nodeTargetLevelSpells.createChild();
	if not nodeNewSpell then
		return nil;
	end
	
	-- Copy the spell details over
	DB.copyNode(nodeSource, nodeNewSpell);
	
	-- Convert the description field from module data
	SpellManager.convertSpellDescToString(nodeNewSpell);

	local nodeParent = nodeTargetLevelSpells.getParent();
	if nodeParent then
		-- Set the default cost for points casters
		local nCost = tonumber(string.sub(nodeParent.getName(), -1)) or 0;
		if nCost > 0 then
			nCost = ((nCost - 1) * 2) + 1;
		end
		DB.setValue(nodeNewSpell, "cost", "number", nCost);

		-- If spell level not visible, then make it so.
		local sAvailablePath = "....available" .. nodeParent.getName();
		local nAvailable = DB.getValue(nodeTargetLevelSpells, sAvailablePath, 1);
		if nAvailable <= 0 then
			DB.setValue(nodeTargetLevelSpells, sAvailablePath, "number", 1);
		end
	end
	
	-- Parse spell details to create actions
	if DB.getChildCount(nodeNewSpell, "actions") == 0 then
		SpellManager.parseSpell(nodeNewSpell);
	else -- bmos adding Kel's tag parsing
		local nodeActions = nodeNewSpell.getChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.getChildren();
			if nodeAction then
				for k, v in pairs(nodeAction) do
					if DB.getValue(v, "type") == "cast" then
						if usingKelrugemExt() then SpellManager.addTags(nodeNewSpell, v) end
						DB.setValue(v, 'usereset', 'string', 'consumable')	-- bmos setting spell as consumable (no reset on rest)
					end
				end
			end
		end
	end
	
	return nodeNewSpell;
end

local function addSpellToActionList(nodeChar, nodeSpell, sDisplayName, nUsesAvailable, nSpellLevel, nCL, sItemSource)
	if not nodeChar or not nodeSpell or sDisplayName == "" or sItemSource == "" or nSpellLevel < 0 or nSpellLevel > 9 then
		return;
	end
	local nodeSpellSet = nodeChar.createChild("spellset");
	if not nodeSpellSet then
		return;
	end
	local nodeNewSpellClass = nodeSpellSet.createChild();
	--Debug.chat("addActionItem", "nodeSpellSet", nodeSpellSet);
	--Debug.chat("addActionItem", "nodeNewSpellClass", nodeNewSpellClass);
	if nodeNewSpellClass then
		DB.setValue(nodeNewSpellClass, "label", "string", sDisplayName);
		DB.setValue(nodeNewSpellClass, "castertype", "string", "spontaneous");
		DB.setValue(nodeNewSpellClass, "availablelevel" .. nSpellLevel, "number", nUsesAvailable);
		DB.setValue(nodeNewSpellClass, "source_name", "string", sItemSource);
		DB.setValue(nodeNewSpellClass, "cl", "number", nCL);
		DB.setValue(nodeChar, "spellmode", "string", "standard");
		--Debug.chat("addActionItem", "nodeSpell", nodeSpell);
		--Debug.chat("addActionItem", "nodeNewSpellClass", nodeNewSpellClass);
		--Debug.chat("addActionItem", "nSpellLevel", nSpellLevel);
		local nodeNew = addSpell(nodeSpell, nodeNewSpellClass, nSpellLevel);
		--Debug.chat("addActionItem", "nodeNew", nodeNew);
		if nodeNew then
			for _,nodeAction in pairs(DB.getChildren(nodeNew, "actions")) do
				if DB.getValue(nodeAction, "type", "") == "cast" then
					DB.setValue(nodeAction, "usereset", "string", "consumable");
				end
			end
		end
	end
	return nodeSpellSet, nodeNewSpellClass;
end

local function getCasterLevelByClass(sClassName, sSpellClassLevel)
	if sSpellClassLevel == "0" or sSpellClassLevel == "1" then
		return 1;
	end
	local sLowerClassName = sClassName:lower();
	--Debug.chat(sLowerClassName);
	if StringManager.contains({CLASS_NAME_ALCHEMIST, CLASS_NAME_ANTIPALADIN, CLASS_NAME_BARD, CLASS_NAME_BLOODRAGER, CLASS_NAME_HUNTER, CLASS_NAME_INQUISITOR, CLASS_NAME_MAGUS, CLASS_NAME_PALADIN, CLASS_NAME_RANGER, CLASS_NAME_SKALD, CLASS_NAME_SUMMONER, CLASS_NAME_WARPRIEST}, sLowerClassName) then
		return (tonumber(sSpellClassLevel)-1) * 3 + 1;
	elseif StringManager.contains({CLASS_NAME_ARCHANIST, CLASS_NAME_ORACLE, CLASS_NAME_SORCERER}, sLowerClassName) then
		return tonumber(sSpellClassLevel) * 2;
	elseif StringManager.contains({CLASS_NAME_CLERIC, CLASS_NAME_DRUID, CLASS_NAME_SHAMAN, CLASS_NAME_WITCH, CLASS_NAME_WIZARD}, sLowerClassName) then
		return (tonumber(sSpellClassLevel)-1) * 2 + 1;
	elseif StringManager.contains({CLASS_NAME_ADEPT}, sLowerClassName) then
		return (tonumber(sSpellClassLevel)-1) * 4;
	elseif StringManager.contains({CLASS_NAME_BLACKGUARD, CLASS_NAME_ASSASSIN}, sLowerClassName) then
		return tonumber(sSpellClassLevel) * 2 - 1;
	end
	return nil;
end

local function getSpellLevel(nodeSpell)
	if not nodeSpell then
		return 0;
	end;
	local nSpellLevel = 0;
	local sSpellLevelField = DB.getValue(nodeSpell, "level", "");
	local nLowestCasterLevel = 0;
	if sSpellLevelField ~= "" then
		local aSpellClassChoices = StringManager.split(sSpellLevelField, ",");
		for _, sSpellClassChoice in ipairs(aSpellClassChoices) do
			local sComboClassName, sSpellClassLevel = sSpellClassChoice:match("(.*) (%d)");
			if sComboClassName then
				local aClassChoices = StringManager.split(sComboClassName, "/", true);
				for _,sClassChoice in ipairs(aClassChoices) do
					--Debug.chat("getSpellLevel", "sClassChoice", sClassChoice);
					--Debug.chat("getSpellLevel", "sSpellClassLevel", sSpellClassLevel);
					local nCasterLevel = getCasterLevelByClass(sClassChoice, sSpellClassLevel);
					if nCasterLevel ~= nil and (nLowestCasterLevel == 0 or nCasterLevel < nLowestCasterLevel) then
						nLowestCasterLevel = nCasterLevel;
						nSpellLevel = tonumber(sSpellClassLevel);
					end
				end
			end
		end
	end
	--Debug.chat("getSpellLevel", "nSpellLevel", nSpellLevel);
	--Debug.chat("getSpellLevel", "nLowestCasterLevel", nLowestCasterLevel);
	return nSpellLevel, nLowestCasterLevel;
end

local function getCL(nodeItem)
	if not nodeItem then
		return 0;
	end
	local nCL = DB.getValue(nodeItem, "cl", 0);
	local sName = DB.getValue(nodeItem, "name", '');
	local sCL = sName:match("%pCL%s%d+%p");
	if sCL then
		local nNameCL = tonumber(sCL:match("%d+"));
		if nNameCL then
			DB.setValue(nodeItem, "cl", 'number', nNameCL);	-- write CL from name to database node "cl"
		end
		return nNameCL or nCL;
	end
	return nCL;
end

local bAnnnounced = false
function inventoryChanged(nodeChar, nodeItem)
	if nodeChar and nodeItem then
		-- Debug.chat("InventoryChanged", "nodeChar", nodeChar);
		-- Debug.chat("InventoryChanged", "nodeItem", nodeItem);
		local sItemType = string.lower(DB.getValue(nodeItem, "type", ""));
		local bisPotion = sItemType:match("potion")
		local bisWand = sItemType:match("wand")
		local bisScroll = sItemType:match("scroll")
		if not (bisPotion or bisWand or bisScroll) then
			return;
		end
		if DB.getValue(nodeItem, "isidentified") == 0 then
			return;
		end
		local nUsesAvailable = 0;
		local sSource = nodeItem.getPath();
		if bisPotion or bisScroll then
			nUsesAvailable = nodeItem.getChild("count").getValue();
		elseif bisWand then
			nUsesAvailable = getWandCharges(nodeItem);
			if nUsesAvailable == 0 then
				if not bAnnnounced then
					ChatManager.SystemMessage(string.format('%s has no remaining charges listed. Please check it for accuracy.', DB.getValue(nodeItem, 'name', 'This wand')))
					bAnnnounced = true
				end
				nUsesAvailable = 50
			end
		end
		local sItemName = nodeItem.getChild("name").getValue();
		local nodeSpell = getSpellFromItemName(sItemName);
		--Debug.chat("inventoryChanged", "nodeSpell", nodeSpell);
		if not nodeSpell then
			return;
		end
		local nSpellLevel, nMinCasterLevel = getSpellLevel(nodeSpell);
		local nCL = getCL(nodeItem);
		if nCL < nMinCasterLevel then
			nCL = nMinCasterLevel;
		end;
		--Debug.chat("inventoryChanged", "nSpellLevel", nSpellLevel);
		local nodeSpellSet = getSpellSet(nodeChar, nodeItem.getPath());
		-- Debug.chat("inventoryChanged", "nodeSpellSet", nodeSpellSet);
		local nCarried = DB.getValue(nodeItem, "carried", 1)
		-- Debug.chat("inventoryChanged", "nCarried", nCarried);
		if nCarried ~= 2 then
			if nodeSpellSet then
				removeSpellClass(nodeItem, nodeSpellSet, nSpellLevel);
			end
		else
			if nodeSpellSet then
				updateSpellSet(nodeSpellSet, nUsesAvailable, nSpellLevel);
			elseif nCarried == 2 then
				nodeSpellSet = addSpellToActionList(nodeChar, nodeSpell, sItemName, nUsesAvailable, nSpellLevel, nCL, nodeItem.getPath());
			end
		end
	end
end

function onItemChanged(nodeField)
	local nodeChar = DB.getChild(nodeField, "....");
	if nodeChar then
		local nodeItem = DB.getChild(nodeField, "..");
		if nodeItem then
			inventoryChanged(nodeChar, nodeItem);
		end
	end
end

function onInit()
    DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", onItemChanged);
    DB.addHandler("charsheet.*.inventorylist.*.carried", "onUpdate", onItemChanged);
    DB.addHandler("charsheet.*.inventorylist.*.count", "onUpdate", onItemChanged);
	if usingEnhancedItems() then DB.addHandler("charsheet.*.inventorylist.*.charge", "onUpdate", onItemChanged); end
end