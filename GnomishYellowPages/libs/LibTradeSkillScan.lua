local modName, modTable = ...


local MAJOR, MINOR = "LibTradeSkillScan", tonumber("r64") or 1;
local Lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR);
if not Lib then
	return -- No Upgrade needed.
end

local CloseTradeSkill

local maxSkillDepth = 30

if ArmoryTradeSkillFrame then
	maxSkillDepth = 0
	CloseTradeSkill = function()
		ArmoryTradeSkillFrame.closing = nil
		_G.CloseTradeSkill()
	end
else
	CloseTradeSkill = _G.CloseTradeSkill
end


do
	local AddonRegistry = {}
	local scanInitiated
	local scanComplete

	local clientVersion, clientBuild = GetBuildInfo()
	clientBuild = tonumber(clientBuild)
	local minBuild = clientBuild


	local fullTradeLink = {}


	local startTime
	local startMem

	local encodedByte = {
							'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
							'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
							'0','1','2','3','4','5','6','7','8','9','+','/'
						}

	local decodedByte = {}

	for i=1,#encodedByte do
		local b = string.byte(encodedByte[i])

		decodedByte[b] = i - 1
	end


	local tradeIDList = { 2259, 2018, 7411, 4036, 45357, 25229, 2108, 3908,  2550, 3273 }

	local tradeIndexByID = {}

	for k,tradeID in ipairs(tradeIDList) do
		tradeIndexByID[tradeID] = k
	end


	local tradeIDByName = {}

	for index, id in pairs(tradeIDList) do
		local tradeName = string.lower(GetSpellInfo(id))
		tradeIDByName[tradeName] = id
	end

	tradeIDByName[string.lower(GetSpellInfo(2575))] = 2656	-- special case for mining/smelting





	local playerGUID

	local spellList = {}


	local tradeIndex = 1
	local spellBit = 0
	local countDown = 5
	local bitMapSizes = {}
	local timeToClose = 0
	local frameOpen = false

	local framesRegistered

	local progressBar

	local OnScanCompleteCallback


	local function DispatchInitialization()
		for addon,addon in pairs(AddonRegistry) do
			addon.init(spellList)
		end
	end


	local function ScanComplete(frame)

		frame:SetScript("OnUpdate", nil)
		frame:UnregisterEvent("TRADE_SKILL_UPDATE")
		frame:UnregisterEvent("TRADE_SKILL_CLOSE")
		frame:UnregisterEvent("TRADE_SKILL_SHOW")

		frame:Hide()

		for k,f in pairs(framesRegistered) do
			f:RegisterEvent("TRADE_SKILL_SHOW")
		end

		progressBar:Hide()


--[[
		collectgarbage()
		UpdateAddOnMemoryUsage()
		local mem = GetAddOnMemoryUsage(modName) - startMem

		DEFAULT_CHAT_FRAME:AddMessage("Scan Completed in "..(time()-startTime).." seconds ("..math.floor(mem+.5).."k)")
]]

		scanComplete = true

		DispatchInitialization()
	end



	local function OnTradeSkillShow()
		frameOpen = true
	end


	local function OnTradeSkillClose(frame)
		frameOpen = false

		spellBit = spellBit + 1

		if spellBit <= (bitMapSizes[tradeIndex] or 0)*6 then
			local percentComplete = spellBit/(bitMapSizes[tradeIndex]*6)

			progressBar.fg:SetWidth(300*percentComplete)
			progressBar.textRight:SetText(spellBit)


			local bytes = floor((spellBit-1)/6)
			local bits = (spellBit-1) - bytes*6

			local bmap = string.rep("A", bytes) .. encodedByte[bit.lshift(1, bits)+1] .. string.rep("A", bitMapSizes[tradeIndex]-bytes-1)

			local tradeString = string.format("trade:%d:600:600:%s:%s", tradeIDList[tradeIndex], playerGUID, bmap)

			local link = "|cffffd000|H"..tradeString.."|h["..GetSpellInfo(tradeIDList[tradeIndex]).."]|h|r"

			timeToClose = 30

			ItemRefTooltip:SetHyperlink(tradeString)
		else
			tradeIndex = tradeIndex + 1
			spellBit = 0

			if tradeIndex <= #tradeIDList then
				OnTradeSkillClose(frame)
			else
				ScanComplete(frame)
			end
		end
	end


	local tradeSkillDepth = maxSkillDepth

	local function OnTradeSkillUpdate(frame)
		if spellBit > 0 and bitMapSizes[tradeIndex] then
			if not spellList[tradeIDList[tradeIndex]] then
				spellList[tradeIDList[tradeIndex]] = {}
			end

			local numSkills = GetNumTradeSkills()

			spellList[tradeIDList[tradeIndex]][spellBit] = tradeIDList[tradeIndex] -- placeHolder

