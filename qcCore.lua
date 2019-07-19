local TableInsert = table.insert;
local TableRemove = table.remove;
local StringFormat = string.format;
local ToString = tostring;
local BitBand = bit.band

local qcL = qcLocalize

local qcPins = {}
local qcPinFrames = {}
local qcSparePinFrames = {}

local qcCurrentCategoryID = 0
local qcCurrentCategoryQuestCount = 0
local qcCategoryQuests = {}

--[[ Vars ]]--
local qcCurrentScrollPosition = 1
local qcMapTooltip = nil
local qcQuestReputationTooltip = nil
local qcQuestInformationTooltip = nil
local qcToastTooltip = nil
local qcNewDataAlertTooltip = nil
local qcMutuallyExclusiveAlertTooltip = nil

--[[ Constants ]]--
local QCADDON_VERSION = 109.25
local QCADDON_PURGE = true
local QCDEBUG_MODE = false
local QCADDON_CHAT_TITLE = "|CFF9482C9Quest Completist:|r "


local COLOUR_DEATHKNIGHT = "|cFFC41F3B"
local COLOUR_DEMONHUNTER = "|cFFA330C9"
local COLOUR_DRUID = "|cFFFF7D0A"
local COLOUR_HUNTER = "|cFFABD473"
local COLOUR_MAGE = "|cFF69CCF0"
local COLOUR_PALADIN = "|cFFF58CBA"
local COLOUR_PRIEST = "|cFFFFFFFF"
local COLOUR_ROGUE = "|cFFFFF569"
local COLOUR_SHAMAN = "|cFF0070DE"
local COLOUR_WARLOCK = "|cFF9482C9"
local COLOUR_WARRIOR = "|cFFC79C6E"

local QC_ICON_COORDS_NORMAL = {0,0.125,0,0.25}
local QC_ICON_COORDS_REPEATABLE = {0.125,0.25,0.25,0.50}
local QC_ICON_COORDS_DAILY = {0,0.125,0.25,0.50}
local QC_ICON_COORDS_SPECIAL = {0,0.125,0,0.25}
local QC_ICON_COORDS_WEEKLY = {0,0.125,0,0.25}
local QC_ICON_COORDS_SEASONAL = {0,0.125,0.5,0.75}
local QC_ICON_COORDS_PROFESSION = {0.625,0.75,0,0.25}
local QC_ICON_COORDS_PROGRESS = {0.25,0.375,0.25,0.5}
local QC_ICON_COORDS_READY = {0.125,0.25,0,0.25}
local QC_ICON_COORDS_COMPLETE = {0.125,0.25,0.5,0.75}
local QC_ICON_COORDS_UNATTAINABLE = {0.25,0.375,0.5,0.75}
local QC_ICON_COORDS_ITEMDROPSTANDARD = {0.375,0.5,0,0.25}
local QC_ICON_COORDS_ITEMDROPREPEATABLE = {0.375,0.5,0.25,0.5}
local QC_ICON_COORDS_CLASS = {0.5,0.625,0,0.25}
local QC_ICON_COORDS_KILL = {0.25,0.375,0,0.25}

local qcCategoryDropDownMenu = CreateFrame("Frame", "qcCategoryDropDownMenu")

--[[ Bitwise Values ]]--
qcFactionBits = {
	["ALLIANCE"]=1,["HORDE"]=2,["NEUTRAL"]=4,
}
qcRaceBits = {
	["HUMAN"]=1,["ORC"]=2,["DWARF"]=4,["NIGHTELF"]=8,
	["SCOURGE"]=16,["TAUREN"]=32,["GNOME"]=64,["TROLL"]=128,
	["GOBLIN"]=256,["BLOODELF"]=512,["DRAENEI"]=1024,["WORGEN"]=2048,
	["PANDAREN"]=4096,["VOIDELF"]=8192,["NIGHTBORNE"]=16384,
	["HIGHMOUNTAINTAUREN"]=32768,["LIGHTFORGEDDRAENEI"]=65536,
	["DARKIRONDWARF"]=131072,["MAGHARORC"]=262144,
	["ZANDALARITROLL"]=524288,["KULTIRAN"]=1048576
}
qcClassBits = {
	["WARRIOR"]=1,["PALADIN"]=2,["HUNTER"]=4,["ROGUE"]=8,["PRIEST"]=16,
	["DEATHKNIGHT"]=32,["SHAMAN"]=64,["MAGE"]=128,["WARLOCK"]=256,["DRUID"]=512,
	["MONK"]=1024,["DEMONHUNTER"]=2048
}
qcProfessionBits = {
	[171]=1,		-- Alchemy
	[164]=2,		-- Blacksmithing
	[333]=4,		-- Enchanting
	[202]=8,		-- Engineering
	[773]=16,		-- Inscription
	[755]=32,		-- Jewelcrafting
	[165]=64,		-- Leatherworking
	[197]=128,		-- Tailoring
	[182]=256,		-- Herbalism
	[186]=512,		-- Mining
	[393]=1024,		-- Skinning
	[794]=2048,		-- Archaeology
	[129]=4096,		-- First Aid
	[185]=8192,		-- Cooking
	[356]=16384,	-- Fishing
}
--qcSubQuestCatagoryBits = {
--["Warfront"]=1,
--["Bonus"]=2,
--["Legion Assault"]=4,
--["Assault"]=8
--}
--qcQuestFactionLevelBits = {
--	["Hated"]=1,
--	["NEUTRAL"]=2
--	["Friendly"]=4,
--	["Honored"]=8
--	["Revered"]=16,
--	["Exalted"]=32
--}
local qcHolidayDates = {
	[1]={"180920","111006"},		-- Brewfest 2018
	[2]={"180425","180502"},		-- Children's Week 2018
	[4]={"181101","181103"},		-- Day of the Dead 2018
	[8]={"181216","190102"},		-- Feast of Winter Veil 2018-2019
	[16]={"181018","181101"},		-- Hallow's End 2018
	[32]={"180918","180925"},		-- Harvest Festival 2018
	[64]={"190205","190219"},		-- Love is in the Air 2019
	[128]={"190128","190211"},		-- Lunar Festival 2019
	[256]={"180621","180705"},		-- Midsummer Fire Festival 2018
	[512]={"180402","180409"},		-- Noblegarden 2018
	[1024]={"181119","181126"},		-- Pilgrim's Bounty 2018
	[2048]={"180919","180920"},		-- Pirates' Day 2018
}

--[[ Constants for the Key Bindings & Slash Commands ]]--
BINDING_HEADER_QCQUESTCOMPLETIST = "Quest Completist";
BINDING_NAME_QCTOGGLEFRAME = "Toggle Frame";
SLASH_QUESTCOMPLETIST1 = "/qc"
SLASH_QUESTCOMPLETIST2 = "/questc"

SlashCmdList["QUESTCOMPLETIST"] = function(msg, editbox)
	ShowUIPanel(qcQuestCompletistUI)
end

function qcCopyTable(qcTable)
	if not (qcTable) then return nil end
	if not (type(qcTable) == "table") then return nil end
	local qcNewTable = {}
	for qcKey, qcValue in pairs(qcTable) do
		if (type(qcValue) == "table") then
			qcNewTable[qcKey] = qcCopyTable(qcValue)
		else
			qcNewTable[qcKey] = qcValue
		end
	end
	return qcNewTable
end

function qcUpdateCurrentCategoryText(categoryId)
	qcQuestCompletistUI.qcSelectedCategory:SetText("#")
	for i, e in pairs(qcQuestCategories) do
		if (e[1] == categoryId) then
			qcQuestCompletistUI.qcSelectedCategory:SetText(e[2])
			break
		end
	end
end

local function qcUpdateMutuallyExclusiveCompletedQuest(qcQuestID)
	if (qcMutuallyExclusive[qcQuestID]) then
		for qcMutuallyExclusiveIndex, qcMutuallyExclusiveEntry in pairs(qcMutuallyExclusive[qcQuestID]) do
			if (qcQuestDatabase[qcMutuallyExclusiveEntry]) then
				qcCompletedQuests[qcMutuallyExclusiveEntry] = {["C"]=1}
			end
		end
	end
end

local function qcUpdateSkippedBreadcrumbQuest(qcQuestID)
	if (qcBreadcrumbQuests[qcQuestID]) then
		for qcBreadcrumbIndex, qcBreadcrumbEntry in pairs(qcBreadcrumbQuests[qcQuestID]) do
			if (qcQuestDatabase[qcBreadcrumbEntry]) then
				qcCompletedQuests[qcBreadcrumbEntry] = {["C"]=1}
			end
		end
	end
end

local function qcGetSearchQuests(searchText)
	local tableInsert = table.insert
	local stringUpper = string.upper
	local stringFind = string.find
	wipe(qcSearchQuests) -- TODO: Where is this table, and we dont seem to be returning it correctly.
	local holdingTable = {}
	for qcIndex, qcEntry in pairs(qcQuestDatabase) do
		if (stringFind(stringUpper(qcEntry[2]),searchText,1,true)) then
			tableInsert(holdingTable,qcEntry)
		end
	end
	qcSearchQuests = qcCopyTable(holdingTable)
end

local function qcGetCategoryQuests(categoryId, searchText) -- *
	local tableInsert = table.insert
	local stringUpper = string.upper
	local tableSort = table.sort
	local holdingTable = {}
	wipe(qcCategoryQuests)
	if (searchText) then
		local stringfind = string.find
		for i, e in pairs(qcQuestDatabase) do
			if (stringfind(stringUpper(e[2]),searchText,1,true)) then
				tableInsert(holdingTable,e)
			end
		end
		qcCategoryQuests = qcCopyTable(holdingTable)
		return nil
	end
	local tableRemove = table.remove
	local BitBand = bit.band
	for i, e in pairs(qcQuestDatabase) do
		if (e[5] == categoryId) then
			tableInsert(holdingTable,e)
		end
	end
	qcCategoryQuests = qcCopyTable(holdingTable)
	if (qcSettings.QC_L_HIDE_COMPLETED == 1) then
		for i = #qcCategoryQuests, 1, -1 do
			if (qcCompletedQuests[qcCategoryQuests[i][1]]) then
				if (qcCompletedQuests[qcCategoryQuests[i][1]]["C"] == 1) or (qcCompletedQuests[qcCategoryQuests[i][1]]["C"] == 2) then
					tableRemove(qcCategoryQuests,i)
				end
			end
		end
	end
	if (qcSettings.QC_ML_HIDE_FACTION == 1) then
		local playerFaction, _ = UnitFactionGroup("player")
		local factionFlag = qcFactionBits[stringUpper(playerFaction)]
		for i = #qcCategoryQuests, 1, -1 do
			if (BitBand(qcCategoryQuests[i][7], factionFlag) == 0) then
				tableRemove(qcCategoryQuests,i)
			end
		end
	end
	if (qcSettings.QC_ML_HIDE_RACECLASS == 1) then
		local _, playerRace = UnitRace("player")
		local raceFlag = qcRaceBits[stringUpper(playerRace)]
		local _, playerClass = UnitClass("player")
		local classFlag = qcClassBits[stringUpper(playerClass)]
		for i = #qcCategoryQuests, 1, -1 do
			if ((BitBand(qcCategoryQuests[i][8], raceFlag) == 0) or (BitBand(qcCategoryQuests[i][9], classFlag) == 0)) then
				tableRemove(qcCategoryQuests,i)
			end
		end
	end
	if (qcSettings.SORT == 1) then
		tableSort(qcCategoryQuests,function(a,b) return (a[3]<b[3] or (a[3] == b[3] and a[2]<b[2])) end)
	elseif (qcSettings.SORT == 2) then
		tableSort(qcCategoryQuests,function(a,b) return a[2]<b[2] end)
	else
		tableSort(qcCategoryQuests,function(a,b) return (a[3]<b[3] or (a[3] == b[3] and a[2]<b[2])) end)
	end
