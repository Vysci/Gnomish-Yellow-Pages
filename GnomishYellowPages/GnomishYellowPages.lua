local modName, modTable = ...

-- The Gnomish Yellow Pages
-- let your stumpy little fingers do the walking

local VERSION = ("64")

local faction = UnitFactionGroup("player")
local realmName = GetRealmName()

local serverKey = realmName.."-"..faction
local player = UnitName("player")
local playerGUID


local BlizzardSendWho


GYP = {}
GYP.ads = {}
GYP.timer = {}
GYP.version = VERSION


GYPData = {}



local function OpenTradeLink(tradeString, link, button)
--	ShowUIPanel(ItemRefTooltip)
--	if ( not ItemRefTooltip:IsShown() ) then
--		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
--	end

--	ItemRefTooltip:SetHyperlink(tradeString)
	SetItemRef(tradeString, link, button)
end



local tradeIDList = { 2259, 2018, 7411, 4036, 45357, 25229, 2108, 3908,  2550, 3273 }

local spellList = {}


do
	local frame

	local master = CreateFrame("Frame")

	local function RegisterKeyFunction(frame, key, func)
		if not frame.keyFunctions then
			frame.keyFunctions = {}
		end

		frame.keyFunctions[key] = func
	end


	local function RegisterEvent(frame, event, func)
		if not frame.events then
			frame.events = {}
		end

		if not frame.events[event] then
			frame.events[event] = {}
		end

		table.insert(frame.events[event],func)

		frame:RegisterEvent(event)
	end


	local function ParseEvent(frame, event, ...)
		if frame.events[event] then
