local Addon = CreateFrame("FRAME");


--Frame that stores all the buttons
local mainFrame;

--Selling List and LootList tables
local sellList, lootList, ignoreList = {}, {}, {};



-------------------------------------
--UTILS

-------------------------------------
--
-- Returns the number of items in the "sellList" table
-- @return #integer i : the size of "sellList" table
--
-------------------------------------
local function getSellListSize()
	local i = 0;
	for k,v in pairs(sellList) do
		i = i + 1;
	end
	return i;
end


local function getSellListValue()
	local total = 0;
	for itemID, amount in pairs(sellList) do
		total = total + select(11, GetItemInfo(itemID))*amount;
	end
	return total;
end


-------------------------------------
--
-- Returns the position of an item in your bags.
-- It returns the first slot.
-- @param #integer itemID : the id of the item to search for
-- @return #i integer : the bag slot
-- @return #j integer : the position in the bag
--
-------------------------------------
local function getItemPosition(itemID)
	for i = 0, 4 do
		for j = 1, GetContainerNumSlots(i) do
			if(GetContainerItemID(i, j) and GetContainerItemID(i, j) == itemID) then
				return i, j;
			end
		end
	end
end


-------------------------------------
--
-- Returns the position of an empty slot in your bags
-- @return #i integer : the bag slot
-- @return #j integer : the position in the bag
--
-------------------------------------
local function getEmptySlotPosition()
	for i = 0, 4 do
		for j = 1, GetContainerNumSlots(i) do
			if(not GetContainerItemID(i,j)) then
				return i, j;
			end
		end
	end
end

--/UTILS
-------------------------------------



-------------------------------------
--
-- Adds an item to the "mainFrame".
-- If a button is available (i.e. hidden), it will show up with the given values.
-- @param #integer itemID : the id of the item
-- @param #integer amount : the amount of the item
--
-------------------------------------
local function addItemToFrame(itemID, amount)
	local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID);

	for i=1, 5 do
		local btn = _G["IntegralBirthButton"..i];
		if(not btn:IsShown()) then
			_G["IntegralBirthButton"..i.."IconTexture"]:SetTexture(itemIcon);
			_G["IntegralBirthButton"..i.."Count"]:SetText(amount);
			if(amount > 1) then
				_G["IntegralBirthButton"..i.."Count"]:Show();
			else
				_G["IntegralBirthButton"..i.."Count"]:Hide();
			end
			_G["IntegralBirthButton"..i.."Text"]:SetText(itemName);

			btn.itemID = itemID;
			btn.itemAmount = amount;

			btn:Show();

			lootList[itemID] = nil;

			break;
		end
	end

end


-------------------------------------
--
-- Updates the buttons of the "mainFrame". Used the player clicks on buttons.
-- If there is more items to be prompted, it will handle them.
-- Else, it will hide the "mainFrame".
--
-------------------------------------
local function updateButtons()
	for itemID, amount in pairs(lootList) do
		addItemToFrame(itemID, amount);
	end

	mainFrame.sellValue:SetText("Sell List Value: "..GetCoinTextureString(getSellListValue()));

	--checks if all buttons are hidden, and if yes, hides the frame.
	for i=1, 5 do
		if(_G["IntegralBirthButton"..i]:IsShown()) then
			return;
		end
	end

	mainFrame:Hide();

end


-------------------------------------
--
-- Show the "mainFrame".
-- Used when the player loots something. Inits with some items.
--
-------------------------------------
local function showFrame()

	for itemID, amount in pairs(lootList) do
		addItemToFrame(itemID, amount);
	end

	mainFrame.sellValue:SetText("Sell List Value: "..GetCoinTextureString(getSellListValue()));

	UIFrameFadeIn(mainFrame, 0.25, 0, 1);

end