end

function qcUpdateQuestList(categoryId, startIndex, searchText) -- *
	if not (qcQuestCompletistUI:IsVisible()) then return nil end
	local stringFormat = string.format
	if (categoryId) then
		qcQuestCompletistUI.qcSearchBox:SetText("")
		qcCurrentCategoryID = categoryId
		qcUpdateCurrentCategoryText(categoryId)
		qcGetCategoryQuests(categoryId)
		qcCurrentCategoryQuestCount = (#qcCategoryQuests)
		if (qcCurrentCategoryQuestCount < 16) then
			qcMenuSlider:SetMinMaxValues(1, 1)
		else
			qcMenuSlider:SetMinMaxValues(1, qcCurrentCategoryQuestCount - 15)
		end
		qcMenuSlider:SetValue(startIndex)
	else
		if (searchText) then
			qcGetCategoryQuests(nil, searchText)
			qcCurrentCategoryQuestCount = (#qcCategoryQuests)
			qcQuestCompletistUI.qcSelectedCategory:SetText("Search Results")
			if (qcCurrentCategoryQuestCount < 16) then
				qcMenuSlider:SetMinMaxValues(1, 1)
			else
				qcMenuSlider:SetMinMaxValues(1, qcCurrentCategoryQuestCount - 15)
			end
			qcMenuSlider:SetValue(startIndex)
		end
	end
	qcQuestCompletistUI.qcCurrentCategoryQuestCount:SetText(stringFormat("%d Quests Found",qcCurrentCategoryQuestCount))
	for i = 1, 16 do
		local offset = ((i + startIndex) - 1)
		local questRecord = _G["qcMenuButton" .. i]
		if (qcCurrentCategoryQuestCount >= offset) then
			local e = qcCategoryQuests[offset]
			local questId = e[1]
			local questType = e[6]
			local questFaction = e[7]
			questRecord.QuestName:SetText(stringFormat("[%d] %s",e[3],e[2]))
			questRecord.QuestID = questId
			-- TODO: Possible to reduce code with call to _G[]?
			if (questType == 1) then
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_NORMAL))
				questRecord.QuestName:SetTextColor(1.0, 1.0, 1.0, 1.0)
			elseif (questType == 2) then
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_REPEATABLE))
				questRecord.QuestName:SetTextColor(0.0941176470588235, 0.6274509803921569, 0.9411764705882353, 1.0)
			elseif (questType == 3) then
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_DAILY))
				questRecord.QuestName:SetTextColor(0.0941176470588235, 0.6274509803921569, 0.9411764705882353, 1.0)
			elseif (questType == 4) then
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_SPECIAL))
				questRecord.QuestName:SetTextColor(1.0, 0.6156862745098039, 0.0862745098039216, 1.0)
			elseif (questType == 5) then
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_NORMAL))
				questRecord.QuestName:SetTextColor(1.0, 1.0, 1.0, 1.0)
			elseif (questType == 6) then
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_PROFESSION))
				questRecord.QuestName:SetTextColor(1.0, 1.0, 1.0, 1.0)
			elseif (questType == 7) then
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_SEASONAL))
				questRecord.QuestName:SetTextColor(1.0, 1.0, 1.0, 1.0)
			elseif (questType == 11) then
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_WORLDQUEST))
				questRecord.QuestName:SetTextColor(1.0, 1.0, 1.0, 1.0)
			else
				questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_NORMAL))
				questRecord.QuestName:SetTextColor(1.0, 1.0, 1.0, 1.0)
			end
			questRecord.QuestIcon:Show()
			if ((questFaction == 0) or (questFaction == 3)) then
				questRecord.FactionIcon:Hide()
			elseif (questFaction == 1) then
				questRecord.FactionIcon:SetTexture("Interface\\Addons\\QuestCompletist\\Images\\AllianceIcon")
				questRecord.FactionIcon:Show()
			elseif(questFaction == 2) then
				questRecord.FactionIcon:SetTexture("Interface\\Addons\\QuestCompletist\\Images\\HordeIcon")
				questRecord.FactionIcon:Show()
			else
				questRecord.FactionIcon:Hide()
			end
			if not (GetQuestLogIndexByID(questId) == 0) then
				local isComplete
				_, _, _, _, _, isComplete, _, _, _ = GetQuestLogTitle(GetQuestLogIndexByID(questId)) -- TODO: Still same return?
				if (isComplete == nil) then
					questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_PROGRESS))
					questRecord.QuestName:SetTextColor(0.5803921568627451, 0.5882352941176471, 0.5803921568627451, 1.0)
				elseif (isComplete == 1) then
					questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_READY))
					questRecord.QuestName:SetTextColor(1.0, 0.8196078431372549, 0.0, 1.0)
				elseif (isComplete == -1) then
					questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_NORMAL))
					questRecord.QuestName:SetTextColor(0.9372549019607843, 0.1490196078431373, 0.0627450980392157, 1.0)
				end
			end
			if (qcCompletedQuests[questId]) then
				if not ((questType == 2) or (questType == 3)) then
					if (qcCompletedQuests[questId]["C"] == 1) then
						questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_COMPLETE))
						questRecord.QuestName:SetTextColor(0.0, 1.0, 0.0, 1.0)
					elseif (qcCompletedQuests[questId]["C"] == 2) then
						questRecord.QuestIcon:SetTexCoord(unpack(QC_ICON_COORDS_UNATTAINABLE))
						questRecord.QuestName:SetTextColor(0.77, 0.12, 0.23, 1.0)
					end
				end
			end
			questRecord:Show()
			questRecord:Enable()
		else
			questRecord.QuestName:SetText("#")
			questRecord:Hide()
			questRecord:Disable()
		end
	end
end

function qcSearchBox_OnEditFocusLost(self) -- *
	searchText = string.upper(self:GetText())
	if not (searchText == "") then
		qcUpdateQuestList(nil, 1, searchText)
	else
		qcUpdateQuestList(qcCurrentCategoryID, 1)
	end
end

function qcSearchBox_OnTextChanged(self, userInput) -- *
	if (userInput == true) then
		searchText = string.upper(self:GetText())
		if not (searchText == "") then
			qcUpdateQuestList(nil, 1, searchText)
		else
			qcUpdateQuestList(qcCurrentCategoryID, 1)
		end
	end
end

function qcScrollUpdate(value) -- *
	if not (qcCurrentScrollPosition == value) then
		qcCurrentScrollPosition = value
		qcUpdateQuestList(nil, value)
	end
end

function qcQueryQuestFlaggedComplete()

	local qcChecked = 0
	local qcNewFlagged = 0

	for qcIndex, qcEntry in pairs(qcQuestDatabase) do
		qcChecked = (qcChecked + 1)
		if (IsQuestFlaggedCompleted(qcIndex)) then
			if not (qcQuestDatabase[qcIndex][6] == 2) or (qcQuestDatabase[qcIndex][6] == 3) then
				if (qcCompletedQuests[qcIndex] == nil) then
					qcNewFlagged = (qcNewFlagged + 1)
				end
				qcCompletedQuests[qcIndex] = {["C"]=1}
				qcUpdateMutuallyExclusiveCompletedQuest(qcIndex)
				qcUpdateSkippedBreadcrumbQuest(qcIndex)
			end
		end
	end

	if (qcNewFlagged > 0) then
		print(string.format("%s%d quests where checked, and %d previously completed quest(s) have now been updated as such.",QCADDON_CHAT_TITLE,qcChecked,qcNewFlagged))
		qcUpdateQuestList(nil,qcMenuSlider:GetValue())
	end
	
end

local function qcQuestQueryCompleted()

	local qcCountReturned = 0
	local qcNewFlagged = 0
	local qcCompletedTable = {}

	GetQuestsCompleted(qcCompletedTable)

	for qcIndex, qcEntry in pairs(qcCompletedTable) do
		qcCountReturned = (qcCountReturned + 1)
		if not (qcQuestDatabase[qcIndex] == nil) then
			if not (qcQuestDatabase[qcIndex][6] == 2) or (qcQuestDatabase[qcIndex][6] == 3) then
				if (qcCompletedQuests[qcIndex] == nil) then
					qcNewFlagged = (qcNewFlagged + 1)
				end
				qcCompletedQuests[qcIndex] = {["C"]=1}
				qcUpdateMutuallyExclusiveCompletedQuest(qcIndex)
				qcUpdateSkippedBreadcrumbQuest(qcIndex)
			end
		end
	end

	if (qcCountReturned == 0) then
		print(string.format("%sNo quests were returned from the server query. Attempting to check each quest individually...",QCADDON_CHAT_TITLE))
		qcQueryQuestFlaggedComplete()
	end
	if (qcNewFlagged > 0) then
		print(string.format("%s%d previously completed quest(s) have now been updated as such.",QCADDON_CHAT_TITLE,qcNewFlagged))
		qcUpdateQuestList(nil,qcMenuSlider:GetValue())
	end
	
	print(string.format("%sQuery completed.",QCADDON_CHAT_TITLE))

end

local function qcClearUpdateCache()
	wipe(qcCompletedQuests)
	print(string.format("%sCache Cleared.",QCADDON_CHAT_TITLE))
end