--			if numSkills==2 then
				local recipeLink = GetTradeSkillRecipeLink(numSkills)

				if recipeLink then
					local recipeID = tonumber(recipeLink:match("enchant:(%d+)"))

					progressBar.textLeft:SetText(recipeLink)
					spellList[tradeIDList[tradeIndex]][spellBit] = recipeID
				end

				if tradeSkillDepth < maxSkillDepth then
					tradeSkillDepth = tradeSkillDepth + 1
					CloseTradeSkill()
				else
					tradeSkillDepth = 0
					timeToClose = 0.001
				end
--			else
--				timeToClose = 0.001
--			end
		else
			timeToClose = 0
		end
	end


	local function OnUpdate(frame, elapsed)
		timeToClose = timeToClose - elapsed

		if timeToClose < 0 then
			timeToClose = 1000
			CloseTradeSkill()
		end
	end


	function Lib:Scan(callback)
		startTime = time()

		OnScanCompleteCallback = callback

		local guid = UnitGUID("player")
		playerGUID =  string.gsub(guid,"0x0+", "")


		framesRegistered = { GetFramesRegisteredForEvent("TRADE_SKILL_SHOW") }

		for k,f in pairs(framesRegistered) do
			f:UnregisterEvent("TRADE_SKILL_SHOW")
		end


		for k,id in ipairs(tradeIDList) do
			local spellLink, tradeLink = GetSpellLink(k)

			if tradeLink then
				local tradeID,ranks,guid,bitMap,tail = string.match(tradeLink,"|c%x+|H(trade:%d+):(%d+:%d+):([0-9a-fA-F]+:)([A-Za-z0-9+/]+)(|h%[[^]]+%]|h|r)")

				local fullBitMap = string.rep("/",string.len(bitMap or ""))

				local fullTradeString = string.format("%s:525:525:%s%s%s",tradeID, guid, fullBitMap)

				ItemRefTooltip:SetHyperlink(fullTradeString)
			end
		end

		local backdropInfo =
		{
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileEdge = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		}

		local progressBar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		progressBar:SetBackdrop(backdropInfo)

	
		progressBar:SetBackdropColor(0,0,0,1);


		progressBar:SetFrameStrata("DIALOG")

		progressBar:SetWidth(310)
		progressBar:SetHeight(30)

		progressBar:SetPoint("CENTER",0,-150)

		progressBar.fg = progressBar:CreateTexture()
		progressBar.fg:SetTexture(.8,.7,.2,.5)
		progressBar.fg:SetPoint("LEFT",progressBar,"LEFT",5,0)
		progressBar.fg:SetHeight(20)
		progressBar.fg:SetWidth(300)

		progressBar.textLeft = progressBar:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
		progressBar.textLeft:SetText("Scanning...")
		progressBar.textLeft:SetPoint("LEFT",10,0)

		progressBar.textRight = progressBar:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
		progressBar.textRight:SetText("0%")
		progressBar.textRight:SetPoint("RIGHT",-10,0)

		progressBar:EnableMouse()

		progressBar:SetScript("OnEnter", function(frame)
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(frame, "ANCHOR_NONE")
			GameTooltip:SetPoint("BOTTOM",frame,"TOP",0,5)

			GameTooltip:AddLine("Scanning recipe data for the following addons:")

			for addon in pairs(AddonRegistry) do
				GameTooltip:AddLine(addon)
			end

			GameTooltip:Show()
		end)

		progressBar:SetScript("OnLeave", function(frame)
			GameTooltip:Hide()
		end)

		local scanFrame = CreateFrame("Frame")


		scanFrame:RegisterEvent("TRADE_SKILL_SHOW")
		scanFrame:RegisterEvent("TRADE_SKILL_UPDATE")
		scanFrame:RegisterEvent("TRADE_SKILL_CLOSE")

		scanFrame:SetScript("OnEvent", function(frame,event)
--DEFAULT_CHAT_FRAME:AddMessage(tostring(event))
			if event == "TRADE_SKILL_SHOW" then
				OnTradeSkillShow(frame)
			end

			if event == "TRADE_SKILL_CLOSE" then
				OnTradeSkillClose(frame)
			end

			if event == "TRADE_SKILL_UPDATE" then
				OnTradeSkillUpdate(frame)
			end
		end)

		scanFrame:SetScript("OnUpdate", OnUpdate)


		local tradeIDList = { 2259, 2018, 7411, 4036, 45357, 25229, 2108, 3908,  2550, 3273 }
	

		for tradeIndex, tradeID in ipairs(tradeIDList) do

			local tradeLink, _ = GetSpellTradeSkillLink(tradeID)
			print("Trade Link for id: " .. tradeID)
			print(tradeLink)

			local bitMap = string.match(tradeLink,"|c%x+|Htrade:%d+:%d+:%d+:[0-9a-fA-F]+:([A-Za-z0-9+/]+)|h%[[^]]+%]|h|r")

			bitMapSizes[tradeIndex] = string.len(bitMap)
		end
		

	--	local tradeNameList = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Inscription", "Jewelcrafting", "Leatherworking", "Tailoring",  "Cooking", "First Aid" }
		--for tradeIndex, tradeName in ipairs(tradeNameList) do

	--		CastSpellByName(tradeName)
