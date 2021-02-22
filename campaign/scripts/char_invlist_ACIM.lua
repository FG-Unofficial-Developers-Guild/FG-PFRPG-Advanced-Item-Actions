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
	return (StringManager.contains(Extension.getExtensions(), "PFRPG - Enhanced Items v4.21") or
			StringManager.contains(Extension.getExtensions(), "PFRPG - Enhanced Items"));
end

function onInit()
    DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", onItemChanged);
    DB.addHandler("charsheet.*.inventorylist.*.carried", "onUpdate", onItemChanged);
    DB.addHandler("charsheet.*.inventorylist.*.count", "onUpdate", onItemChanged);
	if usingEnhancedItems() then DB.addHandler("charsheet.*.inventorylist.*.charge", "onUpdate", onItemChanged); end
end

function onItemChanged(nodeField)
	if not nodeField then
		return;
	end
	local nodeChar = DB.getChild(nodeField, "....");
	if nodeChar then
		local nodeItem = DB.getChild(nodeField, "..");
		if nodeItem then
			inventoryChanged(nodeChar, nodeItem);
		end
	end
end

local bAnnnounced = false
function inventoryChanged(nodeChar, nodeItem)
	if nodeChar and nodeItem then
		--Debug.chat("InventoryChanged", "nodeChar", nodeChar);
		--Debug.chat("InventoryChanged", "nodeItem", nodeItem);
		local sItemType = string.lower(DB.getValue(nodeItem, "type", ""));
		if not (sItemType == "potion" or sItemType == "wand" or sItemType == "scroll") then
			return;
		end
		if DB.getValue(nodeItem, "isidentified") == 0 then
			return;
		end
		local nUsesAvailable = 0;
		local sSource = nodeItem.getPath();
		if sItemType == "potion" or sItemType == "scroll" then
			nUsesAvailable = nodeItem.getChild("count").getValue();
		elseif sItemType == "wand" then
			nUsesAvailable = getWandCharges(nodeItem);
			if nUsesAvailable == 0 then
				if not bAnnnounced then
					ChatManager.SystemMessage(string.format('%s has no remaining charges listed. Please check it for accuracy.', DB.getValue(nodeItem, 'name', 'A wand')))
					bAnnnounced = true
				end
				nUsesAvailable = 50
			end
		end
		local sItemName = nodeItem.getChild("name").getValue();
		local nodeSpellSet = getSpellSet(nodeChar, nodeItem.getPath());
		--Debug.chat("inventoryChanged", "nodeSpellSet", nodeSpellSet);
		--Debug.chat("inventoryChanged", "nodeSpellClass", nodeSpellClass);
		--Debug.chat("inventoryChanged", "nodeItem.carried", nodeItem.getChild("carried").getValue());
		local nodeSpell = getSpellFromItemName(sItemName);
		if not nodeSpell then
			return;
		end
		--Debug.chat("inventoryChanged", "nodeSpell", nodeSpell);
		local nSpellLevel, nMinCasterLevel = getSpellLevel(nodeSpell);
		local nCL = getCL(nodeItem);
		if nCL < nMinCasterLevel then
			nCL = nMinCasterLevel;
		end;
		--Debug.chat("inventoryChanged", "nSpellLevel", nSpellLevel);
		local nCarried = DB.getValue(nodeItem, "carried", 1)
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

function getSpellBetweenParenthesis(sItemName)
	local sSpellName = sItemName:match("%b()");
	if sSpellName then
		sSpellName = sSpellName:sub(2,-2);
		sSpellName = sSpellName:gsub(" ", "");
		return sSpellName:lower();
	end
	return "";
end

function getSpellAfterOf(sItemName)
	local i, j = sItemName:find("of ");
	if j ~= nil then
		local sSpellName = sItemName:sub(j);
		sSpellName = sSpellName:gsub(" ", "");
		sSpellName = sSpellName:match("%a+");
		return sSpellName:lower();
	end
	return "";
end

function getSpellFromItemName(sItemName)
	local nodeSpell = nil;
	if sItemName ~= "" then
		local sSpellName = getSpellBetweenParenthesis(sItemName);
		sSpellName = sSpellName:gsub('%p', '')
		if sSpellName ~= "" then
			nodeSpell = DB.findNode("spelldesc." .. sSpellName .."@*");
			if not nodeSpell then nodeSpell = DB.findNode("reference.spells." .. sSpellName .. "@*") end
			if not nodeSpell then
				sSpellName = getSpellAfterOf(sItemName);
				sSpellName = sSpellName:gsub('%p', '')
				if sSpellName ~= "" then
					nodeSpell = DB.findNode("spelldesc." .. sSpellName .."@*");
					if not nodeSpell then nodeSpell = DB.findNode("reference.spells." .. sSpellName .. "@*") end
					return nodeSpell;
				end
			else
				return nodeSpell;
			end
		else
			local sSpellName = getSpellAfterOf(sItemName);
			sSpellName = sSpellName:gsub('%p', '')
			if sSpellName ~= "" then
				nodeSpell = DB.findNode("spelldesc." .. sSpellName .."@*");
				if not nodeSpell then nodeSpell = DB.findNode("reference.spells." .. sSpellName .. "@*") end
				return nodeSpell;
			end
		end
	end
	return nil;
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

function removeSpellClass(nodeItem, nodeSpellSet, nSpellLevel)
	if nodeItem and nodeSpellSet and nSpellLevel then
		local sItemType = DB.getValue(nodeItem, "type");
		if sItemType == "Wand" then
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

function updateSpellSet(nodeSpellSet, nUsesAvailable, nSpellLevel)
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
	elseif usingKelrugemExt() then											-- bmos adding Kel's tag parsing
		local nodeActions = nodeNewSpell.createChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.getChildren();
			if nodeAction then
				for k, v in pairs(nodeAction) do
					if DB.getValue(v, "type") == "cast" then
						SpellManager.addTags(nodeNewSpell, v);
						DB.setValue(v, 'usereset', 'string', 'consumable')	-- bmos setting spell as consumable (no reset on rest)
					end
				end
			end
		end
	end
	
	return nodeNewSpell;
end

function addSpellToActionList(nodeChar, nodeSpell, sDisplayName, nUsesAvailable, nSpellLevel, nCL, sItemSource)
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
			if StringManager.contains(Extension.getExtensions(), "Save versus tags") then
				for _,nodeAction in pairs(DB.getChildren(nodeNew, "actions")) do
					if DB.getValue(nodeAction, "type", "") == "cast" then
						nodeAction.createChild("usereset", "string");
						nodeAction.getChild("usereset").setValue("consumable");
					end
				end
			end
		end
	end
	return nodeSpellSet, nodeNewSpellClass;
end

function getSpellLevel(nodeSpell)
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

function getCasterLevelByClass(sClassName, sSpellClassLevel)
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

function getCL(nodeItem)
	if not nodeItem then
		return 0;
	end
	local nCL = DB.getValue(nodeItem, "cl", 0);
	local sName = DB.getValue(nodeItem, "name", '');
	local sCL = sName:match("%pCL%s%d+%p");
	if sCL then
		local nNameCL = tonumber(sCL:match("%d+"));
		if usingEnhancedItems() and nNameCL then
			DB.setValue(nodeItem, "cl", 'number', nNameCL);							-- write CL from name to database node "cl"
		end
		return nNameCL or nCL;
	end
	return nCL;
end

function getWandCharges(nodeItem)
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