local function qcPurgeCollectedCache()
	if (qcCollectedQuests == nil) then qcCollectedQuests = {} end
	if (qcProgressComplete == nil) then qcProgressComplete = {} end
	wipe(qcCollectedQuests)
	wipe(qcProgressComplete)
	print(string.format("%sCollected Cache Purged.",QCADDON_CHAT_TITLE))
end

function qcMenuMouseWheel(self, delta) -- *
	local position = qcMenuSlider:GetValue()
	if (delta < 0) and (position < qcCurrentCategoryQuestCount) then
		qcMenuSlider:SetValue(position + 2)
	elseif (delta > 0) and (position > 1) then
		qcMenuSlider:SetValue(position - 2)
	end
end

function qcProcessMenuAction(button, arg1)

	if (arg1 == "PERFORMSERVERQUERY") then
		print(string.format("%s%s",QCADDON_CHAT_TITLE,qcL.QUERYREQUESTED))
		qcQuestQueryCompleted()
		CloseDropDownMenus()
	elseif (arg1 == "CLEARUPDATECACHE") then
		print(string.format("%s%s",QCADDON_CHAT_TITLE,"Clearing your update Cache..."))
		qcClearUpdateCache()
		CloseDropDownMenus()
	elseif (arg1 == "SORTLEVEL") then
		qcSettings.SORT = 1
		qcQuestCompletistUI.qcSearchBox:SetText("")
		qcUpdateQuestList(qcCurrentCategoryID, qcMenuSlider:GetValue())
		CloseDropDownMenus()
	elseif (arg1 == "SORTALPHA") then
		qcSettings.SORT = 2
		qcQuestCompletistUI.qcSearchBox:SetText("")
		qcUpdateQuestList(qcCurrentCategoryID, qcMenuSlider:GetValue())
		CloseDropDownMenus()
	end

end

function qcProcessMenuSelection(self, arg1)
	qcQuestCompletistUI.qcSearchBox:SetText("");
	qcUpdateQuestList(arg1,1);
	CloseDropDownMenus();
end

function qcCategoryDropdown_Initialize(self, level, menuList)

	local stringformat = string.format
	local qcMenuData = {}
	
	if (level == 1) then
		for qcMenuIndex, qcMenuEntry in ipairs(qcCategoryMenu) do
			if (qcMenuEntry[3]) then
				qcMenuData = {text=stringformat("   %s",qcMenuEntry[2]),isTitle=false,notCheckable=true,hasArrow=true,value=qcMenuEntry[1]}
			else
				qcMenuData = {text=qcMenuEntry[2],isTitle=true,notCheckable=true,hasArrow=false}
			end
			UIDropDownMenu_AddButton(qcMenuData, level)
		end
	elseif (level == 2) then
		local qcParentValue = UIDROPDOWNMENU_MENU_VALUE
		for qcMenuIndex, qcMenuEntry in ipairs(qcCategoryMenu) do
			if (qcMenuEntry[1] == qcParentValue) then
				for qcSubmenuIndex, qcSubmenuEntry in ipairs(qcMenuEntry[3]) do
					if (qcSubmenuEntry[3]) then
						qcMenuData = {text=stringformat("   %s",qcSubmenuEntry[2]),isTitle=false,notCheckable=true,hasArrow=true,value=qcSubmenuEntry[1]}
					else
						if (tonumber(qcSubmenuEntry[1])) then
							qcMenuData = {text=qcSubmenuEntry[2],isTitle=false,notCheckable=false,hasArrow=false,value=qcSubmenuEntry[1],arg1=qcSubmenuEntry[1],func=function(button,arg1) qcQuestCompletistUI.qcSearchBox:SetText("");qcUpdateQuestList(arg1,1);CloseDropDownMenus();end}
						else
							qcMenuData = {text=qcSubmenuEntry[2],isTitle=false,notCheckable=false,hasArrow=false,value=qcSubmenuEntry[1],arg1=qcSubmenuEntry[1],func=function(button,arg1) qcProcessMenuAction(button,arg1);end}
						end
					end
					UIDropDownMenu_AddButton(qcMenuData, level)
				end
				break
			end
		end
	elseif (level == 3) then
		local qcParentValue = UIDROPDOWNMENU_MENU_VALUE
		for qcMenuIndex, qcMenuEntry in ipairs(qcCategoryMenu) do
			if (qcMenuEntry[3]) then
				for qcSubmenuIndex, qcSubmenuEntry in ipairs(qcMenuEntry[3]) do
					if (qcSubmenuEntry[1] == qcParentValue) then
						if (tonumber(qcSubmenuEntry[1])) then
							qcMenuData = {text=qcSubmenuEntry[2],isTitle=false,notCheckable=false,hasArrow=false,value=qcSubmenuEntry[1],arg1=qcSubmenuEntry[1],func=function(button,arg1) qcQuestCompletistUI.qcSearchBox:SetText("");qcUpdateQuestList(arg1,1);CloseDropDownMenus();end}
						else
							qcMenuData = {text=qcSubmenuEntry[2],isTitle=false,notCheckable=false,hasArrow=false,value=qcSubmenuEntry[1],arg1=qcSubmenuEntry[1],func=function(button,arg1) qcProcessMenuAction(button,arg1);end}
						end
						UIDropDownMenu_AddButton(qcMenuData, level)
					end
					break
				end
			else
				qcMenuData = {text=qcMenuEntry[2],isTitle=true,notCheckable=true,hasArrow=false}
			end
		end
	end

end

function qcCategoryDropdownButton_OnClick(self, button, down) -- *
	EasyMenu(qcMenu, qcCategoryDropDownMenu, self:GetName(), 0, 0, nil)
end

function qcCategoryDropdown_OnLoad(self) -- TODO: Is this even needed anymore?
	UIDropDownMenu_Initialize(self, qcCategoryDropdown_Initialize)
end

local function qcZoneChangedNewArea() -- *
--	SetMapToCurrentZone()
	local id = C_Map.GetBestMapForUnit("player")
	if (qcAreaIDToCategoryID[id]) then
		qcCurrentCategoryID = qcAreaIDToCategoryID[id]
		qcUpdateQuestList(qcCurrentCategoryID,1)
	end
end

function qcUpdateTooltip(index)
	local stringFormat = string.format
	local questId = _G["qcMenuButton" .. index].QuestID

	if not (questId == nil) then
		qcQuestInformationTooltip:SetOwner(qcQuestCompletistUI,"ANCHOR_BOTTOMRIGHT",-30,500)
		qcQuestInformationTooltip:ClearLines()
--		qcQuestInformationTooltip:SetHyperlink(stringFormat("quest:%d",questId))
		qcQuestInformationTooltip:AddLine(" ")
		qcQuestInformationTooltip:AddDoubleLine("Quest ID:", stringFormat("|cFF69CCF0%d|r",questId))
		if not (qcQuestDatabase[questId][13] == nil) then
			for qcInitiatorIndex, qcInitiatorEntry in pairs(qcQuestDatabase[questId][13]) do
				local qcInitiatorID = qcInitiatorEntry[1]
				local qcInitiatorName = qcInitiatorEntry[2]
				local qcInitiatorMapID = qcInitiatorEntry[3]
				local qcInitiatorMapLevel = qcInitiatorEntry[4]
				local qcInitiatorX = qcInitiatorEntry[5]
				local qcInitiatorY = qcInitiatorEntry[6]
				if not (qcInitiatorID == 0) then
					if not (qcInitiatorName == nil) then
						qcQuestInformationTooltip:AddDoubleLine("Quest Giver:", stringFormat("%s%s [%d]",COLOUR_HUNTER,qcInitiatorName,qcInitiatorID))
					else
						qcQuestInformationTooltip:AddDoubleLine("Quest Giver:", stringFormat("%s%s [%d]",COLOUR_HUNTER,"Self-provided Quest",qcInitiatorID))
					end
				else
					if not (qcInitiatorName == nil) then
						qcQuestInformationTooltip:AddDoubleLine("Quest Giver:", stringFormat("%s%s",COLOUR_HUNTER,qcInitiatorName))
					else
						qcQuestInformationTooltip:AddDoubleLine("Quest Giver:", stringFormat("%s%s",COLOUR_HUNTER,"Self-provided Quest"))
					end
				end
				if not (qcInitiatorMapLevel == 0) then
					qcQuestInformationTooltip:AddDoubleLine("  - Location:", stringFormat("%s%s, Floor %d @ %.1f,%.1f",COLOUR_HUNTER,tostring(GetMapNameByID(qcInitiatorMapID) or nil),qcInitiatorMapLevel,qcInitiatorX,qcInitiatorY),nil,nil,nil,true)
				else
					qcQuestInformationTooltip:AddDoubleLine("  - Location:", stringFormat("%s%s @ %.1f,%.1f",COLOUR_HUNTER,tostring(GetMapNameByID(qcInitiatorMapID) or nil),qcInitiatorX,qcInitiatorY),nil,nil,nil,true)
				end
			end
		end
		qcQuestInformationTooltip:Show()
		qcQuestReputationTooltip:SetOwner(qcQuestInformationTooltip,"ANCHOR_BOTTOMRIGHT",-qcQuestInformationTooltip:GetWidth())
		qcQuestReputationTooltip:ClearLines()
		if not (qcQuestDatabase[questId][12] == nil) then
			qcReputationCount = 0
			qcQuestReputationTooltip:AddLine(GetText("COMBAT_TEXT_SHOW_REPUTATION_TEXT"))
			qcQuestReputationTooltip:AddLine(" ")
			for qcReputationIndex, qcReputationEntry in pairs(qcQuestDatabase[questId][12]) do
				qcReputationCount = (qcReputationCount+1)
				qcQuestReputationTooltip:AddDoubleLine(tostring(qcFactions[qcReputationIndex] or qcReputationIndex), stringFormat("%s%d rep",COLOUR_DRUID,qcReputationEntry))
			end
			if (qcReputationCount > 0) then
				qcQuestReputationTooltip:Show()
			else
				qcQuestReputationTooltip:Hide()
			end
		end
	else
		qcQuestReputationTooltip:Hide()
	end

end