-------------------------------------
--
-- Creates 5 buttons for "mainFrame".
-- Used on the initialize function.
--
-------------------------------------
local function createButtons()
	for i=1, 5 do
		local btn = CreateFrame("BUTTON", "IntegralBirthButton"..i, mainFrame, "LootButtonTemplate");
		btn:SetPoint("TOPLEFT", 6, -6+(1-i)*41);

		btn:SetScript("OnClick", function(self, button)
			if(button == "LeftButton" and IsShiftKeyDown()) then
				sellList[self.itemID] = (sellList[self.itemID] or 0) + self.itemAmount;
				self:Hide();
				updateButtons();
			elseif(button == "RightButton") then
				self:Hide();
				updateButtons();
			end
		end);

		btn:SetScript("OnUpdate", nil);
		btn:SetScript("OnEnter", function(self, motion)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetHyperlink(select(2, GetItemInfo(self.itemID)));
			CursorUpdate(self);
		end);

		btn:Hide();
	end
end


--Frame that sells items when their stacks are bigger than necessary
local queueFrame = CreateFrame("FRAME");


-------------------------------------
--
-- Splits items and sells them.
-- Used when the player interacts with a vendor.
-- It's only called when the stack in the player's bag is bigger than necessary.
--
-------------------------------------
local function splitItemsAndSell()
	local total, x, y, w, z = 0;
	queueFrame:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed;
		if(total > 0.15) then
			total = 0;
			
			if(not self.moving) then
				for itemID, amount in pairs(sellList) do
					x, y = getItemPosition(itemID)
					--it means the player equipped/dropped/traded, i.e. it's no longer in the bags
					if(not x or not y) then
						sellList[itemID] = nil;
						return;
					end
					w, z = getEmptySlotPosition();
					SplitContainerItem(x, y, amount);
					PickupContainerItem(w, z);
					
					self.itemID = itemID;
					self.moving = true;
					return;
				end
			else
				UseContainerItem(w, z);
				sellList[self.itemID] = nil;
				self.moving = false;
				if(getSellListSize() == 0) then
					self:SetScript("OnUpdate", nil);
				end
			end
					
		end
	end);
end


-------------------------------------
--
-- Initialize function.
-- It sets up the "mainFrame" : "IntegralBirth" with all the frames/buttons and scripts.
--
-------------------------------------
local function setUpIntegralBirth()

	mainFrame = CreateFrame("FRAME", "IntegralBirth", UIParent);
	mainFrame:SetSize(160,213);
	mainFrame:SetPoint("CENTER");

	mainFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 18, edgeSize = 18,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }});
	mainFrame:SetBackdropColor(0,0,0,1);

	--title
	mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge");
	mainFrame.title:SetText("New Loot");
	mainFrame.title:SetPoint("TOP", 0, 16);

	mainFrame.sellValue = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	mainFrame.sellValue:SetPoint("BOTTOM", 0, -16);

	--buttons
	createButtons();


	mainFrame:SetScript("OnEvent", function(self, event, ...)
		if(event == "CHAT_MSG_LOOT") then
			local message, itemID, amount = ...;

			--checks if was the player that looted
			if(string.find(message, "You receive loot")) then
				itemID = tonumber(string.match(message, ":?(%d+):"));
				
				--checks if has a price (it should block most quest-items) or is being ignored
				if(select(11, GetItemInfo(itemID)) == 0 or ignoreList[itemID]) then
					return;
				end
				amount = tonumber(string.match(message, "x(%d+)")) or 1;
				lootList[itemID] = amount;
				if(not mainFrame:IsShown()) then
					showFrame();
				else
					updateButtons();
				end
			end
		else -- MERCHANT_SHOW
			for i = 0, 4 do
				for j = 1, GetContainerNumSlots(i) do
					local itemID = GetContainerItemID(i, j);
					if(itemID and sellList[itemID]) then
						local stackSize = select(2, GetContainerItemInfo(i, j));
						if(stackSize < sellList[itemID]) then
							UseContainerItem(i, j);
							sellList[itemID] = sellList[itemID] - stackSize;
						elseif(stackSize == sellList[itemID]) then
							UseContainerItem(i, j);
							sellList[itemID] = nil;
						end
					end
				end
			end
			--must split if there still items to sell
			if(getSellListSize() > 0) then
				splitItemsAndSell();
			end
		end
	end);

	mainFrame:EnableMouse();
	mainFrame:SetScript("OnMouseDown", function(self, button)
		if(IsAltKeyDown() and button == "LeftButton") then
			self:SetMovable(true);
			self:StartMoving();
		end
	end);

	mainFrame:SetScript("OnMouseUp", function(self, button)
		if(IsAltKeyDown() and button == "LeftButton") then
			self:SetMovable(false);
			self:StopMovingOrSizing();
			IntegralBirthSV[UnitName("player")]["Position"] = { self:GetPoint() };
		end
	end);


	mainFrame:RegisterEvent("CHAT_MSG_LOOT");
	mainFrame:RegisterEvent("MERCHANT_SHOW");

	mainFrame:Hide();
