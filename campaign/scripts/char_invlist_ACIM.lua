CLASS_NAME_ALCHEMIST = "alchemist";
CLASS_NAME_ANTIPALADIN	= "antipaladin";
CLASS_NAME_ARCHANIST = "archanist";
CLASS_NAME_BARD = "bard";
CLASS_NAME_BLOODRAGER = "bloodrager";
CLASS_NAME_CLERIC = "cleric";
CLASS_NAME_DRUID = "druid";
CLASS_NAME_HYUNTER = "hunter";
CLASS_NAME_INQUISITOR = "inquisitor";
CLASS_NAME_INVESTIGATOR = "investigator";
CLASS_NAME_MAGUS = "magus";
CLASS_NAME_ORACLE = "oracle";
CLASS_NAME_PALADIN = "paladin";
CLASS_NAME_RANGER = "ranger";
CLASS_NAME_SHAMAN = "shaman";
CLASS_NAME_SKALD = "skald";
CLASS_NAME_SORCERER = "sorcerer";
CLASS_NAME_SUMMONER = "summoner";
CLASS_NAME_WARPRIEST = "warpriest";
CLASS_NAME_WITCH = "witch";
CLASS_NAME_WIZARD = "wizard";
CLASS_NAME_ADEPT = "adept";
CLASS_NAME_BLACKGUARD = "blackguard";
CLASS_NAME_ASSASSIN = "assassin";

function onInit()
    DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", onItemChanged);
    DB.addHandler("charsheet.*.inventorylist.*.carried", "onUpdate", onItemChanged);
    DB.addHandler("charsheet.*.inventorylist.*.count", "onUpdate", onItemChanged);
	if StringManager.contains(Extension.getExtensions(), "PFRPG Enhanced Items v4.2") then
		DB.addHandler("charsheet.*.inventorylist.*.charge", "onUpdate", onItemChanged);
	end
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

function inventoryChanged(nodeChar, nodeItem)
	if nodeChar and nodeItem then
		--Debug.chat("InventoryChanged", "nodeChar", nodeChar);
		--Debug.chat("InventoryChanged", "nodeItem", nodeItem);
		local sItemType = DB.getValue(nodeItem, "type");
		if not (sItemType == "Potion" or sItemType == "Wand" or sItemType == "Scroll") then
			return;
		end
		if DB.getValue(nodeItem, "isidentified") == 0 then
			return;
		end
		local nCL = DB.getValue(nodeItem, "cl", 1);
		local nUsesAvailable = 0;
		local sSource = nodeItem.getPath();
		if sItemType == "Potion" or sItemType == "Scroll" then
			nUsesAvailable = nodeItem.getChild("count").getValue();
		else
			nUsesAvailable = getWantCharges(nodeItem);
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
		if nCL < nMinCasterLevel then
			nCL = nMinCasterLevel;
		end;
		--Debug.chat("inventoryChanged", "nSpellLevel", nSpellLevel);
		if DB.getValue(nodeItem, "carried", 0) == 0 then
			if nodeSpellSet then
				removeSpellClass(nodeItem, nodeSpellSet, nSpellLevel);
			end
		else
			if nodeSpellSet then
				updateSpellSet(nodeSpellSet, nUsesAvailable, nSpellLevel);
			else
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
	local nodeSpell1 = nil;
	local nodeSpell2 = nil;
	if sItemName ~= "" then
		sSpellName = getSpellBetweenParenthesis(sItemName);
		if sSpellName ~= "" then
			nodeSpell1 = DB.findNode("spelldesc." .. sSpellName .."@*");
			nodeSpell2 = DB.findNode("reference.spells." .. sSpellName .. "@*");
			if not nodeSpell1 and not nodeSpell2 then
				sSpellName = getSpellAfterOf(sItemName);
				if sSpellName ~= "" then
					nodeSpell1 = DB.findNode("spelldesc." .. sSpellName .."@*");
					nodeSpell2 = DB.findNode("reference.spells." .. sSpellName .. "@*");
					if nodeSpell2 then
						return nodeSpell2;
					end
					return nodeSpell1;
				end
			elseif nodeSpell2 then
				return nodeSpell2;
			else
				return nodeSpell1;
			end
		else
			sSpellName = getSpellAfterOf(sItemName);
			if sSpellName ~= "" then
				nodeSpell1 = DB.findNode("spelldesc." .. sSpellName .."@*");
				nodeSpell2 = DB.findNode("reference.spells." .. sSpellName .. "@*");
				if nodeSpell2 then
					return nodeSpell2;
				end
				return nodeSpell1;
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
			if StringManager.contains(Extension.getExtensions(), "PFRPG Enhanced Items v4.2") then
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

function getWantCharges(nodeItem)
	if not nodeItem then
		return 0;
	end
	local nCharges = DB.getValue(nodeItem, "charge", 0);
	local nName = DB.getValue(nodeItem, "name");
	local sCharges = nName:match("%b[]");
	if sCharges then
		sCharges = sCharges:match("%d+");
		if sCharges then
			if nCharges ~= 0 and nCharges < tonumber(sCharges) then
				return nCharges;
			else
				return tonumber(sCharges);
			end
		end
	end
	return nCharges;
end