function qcQuestClick(qcButtonIndex)
	local qcQuestID = _G["qcMenuButton" .. qcButtonIndex].QuestID
	if (IsLeftShiftKeyDown()) then --[[ User wants to toggle the completed status of a quest ]]--
	  --print(string.format("%sLeft shift key is down",QCADDON_CHAT_TITLE))
		if (qcCompletedQuests[qcQuestID] == nil) then
			qcCompletedQuests[qcQuestID] = {["C"] = 1}
		else
			if (qcCompletedQuests[qcQuestID]["C"] == nil) then
				qcCompletedQuests[qcQuestID]["C"] = 1
			else
				if (qcCompletedQuests[qcQuestID]["C"] == 1) then
					qcCompletedQuests[qcQuestID]["C"] = 0
				elseif (qcCompletedQuests[qcQuestID]["C"] == 0) then
					qcCompletedQuests[qcQuestID]["C"] = 1
				elseif (qcCompletedQuests[qcQuestID]["C"] == 2) then
					qcCompletedQuests[qcQuestID]["C"] = 1
				end
			end
		end
	elseif (IsLeftAltKeyDown()) then --[[ User wants to toggle the unattainable status of a quest ]]--
	  --print(string.format("%sLeft alt key is down",QCADDON_CHAT_TITLE))
		if (qcCompletedQuests[qcQuestID] == nil) then
			qcCompletedQuests[qcQuestID] = {["C"] = 2}
		else
			if (qcCompletedQuests[qcQuestID]["C"] == nil) then
				qcCompletedQuests[qcQuestID]["C"] = 2
			else
				if (qcCompletedQuests[qcQuestID]["C"] == 2) then
					qcCompletedQuests[qcQuestID]["C"] = 0
				elseif (qcCompletedQuests[qcQuestID]["C"] == 0) then
					qcCompletedQuests[qcQuestID]["C"] = 2
				elseif (qcCompletedQuests[qcQuestID]["C"] == 1) then
					qcCompletedQuests[qcQuestID]["C"] = 2
				end
			end
		end
  else
		-- print(string.format("%sLooking for Tom Tom.",QCADDON_CHAT_TITLE))
		if (IsAddOnLoaded('TomTom')) then
			local addedWayPoint;
			-- print(string.format("%sLooking for quest in db.",QCADDON_CHAT_TITLE))
			for qcMapIndex, qcMapEntry in pairs(qcPinDB) do
				for qcInitiatorIndex, qcInitiatorEntry in pairs(qcPinDB[qcMapIndex]) do
					for qcInitiatorQuestIndex, qcInitiatorQuestEntry in pairs(qcPinDB[qcMapIndex][qcInitiatorIndex][7]) do
						if (qcInitiatorQuestEntry == qcQuestID) then
							-- print(string.format("%sFound quest. Initiator: %s",QCADDON_CHAT_TITLE, qcInitiatorEntry[4]))
							-- print("/way " .. qcInitiatorEntry[5] .. qcInitiatorEntry[6])
							--TomTom:AddWaypoint(qcMapIndex, 0, qcInitiatorEntry[5]/100, qcInitiatorEntry[6]/100, {title=qcInitiatorEntry[4]})
							TomTom:AddWaypointToCurrentZone(qcInitiatorEntry[5], qcInitiatorEntry[6], qcInitiatorEntry[4])
							addedWayPoint = true
							break
						end
					end
				end
			end
			if (addedWayPoint) then
				TomTom:SetClosestWaypoint()
			end
		end
	end

  --print(string.format("%sUpdating quest list",QCADDON_CHAT_TITLE))
	qcUpdateQuestList(nil, qcMenuSlider:GetValue())

end

function qcFilterButton_OnClick(self, button, down) -- *
    InterfaceOptionsFrame_OpenToCategory(qcInterfaceOptions)
    InterfaceOptionsFrame_OpenToCategory(qcInterfaceOptions)
end

function qcCloseTooltip()
	qcQuestInformationTooltip:Hide()
	qcQuestReputationTooltip:Hide()
end

local function qcUpdateCompletedQuest(questId) -- *
	if (qcQuestDatabase[questId]) then
		if ((qcQuestDatabase[questId][6] == 2) or (qcQuestDatabase[questId][6] == 3)) then
			return nil
		end
	end
	if not (qcCompletedQuests[questId]) then qcCompletedQuests[questId] = {["C"]=1} end
end

local function qcNewDataChecks(questId) -- *
	if ((questId == nil) or (questId == 0)) then return nil end
	if not (qcQuestDatabase[questId]) then
		qcNewDataAlert.New = true
		qcNewDataAlert.Faction = false
		qcNewDataAlert.Race = false
		qcNewDataAlert.Class = false
		qcNewDataAlert:Show()
	else
		qcNewDataAlert:Hide()
		qcNewDataAlert.New = false
		qcNewDataAlert.Faction = false
		qcNewDataAlert.Race = false
		qcNewDataAlert.Class = false
		local factionFlag, raceFlag, classFlag = 0, 0, 0
		local playerFaction, _ = UnitFactionGroup("player")
		local _, playerRace = UnitRace("player")
		local _, playerClass = UnitClass("player")
		factionFlag = qcFactionBits[string.upper(playerFaction)]
		if (bit.band(factionFlag,qcQuestDatabase[questId][7]) == 0) then
			qcNewDataAlert.Faction = true
		end
		raceFlag = qcRaceBits[string.upper(playerRace)]
		if (bit.band(raceFlag,qcQuestDatabase[questId][8]) == 0) then
			qcNewDataAlert.Race = true
		end
		classFlag = qcClassBits[string.upper(playerClass)]
		if (bit.band(classFlag,qcQuestDatabase[questId][9]) == 0) then
			qcNewDataAlert.Class = true
		end
		if ((qcNewDataAlert.Faction) or (qcNewDataAlert.Race) or (qcNewDataAlert.Class)) then
			qcNewDataAlert:Show()
		end
	end
end

function qcNewDataAlert_OnEnter(self) -- *
	qcNewDataAlertTooltip:SetOwner(qcNewDataAlert, "ANCHOR_CURSOR")
	qcNewDataAlertTooltip:ClearLines()
	qcNewDataAlertTooltip:AddLine("Quest Completist")
	qcNewDataAlertTooltip:AddLine(COLOUR_HUNTER .. "Quest Completist was not aware of the following information. Please help improve the accuracy of the addon by submiting a post ore new issue over at curse", nil, nil, nil, true)
	if (qcNewDataAlert.New) then
		qcNewDataAlertTooltip:AddLine(COLOUR_MAGE .. " - Quest does not exist in the database.", nil, nil, nil, true)
		qcNewDataAlertTooltip:Show()
	end
	if (qcNewDataAlert.Faction) then
		qcNewDataAlertTooltip:AddLine(COLOUR_MAGE .. " - QC was not aware your FACTION could complete this quest.", nil, nil, nil, true)
	end
	if (qcNewDataAlert.Race) then
		qcNewDataAlertTooltip:AddLine(COLOUR_MAGE .. " - QC was not aware your RACE could complete this quest.", nil, nil, nil, true)
	end
	if (qcNewDataAlert.Class) then
		qcNewDataAlertTooltip:AddLine(COLOUR_MAGE .. " - QC was not aware your CLASS could complete this quest.", nil, nil, nil, true)
	end
	if ((qcNewDataAlert.New) or (qcNewDataAlert.Faction) or (qcNewDataAlert.Race) or (qcNewDataAlert.Class)) then
		qcNewDataAlertTooltip:Show()
	end
end

function qcNewDataAlert_OnLeave(self) -- *
	qcNewDataAlertTooltip:Hide()
end

local function qcBreadcrumbChecks(qcQuestID)

	if (qcQuestID == nil) or (qcQuestID == 0) then return nil end

	if (qcBreadcrumbQuests[qcQuestID] == nil) then
		qcToast.QuestID = nil
		qcToast:Hide()
	else
		qcToast.QuestID = qcQuestID
		local qcCount = 0
		for qcBreadcrumbIndex, qcBreadcrumbEntry in pairs(qcBreadcrumbQuests[qcQuestID]) do
			if (qcCompletedQuests[qcBreadcrumbEntry] == nil) then
				qcCount = (qcCount + 1)
			else
				if not (qcCompletedQuests[qcBreadcrumbEntry]["C"] == 1) then
					qcCount = (qcCount + 1)
				end
			end
		end
		if (qcCount == 0) then
			qcToast.QuestID = nil
			qcToast:Hide()
		else
			if (qcCount == 1) then
				qcToastText:SetText("1 Breadcrumb Available!")
			else
				qcToastText:SetText(string.format("%d Breadcrumbs Available!",qcCount))
			end
			qcToast:Show()
		end
	end

end

local function qcMutuallyExclusiveChecks(qcQuestID)

	if (qcQuestID == nil) or (qcQuestID == 0) then return nil end

	if (qcMutuallyExclusive[qcQuestID] == nil) then
		qcMutuallyExclusiveAlert.QuestID = nil
		qcMutuallyExclusiveAlert:Hide()
	else
		qcMutuallyExclusiveAlert.QuestID = qcQuestID
		qcMutuallyExclusiveAlert:Show()
	end

end

function qcMapTooltipSetup() -- *
	qcMapTooltip = CreateFrame("GameTooltip", "qcMapTooltip", UIParent, "GameTooltipTemplate")
	qcMapTooltip:SetFrameStrata("TOOLTIP")
	WorldMapFrame:HookScript("OnSizeChanged",
		function(self)
			qcMapTooltip:SetScale(1/self:GetScale())
		end
	)
end

function qcQuestReputationTooltipSetup() -- *
	qcQuestReputationTooltip = CreateFrame("GameTooltip", "qcQuestReputationTooltip", qcQuestCompletistUI, "GameTooltipTemplate")
	qcQuestReputationTooltip:SetFrameStrata("TOOLTIP")
end

function qcQuestInformationTooltipSetup() -- *
	qcQuestInformationTooltip = CreateFrame("GameTooltip", "qcQuestInformationTooltip", qcQuestCompletistUI, "GameTooltipTemplate")
	qcQuestInformationTooltip:SetFrameStrata("TOOLTIP")
end

function qcToastTooltipSetup() -- *
	qcToastTooltip = CreateFrame("GameTooltip", "qcToastTooltip", qcToast, "GameTooltipTemplate")
	qcToastTooltip:SetFrameStrata("TOOLTIP")
end

function qcNewDataAlertTooltipSetup() -- *
	qcNewDataAlertTooltip = CreateFrame("GameTooltip", "qcNewDataAlertTooltip", qcNewDataAlert, "GameTooltipTemplate")
	qcNewDataAlertTooltip:SetFrameStrata("TOOLTIP")
end

function qcMutuallyExclusiveAlertTooltipSetup() -- *
	qcMutuallyExclusiveAlertTooltip = CreateFrame("GameTooltip", "qcMutuallyExclusiveAlertTooltip", qcMutuallyExclusiveAlert, "GameTooltipTemplate")
	qcMutuallyExclusiveAlertTooltip:SetFrameStrata("TOOLTIP")