end


-------------------------------------
--
-- Loads SavedVariables.
-- Gets the position of the "mainFrame" and the "sellList" table.
--
-------------------------------------
local function loadSavedVariables()

	if(not IntegralBirthSV) then
		IntegralBirthSV = {};
		IntegralBirthSV[UnitName("player")] = {};
	elseif(IntegralBirthSV[UnitName("player")]) then
		sellList = IntegralBirthSV[UnitName("player")]["SellList"];
		ignoreList = IntegralBirthSV[UnitName("player")]["IgnoreList"];
		mainFrame:SetPoint(unpack(IntegralBirthSV[UnitName("player")]["Position"]));
	else
		IntegralBirthSV[UnitName("player")] = {};
		IntegralBirthSV[UnitName("player")]["Position"] = { mainFrame:GetPoint() };
	end

end


SLASH_IntegralBirth1, SLASH_IntegralBirth2 = "/integralbirth", "/intb";

-------------------------------------
--
-- Adds an item to the "mainFrame".
-- If a button is available (i.e. hidden), it will show up with the given values.
-- @param #string cmd : the command that player executes
--
-------------------------------------
function SlashCmd(cmd)
    if(cmd:match("remove")) then
		local itemID = tonumber(string.match(cmd, ":?(%d+):"));
		local itemName, itemLink = GetItemInfo(itemID);
		if(sellList[itemID]) then
			sellList[itemID] = nil;
			print("|cffffdd22IntegralBirth:|r You removed item:" .. itemLink .. " from the Sell List");
		end
	elseif(cmd:match("ignore")) then
		local itemID = tonumber(string.match(cmd, ":?(%d+):"));
		local itemName, itemLink = GetItemInfo(itemID);
		if(not ignoreList[itemID]) then
			ignoreList[itemID] = true;
			print("|cffffdd22IntegralBirth:|r You are now ignoring item:" .. itemLink);
		else
			ignoreList[itemID] = nil;
			print("|cffffdd22IntegralBirth:|r You are not ignoring item:" .. itemLink);
		end
    elseif(cmd:match("sellList")) then
    	print("Sell List:")
    	for itemID, amount in pairs(sellList) do
    		local itemName, itemLink = GetItemInfo(itemID);
    		print("       "..itemLink.."x" .. amount);
    	end
    	print("|cffffdd22IntegralBirth:|r "..GetCoinTextureString(getSellListValue()));
    else
    	print("|cffffdd22IntegralBirth:|r")
    	print("/intb remove item");
    	print("/intb ignore item");
    	print("/intb sellList");
    end
end

SlashCmdList["IntegralBirth"] = SlashCmd;


-------------------------------------
--
-- Addon SetScript OnEvent
-- Starts up the addOn.
--
-- Handled events:
-- "PLAYER_ENTERING_WORLD"
-- "PLAYER_LOGOUT"
--
-------------------------------------
Addon:SetScript("OnEvent", function(self, event, ...)
	if(event == "PLAYER_LOGOUT") then
		IntegralBirthSV[UnitName("player")]["SellList"] = sellList;
		IntegralBirthSV[UnitName("player")]["IgnoreList"] = ignoreList;
	else
		setUpIntegralBirth();
		loadSavedVariables();

		Addon:UnregisterEvent("PLAYER_ENTERING_WORLD");
	end
end);


Addon:RegisterEvent("PLAYER_ENTERING_WORLD");
Addon:RegisterEvent("PLAYER_LOGOUT");