--		DEFAULT_CHAT_FRAME:AddMessage(event)
			for i=1,#frame.events[event] do
				if frame.events[event][i] then
					frame.events[event][i](...)
				end
			end
		end
	end


	local recipeTotals = {}


	local st

	local timerList = {}



	local priorityWho = {}
	local backgroundWho = {}


	local whoDataPending = false
	local guildDataPending = false



	local function PrioritySendWho(who)
		timerList["ProcessWhoQueue"].countDown = 0
		if #priorityWho > 0 then
			if priorityWho[#priorityWho] ~= who then
				table.insert(priorityWho, who)
			end
		else
			table.insert(priorityWho, who)
		end
	end

	local function BackgroundSendWho(who)
		table.insert(backgroundWho, who)
	end

	local lastWho = 0

	local function ProcessWhoQueue()
		local elapsed = time() - lastWho
		if elapsed > 5 then
			if #priorityWho > 0 then
				local who = table.remove(priorityWho, 1)

				BlizzardSendWho(who)
--DEFAULT_CHAT_FRAME:AddMessage("priority "..who.." "..elapsed)
			elseif #backgroundWho > 0 then

				local who = table.remove(backgroundWho, 1)

				whoDataPending = true
				SetWhoToUI(1)
				BlizzardSendWho(who)
--DEFAULT_CHAT_FRAME:AddMessage("background "..who.." "..elapsed)
			end
		end
	end


	local selectedRows = {}


	local tradeIDbyName = {}
	local basicTradeID = {}
	local tradeList = {}

	local tradeSkillIsOpen


	local function buildBasicTradeTable(aliases)
		for n=1,#aliases do
			basicTradeID[aliases[n]] = aliases[1]
		end

		table.insert(tradeList,{ tradeID = aliases[1]})

		tradeIDbyName[GetSpellInfo(aliases[1])] = aliases[1]
	end



	buildBasicTradeTable({ 2259,3101,3464,11611,28596,28677,28675,28672,51304,80731 })						-- alchemy
	buildBasicTradeTable({ 2018,3100,3538,9785,9788,9787,17039,17040,17041,29844,51300,76666 })				-- bs
	buildBasicTradeTable({ 7411,7412,7413,13920,28029,51313,74258 })										-- enchanting
	buildBasicTradeTable({ 4036,4037,4038,12656,20222,20219,30350,51306,82774 })							-- eng
	buildBasicTradeTable({ 45357,45358,45359,45360,45361,45363,86008 })										-- inscription
	buildBasicTradeTable({ 25229,25230,28894,28895,28897,51311,73318 })										-- jc
	buildBasicTradeTable({ 2108,3104,3811,10656,10660,10658,10662,32549,51302,81199 })						-- lw
	buildBasicTradeTable({ 3908,3909,3910,12180,26801,26798,26797,26790,51309,75156 })						-- tailoring


	buildBasicTradeTable({ 2550,3102,3413,18260,33359,51296,88053 })										-- cooking
	buildBasicTradeTable({ 3273,3274,7924,10846,27028,45542,10846,74559 })									-- first aid

--	buildBasicTradeTable({ 2656 })


	local simpleBitmap = {}



	local currentTradeskill = nil
	local currentTradeBitmap = nil
	local currentTradeLink = nil

--[[
	tradeskill filter popup stuff:
]]
	local selectedTradeskill = nil

	local function TradeFilterToggle(button, slot)
		selectedTradeskill = tradeList[slot].tradeID
		st:SortData()
	end


	local function TradeFilterAll()
		selectedTradeskill = nil
		st:SortData()
	end


	local tradeFilterMenu = {}

	table.insert(tradeFilterMenu, { text = "All Trades", func = TradeFilterAll, fontObject = GameFontNormal})

	for i=1,#tradeList do
		table.insert(tradeFilterMenu, { text = GetSpellInfo(tradeList[i].tradeID), func = TradeFilterToggle, arg1 = i, checked = function() return selectedTradeskill == tradeList[i].tradeID end })
	end

--[[
	age filter popup stuff:
]]
	local selectedAge = nil

	local function AgeFilterSet(button, age)
		selectedAge = age
		st:SortData()
	end

	local ageFilterMenu = {
		{ text = "All", func = AgeFilterSet, arg1 = nil,  fontObject = GameFontNormal },
		{ text = "1 day", func = AgeFilterSet, arg1 = 1, checked = function() return selectedAge == 1 end },
		{ text = "1 week", func = AgeFilterSet, arg1 = 7, checked = function() return selectedAge == 7 end},
		{ text = "2 weeks", func = AgeFilterSet, arg1 = 14, checked = function() return selectedAge == 14 end },
		{ text = "1 month", func = AgeFilterSet, arg1 = 30, checked = function() return selectedAge == 30 end },
	}



--[[
	level filter popup stuff:
]]
	local selectedLevel = nil

	local function LevelFilterSet(button, level)
		selectedLevel = level
		st:SortData()
	end

	local levelFilterMenu = {
		{ text = "All", func = LevelFilterSet, arg1 = nil,  checked = function() return not selectedLevel end, fontObject = GameFontNormal },
		{ text = "100+", func = LevelFilterSet, arg1 = 100, checked = function() return selectedLevel == 100 end },
		{ text = "200+", func = LevelFilterSet, arg1 = 200, checked = function() return selectedLevel == 200 end},
		{ text = "300+", func = LevelFilterSet, arg1 = 300, checked = function() return selectedLevel == 300 end },
		{ text = "375+", func = LevelFilterSet, arg1 = 375, checked = function() return selectedLevel == 375 end },
		{ text = "450", func = LevelFilterSet, arg1 = 450, checked = function() return selectedLevel == 450 end },
	}



--[[
	player filter popup stuff:
]]
	local selectedPlayers = {["STRANGERS"] = true, ["OFFLINE"] = true}

	local function PlayerFilterSet(button, setting)
		selectedPlayers[setting] = not selectedPlayers[setting]
		st:SortData()
	end



	local playerFilterMenu = {
		{ text = "Show Strangers", func = PlayerFilterSet, arg1 = "STRANGERS", checked = function() return selectedPlayers["STRANGERS"] end},
		{ text = "Show Offline", func = PlayerFilterSet, arg1 = "OFFLINE", checked = function() return selectedPlayers["OFFLINE"] end },
	}



	local onlineColorTable = { ["r"] = 0.8, ["g"] = 0.8, ["b"] = 0.8, ["a"] = 1.0 }
	local offlineColorTable = { ["r"] = 1.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 1.0 }
	local localColorTable = { ["r"] = 0.4, ["g"] = 0.8, ["b"] = 1.0, ["a"] = 1.0 }
	local friendColorTable = { ["r"] = 1.0, ["g"] = 0.8, ["b"] = 0.4, ["a"] = 1.0 }
	local guildColorTable = { ["r"] = 0.2, ["g"] = 1.0, ["b"] = 0.2, ["a"] = 1.0 }

	local singleSharedColorTable = 	{ ["r"] = 0.5, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 }
	local sharedColorTable = 		{ ["r"] = 1.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 1.0 }
	local noneSharedColorTable = 	{ ["r"] = 0.5, ["g"] = 0.5, ["b"] = 0.0, ["a"] = 1.0 }


	local playerList = {}
	local playerLocation = {}

	local friendList = {}
	local guildList = {}
	local guildCraftList = {}
	local playerAge = {}
	local playerWhoPending = ""

	local tradeLinkQueue = {}


	local whoAutoUpdateToggle
	local whoAutoUpdateFrequency
	local pruneAge


	local OFFLINE = "** Offline **"
	local ONLINE = "Online"

	local colorWhite = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 }
	local colorBlack = { ["r"] = 0.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 0.0 }
	local colorDark = { ["r"] = 1.1, ["g"] = 0.1, ["b"] = 0.1, ["a"] = 0.0 }

	local highlightOff = { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.0 }
	local highlightSelected = { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 0.5, ["a"] = 0.5 }
	local highlightSelectedMouseOver = { ["r"] = 1, ["g"] = 1, ["b"] = 0.5, ["a"] = 0.5 }

	local selectedRows = {}

	local linkRow = {}

	if not GYPFilterMenuFrame then
		GYPFilterMenuFrame = CreateFrame("Frame", "GYPFilterMenuFrame", getglobal("UIParent"), "UIDropDownMenuTemplate")
	end




	local function SimpleTime(t)
		local mins = t/60
		local hours = mins/60
		local days = hours/24

		if days > 2 then
			return (math.floor(days*10)/10).." days"
		end

		if mins > 100 then
			return (math.floor(hours*10)/10).." hrs"
		end

		return (math.floor(mins)).." mins"
	end





	local columnHeaders = {
		{
			["name"] = "Player",
			["width"] = 100,
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["onclick"] =	function(button, player)
								local playerString = "player:"..player
								local playerLink = "|Hplayer:"..player.."|h["..player.."]|h"

								SetItemRef(playerString,playerLink,button)
							end,
			["rightclick"] = 	function()
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(playerFilterMenu, GYPFilterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								end


		}, -- [1]
		{
			["name"] = "Location",
			["width"] = 150,
			["bgcolor"] = colorDark,
			["sortnext"]= 4,
			["tooltipText"] = "click to sort",
			["onclick"] = function(button, player)
								BackgroundSendWho(player)
							end
		}, -- [2]
		{
			["name"] = "Level",
			["width"] = 40,
			["align"] = "CENTER",
			["bgcolor"] = colorBlack,
			["tooltipText"] = "click to sort\rright-click to filter",
			["sortnext"]= 1,
			["rightclick"] = 	function()
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(levelFilterMenu, GYPFilterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								end
		}, -- [3]
		{
			["name"] = "Trade",
			["width"] = 100,
			["align"] = "CENTER",
			["color"] = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 1.0 },
			["bgcolor"] = colorDark,
			["tooltipText"] = "click to sort\rright-click to filter",
			["sortnext"] = 3,
			["onclick"] =	function(button, link)
								local tradeString = string.match(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")

								if IsShiftKeyDown() then
									ChatEdit_GetLastActiveWindow():Show()
									ChatEdit_InsertLink(link)
								elseif IsControlKeyDown() then
									local tradeID, bitmap = string.match(tradeString, "trade:(%d+):%d+:%d+:[0-9a-fA-F]+:([A-Za-z0-9+/]+)")

									tradeID = tonumber(tradeID)

									GYP.TradeLink:DumpSpells(GYPConfig.spellList[tradeID], bitmap)
								else
									GYPFrame:SetFrameStrata("LOW")

									local tradeID, guid = string.match(tradeString, "trade:(%d+):%d+:%d+:([0-9a-fA-F]+):[A-Za-z0-9+/]+")

									if guid == playerGUID then
										CastSpellByName((GetSpellInfo(tradeID)))
									else
										OpenTradeLink(tradeString, link, button)
									end
								end
							end,
			["rightclick"] = 	function()
									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(tradeFilterMenu, GYPFilterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								end

		}, -- [4]
		{
			["name"] = "Age",
			["width"] = 60,
			["align"] = "CENTER",
			["bgcolor"] = colorBlack,
			["defaultsort"] = "asc",
			["sortnext"]= 4,
			["sort"] = "asc",
			["tooltipText"] = "click to sort\rright-click to filter",
			["DoCellUpdate"] =	function (rowFrame, cellFrame, data, cols, row, realrow, column, fShow, ...)
									if fShow then
										local cellData = data[realrow].cols[column];

										local elapsedTime = time() - cellData.value
										local formattedElapsedTime = SimpleTime(elapsedTime)

										if formattedElapsedTime == "" then
											formattedElapsedTime = "NEW"
										end

										cellFrame.text:SetText(formattedElapsedTime)

										local daysOld = (elapsedTime / (60*60*24))
										local cr = min(1,daysOld*.5+.5)
										local cg = min(1,1-min(math.pow(daysOld,2),1)*.8)
										local cb = max(0,min(1,daysOld*(1-daysOld)))*.8+.2

										cellFrame.text:SetTextColor(cr,cg,cb)
									else
										cellFrame.text:SetText("");
									end
								end,
			["rightclick"] = 	function()

									local x, y = GetCursorPosition()
									local uiScale = UIParent:GetEffectiveScale()

									EasyMenu(ageFilterMenu, GYPFilterMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
								end
		}, -- [5]
		{
			["name"] = "Chat Message",
			["width"] = 100,
			["align"] = "LEFT",
			["bgcolor"] = colorDark,
			["tooltipText"] = "click to sort",
		}, -- [6]
	};


	local ChatMessageTypes = {
		["CHAT_MSG_SYSTEM"] = true,
		["CHAT_MSG_SAY"] = true,
		["CHAT_MSG_TEXT_EMOTE"] = true,
		["CHAT_MSG_YELL"] = true,
		["CHAT_MSG_WHISPER"] = true,
		["CHAT_MSG_PARTY"] = true,
		["CHAT_MSG_GUILD"] = true,
		["CHAT_MSG_OFFICER"] = true,
		["CHAT_MSG_CHANNEL"] = true,
		["CHAT_MSG_RAID"] = true,
	};


	local function AdjustColumnWidths()
		for i=1,#st.cols do
			local col = st.head.cols[i]

			col.frame:SetWidth(columnHeaders[i].width-2)
		end
	end


	local function ResizeMainWindow()
		if st then
			columnHeaders[6].width =  frame:GetWidth() - 29 - 460

			local rows = floor((frame:GetHeight()-71-15) / 15)


			if rows >= #st.filtered then
				st.scrollframe:Show()
				columnHeaders[6].width = columnHeaders[6].width - 17
			else
				st.scrollframe:Hide()
--				columnHeaders[6].width = columnHeaders[6].width + 17
			end

			st:SetDisplayCols(st.cols)
			st:SetDisplayRows(rows, st.rowHeight)

			AdjustColumnWidths()

			st:Refresh()
		end
	end


	local function PlayerFunctionColor(player)
		if playerLocation[player] and not string.find(playerLocation[player], OFFLINE) then
--DEFAULT_CHAT_FRAME:AddMessage(playerLocation[player].." "..GetMinimapZoneText())
			if playerLocation[player] == GetMinimapZoneText() then
				return localColorTable
			end

			if guildList[player] then
				return guildColorTable
			end

			if friendList[player] then
				return friendColorTable
			end

			return onlineColorTable
		else
			return offlineColorTable
		end
	end


	local function PlayerFunctionLocation(player)
		return playerLocation[player] or "?"
	end

	local function LinkFunctionColor(tradeID, bitmap)
		if currentTradeskill then
			if (tradeID ~= currentTradeskill) then
				return noneSharedColorTable
			else
				if currentSingleTradeBitmap and GYP.TradeLink:BitsShared(currentSingleTradeBitmap, bitmap)~=0 then
					return singleSharedColorTable
				end

				if currentTradeBitmap and GYP.TradeLink:BitsShared(currentTradeBitmap, bitmap)==0 then
					return noneSharedColorTable
				end
			end

			return sharedColorTable
		end

		return sharedColorTable
	end



	--fnDoCellUpdate(rowFrame, cellFrame, st.data, st.cols, row, st.filtered[row], col, fShow);
	local function TimeDisplayFunction(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, ...)
		if fShow then
			local cellData = data[realrow].cols[column];

			local elapsedTime = time() - cellData.value
			local formattedElapsedTime = SimpleTime(elapsedTime)

			if formattedElapsedTime == "" then
				formattedElapsedTime = "NEW"
			end

			cellFrame.text:SetText(formattedElapsedTime)

			local daysOld = (elapsedTime / (60*60*24))
			local cr = min(1,daysOld*.5+.5)
			local cg = min(1,1-min(math.pow(daysOld,2),1)*.8)
			local cb = max(0,min(1,daysOld*(1-daysOld)))*.8+.2

			cellFrame.text:SetTextColor(cr,cg,cb)
		else
			cellFrame.text:SetText("");
		end


	end


	local function CountRecipes(tradeID)
		if not recipeTotals[tradeID] then
			local c = 0

			for s in pairs(GYPConfig.spellList[tradeID]) do
				c = c + 1
			end

			recipeTotals[tradeID] = c
		end

		return recipeTotals[tradeID]
	end


	local function AddToScrollingTable(trade,player,ad)
		if not guildCraftList[player] then

			if not ad.link or not ad.message or not ad.time then
				GYPData[serverKey][trade][player] = nil
			else
				local key = trade.."-"..player
				local row = linkRow[key]

				if not row then
					local tradeID,level,bitmap  = string.match(ad.link, "trade:(%d+):(%d+):%d+:[0-9a-fA-F]+:([A-Za-z0-9+/]+)|h")
					tradeID = tonumber(tradeID)

					local basicTrade = GetSpellInfo(basicTradeID[tradeID])

					local compressedBitmap = GYP.TradeLink:BitmapCompress(bitmap)

					local basicTrade = GetSpellInfo(basicTradeID[tradeID])
					local recipeCount = GYP.TradeLink:CountBits(compressedBitmap)
					local totalRecipes = CountRecipes(basicTradeID[tradeID])

					row = #st.data + 1

					st.data[row] = {}

					st.data[row].auxData = trade.."-"..player

					st.data[row].cols = {
						{value=player, color=PlayerFunctionColor, colorargs={player}, tooltipText = "double-click to whisper player", onclickargs={player}},
						{value=PlayerFunctionLocation, args={player}, color=PlayerFunctionColor, colorargs={player}, onclickargs={player}, tooltipText = "double-click to refresh status"},
						{value=tonumber(level), tooltipText = recipeCount.." of "..totalRecipes.." known recipes"},
						{value="["..basicTrade.."]", tradeID=basicTradeID[tradeID], onclickargs={ad.link}, color=LinkFunctionColor, colorargs={basicTradeID[tradeID],compressedBitmap}, tooltipText="double-click to open link\rshift-double-click to send to chat"},
						{value=ad.time},
						{value=ad.message}
					}

					linkRow[key] = row
				elseif ad.link ~= st.data[row].cols[4].onclickargs[1] then

					local tradeID,level,bitmap  = string.match(ad.link, "trade:(%d+):(%d+):%d+:[0-9a-fA-F]+:([A-Za-z0-9+/]+)|h")
					tradeID = tonumber(tradeID)

					local basicTrade = GetSpellInfo(basicTradeID[tradeID])

					local compressedBitmap = GYP.TradeLink:BitmapCompress(bitmap)

					local basicTrade = GetSpellInfo(basicTradeID[tradeID])
					local recipeCount = GYP.TradeLink:CountBits(compressedBitmap)
					local totalRecipes = CountRecipes(basicTradeID[tradeID])

					st.data[row].cols[3].value = tonumber(level)
					st.data[row].cols[3].tooltipText = recipeCount.." of "..totalRecipes.." known recipes"

					st.data[row].cols[4].onclickargs[1]=ad.link
					st.data[row].cols[4].colorargs[2]=compressedBitmap

					st.data[row].cols[5].value = ad.time

					st.data[row].cols[6].value = ad.message
				else
					st.data[row].cols[5].value = ad.time
					st.data[row].cols[6].value = ad.message
				end
			end
		end
	end


	local function BuildScrollingTable(force)
--		if not false then return end


		if not st then
			local ScrollPaneBackdrop  = {
				bgFile = "Interface\\AddOns\\GnomishYellowPages\\Art\\newFrameInsetBackground.tga",
				edgeFile = "Interface\\AddOns\\GnomishYellowPages\\Art\\newFrameInsetBorder.tga",
				tile = true, tileSize = 16, edgeSize = 16,
				insets = { left = 3, right = 3, top = 3, bottom = 3 }
			};


			local rows = floor((frame:GetHeight() - 71-15) / 15)
			local LibScrollingTable = LibStub("ScrollingTable")

			st = LibScrollingTable:CreateST(columnHeaders,rows,nil,nil,frame)
			st.frame:SetPoint("BOTTOMLEFT",20,20)
			st.frame:SetPoint("TOP", frame, 0, -65)
			st.frame:SetPoint("RIGHT", frame, -20,0)

			st.LibraryRefresh = st.Refresh


--			SetBetterBackdrop(st.frame,ScrollPaneBackdrop);
--			st.frame:SetBackdropColor(1,1,1,1);

			st.frame:SetBackdrop(nil);





			for i=1,#st.cols do
				local col = st.head.cols[i]



				col.frame = CreateFrame("Frame", nil, st.frame)
				GYP.Window:SetBetterBackdrop(col.frame,ScrollPaneBackdrop)
				col.frame:SetPoint("TOP", st.frame, "TOP", 0,0)
				col.frame:SetPoint("BOTTOM", st.frame, "BOTTOM", 0,0)

				if i > 1 then
					col.frame:SetPoint("LEFT", st.head.cols[i-1], "RIGHT", 0, 0)
				else
					col.frame:SetPoint("LEFT", st.head, "LEFT", 0, 0)
				end

				col:SetPoint("LEFT",(columnHeaders[i].width-3))
			end

			AdjustColumnWidths()



			st.scrollframe:SetScript("OnHide", nil)
			st.scrollframe:SetPoint("TOPLEFT", st.frame, "TOPLEFT", 0, -2)
			st.scrollframe:SetPoint("BOTTOMRIGHT", st.frame, "BOTTOMRIGHT", -20, 2)


			local scrolltrough = getglobal(st.frame:GetName().."ScrollTrough")
			scrolltrough:SetWidth(17)
			scrolltrough:SetPoint("TOPRIGHT", st.frame, "TOPRIGHT", 2, -1);
			scrolltrough:SetPoint("BOTTOMRIGHT", st.frame, "BOTTOMRIGHT", 2, 2);

			st.scrollframe:SetFrameLevel(st.scrollframe:GetFrameLevel()+10)

			st.rows[1]:SetPoint("TOPLEFT", st.frame, "TOPLEFT", 0, -1);
			st.rows[1]:SetPoint("TOPRIGHT", st.frame, "TOPRIGHT", -1, -1);


			st.head:SetPoint("BOTTOMLEFT", st.frame, "TOPLEFT", 2, 2);
			st.head:SetPoint("BOTTOMRIGHT", st.frame, "TOPRIGHT", 0, 2);


			st.frame.noDataFrame = CreateFrame("Frame",nil,st.frame)
			st.frame.noDataFrame:SetAllPoints(st.frame)
			GYP.Window:SetBetterBackdrop(st.frame.noDataFrame,ScrollPaneBackdrop);
			st.frame.noDataFrame:Hide()


			local text = st.frame.noDataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
			text:SetJustifyH("CENTER")
			text:SetPoint("CENTER",0,0)
			text:SetTextColor(1,1,1)
			text:SetText("NO DATA")

			st.data = {}


			st.Refresh = function(st)
				st:LibraryRefresh()

	--[[
				for i=1, 5 do
					if columnHeaders[i].divider then
						if #st.filtered==0 then
							columnHeaders[i].divider:Hide()
						else
							columnHeaders[i].divider:Show()
						end
					end
				end
	]]
				for i=1,st.displayRows do
					local row = i+(st.offset or 0)

					local filteredRow = st.filtered[row]

					if filteredRow and st.data[filteredRow] then
						if selectedRows[st.data[filteredRow].auxData] then
							if i ~= st.mouseOverRow then
								st:SetHighLightColor(st.rows[i],highlightSelected)
							else
								st:SetHighLightColor(st.rows[i],highlightSelectedMouseOver)
							end
						else
							if i ~= st.mouseOverRow then
								st:SetHighLightColor(st.rows[i],highlightOff)
							else
								st:SetHighLightColor(st.rows[i],st:GetDefaultHighlight())
							end
						end
					end
				end
			end

			st:RegisterEvents({
				["OnEvent"] =  function (rowFrame, cellFrame, data, cols, row, realrow, column, st, event, arg1, arg2, ...)
--	DEFAULT_CHAT_FRAME:AddMessage("EVENT "..tostring(event))
					if event == "MODIFIER_STATE_CHANGED" then
						if arg1 == "LCTRL" or arg1 == "RCTRL" then
							frame.keyCapture:EnableKeyboard(arg2==1)
						end
					end
				end,
				["OnEnter"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, ...)
	--				frame.keyCapture:EnableKeyboard(true)
--DEFAULT_CHAT_FRAME:AddMessage("onEnter start")
					if row then
--DEFAULT_CHAT_FRAME:AddMessage("row "..row.." realrow "..realrow.." filtered row "..st.filtered[row].." filter row + offet "..st.filtered[row+st.offset])

						cellFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

						if realrow and selectedRows[data[realrow].auxData or 0] then
							st:SetHighLightColor(rowFrame,highlightSelectedMouseOver)
						else
							st:SetHighLightColor(rowFrame,st:GetDefaultHighlight())
						end

						st.mouseOverRow = row

						local cellData = data[realrow].cols[column]

						if st.fencePicking then
							for i=1,#data do
								selectedRows[data[i].auxData] = false
							end

							local rowStart, rowEnd = st.fencePickStart, row + st.offset

							if rowStart > rowEnd then
								rowStart, rowEnd = rowEnd, rowStart
							end

							for i=rowStart, rowEnd do
								local r = st.filtered[i]
								selectedRows[data[r].auxData] = true
							end

							st:Refresh()
						else

							GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")

							GameTooltip:ClearLines()

							GameTooltip:AddLine(columnHeaders[column].name,1,1,1,true)

							local value = cellFrame.text:GetText()

							local r,g,b = cellFrame.text:GetTextColor()

							GameTooltip:AddLine(value,r,g,b,true)
							GameTooltip:AddLine(cellData.tooltipText,.7,.7,.7)

							GameTooltip:Show()
						end
					else
						GameTooltip:SetOwner(cellFrame, "ANCHOR_TOPLEFT")

						GameTooltip:ClearLines()

						local value = columnHeaders[column].name

						local r,g,b = 1,1,1

						GameTooltip:AddLine(value,r,g,b,true)
						GameTooltip:AddLine(columnHeaders[column].tooltipText,.7,.7,.7)

						GameTooltip:Show()
					end

					return true
--DEFAULT_CHAT_FRAME:AddMessage("onEnter end")
				end,
				["OnMouseDown"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
					if row  then
						if button == "LeftButton" then
							st.fencePicking = true
							st.fencePickStart = row + st.offset
							local r = st.filtered[st.fencePickStart]

							for i=1,#data do
								selectedRows[data[i].auxData] = false
							end

							selectedRows[data[r].auxData] = true

							st:Refresh()
						end
					end
				end,
				["OnMouseUp"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
					if row  then
						if button == "LeftButton" then
							st.fencePicking = false
						end
					end
				end,
				["OnLeave"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, ...)
--DEFAULT_CHAT_FRAME:AddMessage("onLeave start")
	--				frame.keyCapture:EnableKeyboard(false)
					cellFrame:UnregisterEvent("MODIFIER_STATE_CHANGED")

					if row  then
						if realrow and selectedRows[data[realrow].auxData or 0] then
							st:SetHighLightColor(rowFrame,highlightSelected)
						else
							st:SetHighLightColor(rowFrame,highlightOff)
						end

						if st.mouseOverRow == row then
							st.mouseOverRow = nil
						end

						GameTooltip:Hide()

						st:Refresh()
					else
						GameTooltip:Hide()
					end

					return true
--DEFAULT_CHAT_FRAME:AddMessage("onLeave end")
				end,
				["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, st, button, ...)
					if row then
						if button == "LeftButton" then
							if not IsShiftKeyDown() then
								for i=1,#data do
									selectedRows[data[i].auxData] = false
								end
							end

							selectedRows[data[realrow].auxData] = true

							st:Refresh()
						end
					else
						if button == "RightButton" then
							if columnHeaders[column].rightclick then
								columnHeaders[column].rightclick()
							end
						end
					end
				end,
				["OnDoubleClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, button, st, ...)
					if row then
						local cellData = data[realrow].cols[column]

						if cellData.onclick then
							cellData.onclick(button, unpack(cellData.onclickargs or {}))
						else
							if cols[column].onclick then
								cols[column].onclick(button, unpack(cellData.onclickargs or cols[column].onclickargs or {}))
							end
						end
					end
				end,
			})



			st:SetFilter(function(self, row)
				if currentTradeskill then
					if (row.cols[4].tradeID ~= currentTradeskill) then
						return false
					end
				else
					if selectedTradeskill and (row.cols[4].tradeID ~= selectedTradeskill) then
						return false
					end
				end


				if selectedAge and ((time() - row.cols[5].value)/(60*60*24) > selectedAge) then
					return false
				end

				if not selectedPlayers["OFFLINE"] then
					if not playerLocation[row.cols[1].value] or string.find(playerLocation[row.cols[1].value],OFFLINE) then
						return false
					end
				end

				if not selectedPlayers["STRANGERS"] then
					if not guildList[row.cols[1].value] and not friendList[row.cols[1].value] then
						return false
					end
				end
	--DEFAULT_CHAT_FRAME:AddMessage(type(selectedLevel).." "..tostring(selectedLevel))

				if selectedLevel and tonumber(row.cols[3].value) < selectedLevel then
					return false
				end

				return true
			end)
		end

		local data = st.data


		if force then
			st.data = {}
			data = st.data
		end


-- GUILD CRAFT INTERFACE
--
		if GuildCraft then
			local guildLinks = GuildCraft.db.factionrealm.links

			for player, links in pairs(guildLinks) do
				guildCraftList[player] = ONLINE

				for trade, link in pairs(links) do
					local key = trade.."-"..player

					local tradeID,level,bitmap  = string.match(link, "trade:(%d+):(%d+):%d+:[0-9a-fA-F]+:([A-Za-z0-9+/]+)")
					tradeID = tonumber(tradeID)
					level = tonumber(level)

					local basicTrade = GetSpellInfo(basicTradeID[tradeID])

					local compressedBitmap = GYP.TradeLink:BitmapCompress(bitmap)
					local recipeCount = GYP.TradeLink:CountBits(compressedBitmap)
					local totalRecipes = CountRecipes(basicTradeID[tradeID])

					local row = linkRow[key]

					if not row then
						row = #st.data + 1

						st.data[row] = {}

						st.data[row].auxData = key

						st.data[row].cols = {
								{value=player, color=PlayerFunctionColor, colorargs={player}, tooltipText = "double-click to whisper player", onclickargs={player}},
								{value=PlayerFunctionLocation, args={player}, color=PlayerFunctionColor, colorargs={player}, onclickargs={player}, tooltipText = "double-click to refresh status"},
								{value=level, tooltipText = recipeCount.." of "..totalRecipes.." known recipes"},
								{value="["..basicTrade.."]", tradeID=basicTradeID[tradeID], onclickargs={link}, color=LinkFunctionColor, colorargs={basicTradeID[tradeID],compressedBitmap}, tooltipText="double-click to open link\rshift-double-click to send to chat"},
								{value=time()},
								{value="guildcraft data"}
							}

						linkRow[key] = row
					else
						st.data[row].cols[3].value = level
						st.data[row].cols[3].tooltipText = recipeCount.." of "..totalRecipes.." known recipes"

						st.data[row].cols[4].onclickargs[1]=link
						st.data[row].cols[4].colorargs[2]=compressedBitmap

						st.data[row].cols[5].value = time()

						st.data[row].cols[6].value="guildcraft data"
					end
				end
			end
		end



		for trade, adList in pairs(GYPData[serverKey]) do
			for player, ad in pairs(adList) do
				AddToScrollingTable(trade,player, ad)

			end
		end



--		st:SetData(data)


		st:SortData()
		ResizeMainWindow()
	end


	local function CloseFrame()
		frame:Hide()
	end


	local function ToggleFrame()
		if frame:IsVisible() then
			frame:Hide()
			frame.title:Hide()
		else
			BuildScrollingTable()
			frame:Show()
			frame.title:Show()
		end
	end



	local bid = 1
	local function CreateToggle(parent, text, value, callback)
		local toggleButton = CreateFrame("CheckButton", "CheckButtonID"..bid, parent, "UICheckButtonTemplate")
		toggleButton.text = getglobal("CheckButtonID"..bid.."Text")

		bid = bid + 1
		toggleButton:SetHeight(24)
		toggleButton:SetWidth(24)

		toggleButton.text:SetText(text)

		if value then
			toggleButton:SetChecked(true)
		end

		toggleButton.value = value


		toggleButton:SetScript("OnClick", function(self)
			self.value = self:GetChecked()

			local kids = { toggleButton:GetChildren() }

			for _, child in ipairs(kids) do
				if self.value then
				 	child:Show()
				else
					child:Hide()
				end
			end

			if callback then
				callback()
			end
		end)

		return toggleButton
	end


	local function CreateSlider(parent, text, min, max, value, units, callback)
		local slider = CreateFrame("Slider", "SliderID"..bid, parent, "OptionsSliderTemplate")
		slider.text = getglobal("SliderID"..bid.."Text")
		slider.textLow = getglobal("SliderID"..bid.."Low")
		slider.textHigh = getglobal("SliderID"..bid.."High")
		bid = bid + 1

		slider.text:SetText(text)
		slider.textLow:SetText(min)
		slider.textHigh:SetText(max)

		slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -30)
		slider:SetWidth(200)
		slider:SetHeight(17)


		slider:SetMinMaxValues(min,max)
		slider:SetValueStep(1)
		slider:SetValue(value)

		slider.tooltipText = value.." "..units
		slider.value = value


		slider:SetScript("OnValueChanged", function(self, value)
			self.tooltipText = value.." "..units
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1);
			self.value = value

			if callback then
				callback()
			end
		end)

		return slider
	end


	local function SelectedRowsDelete()
		if selectedRows then
			for key in pairs(selectedRows) do
				if selectedRows[key] then
					local trade, player = string.split("-",key)

					GYPData[serverKey][trade][player] = nil

					selectedRows[key] = nil
				end
			end

			selectedRows = {}

			if frame:IsVisible() then
				linkRow = {}
				BuildScrollingTable(true)
			end
		end
	end


	local function AddToPlayerList(player, age, location)
		if not playerLocation[player] then
			table.insert(playerList, player)

			playerLocation[player] = location
			playerAge[player] = age
		end
	end

	-- sample link
	-- "|cffffd000|Htrade:26790:375:375:544DE6:tz{zgfvUvy_cu{KtpwvUio]Wrs{c[ocGD><<Lt{Mx{Cm=<F<<\\A<B<D<<<<<<<<<<<<<<<|h[Tailoring]|h|r", -- [3]


	local function SaveAdvertisement(player,tradeName,level,link,message,age)
		local tradeData = GYPData[serverKey]
--DEFAULT_CHAT_FRAME:AddMessage("saving ad "..tostring(message).. " "..tostring(player))

		if not age then
			age = 0
		end

		local recordTime = time() - age


		if not tradeData[tradeName] then
			tradeData[tradeName] = {}
		end

		if tradeData[tradeName][player] then
			local data = tradeData[tradeName][player]

			if data.time < recordTime then

				data.message = message
				data.time = recordTime
				data.link = link
				data.level = level

				if frame:IsVisible() then
					AddToScrollingTable(tradeName,player,data)
					st:Refresh()
				end

				return data
			end
		else
			tradeData[tradeName][player] = { ["message"] = message, ["time"] = time(), ["link"] = link, ["level"] = tonumber(level)}

			AddToPlayerList(player, 0, OFFLINE)

			if frame:IsVisible() then
				AddToScrollingTable(tradeName,player,tradeData[tradeName][player])
				st:Refresh()
			end

			return tradeData[tradeName][player]
		end
	end


	local function ChatMessage(message)
		if string.find(message, "|Htrade:") then
--			SaveAdvertisement(message, player)

			for link in string.gmatch(message, "|c%x+|Htrade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+|h%[[^]]+%]|h|r") do
				local color,profession,level,playerID,tradeName = string.match(link,"(|c%x+)|Htrade:(%d+):(%d+):%d+:([0-9a-fA-F]+):[A-Za-z0-9+/]+|h%[([^]]+)%]|h|r")

--[[
TODO:

options here would be to black list players or professions and to have a level requirement (like say 250+)

this would help cut down on data overload
]]
				local messageClean = string.gsub(message, "|Htrade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+|h","")

				table.insert(tradeLinkQueue, { link, messageClean } )
--DEFAULT_CHAT_FRAME:AddMessage("added message to queue..."..link)

			end
		end
	end


	local function UpdateWhoData()
		local numWhos, totalCount = GetNumWhoResults()

		local tradeData = GYPData[serverKey]

		playerLocation[playerWhoPending] = OFFLINE

		for i=1,numWhos do
			local charname, guildname, level, race, class, zone, classFileName = GetWhoInfo(i)
			if charname == playerWhoPending then
				playerWhoPending = ""
			end

			if playerLocation[charname] then
				playerLocation[charname] = zone
			end
		end

		if st then
			st:SortData()
			st:Refresh()
		end

		whoDataPending = false
		SetWhoToUI(0)
		lastWho = time()
	end


	local function InitPlayerLocation()
		for trade,data in pairs(GYPData[serverKey]) do
			for player,ad in pairs(data) do
				AddToPlayerList(player, time() - ad.time, OFFLINE)
			end
		end


		table.sort(playerList, function(a,b) return (playerAge[a] or 0)<(playerAge[b] or 0) end)
	end


	local function CreateTimer(name, countDown, triggerFunction, repeatTime)
		timerList[name] = {countDown=countDown, triggerFunction=triggerFunction, repeatTime=repeatTime}
	end


	local function DeleteTimer(name)
		timerList[name] = nil
	end


	local function UpdateHandler(this, elapsed)
		for name,timer in pairs(timerList) do
			timer.countDown = timer.countDown - elapsed
			if timer.countDown <= 0 then
				if timer.triggerFunction then
					timer:triggerFunction(timer)
				else
					print("trigger function is nil for timer: "..name)
				end

				if timer.repeatTime then
					timer.countDown = timer.countDown + timer.repeatTime
				else
					timerList[name] = nil
				end
			end
		end
	end


	local framesRegistered = {}

	local function TradeSkillUpdate()
--DEFAULT_CHAT_FRAME:AddMessage("TSUPDATE")
		local spells = {}

		for i=1,GetNumTradeSkills() do

			local recipeID = string.match(GetTradeSkillRecipeLink(i) or "","enchant:(%d+)")

			if recipeID then
				spells[tonumber(recipeID)] = true
			end
		end

		currentTradeskill = tradeIDbyName[GetTradeSkillLine()]

		if currentTradeskill then
			local bitmap = GYP.TradeLink:BitmapEncode(GYPConfig.spellList[currentTradeskill], spells)

			currentTradeBitmap = GYP.TradeLink:BitmapCompress(bitmap)
		else
			currentSingleTradeBitmap = nil
		end

		GYP.TradeButton:Update(currentTradeskill)

		if st then
			st:SortData()
			st:Refresh()
		end
	end


	local function TradeSkillOpen()
--DEFAULT_CHAT_FRAME:AddMessage("TSOPEN")
		tradeSkillIsOpen = true
	end


	local function TradeSkillClose()
--DEFAULT_CHAT_FRAME:AddMessage("TSCLOSE")
		tradeSkillIsOpen = nil
		currentTradeskill = nil
		currentTradeBitmap = nil
		currentSingleTradeBitmap = nil
		currentTradeLink = nil

		GYP.TradeButton:Update(currentTradeskill)

		if st then
			st:SortData()
			st:Refresh()
		end
	end


	local function TradeSkillValidateAndClose()
--DEFAULT_CHAT_FRAME:AddMessage("validate")
		DeleteTimer("validateTimeout")

		if IsTradeSkillLinked() and tradeLinkQueue[1] then
--DEFAULT_CHAT_FRAME:AddMessage("is valid")
			local tradeName, level = GetTradeSkillLine()
			local _,player = IsTradeSkillLinked()

			if tradeName ~= "UNKNOWN" then
				SaveAdvertisement(player,tradeName,tonumber(level),tradeLinkQueue[1][1],tradeLinkQueue[1][2])

				if tradeLinkQueue[1] then
					table.remove(tradeLinkQueue,1)
				end
			else
				if tradeLinkQueue[1] then
					table.remove(tradeLinkQueue,1)			-- delete broken links
				end
			end

			CloseTradeSkill()
		end

		RegisterEvent(master, "TRADE_SKILL_SHOW", TradeSkillOpen)

		for k,f in pairs(framesRegistered) do
			f:RegisterEvent("TRADE_SKILL_SHOW")
		end
	end



	local function TradeLinkValidate(timer)
		if not tradeSkillIsOpen then
			if #tradeLinkQueue > 0 then
				local t = tradeLinkQueue[1]

				local link = t[1]
				local message = t[2]

	--			local tradeString = string.match(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")
				local tradeString, bitmap = string.match(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+):([A-Za-z0-9+/]+)")
				local tradeID = string.match(tradeString, "trade:(%d+):")

				tradeID = tonumber(tradeID)

				if not simpleBitmap[tradeID] then
					simpleBitmap[tradeID] = "//"..string.rep("A", string.len(bitmap)-2)
				end

				framesRegistered = { GetFramesRegisteredForEvent("TRADE_SKILL_SHOW") }

				for k,f in pairs(framesRegistered) do
					f:UnregisterEvent("TRADE_SKILL_SHOW")
				end

				RegisterEvent(master, "TRADE_SKILL_SHOW", TradeSkillValidateAndClose)
				ItemRefTooltip:SetHyperlink(tradeString..":"..simpleBitmap[tradeID])

				CreateTimer("validateTimeout", 1.0, TradeSkillValidateAndClose)
			end
		end
	end




	local previousIndex = 0
	local whoIteration = 0
	local function WhoUpdate(timer)
		if #playerList < 1 then return end

		if not WhoFrame:IsVisible() and #backgroundWho == 0 then
			playerWhoPending = ""

			whoIteration = whoIteration + 1

			local index = previousIndex + 1

			if index > #playerList then
				index = 1
			end

			previousIndex = index

			if not friendList[playerList[index]] and not guildList[playerList[index]] then
				BackgroundSendWho("n-"..playerList[index])
				playerWhoPending = playerList[index]
			else
				timer.countDown = 1 - timer.repeatTime			-- hack to try again in 1 second since this player is not interesting to us
			end
		end
	end


	local function FriendUpdate(timer)
		for i=1,GetNumFriends() do
			local name, level, class, area, connected, status, note = GetFriendInfo(i)

			if name then
				if connected then
					playerLocation[name] = area
				else
					playerLocation[name] = OFFLINE
				end

				friendList[name] = true
			end
		end
	end


	local function GuildRosterUpdate()
		local members = GetNumGuildMembers(true)


		for i=1,members do
			local name, _, _, _, _, zone, _, _, online, status = GetGuildRosterInfo(i)

			if name then
				if online then
					playerLocation[name] = zone
				else
					local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
					local lastOn

					if yearsOffline == 0 and monthsOffline == 0 then
						if daysOffline > 0 then
							lastOn = (math.floor((daysOffline + hoursOffline/24)*10+5)/10).." days"
						else
							if hoursOffline == 0 then
								lastOn = "not long"
							else
								lastOn = (math.floor(hoursOffline*10+5)/10).." hours"
							end
						end
					else
						lastOn = "ages"
					end

					playerLocation[name] = OFFLINE .. " ("..lastOn..")"
				end

				guildList[name] = true
			end
		end

		guildDataPending = false
	end


	local function GuildUpdate(timer)
		if IsInGuild() then
			GuildRoster()

			guildDataPending = true
		end
	end


	local function SystemMessageParse(msg)
		if string.find(msg,"^|Hplayer:") then
			local playerLinkID, playerLinkName, level, race, class, guild, zone = string.match(msg, WHO_LIST_GUILD_FORMAT)

			if not zone then
				local _, _, _, _, _, zone = string.match(msg, WHO_LIST_FORMAT)
			end

			if playerLocation[playerLinkName] then
				playerLocation[playerLinkName] = zone
			end

			lastWho = time()
		end
	end


--["link"] = "|cffffd000|Htrade:13920:245:300:2EAC490:4//fb7a8f5Z/muyHPAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAA|h[Enchanting]|h|r",

	local function UpdateDatabase(oldList, newList)
		for serverKey, serverData in pairs(GYPData) do
			serverData["UNKNOWN"] = nil								-- delete any malformed ads

			for tradeName, tradeData in pairs(serverData) do
				local spellMask = {}

				local tradeID = tradeIDbyName[tradeName]

				if tradeName ~= "UNKNOWN" then
					for player, ad in pairs(tradeData) do
						local tradeInfo,bitmap = string.match(ad.link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:)([A-Za-z0-9+/]+)")
--DEFAULT_CHAT_FRAME:AddMessage("UPDATING "..player.." "..ad.link.." "..tostring(tradeID))
						spellMask = GYP.TradeLink:BitmapDecode(oldList[tradeID], bitmap, spellMask)

						local newBitmap = GYP.TradeLink:BitmapEncode(newList[tradeID], spellMask)

						if newBitmap ~= bitmap then
	--						local xormap = TradeLink:BitmapBitLogic(newBitmap, bitmap, bit.bxor)

	--						TradeLink:DumpSpells(newList, xormap)

							ad.link = "|cffffd000|H"..tradeInfo..newBitmap.."|h["..tradeName.."]|h|r"
						end
					end
				else

				end
			end
		end
	end



	local function InitSystem(spellList)
		print("Init")
		local version, build = GetBuildInfo()

		build = tonumber(build)
		GYPConfig.dataVersion = tonumber(GYPConfig.dataVersion)

		if GYPConfig.dataVersion ~= build then
			if not GYPConfig.spellList then
				GYPData = {}
			else
				UpdateDatabase(GYPConfig.spellList, spellList)
			end

			GYPConfig.spellList = spellList
		end

		GYPConfig.dataVersion = build

		if not GYPData then GYPData = {} end
		if not GYPData[serverKey] then GYPData[serverKey] = {} end


		InitPlayerLocation()

		frame = GYP.Window:CreateResizableWindow("GYPFrame", "Gnomish Yellow Pages (rev"..VERSION..")", 700, 400, ResizeMainWindow)

		frame:SetMinResize(600,200)



		frame:SetScript("OnEvent", EventHandler)

		SLASH_GNOMISHYELLOWPAGES1 = "/gnomishyellowpages"
		SLASH_GNOMISHYELLOWPAGES2 = "/GYP"
		SLASH_GNOMISHYELLOWPAGES3 = "/yp"
		SLASH_GNOMISHYELLOWPAGES4 = "/yellowpages"
		SlashCmdList["GNOMISHYELLOWPAGES"] = function() ToggleFrame() end

		local oldClose = CloseSpecialWindows

		CloseSpecialWindows = function()
			if not frame:IsVisible() then
				return oldClose()
			else
				frame.title:Hide()
				frame:Hide()
				return 1
			end
		end


		frame.keyCapture = CreateFrame("Frame", nil, frame)

--		frame.keyCapture:SetPoint("TOPLEFT",0,0)
--		frame.keyCapture:SetPoint("BOTTOMRIGHT",0,0)
--		frame.keyCapture:SetFrameLevel(frame:GetFrameLevel()+50)
--		frame.keyCapture:EnableMouse(true)

		local function keyboardEnabler(eventFrame, event, arg1, arg2)
			if event == "MODIFIER_STATE_CHANGED" then
				if arg1 == "LCTRL" or arg1 == "RCTRL" then
					frame.keyCapture:EnableKeyboard(arg2==1)
				end
			end
		end

		frame.mover:SetScript("OnEnter", function(frame) frame:RegisterEvent("MODIFIER_STATE_CHANGED") end)
		frame.mover:SetScript("OnLeave", function(frame) frame:UnregisterEvent("MODIFIER_STATE_CHANGED") end)
		frame.mover:SetScript("OnEvent", keyboardEnabler)

		frame.keyCapture:SetScript("OnKeyUp", function(frame, key)
			if frame.keyFunctions[key] then
				frame.keyFunctions[key]()
			end

			if not IsControlKeyDown() then
				frame:EnableKeyboard(false)
			end
		end)

		local function DeleteEntries()
			if selectedRows then
				local count = 0

				for k,s in pairs(selectedRows) do
					if s then
						count = count + 1
					end
				end

				if count > 1 then
					GYP.UserInputDialog:Show("Okay to delete "..count.." yellow pages entries?", "Okay", SelectedRowsDelete, "Cancel", function () end)
				else
					GYP.UserInputDialog:Show("Okay to delete this entry?", "Okay", SelectedRowsDelete, "Cancel", function () end)
				end
			end
		end

		RegisterKeyFunction(frame.keyCapture, "X", DeleteEntries)

		local oldFriendsFrame_OnEvent = FriendsFrame_OnEvent

		FriendsFrame_OnEvent = function (...)
			if event == "WHO_LIST_UPDATE" then
				if not whoDataPending or WhoFrame:IsVisible() then
					oldFriendsFrame_OnEvent(...)
				end
			elseif event == "GUILD_ROSTER_UPDATE" then
				if not guildDataPending then
					oldFriendsFrame_OnEvent(...)
				end
			else
				oldFriendsFrame_OnEvent(...)
			end
		end



		BlizzardSendWho = SendWho

		SendWho = PrioritySendWho


		hooksecurefunc("SelectTradeSkill", function(index)
			if index then
				local spells = {}

				local found,_,recipeID = string.find(GetTradeSkillRecipeLink(index) or "","enchant:(%d+)")

				if found then
					spells[tonumber(recipeID)] = true
				end

				currentTradeskill = tradeIDbyName[GetTradeSkillLine()]

				if currentTradeskill then
					local bitmap = GYP.TradeLink:BitmapEncode(GYPConfig.spellList[currentTradeskill], spells)

					currentSingleTradeBitmap = GYP.TradeLink:BitmapCompress(bitmap)
				else
					currentSingleTradeBitmap = nil
				end
			else
				currentSingleTradeBitmap = nil
			end

			if st then
				st:SortData()
				st:Refresh()
			end
		end)



		hooksecurefunc("SetItemRef", function(s,link,button)
			if string.find(s,"trade:") then
				currentTradeLink = link
--DEFAULT_CHAT_FRAME:AddMessage("string = "..s);
			end
		end)



		LoadAddOn("Skillet")

		if Skillet then
			local original_SkilletSetSelectedSkill = Skillet.SetSelectedSkill

			function Skillet:SetSelectedSkill(skillIndex, wasClicked)
				if skillIndex then
					SelectTradeSkill(skillIndex)
				end

				original_SkilletSetSelectedSkill(Skillet,skillIndex, wasClicked)
			end
		end



		local optionsPanel = CreateFrame( "Frame", "GYPConfigPanel", UIParent );

		optionsPanel.name  = "Gnomish Yellow Pages"
		optionsPanel.okay = function(self) end
		optionsPanel.cancel = function(self) end

		InterfaceOptions_AddCategory(optionsPanel);

		local function WhoTimerAdjustment()
			GYPConfig["WhoUpdate"] = whoAutoUpdateToggle.value
			GYPConfig["WhoFrequency"] = whoAutoUpdateFrequency.value

			if whoAutoUpdateToggle.value then
--				CreateTimer("whoUpdater", whoAutoUpdateFrequency.value, WhoUpdate, whoAutoUpdateFrequency.value)
			else
				DeleteTimer("whoUpdater")
			end
		end

		whoAutoUpdateToggle = CreateToggle(optionsPanel, "Auto Update Stranger Locations", GYPConfig["WhoUpdate"], WhoTimerAdjustment)
		whoAutoUpdateFrequency = CreateSlider(whoAutoUpdateToggle, "Frequency for Update", 10, 60, GYPConfig["WhoFrequency"], "seconds", WhoTimerAdjustment)

		whoAutoUpdateToggle:SetPoint("TOPLEFT", 50,-50)


		local function PruneAgeAdjust()
			GYPConfig["PruneAge"] = pruneAge.value
		end

		pruneAge = CreateSlider(optionsPanel, "Age Pruning (on reload)", 10, 60, GYPConfig["PruneAge"], "days", PruneAgeAdjust)
		pruneAge:SetPoint("TOPLEFT", 50, -150)


		WhoTimerAdjustment()


		CreateTimer("friendUpdater", 15, FriendUpdate, 60)
		CreateTimer("guildUpdater", 5, GuildUpdate, 60)
		CreateTimer("ProcessWhoQueue", 1, ProcessWhoQueue, 1)
		CreateTimer("tradeLinkValidate", 5, TradeLinkValidate, 5)

		GYP.TradeButton:Create(tradeList, frame, GYPConfig.spellList)


		RegisterEvent(master, "WHO_LIST_UPDATE", UpdateWhoData)
		RegisterEvent(master, "GUILD_ROSTER_UPDATE", GuildRosterUpdate)
		RegisterEvent(master, "TRADE_SKILL_SHOW", TradeSkillOpen)
		RegisterEvent(master, "TRADE_SKILL_CLOSE", TradeSkillClose)
		RegisterEvent(master, "TRADE_SKILL_UPDATE", TradeSkillUpdate)
--		RegisterEvent(master, "CHAT_MSG_SYSTEM", SystemMessageParse)


		local now = time()
		local secondsPerDay = 60*60*24

		for trade, adList in pairs(GYPData[serverKey]) do
			for player, ad in pairs(adList) do
				if (now-ad.time)/secondsPerDay > GYPConfig.PruneAge then
					adList[player] = nil
				end
			end
		end


		for i=1, #tradeIDList do
			local tradeID = tradeIDList[i]


--	local function SaveAdvertisement(player,tradeName,level,link,message,age)
			local spellName = GetSpellInfo(tradeID)

			local link,tradeLink = GetSpellLink(tradeID)

--DEFAULT_CHAT_FRAME:AddMessage("trade list "..i.." "..tradeID.." "..tostring(spellName).." "..tostring(tradeLink))

			if tradeLink then
				local level = tradeLink:match("trade:%d+:(%d+)")

				level = tonumber(level or 0)

				if level>0 then
					SaveAdvertisement(player,spellName,level,tradeLink,"added by gyp")
				end
			end
		end

--	guild sharing wip
--		GYP.guild:Initialize(frame, master)
	end


	local function OnLoad()
		print ("LOADED")
		local guid = UnitGUID("player")
		playerGUID = string.gsub(guid,"0x0+", "")

		local version, build = GetBuildInfo()
		build = tonumber(build)

		if not GYPConfig then
			GYPConfig = { ["WhoUpdate"] = true, ["WhoFrequency"] = 20, ["PruneAge"] = 30  }
		end

		if not GYPConfig.PruneAge then
			GYPConfig.PruneAge = 30
		end

		GYPConfig.dataVersion = tonumber(GYPConfig.dataVersion)

		GYP.TradeLink = LibStub:GetLibrary("LibTradeSkillScan", true)


		GYP.TradeLink:Register(modName, InitSystem, GYPConfig.dataVersion, GYPConfig.spellList)							-- Scan() calls InitSystem with newly discovered spellList

--[[
		if GYPConfig.dataVersion ~= build or not GYPConfig.spellList then
			if not GYPSpellData or not GYPSpellData[build] then
				GYP.TradeLink:Scan(modName, InitSystem, GYPConfig.dataVersion, GYPConfig.spellList)							-- Scan() calls InitSystem with newly discovered spellList
			else
				InitSystem(GYPSpellData[build])						-- call InitSystem with packaged spell data for this build
			end
		else
			InitSystem(GYPConfig.spellList)							-- call InitSystem with the current spell data
		end
]]
	end


	function GYP.RegisterEvent(event,func)
		if eventFrame==nil then
			eventFrame=CreateFrame("Frame")	
		end
		if eventFrame._GPIPRIVAT_events==nil then 
			eventFrame._GPIPRIVAT_events={}
			eventFrame:SetScript("OnEvent",EventHandler)
		end
		tinsert(eventFrame._GPIPRIVAT_events,{event,func})
		eventFrame:RegisterEvent(event)	
	end

	local function ChatEventHandler(message)
		ChatMessage(message)
	end


	for v in pairs(ChatMessageTypes) do
		RegisterEvent(master, v,  ChatEventHandler)
	end

	if not IsAddOnLoaded("AddonLoader") then
		RegisterEvent(master, "PLAYER_ENTERING_WORLD", function()
			CreateTimer("Load", 5, OnLoad)
			master:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end )
	else
		GYP.RegisterEvent("ADDON_LOADED",OnLoad)
--		OnLoad()
	end


--	RegisterEvent(master, "PLAYER_ENTERING_WORLD", function() OnLoad() master:UnregisterEvent("PLAYER_ENTERING_WORLD") end )


	master:SetScript("OnEvent", ParseEvent)
	master:SetScript("OnUpdate", UpdateHandler)



	GYP.basicTrade = basicTrade

	GYP.ads.SaveAdvertisement = SaveAdvertisement
	GYP.timer.CreateTimer = CreateTimer
	GYP.timer.DeleteTimer = DeleteTimer
end