end

function qcGetToastQuestInformation(questId) -- *
	if (questId) then
		if (qcQuestDatabase[questId]) then
			return tostring(qcQuestDatabase[questId][2] or nil)
		end
	end
end

function qcToast_OnEnter(self)

	if (self.QuestID == nil) then
		qcToastTooltip:Hide()
	else
		qcToastTooltip:SetOwner(qcToast, "ANCHOR_CURSOR")
		qcToastTooltip:ClearLines()
		qcToastTooltip:AddLine("Breadcrumb Quests")
		for qcBreadcrumbIndex, qcBreadcrumbEntry in pairs(qcBreadcrumbQuests[self.QuestID]) do
			if (qcCompletedQuests[qcBreadcrumbEntry] == nil) then
				local qcQuestName = qcGetToastQuestInformation(qcBreadcrumbEntry)
				if (qcQuestName and qcBreadcrumbEntry) then qcToastTooltip:AddLine(tostring(COLOUR_DRUID .. qcQuestName .. COLOUR_MAGE .. " [" .. qcBreadcrumbEntry .. "]")) end
			else
				if not (qcCompletedQuests[qcBreadcrumbEntry]["C"] == 1) then
				local qcQuestName = qcGetToastQuestInformation(qcBreadcrumbEntry)
				if (qcQuestName and qcBreadcrumbEntry) then qcToastTooltip:AddLine(tostring(COLOUR_DRUID .. qcQuestName .. " [" .. qcBreadcrumbEntry .. "]")) end
				end
			end
		end
		qcToastTooltip:Show()
	end

end

function qcToast_OnLeave(self) -- *
	qcToastTooltip:Hide()
end

function qcMutuallyExclusiveQuestInformation(qcQuestID)

	if (qcQuestID) then
		if (qcQuestDatabase[qcQuestID]) then
			local qcQuestName = tostring(qcQuestDatabase[qcQuestID][2] or nil)
			return qcQuestName
		end
	end

	return nil

end

function qcMutuallyExclusiveAlert_OnEnter(self)

	if (self.QuestID == nil) then
		qcMutuallyExclusiveAlertTooltip:Hide()
	else
		qcMutuallyExclusiveAlertTooltip:SetOwner(qcMutuallyExclusiveAlert, "ANCHOR_BOTTOMRIGHT")
		qcMutuallyExclusiveAlertTooltip:ClearLines()
		qcMutuallyExclusiveAlertTooltip:AddLine("Quest Completist")
		qcMutuallyExclusiveAlertTooltip:AddLine(COLOUR_MAGE .. "This quest is mutually exclusive with others, meaning you can only complete one of them. The other quests are:", nil, nil, nil, true)
		for qcMutuallyExclusiveIndex, qcMutuallyExclusiveEntry in pairs(qcMutuallyExclusive[self.QuestID]) do
			if (qcQuestDatabase[qcMutuallyExclusiveEntry] == nil) then
				qcMutuallyExclusiveAlertTooltip:AddLine(string.format("%s<Quest Not Found In DB> [%d]|r",COLOUR_DRUID,qcMutuallyExclusiveEntry))
			else
				local qcQuestName = qcMutuallyExclusiveQuestInformation(qcMutuallyExclusiveEntry)
				if (qcQuestName and qcMutuallyExclusiveEntry) then qcMutuallyExclusiveAlertTooltip:AddLine(string.format("%s%s [%d]|r",COLOUR_DRUID,qcQuestName,qcMutuallyExclusiveEntry)) end
			end
		end
		qcMutuallyExclusiveAlertTooltip:Show()
	end
end

function qcMutuallyExclusiveAlert_OnLeave(self)

	qcMutuallyExclusiveAlertTooltip:Hide()

end

--[[ ##### MAP PINS START ##### ]]--

local function qcColouredQuestName(questId)
	if not (questId) then return nil end
	if not (qcQuestDatabase[questId]) then return nil end
	if ((qcQuestDatabase[questId][6] == 3) or (qcQuestDatabase[questId][6] == 2)) then
		return string.format("|cff178ed5%s|r",qcQuestDatabase[questId][2])
	elseif (qcCompletedQuests[questId] == nil) then
		return string.format("|cffffffff%s|r",qcQuestDatabase[questId][2])
	elseif ((qcCompletedQuests[questId]["C"] == 1) or (qcCompletedQuests[questId]["C"] == 2)) then
		return string.format("|cff00ff00%s|r",qcQuestDatabase[questId][2])
	else
		return string.format("|cffffffff%s [U]|r",qcQuestDatabase[questId][2])
	end
end

local function qcHideAllPins() -- *
	for i = #qcPinFrames, 1, -1 do
		qcPinFrames[i]:Hide()
		TableInsert(qcSparePinFrames, qcPinFrames[i])
		TableRemove(qcPinFrames,i)
	end
end

local function qcGetPin()
	local pin = nil
	if (#qcSparePinFrames > 0) then
		pin = qcSparePinFrames[1]
		TableRemove(qcSparePinFrames, 1)
	end
	if not (pin) then
		pin = CreateFrame("Frame", "qcPin", WorldMapDetailFrame)
		pin:SetWidth(16)
		pin:SetHeight(16)
		pin.Texture = pin:CreateTexture()
		pin.Texture:SetTexture("Interface\\Addons\\QuestCompletist\\Images\\QCIcons")
		pin.Texture:SetAllPoints()
		pin:EnableMouse(true)
		pin:SetFrameStrata(WorldMapDetailFrame:GetFrameStrata()) -- ****
		pin:SetFrameLevel(WorldMapPOIFrame:GetFrameLevel() + 1)
		pin:HookScript("OnEnter",
			function(self, motion)
				local frames = {}
				local frame = EnumerateFrames()
				while (frame) do
					if (frame:IsVisible() and MouseIsOver(frame) and (frame:GetName() == "qcPin")) then
						TableInsert(frames, frame)
					end
					frame = EnumerateFrames(frame)
				end
				qcMapTooltip:SetParent(self)
				qcMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
				qcMapTooltip:ClearLines()
				for i, e in pairs(frames) do -- TODO: Possible ipairs?
					local initiatorsIndex = e.PinIndex
					if (qcPins[initiatorsIndex][3] == 0) then
						qcMapTooltip:AddLine(qcPins[initiatorsIndex][4] or StringFormat("%s %s",UnitName("player"),"|cff69ccf0<Yourself>|r"))
					else
						qcMapTooltip:AddDoubleLine(qcPins[initiatorsIndex][4] or StringFormat("%s %s",UnitName("player"),"|cff69ccf0<Yourself>|r"), StringFormat("|cffff7d0a[%d]|r",qcPins[initiatorsIndex][3]))
					end
					for qcIndex, qcEntry in ipairs(qcPins[initiatorsIndex][7]) do
						qcMapTooltip:AddDoubleLine(tostring(qcColouredQuestName(qcEntry)), StringFormat("|cffff7d0a[%d]|r",tostring(qcEntry)))
						if (#qcPins[initiatorsIndex][7] <= 10) then
							--[[ Order by most likely first, always leaving completed until the end ]]--
							--[[ TODO: Create a texture object and use in-game texture with SetTexCoord ]]--
							if (qcQuestDatabase[qcEntry]) then
								if (qcQuestDatabase[qcEntry][6] == 3) then
									qcMapTooltip:AddTexture("Interface\\Addons\\QuestCompletist\\Images\\DailyQuestIcon")
								elseif (qcQuestDatabase[qcEntry][6] == 2) then
									qcMapTooltip:AddTexture("Interface\\Addons\\QuestCompletist\\Images\\DailyActiveQuestIcon")
								elseif (qcCompletedQuests[qcEntry] ~= nil) and (qcCompletedQuests[qcEntry]["C"] == 1 or qcCompletedQuests[qcEntry]["C"] == 2) then
									qcMapTooltip:AddTexture("Interface\\Addons\\QuestCompletist\\Images\\QuestCompleteIcon")
								else
									qcMapTooltip:AddTexture("Interface\\Addons\\QuestCompletist\\Images\\AvailableQuestIcon")
								end
							end
						end
					end
					if (qcPins[initiatorsIndex][8]) then
						qcMapTooltip:AddLine(StringFormat("|cffabd473%s|r",qcPins[initiatorsIndex][8]),nil,nil,nil,true)
					end
				end
				qcMapTooltip:Show()
			end
		)
		pin:HookScript("OnLeave",
			function(self)
				qcMapTooltip:Hide()
			end
		)
	end
	TableInsert(qcPinFrames, pin)
	return pin
end

local function qcShowPin(index, icon) -- *
	local pin = qcGetPin()
	pin:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", (qcPins[index][5] / 100) * WorldMapDetailFrame:GetWidth(), (-qcPins[index][6] / 100) * WorldMapDetailFrame:GetHeight())
	pin.PinIndex = index
	if (icon == 1) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_NORMAL))
	elseif (icon == 3) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_DAILY))
	elseif (icon == 2) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_REPEATABLE))
	elseif (icon == 5) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_SEASONAL))
	elseif (icon == 4) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_SPECIAL))
	elseif (icon == 6) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_PROFESSION))
	elseif (icon == 7) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_ITEMDROPSTANDARD))
	elseif (icon == 8) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_ITEMDROPREPEATABLE))
	elseif (icon == 9) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_CLASS))
	elseif (icon == 10) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_KILL))
	elseif (icon == 11) then
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_WORLDQUEST))
	else
		pin.Texture:SetTexCoord(unpack(QC_ICON_COORDS_NORMAL))
	end
	pin:Show()
end