--			local tradeLink, _ = GetTradeSkillListLink()
		--	print("Trade Link for id: " .. tradeName)
		--	print(tradeLink)

		--	local bitMap = string.match(tradeLink,"|c%x+|Htrade:%d+:%d+:%d+:[0-9a-fA-F]+:([A-Za-z0-9+/]+)|h%[[^]]+%]|h|r")

	--		bitMapSizes[tradeIndex] = string.len(bitMap)
	--	end


		OnTradeSkillClose()
	end


	function Lib:BitmapEncode(data, mask)
		local v = 0
		local b = 1
		local bitmap = ""

		for i=1,#data do
			if mask[data[i]] == true then
				v = v + b
			end

			b = b * 2

			if b == 64 then
				bitmap = bitmap .. encodedByte[v+1]
				v = 0
				b = 1
			end
		end

		if b>1 then
			bitmap = bitmap .. encodedByte[v+1]
		end

		return bitmap
	end


	function Lib:BitmapDecode(data, bitmap, maskTable)
		local mask = maskTable or {}
		local index = 1

		for i=1, string.len(bitmap) do
			local b = decodedByte[string.byte(bitmap, i)]
			local v = 1

			for j=1,6 do
				if index <= #data and data[index] then
					if bit.band(v, b) == v then
						mask[data[index]] = true
					else
						mask[data[index]] = false
					end
				end
				v = v * 2

				index = index + 1
			end
		end

		return mask
	end


	function Lib:BitmapBitLogic(A,B,logic)
		local length = math.min(string.len(A), string.len(B))
		local R = ""

		for i=1, length do
			local a = decodedByte[string.byte(A, i)]
			local b = decodedByte[string.byte(B, i)]

			local r = logic(a,b)

			R = R..encodedByte[r+1]
		end

		return R
	end


	function Lib:DumpSpells(data, bitmap)
		local index = 1

		for i=1, string.len(bitmap) do
			local b = decodedByte[string.byte(bitmap, i)]
			local v = 1

			for j=1,6 do
				if index <= #data then
					if bit.band(v, b) == v then
						DEFAULT_CHAT_FRAME:AddMessage("bit "..index.." = spell:"..data[index].." "..GetSpellLink(data[index]))
					end
				end
				v = v * 2

				index = index + 1
			end
		end
	end



	function Lib:BitmapCompress(bitmap)
		if not bitmap then return end

		local len = string.len(bitmap)
		local compressed = {}
		local n = 1

		for i=1,len,5 do
			local map = 0

			map = decodedByte[string.byte(bitmap, i) or 65]

			v = decodedByte[string.byte(bitmap,i+1) or 65]
			map = bit.lshift(map, 6) + v


			v = decodedByte[string.byte(bitmap,i+2) or 65]
			map = bit.lshift(map, 6) + v


			v = decodedByte[string.byte(bitmap,i+3) or 65]
			map = bit.lshift(map, 6) + v


			v = decodedByte[string.byte(bitmap,i+4) or 65]
			map = bit.lshift(map, 6) + v

			compressed[n] = map

			n = n + 1
		end

		return compressed
	end




	-- must pass the guid
	function Lib:GenerateLink(guid)
		if guid and GetTradeSkillLine() then
			local tradeName, rank, maxRank = GetTradeSkillLine()

			local tradeID = tradeIDByName[string.lower(tradeName)]

			local bitMapSize = bitMapSizes[tradeIndexByID[tradeID]] or 0

			local mask = {}

			for i=1,bitMapSize*6 do
				local spellName, spellType = GetTradeSkillInfo(i)

				if spellName and spellType ~= "header" then
					local recipeLink = GetTradeSkillRecipeLink(i)
					local recipeID = tonumber(recipeLink:match("enchant:(%d+)"))

					mask[recipeID] = true
				end
			end


			local bitMap = Lib:BitmapEncode(spellList[tradeID], mask)

			local tradeLink = string.format("|cffffd000|Htrade:%d:%d:%d:%s:%s:|h[%s]|h|r", tradeID, rank, maxRank, guid, bitMap,tradeName)

			return tradeLink
		end
	end



