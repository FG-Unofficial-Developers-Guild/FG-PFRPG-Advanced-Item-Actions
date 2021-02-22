function onInit()
	update();
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function updateControl(sControl, bReadOnly, bID)
	if not self[sControl] then
		return false;
	end

	if not bID then
		return self[sControl].update(bReadOnly, true);
	end
	
	return self[sControl].update(bReadOnly);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID, bOptionID = ItemManager.getIDState(nodeRecord);
	
	local sType = string.lower(type.getValue() or "");
	local sSubType = string.lower(DB.getValue(nodeRecord, "subtype", ""));
	
	local bWeapon = (string.find(sType, "weapon") ~= nil);
	local bArmor = (string.find(sType, "armor") ~= nil);
	local bShield = (string.find(sSubType, "shield") ~= nil);
	local bWand = (string.find(sType, "wand") ~= nil);
	local bStaff = (string.find(sType, "staff") ~= nil);
	local bWondrous = (string.find(sType, "wondrous item") ~= nil);
	
	local bSection1 = false;
	if bOptionID and User.isHost() then
		if updateControl("nonid_name", bReadOnly, true) then bSection1 = true; end;
	else
		updateControl("nonid_name", false);
	end

	if bOptionID and (User.isHost() or not bID) then
		if updateControl("nonidentified", bReadOnly, true) then bSection1 = true; end;
	else
		updateControl("nonidentified", false);
	end

	local bSection2 = false;
	if updateControl("type", bReadOnly, bID) then bSection2 = true; end
	if updateControl("subtype", bReadOnly, bID) then bSection2 = true; end
	
	local bSection3 = false;
	if updateControl("cost", bReadOnly, bID) then bSection3 = true; end
	if updateControl("weight", bReadOnly, bID) then bSection3 = true; end
	if StringManager.contains(Extension.getExtensions(), "Customized Item Generator for 3.5E and Pathfinder") then
		if updateControl("size", bReadOnly, bID) then bSection3 = true; end
	end
	
	local bSection8 = false;
	if updateControl("damage", bReadOnly, bID and (bWeapon or bShield)) then bSection8 = true; end
	if updateControl("damagetype", bReadOnly, bID and (bWeapon or bShield)) then bSection8 = true; end
	if updateControl("critical", bReadOnly, bID and (bWeapon or bShield)) then bSection8 = true; end
	if updateControl("range", bReadOnly, bID and (bWeapon or bShield)) then bSection8 = true; end
	
	local bSection4 = false;
	if updateControl("ac", bReadOnly, bID and bArmor) then bSection4 = true; end
	if updateControl("maxstatbonus", bReadOnly, bID and bArmor) then bSection4 = true; end
	if updateControl("checkpenalty", bReadOnly, bID and bArmor) then bSection4 = true; end
	if updateControl("spellfailure", bReadOnly, bID and bArmor) then bSection4 = true; end
	if updateControl("speed30", bReadOnly, bID and bArmor) then bSection4 = true; end
	if updateControl("speed20", bReadOnly, bID and bArmor) then bSection4 = true; end

	local bPFRPGEILoaded = StringManager.contains(Extension.getExtensions(), "PFRPG - Enhanced Items");

	if bPFRPGEILoaded then
		current_label.setVisible(false);
		maxcharges.setVisible(false);
		maxcharges_label.setVisible(false);
		if updateControl("charge", bReadOnly, bID and (bWand or bStaff)) then
			current_label.setVisible(true);
			maxcharges.setVisible(true);
			maxcharges.setReadOnly(bReadOnly);
			maxcharges_label.setVisible(true);
			bSection8 = true;
		end
		charge.setReadOnly(false);

		if updateControl("equipslot", bReadOnly, bID and bWondrous) then bSection8 = true; end
	end

	if updateControl("properties", bReadOnly, bID and (bWeapon or bArmor)) then bSection4 = true; end
	
	local bSection5 = false;
	if updateControl("bonus", bReadOnly, bID and (bWeapon or bArmor)) then bSection5 = true; end
	if updateControl("aura", bReadOnly, bID) then bSection5 = true; end
	if updateControl("cl", bReadOnly, bID) then bSection5 = true; end
	if updateControl("prerequisites", bReadOnly, bID) then bSection5 = true; end
	
	local bSection6 = bID;
	description.setVisible(bID);
	description.setReadOnly(bReadOnly);

	local bSection7 = false;
	if bPFRPGEILoaded then
		updateControl("sourcebook", bReadOnly, bID);
		divider6.setVisible(false);
		gmonly_label.setVisible(false);
		gmonly.setVisible(false);
		if bOptionID and User.isHost() then
			if updateControl("gmonly", bReadOnly, true) then bSection7 = true; end
		else
			updateControl("gmonly", bReadOnly, false);
		end
		if User.isHost() then 
			divider6.setVisible((bSection1 or bSection2 or bSection3 or bSection4 or bSection5) and bSection7);
		end
	end
	
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
	divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection8);
	divider8.setVisible((bSection1 or bSection2 or bSection3 or bSection8) and bSection4)
	divider4.setVisible((bSection1 or bSection2 or bSection3 or bSection8 or bSection4) and bSection5);
	divider5.setVisible((bSection1 or bSection2 or bSection3 or bSection8 or bSection4 or bSection5) and bSection6);
end