local function qcRefreshPins(uimapId, mapLevel)
	if not (WorldMapFrame:IsVisible()) then return nil end
	qcHideAllPins()
	wipe(qcPins)
	if (qcSettings.QC_M_SHOW_ICONS == 0) or (qcPinDB[uimapId] == nil) then
		wipe(qcPins)
		return nil
	end
	qcPins = qcCopyTable(qcPinDB[uimapId])
	for i = #qcPins, 1, -1 do
		if not (qcPins[i][1] == mapLevel) then
			TableRemove(qcPins,i)
		end
	end
	if (qcSettings.QC_M_HIDE_LOWLEVEL == 1) then
		for i = #qcPins, 1, -1 do
			for questIndex = #qcPins[i][7], 1, -1 do
				local questId = qcPins[i][7][questIndex]
				if (qcQuestDatabase[questId]) then
					local questLevel = qcQuestDatabase[questId][3] or 0
					local greenCutoff = (UnitLevel("player") - GetQuestGreenRange())
					if (questLevel < greenCutoff) then
						TableRemove(qcPins[i][7],questIndex)
					end
				else
					TableRemove(qcPins[i][7],questIndex)
				end
			end
			if (#qcPins[i][7] == 0) then
				TableRemove(qcPins, i)
			end
		end
	end
	if (qcSettings["QC_M_HIDE_COMPLETED"] == 1) then
		for i = #qcPins, 1, -1 do
			for qcQuestIndex = #qcPins[i][7], 1, -1 do
				local qcQuestID = qcPins[i][7][qcQuestIndex]
				if (qcCompletedQuests[qcQuestID]) and ((qcCompletedQuests[qcQuestID]["C"] == 1) or (qcCompletedQuests[qcQuestID]["C"] == 2)) then
					TableRemove(qcPins[i][7], qcQuestIndex)
				end
			end
			if (#qcPins[i][7] == 0) then
				TableRemove(qcPins, i)
			end
		end
	end

	--[[ Faction ]]--
	if (qcSettings["QC_ML_HIDE_FACTION"] == 1) then
		for i = #qcPins, 1, -1 do
			for qcQuestIndex = #qcPins[i][7], 1, -1 do
				local qcQuestID = qcPins[i][7][qcQuestIndex]
				local qcCurrentPlayerFaction, _S = UnitFactionGroup("player")
				local qcCurrentFaction = qcFactionBits[string.upper(qcCurrentPlayerFaction)]
				if (qcQuestDatabase[qcQuestID]) and (BitBand(qcQuestDatabase[qcQuestID][7], qcCurrentFaction) == 0) then
					TableRemove(qcPins[i][7], qcQuestIndex)
				end
			end
			if (#qcPins[i][7] == 0) then
				TableRemove(qcPins, i)
			end
		end
	end

	--[[ Race\Class ]]--
	if (qcSettings["QC_ML_HIDE_RACECLASS"] == 1) then
		for i = #qcPins, 1, -1 do
			for qcQuestIndex = #qcPins[i][7], 1, -1 do
				local qcQuestID = qcPins[i][7][qcQuestIndex]
				local _S, qcCurrentPlayerRace = UnitRace("player")
				local qcCurrentRace = qcRaceBits[string.upper(qcCurrentPlayerRace)]
				local _S, qcCurrentPlayerClass = UnitClass("player")
				local qcCurrentClass = qcClassBits[string.upper(qcCurrentPlayerClass)]
				if (qcQuestDatabase[qcQuestID]) and (BitBand(qcQuestDatabase[qcQuestID][8], qcCurrentRace) == 0) then
					TableRemove(qcPins[i][7], qcQuestIndex)
				elseif (qcQuestDatabase[qcQuestID]) and (BitBand(qcQuestDatabase[qcQuestID][9], qcCurrentClass) == 0) then
					TableRemove(qcPins[i][7], qcQuestIndex)
				end
			end
			if (#qcPins[i][7] == 0) then
				TableRemove(qcPins, i)
			end
		end
	end

	--[[ Seasonal ]]--
	if (qcSettings["QC_M_HIDE_SEASONAL"] == 1) then
		local qcToday = date("%y%m%d")
		for i = #qcPins, 1, -1 do
			for qcQuestIndex = #qcPins[i][7], 1, -1 do
				local qcQuestID = qcPins[i][7][qcQuestIndex]
				if (qcQuestDatabase[qcQuestID]) and (qcQuestDatabase[qcQuestID][11] > 0) then
					if not ((qcToday >= qcHolidayDates[qcQuestDatabase[qcQuestID][11]][1]) and (qcToday <= qcHolidayDates[qcQuestDatabase[qcQuestID][11]][2])) then
						TableRemove(qcPins[i][7], qcQuestIndex)
					end
				end
			end
			if (#qcPins[i][7] == 0) then
				TableRemove(qcPins, i)
			end
		end
	end

	--[[ Professions ]]--
	if (qcSettings["QC_M_HIDE_PROFESSION"] == 1) then
		local qcProfessionBitwise = 0
		local qcProfessions = {GetProfessions()}
		for qcIndex, qcEntry in pairs(qcProfessions) do
			local qcName, qcTexture, _S, _S, _S, _S, qcProfessionID, _S = GetProfessionInfo(qcEntry)
			qcProfessionBitwise = (qcProfessionBitwise + qcProfessionBits[qcProfessionID])
		end
		for i = #qcPins, 1, -1 do
			for qcQuestIndex = #qcPins[i][7], 1, -1 do
				local qcQuestID = qcPins[i][7][qcQuestIndex]
				if (qcQuestDatabase[qcQuestID]) and (qcQuestDatabase[qcQuestID][10] > 0) then
					if (BitBand(qcQuestDatabase[qcQuestID][10], qcProfessionBitwise) == 0) then
						TableRemove(qcPins[i][7], qcQuestIndex)
					end
				end
			end
			if (#qcPins[i][7] == 0) then
				TableRemove(qcPins, i)
			end
		end
	end

	--[[ In progress ]]--
	if (qcSettings["QC_M_HIDE_INPROGRESS"] == 1) then
		for i = #qcPins, 1, -1 do
			for qcQuestIndex = #qcPins[i][7], 1, -1 do
				local qcQuestID = qcPins[i][7][qcQuestIndex]
				if (GetQuestLogIndexByID(qcQuestID) ~= 0) then
					TableRemove(qcPins[i][7], qcQuestIndex)
				end
			end
			if (#qcPins[i][7] == 0) then
				TableRemove(qcPins, i)
			end
		end
	end

	--[[ Empty quest sub-tables ]]--
	for i = #qcPins, 1, -1 do
		if (#qcPins[i][7] == 0) then
			TableRemove(qcPins, i)
		end
	end

	--[[ Check if only 1 quest remains for each initiator, and customize icon for that final quest ]]--
	for i = #qcPins, 1, -1 do
		local qcIconType = qcPins[i][2]
		if (#qcPins[i][7] == 1) then
			local qcQuestID = qcPins[i][7][1]
			if ((qcQuestDatabase[qcQuestID]) and (qcIconType == 1)) then
				if (qcQuestDatabase[qcQuestID][6] == 1) then
					qcIconType = 1
				elseif (qcQuestDatabase[qcQuestID][6] == 3) then
					qcIconType = 3
				elseif (qcQuestDatabase[qcQuestID][6] == 2) then
					qcIconType = 2
				elseif (qcQuestDatabase[qcQuestID][6] == 4) then
					qcIconType = 4
				end
			end
		end
		qcShowPin(i, qcIconType)
	end

end

--[[ ##### MAP PINS END ##### ]]--

--[[ ##### INTERFACE OPTIONS START ##### ]]--

function qcInterfaceOptions_Okay(self) -- *
	qcUpdateQuestList(qcCurrentCategoryID, 1)
	qcRefreshPins(C_Map.GetBestMapForUnit("player"))
end

function qcInterfaceOptions_Cancel(self) -- *
end

function qcInterfaceOptions_OnShow(self)
	local qcL = qcLocalize

    qcConfigTitle = self:CreateFontString("qcConfigTitle", "ARTWORK", "GameFontNormalLarge")
    qcConfigTitle:SetPoint("TOPLEFT", 16, -16)
    qcConfigTitle:SetText(qcL.CONFIGTITLE)

    qcConfigSubtitle = self:CreateFontString("qcConfigSubtitle", "ARTWORK", "GameFontHighlightSmall")
    qcConfigSubtitle:SetHeight(22) -- Hight from top to put the checkbox in filters
    qcConfigSubtitle:SetPoint("TOPLEFT", qcConfigTitle, "BOTTOMLEFT", 0, -8)
    qcConfigSubtitle:SetPoint("RIGHT", self, -32, 0)
    qcConfigSubtitle:SetNonSpaceWrap(true)
    qcConfigSubtitle:SetJustifyH("LEFT")
    qcConfigSubtitle:SetJustifyV("TOP")
    qcConfigSubtitle:SetText(qcL.CONFIGSUBTITLE)

    qcMapFiltersTitle = self:CreateFontString("qcMapFiltersTitle", "ARTWORK", "GameFontNormal")
    qcMapFiltersTitle:SetPoint("TOPLEFT", qcConfigSubtitle, "BOTTOMLEFT", 16, -4)
    qcMapFiltersTitle:SetText(qcL.MAPFILTERS)

	qcIO_M_SHOW_ICONS = CreateFrame("CheckButton", "qcIO_M_SHOW_ICONS", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_M_SHOW_ICONS:SetPoint("TOPLEFT", qcMapFiltersTitle, "BOTTOMLEFT", 16, -6)
	_G[qcIO_M_SHOW_ICONS:GetName().."Text"]:SetText(qcL.SHOWMAPICONS)
	qcIO_M_SHOW_ICONS:SetScript("OnClick", function(self)
		if (qcIO_M_SHOW_ICONS:GetChecked() == false) then
			qcSettings.QC_M_SHOW_ICONS = 0
		else
			qcSettings.QC_M_SHOW_ICONS = 1
		end
	end)

	qcIO_M_HIDE_COMPLETED = CreateFrame("CheckButton", "qcIO_M_HIDE_COMPLETED", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_M_HIDE_COMPLETED:SetPoint("TOPLEFT", qcIO_M_SHOW_ICONS, "BOTTOMLEFT", 0, 0)
	_G[qcIO_M_HIDE_COMPLETED:GetName().."Text"]:SetText(qcL.HIDECOMPLETEDQUESTS)
	qcIO_M_HIDE_COMPLETED:SetScript("OnClick", function(self)
		if (qcIO_M_HIDE_COMPLETED:GetChecked() == false) then
			qcSettings.QC_M_HIDE_COMPLETED = 0
		else
			qcSettings.QC_M_HIDE_COMPLETED = 1
		end
	end)

	qcIO_M_HIDE_LOWLEVEL = CreateFrame("CheckButton", "qcIO_M_HIDE_LOWLEVEL", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_M_HIDE_LOWLEVEL:SetPoint("TOPLEFT", qcIO_M_HIDE_COMPLETED, "BOTTOMLEFT", 0, 0)
	_G[qcIO_M_HIDE_LOWLEVEL:GetName().."Text"]:SetText(qcL.HIDELOWLEVELQUESTS)
	qcIO_M_HIDE_LOWLEVEL:SetScript("OnClick", function(self)
		if (qcIO_M_HIDE_LOWLEVEL:GetChecked() == false) then
			qcSettings.QC_M_HIDE_LOWLEVEL = 0
		else
			qcSettings.QC_M_HIDE_LOWLEVEL = 1
		end
	end)

	qcIO_M_HIDE_PROFESSION = CreateFrame("CheckButton", "qcIO_M_HIDE_PROFESSION", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_M_HIDE_PROFESSION:SetPoint("TOPLEFT", qcIO_M_HIDE_LOWLEVEL, "BOTTOMLEFT", 0, 0)
	_G[qcIO_M_HIDE_PROFESSION:GetName().."Text"]:SetText(qcL.HIDEOTHERPROFESSIONQUESTS)
	qcIO_M_HIDE_PROFESSION:SetScript("OnClick", function(self)
		if (qcIO_M_HIDE_PROFESSION:GetChecked() == false) then
			qcSettings.QC_M_HIDE_PROFESSION = 0
		else
			qcSettings.QC_M_HIDE_PROFESSION = 1
		end
	end)

--diabled whit line 1548 ->1552 getting behind other filter
--	qcIO_M_HIDE_WORLDQUEST = CreateFrame("CheckButton", "qcIO_M_HIDE_WORLDQUEST", self, "InterfaceOptionsCheckButtonTemplate")
--    qcIO_M_HIDE_WORLDQUEST:SetPoint("TOPLEFT", qcIO_M_HIDE_LOWLEVEL, "BOTTOMLEFT", 0, 0)
--	_G[qcIO_M_HIDE_WORLDQUEST:GetName().."Text"]:SetText(qcL.HIDEWORLDQUEST)
--	qcIO_M_HIDE_WORLDQUEST:SetScript("OnClick", function(self)
--		if (qcIO_M_HIDE_WORLDQUEST:GetChecked() == false) then
--			qcSettings.QC_M_HIDE_WORLDQUEST = 0
--		else
--			qcSettings.QC_M_HIDE_WORLDQUEST = 1
--		end
--	end)

	qcIO_M_HIDE_SEASONAL = CreateFrame("CheckButton", "qcIO_M_HIDE_SEASONAL", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_M_HIDE_SEASONAL:SetPoint("TOPLEFT", qcIO_M_HIDE_PROFESSION, "BOTTOMLEFT", 0, 0)
	_G[qcIO_M_HIDE_SEASONAL:GetName().."Text"]:SetText(qcL.HIDENONACTIVESEASONALQUESTS)
	qcIO_M_HIDE_SEASONAL:SetScript("OnClick", function(self)
		if (qcIO_M_HIDE_SEASONAL:GetChecked() == false) then
			qcSettings.QC_M_HIDE_SEASONAL = 0
		else
			qcSettings.QC_M_HIDE_SEASONAL = 1
		end
	end)

	qcIO_M_HIDE_INPROGRESS = CreateFrame("CheckButton", "qcIO_M_HIDE_INPROGRESS", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_M_HIDE_INPROGRESS:SetPoint("TOPLEFT", qcIO_M_HIDE_SEASONAL, "BOTTOMLEFT", 0, 0)
	_G[qcIO_M_HIDE_INPROGRESS:GetName().."Text"]:SetText(qcL.HIDEINPROGRESSQUESTS)
	qcIO_M_HIDE_INPROGRESS:SetScript("OnClick", function(self)
		if (qcIO_M_HIDE_INPROGRESS:GetChecked() == false) then
			qcSettings.QC_M_HIDE_INPROGRESS = 0
		else
			qcSettings.QC_M_HIDE_INPROGRESS = 1
		end
	end)

--- Quest List Filters Start ---
    qcListFiltersTitle = self:CreateFontString("qcListFiltersTitle", "ARTWORK", "GameFontNormal")
    qcListFiltersTitle:SetPoint("TOPLEFT", qcConfigSubtitle, "BOTTOMLEFT", 16, -185)
    qcListFiltersTitle:SetText(qcL.QUESTLISTFILTERS)

	qcIO_L_HIDE_COMPLETED = CreateFrame("CheckButton", "qcIO_L_HIDE_COMPLETED", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_L_HIDE_COMPLETED:SetPoint("TOPLEFT", qcListFiltersTitle, "BOTTOMLEFT", 16, -6)
	_G[qcIO_L_HIDE_COMPLETED:GetName().."Text"]:SetText(qcL.HIDECOMPLETEDQUESTS)
	qcIO_L_HIDE_COMPLETED:SetScript("OnClick", function(self)
		if (qcIO_L_HIDE_COMPLETED:GetChecked() == false) then
			qcSettings.QC_L_HIDE_COMPLETED = 0
		else
			qcSettings.QC_L_HIDE_COMPLETED = 1
		end
	end)

	qcIO_L_HIDE_LOWLEVEL = CreateFrame("CheckButton", "qcIO_L_HIDE_LOWLEVEL", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_L_HIDE_LOWLEVEL:SetPoint("TOPLEFT", qcIO_L_HIDE_COMPLETED, "BOTTOMLEFT", 0, 0)
	_G[qcIO_L_HIDE_LOWLEVEL:GetName().."Text"]:SetText(qcL.HIDELOWLEVELQUESTS .. COLOUR_DEATHKNIGHT .. " (Not Yet Implemented)")
	qcIO_L_HIDE_LOWLEVEL:SetScript("OnClick", function(self)
		if (qcIO_L_HIDE_LOWLEVEL:GetChecked() == false) then
			qcSettings.QC_L_HIDE_LOWLEVEL = 0
		else
			qcSettings.QC_L_HIDE_LOWLEVEL = 1
		end
	end)

	qcIO_L_HIDE_PROFESSION = CreateFrame("CheckButton", "qcIO_L_HIDE_PROFESSION", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_L_HIDE_PROFESSION:SetPoint("TOPLEFT", qcIO_L_HIDE_LOWLEVEL, "BOTTOMLEFT", 0, 0)
	_G[qcIO_L_HIDE_PROFESSION:GetName().."Text"]:SetText(qcL.HIDEOTHERPROFESSIONQUESTS .. COLOUR_DEATHKNIGHT .. " (Not Yet Implemented)")
	qcIO_L_HIDE_PROFESSION:SetScript("OnClick", function(self)
		if (qcIO_L_HIDE_PROFESSION:GetChecked() == false) then
			qcSettings.QC_L_HIDE_PROFESSION = 0
		else
			qcSettings.QC_L_HIDE_PROFESSION = 1
		end
	end)

--diabled whit line 1578 ->1582 getting behind other filter
	--qcIO_L_HIDE_WORLDQUEST = CreateFrame("CheckButton", "qcIO_L_HIDE_WORLDQUEST", self, "InterfaceOptionsCheckButtonTemplate")
   -- qcIO_L_HIDE_WORLDQUEST:SetPoint("TOPLEFT", qcIO_L_HIDE_LOWLEVEL, "BOTTOMLEFT", 0, 0)
	--_G[qcIO_L_HIDE_WORLDQUEST:GetName().."Text"]:SetText(qcL.HIDEWORLDQUEST .. COLOUR_DEATHKNIGHT .. " (Not Yet Implemented)")
	--qcIO_L_HIDE_WORLDQUEST:SetScript("OnClick", function(self)
	--	if (qcIO_L_HIDE_WORLDQUEST:GetChecked() == false) then
	--		qcSettings.QC_L_HIDE_WORLDQUEST = 0
	--	else
	--		qcSettings.QC_L_HIDE_WORLDQUEST = 1
	--	end
	--end)

--- Combined Map and Quest FILTERS
    qcCombinedFiltersTitle = self:CreateFontString("qcCombinedFiltersTitle", "ARTWORK", "GameFontNormal")
    qcCombinedFiltersTitle:SetPoint("TOPLEFT", qcConfigSubtitle, "BOTTOMLEFT", 16, -350)
    qcCombinedFiltersTitle:SetText(qcL.COMBINEDMAPANDQUESTFILTERS)

	qcIO_ML_HIDE_FACTION = CreateFrame("CheckButton", "qcIO_ML_HIDE_FACTION", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_ML_HIDE_FACTION:SetPoint("TOPLEFT", qcCombinedFiltersTitle, "BOTTOMLEFT", 16, -6)
	_G[qcIO_ML_HIDE_FACTION:GetName().."Text"]:SetText(qcL.HIDEOTHERFACTIONQUESTS)
	qcIO_ML_HIDE_FACTION:SetScript("OnClick", function(self)
		if (qcIO_ML_HIDE_FACTION:GetChecked() == false) then
			qcSettings.QC_ML_HIDE_FACTION = 0
		else
			qcSettings.QC_ML_HIDE_FACTION = 1
		end
	end)

	qcIO_ML_HIDE_RACECLASS = CreateFrame("CheckButton", "qcIO_ML_HIDE_RACECLASS", self, "InterfaceOptionsCheckButtonTemplate")
    qcIO_ML_HIDE_RACECLASS:SetPoint("TOPLEFT", qcIO_ML_HIDE_FACTION, "BOTTOMLEFT", 0, 0)
	_G[qcIO_ML_HIDE_RACECLASS:GetName().."Text"]:SetText(qcL.HIDEOTHERRACEANDCLASSQUESTS)
	qcIO_ML_HIDE_RACECLASS:SetScript("OnClick", function(self)
		if (qcIO_ML_HIDE_RACECLASS:GetChecked() == false) then
			qcSettings.QC_ML_HIDE_RACECLASS = 0
		else
			qcSettings.QC_ML_HIDE_RACECLASS = 1
		end
	end)

    self:SetScript("OnShow", qcConfigRefresh) 
    qcConfigRefresh(self)

end

function qcConfigRefresh(self)
	if not (self:IsVisible()) then return end
	--[[ Set control values here ]]--
end

function qcInterfaceOptions_OnLoad(self)

	self.name = "Quest Completist"
	self.okay = function(self) qcInterfaceOptions_Okay(self) end
	self.cancel = function(self) qcInterfaceOptions_Cancel(self) end
	InterfaceOptions_AddCategory(self)

end

--[[ ##### INTERFACE OPTIONS END ##### ]]--

local function qcWelcomeMessage()
	print(string.format("%sThanks for using Quest Completist. Spot a quest innaccuracy? Please report it on curse",QCADDON_CHAT_TITLE))
	print(string.format("%sWarning!!! Map Pins are missing, we are working on a solution no eta",QCADDON_CHAT_TITLE))
end

local function qcCheckSettings()

	if (qcSettings == nil) then
		qcSettings = {}
	end

	if (qcSettings.SORT == nil) then --[[ 1:Level, 2:Alpha, 3:Quest Giver ]]--
		qcSettings.SORT = 1
	end
	if (qcSettings.PURGED == nil) then
		qcSettings.PURGED = 0
	end

	--[[ Interface Options ]]--

	if (qcSettings.QC_M_SHOW_ICONS == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_M_SHOW_ICONS = 1
	end
	if (qcSettings.QC_M_HIDE_COMPLETED == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_M_HIDE_COMPLETED = 0
	end
	if (qcSettings.QC_M_HIDE_LOWLEVEL == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_M_HIDE_LOWLEVEL = 0
	end
	if (qcSettings.QC_M_HIDE_PROFESSION == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_M_HIDE_PROFESSION = 1
	end
	if (qcSettings.QC_M_HIDE_WORLDQUEST == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_M_HIDE_WORLDQUEST = 1
	end
	if (qcSettings.QC_M_HIDE_SEASONAL == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_M_HIDE_SEASONAL = 1
	end
	if (qcSettings.QC_M_HIDE_INPROGRESS == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_M_HIDE_INPROGRESS = 0
	end
	if (qcSettings.QC_L_HIDE_COMPLETED == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_L_HIDE_COMPLETED = 0
	end
	if (qcSettings.QC_L_HIDE_LOWLEVEL == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_L_HIDE_LOWLEVEL = 0
	end
	if (qcSettings.QC_L_HIDE_PROFESSION == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_L_HIDE_PROFESSION = 1
	end
	if (qcSettings.QC_L_HIDE_WORLDQUEST == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_L_HIDE_WORLDQUEST = 1
	end
	if (qcSettings.QC_ML_HIDE_FACTION == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_ML_HIDE_FACTION = 1
	end
	if (qcSettings.QC_ML_HIDE_RACECLASS == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_ML_HIDE_RACECLASS = 1
	end
	if (qcSettings.QC_SERVER_QUERY_COMPLETE == nil) then --[[ 0:No, 1:Yes ]]--
		qcSettings.QC_SERVER_QUERY_COMPLETE = 0
	end
	if (qcSettings.QCIO_M_HIDE_DAILYREPEATABLE == nil) then
		qcSettings.QCIO_M_HIDE_DAILYREPEATABLE = 0
	end

end

local function qcApplySettings()

	if (qcSettings.QC_M_SHOW_ICONS == 0) then
		qcIO_M_SHOW_ICONS:SetChecked(false)
	else
		qcIO_M_SHOW_ICONS:SetChecked(true)
	end
	if (qcSettings.QC_M_HIDE_COMPLETED == 0) then
		qcIO_M_HIDE_COMPLETED:SetChecked(false)
	else
		qcIO_M_HIDE_COMPLETED:SetChecked(true)
	end
	if (qcSettings.QC_M_HIDE_LOWLEVEL == 0) then
		qcIO_M_HIDE_LOWLEVEL:SetChecked(false)
	else
		qcIO_M_HIDE_LOWLEVEL:SetChecked(true)
	end
	if (qcSettings.QC_M_HIDE_PROFESSION == 0) then
		qcIO_M_HIDE_PROFESSION:SetChecked(false)
	else
		qcIO_M_HIDE_PROFESSION:SetChecked(true)
	end
--	if (qcSettings.QC_M_HIDE_WORLDQUEST == 0) then
--		qcIO_M_HIDE_WORLDQUEST:SetChecked(false)
--	else
--		qcIO_M_HIDE_WORLDQUEST:SetChecked(true)
--	end
	if (qcSettings.QC_M_HIDE_SEASONAL == 0) then
		qcIO_M_HIDE_SEASONAL:SetChecked(false)
	else
		qcIO_M_HIDE_SEASONAL:SetChecked(true)
	end
	if (qcSettings.QC_M_HIDE_INPROGRESS == 0) then
		qcIO_M_HIDE_INPROGRESS:SetChecked(false)
	else
		qcIO_M_HIDE_INPROGRESS:SetChecked(true)
	end
	if (qcSettings.QC_L_HIDE_COMPLETED == 0) then
		qcIO_L_HIDE_COMPLETED:SetChecked(false)
	else
		qcIO_L_HIDE_COMPLETED:SetChecked(true)
	end
	if (qcSettings.QC_L_HIDE_LOWLEVEL == 0) then
		qcIO_L_HIDE_LOWLEVEL:SetChecked(false)
	else
		qcIO_L_HIDE_LOWLEVEL:SetChecked(true)
	end
	if (qcSettings.QC_L_HIDE_PROFESSION == 0) then
		qcIO_L_HIDE_PROFESSION:SetChecked(false)
	else
		qcIO_L_HIDE_PROFESSION:SetChecked(true)
	end
	--if (qcSettings.QC_L_HIDE_WORLDQUEST == 0) then
	--	qcIO_L_HIDE_WORLDQUEST:SetChecked(false)
	--else
	--	qcIO_L_HIDE_WORLDQUEST:SetChecked(true)
	--end

	if (qcSettings.QC_ML_HIDE_FACTION == 0) then
		qcIO_ML_HIDE_FACTION:SetChecked(false)
	else
		qcIO_ML_HIDE_FACTION:SetChecked(true)
	end
	if (qcSettings.QC_ML_HIDE_RACECLASS == 0) then
		qcIO_ML_HIDE_RACECLASS:SetChecked(false)
	else
		qcIO_ML_HIDE_RACECLASS:SetChecked(true)
	end

	if (QCADDON_PURGE == true) then
		if not (qcSettings.PURGED == QCADDON_VERSION) then
			qcPurgeCollectedCache()
			qcSettings.PURGED = QCADDON_VERSION
		end
	end

	if (qcSettings.QC_SERVER_QUERY_COMPLETE == 1) then
		print(string.format("%s%s",QCADDON_CHAT_TITLE,qcL.QUERYREQUESTED))
		qcQuestCompletistUI:RegisterEvent("QUEST_QUERY_COMPLETE")
		QueryQuestsCompleted()
	end

end

local function qcEventHandler(self, event, ...)
	if (event == "ADVENTURE_MAP_OPEN") then
		qcRefreshPins(C_Map.GetBestMapForUnit("player"))
	elseif (event == "UNIT_QUEST_LOG_CHANGED") then
		if (... == "player") then qcUpdateQuestList(nil, qcMenuSlider:GetValue()) end
	elseif (event == "ZONE_CHANGED_NEW_AREA") then
		qcZoneChangedNewArea()
	elseif (event == "QUEST_ITEM_UPDATE") then
		if (QuestFrame:IsShown()) then QuestFrameNpcNameText:SetText(string.format("%s [%d]",UnitName("questnpc") or "nil",GetQuestID())) end
	elseif (event == "QUEST_DETAIL") then
		local qcQuestID = GetQuestID()
		if (QuestFrame:IsShown()) then QuestFrameNpcNameText:SetText(string.format("%s [%d]",UnitName("questnpc") or "nil",GetQuestID())) end
		qcBreadcrumbChecks(qcQuestID)
		qcNewDataChecks(qcQuestID)
		qcMutuallyExclusiveChecks(qcQuestID)
		if (QCDEBUG_MODE) then qcVerifyMapDataExists() end
	elseif (event == "QUEST_ACCEPTED") then
		qcUpdateQuestList(nil, qcMenuSlider:GetValue())
	elseif (event == "QUEST_PROGRESS") then
		local qcQuestID = GetQuestID()
		if (QuestFrame:IsShown()) then QuestFrameNpcNameText:SetText(string.format("%s [%d]",UnitName("questnpc") or "nil",GetQuestID())) end
		if not (qcQuestID == 0) then
			qcBreadcrumbChecks(qcQuestID)
			qcNewDataChecks(qcQuestID)
			qcMutuallyExclusiveChecks(qcQuestID)
		end
	elseif (event == "QUEST_COMPLETE") then
		local qcQuestID = GetQuestID()
		if (QuestFrame:IsShown()) then QuestFrameNpcNameText:SetText(string.format("%s [%d]",UnitName("questnpc") or "nil",GetQuestID())) end
		if not (qcQuestID == 0) then
			qcBreadcrumbChecks(qcQuestID)
			qcNewDataChecks(qcQuestID)
			qcMutuallyExclusiveChecks(qcQuestID)
			qcUpdateCompletedQuest(qcQuestID)
			qcUpdateMutuallyExclusiveCompletedQuest(qcQuestID)
			qcUpdateSkippedBreadcrumbQuest(qcQuestID)
			qcUpdateQuestList(nil, qcMenuSlider:GetValue())
			
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
			qcQuestQueryCompleted()
			qcZoneChangedNewArea()
	elseif (event == "ADDON_LOADED") then
		if (... == "QuestCompletist") then
			if not (qcCompletedQuests) then qcCompletedQuests = {} end
			if not (qcWorkingDB) then qcWorkingDB = {} end
			if not (qcWorkingLog) then qcWorkingLog = {} end
			qcCheckSettings()
			qcApplySettings()
			qcWelcomeMessage()
			qcZoneChangedNewArea()
			qcMenuSlider:SetValueStep(1);
			qcMenuSlider:SetObeyStepOnDrag(true);
		end
	end

end

function qcQuestCompletistUI_OnShow(self)
	if (qcSettings) then
		qcUpdateQuestList(qcCurrentCategoryID,qcMenuSlider:GetValue())
	end
end

function qcQuestCompletistUI_OnLoad(self)
	SetPortraitToTexture(self.qcPortrait, "Interface\\ICONS\\TRADE_ARCHAEOLOGY_DRAENEI_TOME")
	self.qcTitleText:SetText(string.format("Quest Completist v%s", QCADDON_VERSION))
	self.qcCategoryDropdownButton:SetText(GetText("CATEGORIES"))
	self.qcOptionsButton:SetText(GetText("FILTERS"))
	self:RegisterForDrag("LeftButton")
	self:RegisterEvent("QUEST_COMPLETE")
	self:RegisterEvent("QUEST_DETAIL")
	self:RegisterEvent("QUEST_PROGRESS")
	self:RegisterEvent("QUEST_ACCEPTED")
	self:RegisterEvent("QUEST_ITEM_UPDATE")
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ADDON_LOADED")
	--self:RegisterEvent("ADVENTURE_MAP_OPEN")
	self:SetScript("OnEvent", qcEventHandler)
	qcQuestInformationTooltipSetup()
	qcQuestReputationTooltipSetup()
	qcMapTooltipSetup()
	qcToastTooltipSetup()
	qcNewDataAlertTooltipSetup()
	qcMutuallyExclusiveAlertTooltipSetup()
end