-- the following only operate on COMPRESSED bitmaps
	function Lib:BitsShared(b1, b2)
		local sharedBits = 0
		local len = math.min(#b1,#b2)

		for i=1,len do
			result = bit.band(b1[i],b2[i] or 0)

			if result~=0 then
				for b=0,29 do
					if bit.band(result, 2^b)~=0 then
						sharedBits = sharedBits + 1
					end
				end
			end
		end

		return sharedBits
	end


	function Lib:CountBits(bmap)
		local bits = 0
		local len = #bmap

		for i=1,len do
			if result~=0 then
				for b=0,29 do
					if bit.band(bmap[i], 2^b)~=0 then
						bits = bits + 1
					end
				end
			end
		end
		return bits
	end



	local function waitForSpellLinks()
		for tradeIndex, tradeID in pairs(tradeIDList) do
			local tradeLink = GetTradeSkillListLink()
			print("WAITING FOR SPELL LINKS")
			print(tradeID)
			if not tradeLink then
				return
			end

		--if tradeLink ~= nil then
			print(tradeLink)
			local tradeHead, bitMap = string.match(tradeLink, "(|cffffd000|Htrade:Player%-%d+%-[0-9A-Fa-f]+:%d+:%d+)([0-9a-zA-Z+/]+)")
			local len = string.len(bitMap)

			local tradeString = tradeHead..string.rep("/",len)

			local fullLink = tradeString.."|h["..GetSpellInfo(tradeID).."]|h|r"

--print(fullLink, string.gsub(fullLink, "|", "||"))

			fullTradeLink[tradeID] = fullLink
		--	end
		end

		return true
	end




	function Lib:Register(addonName, initFunction, build, data)
		build = build or 0

		minBuild = min(build, minBuild)
		print("BUILD IS: " .. build)
		print("MIN BUILD: " .. minBuild)
		print("CLIENT BUILD: " .. clientBuild)
		if build == clientBuild and spellList then
			print("INSIDE")
			spellList = data								-- copy this data!
		end

		AddonRegistry[addonName] = { init = initFunction, build = build, data = data }

		if minBuild ~= clientBuild then
			if not scanInitiated then
				scanInitiated = true
				print("DELAY FRAME")
				local delayFrame = CreateFrame("Frame")
				delayFrame.timer = 1
				delayFrame:SetScript("OnUpdate", function(frame, elapsed)
					frame.timer = frame.timer - elapsed

					if frame.timer < 0 then
						if waitForSpellLinks() then
							frame:Hide()
							frame:SetScript("OnUpdate",nil)

							Lib:Scan()
							frame.timer = 100000
						else
							frame.timer = 1
						end
					end
				end)
			else
				if scanComplete then
					print("SCAN COMPLETE")
					initFunction(spellList)
				end
			end
		else
			print("INIT FUNC")
			initFunction(data)
		end
	end

--[[
	function Lib:Cleanup()
		TradeSkillData = {}
		recipeData = nil
	end
]]

end

