local function qcRound(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function qcUpdateInitiatorData()

	for qcIndex, qcEntry in pairs(qcWorkingDB) do
		if (qcWorkingDB[qcIndex][12] == nil) then
			qcWorkingDB[qcIndex][12] = {}
		end
		if (qcWorkingDB[qcIndex][13] == nil) then
			qcWorkingDB[qcIndex][13] = {}
		else
			wipe(qcWorkingDB[qcIndex][13])
		end
	end

	for qcMapIndex, qcMapEntry in pairs(qcPinDB) do
		for qcInitiatorIndex, qcInitiatorEntry in pairs(qcPinDB[qcMapIndex]) do
			for qcInitiatorQuestIndex, qcInitiatorQuestEntry in pairs(qcPinDB[qcMapIndex][qcInitiatorIndex][7]) do
				if (qcWorkingDB[qcInitiatorQuestEntry] == nil) then
					print("Quest not found:", qcInitiatorQuestEntry)
				else
					--local qcFloorName = _G["DUNGEON_FLOOR_" .. strupper(GetMapInfo() or "") .. (qcPinDB[qcMapIndex][qcInitiatorIndex][1])] or 0
					--if (qcFloorName ~= 0) then print(qcFloorName) end
					table.insert(qcWorkingDB[qcInitiatorQuestEntry][13],{qcPinDB[qcMapIndex][qcInitiatorIndex][3],qcPinDB[qcMapIndex][qcInitiatorIndex][4],qcMapIndex,qcPinDB[qcMapIndex][qcInitiatorIndex][1],qcRound(qcPinDB[qcMapIndex][qcInitiatorIndex][5],1),qcRound(qcPinDB[qcMapIndex][qcInitiatorIndex][6],1)})
				end
			end
		end
	end

end

function qcVerifyMapDataExists()

--	SetMapToCurrentZone()

	local qcQuestID = GetQuestID()
	local qcMapID = C_Map.GetBestMapForUnit("player")
	local qcMapName = C_Map.GetAreaInfo(qcMapID).name  -- qcUiMapID ?

	if not (qcPinDB[qcMapID]) then
		PlaySound("8959", "1115")
		if (qcMapName == nil) then
			print(string.format("|cFF9482C9Quest Completist DEBUG:|r [%d] |cffabd473Map ID %d [CANNOT DETECT MAP NAME] does not yet exist.|r",qcQuestID,qcMapID,GetMapNameByID(qcMapID)))
		else
			print(string.format("|cFF9482C9Quest Completist DEBUG:|r [%d] |cffabd473Map ID %d [%s] does not yet exist.|r",qcQuestID,qcMapID,GetMapNameByID(qcMapID)))
		end
		return nil
	end

	local X, Y = C_Map.GetPlayerMapPosition(qcMapID, "player")
	local qcX = tonumber(string.format("%.1f",X*100))
	local qcY = tonumber(string.format("%.1f",Y*100))
	local qcInitiatorFound
	local qcInitiatorIndex
	local qcQuestFound

	for qcIndex, qcEntry in pairs(qcPinDB[qcMapID]) do
		if (qcEntry[4] == UnitName("questnpc")) then
			if (qcEntry[5] >= qcX-0.1) and (qcEntry[5] <= qcX+0.1) and (qcEntry[6] >= qcY-0.1) and (qcEntry[6] <= qcY+0.1) then
				qcInitiatorFound = true
				qcInitiatorIndex = qcIndex
				for qcQuestIndex, qcQuestEntry in pairs(qcEntry[7]) do
					if (qcQuestEntry == qcQuestID) then
						qcQuestFound = true
					end
				end
			end
		end
	end

	if not (qcQuestFound == true) then
		if (qcInitiatorFound == true) then
			PlaySoundFile("Interface\\AddOns\\QuestCompletist\\debug.mp3","8959")
			print(string.format("|cFF9482C9Quest Completist DEBUG:|r [%d:%d] |cffabd473Initiator exists in map data, but quest needs added.|r [Initiator Index: %d]",qcMapID,qcQuestID,qcInitiatorIndex))
		else
			PlaySound("8959","1115")
			print(string.format("|cFF9482C9Quest Completist DEBUG:|r [%d:%d] |cffabd473Neither initiator or quest found in map data. If initiator is stationary new map entry is likely needed.|r",qcMapID,qcQuestID))
		end
	end

end

function qcGenerateMapData()

--	SetMapToCurrentZone()
	local qcQuestID = GetQuestID()
	local qcMapID = C_Map.GetBestMapForUnit("player")
--	local qcMapLevel = GetCurrentMapDungeonLevel()

	local qcIconType = 1
	if (QuestIsDaily()) then
		qcIconType = 3
	end

	local qcInitiatorGUID = UnitGUID("questnpc")
	local qcInitiatorID = 0
	do
		--local qcGUIDTypeBits = tonumber(strsub(qcInitiatorGUID,3,5),16)
		local qcGUIDType = 0 --bit.band(qcGUIDTypeBits,0x00F)
		if (qcGUIDType == 3) then
			qcInitiatorID = tonumber(strsub(qcInitiatorGUID,7,10),16)
		else
			qcInitiatorID = 0
		end
	end

	local qcInitiatorName = UnitName("questnpc") or ""
	if (qcInitiatorName == UnitName("player")) then
		qcInitiatorName = "CHANGE_TO_NIL"
	end

	local qcX = 0
	local qxY = 0
	do
		local X, Y = C_Map.GetPlayerMapPosition(qcMapID, "player")
		qcX = tonumber(string.format("%.1f",X*100))
		qcY = tonumber(string.format("%.1f",Y*100))
	end
	print(string.format("ZONE MAP:   |cFF69CCF0[%d] = {%d,%d,%d,%q,%.1f,%.1f,{%d}},|r", qcMapID, qcMapLevel, qcIconType, qcInitiatorID, qcInitiatorName, qcX, qcY, qcQuestID))
	
	if (ZoomOut()) then
		local qcMapID = C_Map.GetBestMapForUnit("player")
--		local qcMapLevel = GetCurrentMapDungeonLevel()
		do
			local X, Y = C_Map.GetPlayerMapPosition(qcMapID, "player")
			qcX = tonumber(string.format("%.1f",X*100))
			qcY = tonumber(string.format("%.1f",Y*100))
		end
		if not ((qcX == 0) and (qcY ==0)) then
			print(string.format("PARENT ZONE:   [%d] = {%d,%d,%d,%q,%.1f,%.1f,{%d}},", qcMapID, qcMapLevel, qcIconType, qcInitiatorID, qcInitiatorName, qcX, qcY, qcQuestID))
		end
	end

--	SetMapByID(14)
	local qcMapID = C_Map.GetBestMapForUnit("player")
--	local qcMapLevel = GetCurrentMapDungeonLevel()
	do
		local X, Y = C_Map.GetPlayerMapPosition(qcMapID, "player")
		qcX = tonumber(string.format("%.1f",X*100))
		qcY = tonumber(string.format("%.1f",Y*100))
	end
	if not ((qcX == 0) and (qcY ==0)) then
		print(string.format("EK MAP:   [%d] = {%d,%d,%d,%q,%.1f,%.1f,{%d}},", qcMapID, qcMapLevel, qcIconType, qcInitiatorID, qcInitiatorName, qcX, qcY, qcQuestID))
	end

--	SetMapByID(13)
	local qcMapID = C_Map.GetBestMapForUnit("player")
--	local qcMapLevel = GetCurrentMapDungeonLevel()
	do
		local X, Y = C_Map.GetPlayerMapPosition(qcMapID, "player")
		qcX = tonumber(string.format("%.1f",X*100))
		qcY = tonumber(string.format("%.1f",Y*100))
	end
	if not ((qcX == 0) and (qcY ==0)) then
		print(string.format("KA MAP:   [%d] = {%d,%d,%d,%q,%.1f,%.1f,{%d}},", qcMapID, qcMapLevel, qcIconType, qcInitiatorID, qcInitiatorName, qcX, qcY, qcQuestID))
	end

--	SetMapByID(485)
	local qcMapID = C_Map.GetBestMapForUnit("player")
--	local qcMapLevel = GetCurrentMapDungeonLevel()
	do
		local X, Y = C_Map.GetPlayerMapPosition(qcMapID, "player")
		qcX = tonumber(string.format("%.1f",X*100))
		qcY = tonumber(string.format("%.1f",Y*100))
	end
	if not ((qcX == 0) and (qcY ==0)) then
		print(string.format("NR MAP:   [%d] = {%d,%d,%d,%q,%.1f,%.1f,{%d}},", qcMapID, qcMapLevel, qcIconType, qcInitiatorID, qcInitiatorName, qcX, qcY, qcQuestID))
	end

--	SetMapByID(466)
	local qcMapID = C_Map.GetBestMapForUnit("player")
--	local qcMapLevel = GetCurrentMapDungeonLevel()
	do
		local X, Y = C_Map.GetPlayerMapPosition(qcMapID, "player")
		qcX = tonumber(string.format("%.1f",X*100))
		qcY = tonumber(string.format("%.1f",Y*100))
	end
	if not ((qcX == 0) and (qcY ==0)) then
		print(string.format("OL MAP:   [%d] = {%d,%d,%d,%q,%.1f,%.1f,{%d}},", qcMapID, qcMapLevel, qcIconType, qcInitiatorID, qcInitiatorName, qcX, qcY, qcQuestID))
	end

end

function qcFindMappedNILQuests()

	local qcCount = 0

	for qcMapIndex, qcMapEntry in pairs(qcPinDB) do
		for qcInitiatorIndex, qcInitiatorEntry in pairs(qcPinDB[qcMapIndex]) do
			for qcInitiatorQuestIndex, qcInitiatorQuestEntry in pairs(qcPinDB[qcMapIndex][qcInitiatorIndex][7]) do
				if (qcQuestDatabase[qcInitiatorQuestEntry] == nil) then
					qcCount = qcCount + 1
					print(qcInitiatorQuestEntry .. " - Given by: " .. tostring(qcPinDB[qcMapIndex][qcInitiatorIndex][4]))
				end
			end
		end
	end
	
	print(qcCount)

end

function qcFindQuestsWithNoMapDataByZone()

	local tableinsert = table.insert
	local stringformat = string.format
	
	wipe(qcWorkingLog)

	for qcCategoryIndex, qcCategoryEntry in pairs(qcQuestCategories) do
		local qcFound
		local qcCountFound = 0
		local qcCountNotFound = 0
		local qcQuestCount = 0
		qcCategoryID = qcCategoryEntry[1]
		tableinsert(qcWorkingLog, stringformat("\t%s [%d]",qcCategoryEntry[2],qcCategoryID))
		for qcQuestIndex, qcQuestEntry in pairs(qcQuestDatabase) do
			qcFound = false
			if (qcQuestEntry[5] == qcCategoryID) then
				qcQuestCount = (qcQuestCount + 1)
				for qcMapIndex, qcMapEntry in pairs(qcPinDB) do
					for qcInitiatorIndex, qcInitiatorEntry in pairs(qcPinDB[qcMapIndex]) do
						for qcInitiatorQuestIndex, qcInitiatorQuestEntry in pairs(qcPinDB[qcMapIndex][qcInitiatorIndex][7]) do
							if (qcInitiatorQuestEntry == qcQuestIndex) then
								qcFound = true
								--break
							end
						end
					end
				end
				if not (qcFound) then
					tableinsert(qcWorkingLog, stringformat("\t\t[%d] [%d] %s",qcQuestEntry[1],qcQuestEntry[7],qcQuestEntry[2]))
					qcCountNotFound = (qcCountNotFound + 1)
				else
					qcCountFound = (qcCountFound + 1)
				end
			end
		end
		if not (qcQuestCount == 0) then
			tableinsert(qcWorkingLog, "\t\tOut of " .. qcQuestCount .. " quests, map data was found for " .. qcCountFound .. " (" .. qcRound(((qcCountFound/qcQuestCount)*100),2) .. "%), and " .. qcCountNotFound .. " (" .. qcRound(((qcCountNotFound/qcQuestCount)*100),2) .. "%) had no map data assosiated with it.")
		end
	end

end

function qcFindQuestsWithNoMapData(qcCategoryID)

	local qcFound
	local qcCountFound = 0
	local qcCountNotFound = 0
	local qcQuestCount = 0
	if (qcCategoryID == nil) then
		for qcQuestIndex, qcQuestEntry in pairs(qcQuestDatabase) do
			qcFound = false
			qcQuestCount = (qcQuestCount + 1)
			for qcMapIndex, qcMapEntry in pairs(qcPinDB) do
				for qcInitiatorIndex, qcInitiatorEntry in pairs(qcPinDB[qcMapIndex]) do
					for qcInitiatorQuestIndex, qcInitiatorQuestEntry in pairs(qcPinDB[qcMapIndex][qcInitiatorIndex][7]) do
						if (qcInitiatorQuestEntry == qcQuestIndex) then
							qcFound = true
							--break
						end
					end
				end
			end
			if not (qcFound) then
				print(qcQuestIndex)
				-- Log the quest details.
				-- Possibly log them by Map ID or zone or something similar?
				qcCountNotFound = (qcCountNotFound + 1)
			else
				qcCountFound = (qcCountFound + 1)
			end
		end
	else
		for qcQuestIndex, qcQuestEntry in pairs(qcQuestDatabase) do
			qcFound = false
			if (qcQuestEntry[5] == qcCategoryID) then
				qcQuestCount = (qcQuestCount + 1)
				for qcMapIndex, qcMapEntry in pairs(qcPinDB) do
					for qcInitiatorIndex, qcInitiatorEntry in pairs(qcPinDB[qcMapIndex]) do
						for qcInitiatorQuestIndex, qcInitiatorQuestEntry in pairs(qcPinDB[qcMapIndex][qcInitiatorIndex][7]) do
							if (qcInitiatorQuestEntry == qcQuestIndex) then
								qcFound = true
								--break
							end
						end
					end
				end
				if not (qcFound) then
					print(qcQuestIndex)
					-- Log the quest details.
					-- Possibly log them by Map ID or zone or something similar?
					qcCountNotFound = (qcCountNotFound + 1)
				else
					qcCountFound = (qcCountFound + 1)
				end
			end
		end
	end

	print("Out of " .. qcQuestCount .. " quests, map data was found for " .. qcCountFound .. " (" .. qcRound(((qcCountFound/qcQuestCount)*100),2) .. "%), and " .. qcCountNotFound .. " (" .. qcRound(((qcCountNotFound/qcQuestCount)*100),2) .. "%) had no map data assosiated with it.")

end						

function qcQueryMapDataForQuest(qcQuestID)

	if not (qcQuestID) then return nil end
	local qcFound
	for qcMapIndex, qcMapEntry in pairs(qcPinDB) do
		for qcInitiatorIndex, qcInitiatorEntry in pairs(qcPinDB[qcMapIndex]) do
			for qcInitiatorQuestIndex, qcInitiatorQuestEntry in pairs(qcPinDB[qcMapIndex][qcInitiatorIndex][7]) do
				if (qcInitiatorQuestEntry == qcQuestID) then
					if not (qcFound) then
						print("Quest: " .. qcInitiatorQuestEntry .. " - " .. qcQuestDatabase[qcInitiatorQuestEntry][2])
						print("   Given by: " .. tostring(qcPinDB[qcMapIndex][qcInitiatorIndex][4]))
						print("      Located on Map ID: " .. qcMapIndex .. " @ " .. qcPinDB[qcMapIndex][qcInitiatorIndex][5] .. ", " .. qcPinDB[qcMapIndex][qcInitiatorIndex][6])
					else
						print("   Also given by: " .. tostring(qcPinDB[qcMapIndex][qcInitiatorIndex][4]))
						print("      Located on Map ID: " .. qcMapIndex .. " @ " .. qcPinDB[qcMapIndex][qcInitiatorIndex][5] .. ", " .. qcPinDB[qcMapIndex][qcInitiatorIndex][6])
					end
					qcFound = true
				end
			end
		end
	end

end