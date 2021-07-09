


local TradeLink = {}


local recipeData = {}
local itemSource = {}
local reagentUsage = {}

TradeSkillData = {}

TradeSkillData.recipeData = recipeData
TradeSkillData.itemSource = itemSource
TradeSkillData.reagentUsage = reagentUsage

--YPData.TradeSkillData = TradeSkillData

do
	local function OpenTradeLink(tradeString)
	--	ShowUIPanel(ItemRefTooltip)
	--	if ( not ItemRefTooltip:IsShown() ) then
	--		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
	--	end
--DEFAULT_CHAT_FRAME:AddMessage(tradeString)

		ItemRefTooltip:SetHyperlink(tradeString)
	end

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

		if OnScanCompleteCallback then
			collectgarbage()
			UpdateAddOnMemoryUsage()
			local mem = GetAddOnMemoryUsage("GnomishYellowPages") - startMem

--			DEFAULT_CHAT_FRAME:AddMessage("GYP Scan Completed in "..(time()-startTime).." seconds ("..math.floor(mem+.5).."k)")
			OnScanCompleteCallback(spellList)
		end
	end


	local function OnTradeSkillShow()
--DEFAULT_CHAT_FRAME:AddMessage("SHOW "..spellBit.." "..tostring(GetTradeSkillLine()))
		frameOpen = true
	end


	local function OnTradeSkillClose(frame)
--DEFAULT_CHAT_FRAME:AddMessage("CLOSE "..spellBit.." "..tostring(GetTradeSkillLine()))
		frameOpen = false

		spellBit = spellBit + 1

		if spellBit <= bitMapSizes[tradeIndex]*6 then
			local percentComplete = spellBit/(bitMapSizes[tradeIndex]*6)

			progressBar.fg:SetWidth(300*percentComplete)
			progressBar.textRight:SetText(spellBit)


			local bytes = floor((spellBit-1)/6)
			local bits = (spellBit-1) - bytes*6

			local bmap = string.rep("A", bytes) .. encodedByte[bit.lshift(1, bits)+1] .. string.rep("A", bitMapSizes[tradeIndex]-bytes-1)

--			bmap = string.rep("A", bytes)

			local tradeString = string.format("trade:%d:450:450:%s:%s", tradeIDList[tradeIndex], playerGUID, bmap)

			local link = "|cffffd000|H"..tradeString.."|h["..GetSpellInfo(tradeIDList[tradeIndex]).."]|h|r"

--DEFAULT_CHAT_FRAME:AddMessage(tradeString)
--DEFAULT_CHAT_FRAME:AddMessage(link)

			timeToClose = 30

			OpenTradeLink(tradeString)
		else
			tradeIndex = tradeIndex + 1
			spellBit = 0

			if tradeIndex <= #tradeIDList then
				OnTradeSkillClose()
--				timeToClose = 0.1
			else
				ScanComplete(frame)
			end
		end
	end


	local tradeSkillDepth = 0

	local function OnTradeSkillUpdate(frame)
--DEFAULT_CHAT_FRAME:AddMessage("UPDATE "..spellBit.." "..tostring(GetTradeSkillLine()))

		if not spellList[tradeIDList[tradeIndex]] then
			spellList[tradeIDList[tradeIndex]] = {}
		end

		if spellBit > 0 and bitMapSizes[tradeIndex] then
			local numSkills = GetNumTradeSkills()


--			DEFAULT_CHAT_FRAME:AddMessage("skills = "..tonumber(numSkills))

			spellList[tradeIDList[tradeIndex]][spellBit] = tradeIDList[tradeIndex] -- placeHolder

			if numSkills==2 then
				local recipeLink = GetTradeSkillRecipeLink(2)

				if recipeLink then
					local recipeID = tonumber(recipeLink:match("enchant:(%d+)"))

--DEFAULT_CHAT_FRAME:AddMessage(spellBit.." = "..id.."-"..recipeLink)
					progressBar.textLeft:SetText(recipeLink)
					spellList[tradeIDList[tradeIndex]][spellBit] = recipeID
				end

--				timeToClose = 0.001
--				timeToClose = .1
--DEFAULT_CHAT_FRAME:AddMessage("Manual Close")
				if tradeSkillDepth < 20 then
					tradeSkillDepth = tradeSkillDepth + 1
					CloseTradeSkill()
				else
					tradeSkillDepth = 0
					timeToClose = 0.001
				end
			else
				timeToClose = 0.001
			end
		else
			timeToClose = 0
		end
	end


	local function OnUpdate(frame, elapsed)
--DEFAULT_CHAT_FRAME:AddMessage("UPDATE")
--		countDown = countDown - elapsed
		timeToClose = timeToClose - elapsed

--DEFAULT_CHAT_FRAME:AddMessage("countDown = "..countDown)
--		if countDown < 0 then
--			OnTradeSkillClose()
--		end

		if timeToClose < 0 then
			timeToClose = 1000
--DEFAULT_CHAT_FRAME:AddMessage("Call Auto-Close")
			CloseTradeSkill()
		end
	end

	function TradeLink:Scan(callback)

		startTime = time()

		GYPData.TradeSkillData = TradeSkillData


		OnScanCompleteCallback = callback

		local guid = UnitGUID("player")
		playerGUID = "0" -- "2C0D8F4" -- string.gsub(guid,"0x0+", "")
		playerGUID =  string.gsub(guid,"0x0+", "")




		framesRegistered = { GetFramesRegisteredForEvent("TRADE_SKILL_SHOW") }

		for k,f in pairs(framesRegistered) do
			f:UnregisterEvent("TRADE_SKILL_SHOW")
		end


		progressBar = CreateFrame("Frame", nil, UIParent)

		progressBar:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                                            tile = true, tileSize = 16, edgeSize = 16,
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
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
			GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")

			GameTooltip:AddLine("The Gnomish Yellow Pages Is Scanning...")
			GameTooltip:AddLine("|ca0ffffffA comprehensive scan of trade skills is required.")
			GameTooltip:AddLine("|ca0ffffffThis will take a few minutes and may pause while")
			GameTooltip:AddLine("|ca0ffffffdata is collected from the server.  A scan should")
			GameTooltip:AddLine("|ca0ffffffonly be required on initial install, when a new")
			GameTooltip:AddLine("|ca0ffffffgame patch has been released, or when gyp's")
			GameTooltip:AddLine("|ca0ffffffsaved variables file has been purged.")
			GameTooltip:AddLine("|ca0ffffffDuring the scan, trade skill interaction is blocked.")

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

		collectgarbage()
		UpdateAddOnMemoryUsage()
		startMem = GetAddOnMemoryUsage("GnomishYellowPages")


		local tradeIDList = { 2259, 2018, 7411, 4036, 45357, 25229, 2108, 3908,  2550, 3273 }

		for tradeIndex, tradeID in ipairs(tradeIDList) do

			local _,tradeLink = GetSpellLink(tradeID)

			local bitMap = string.match(tradeLink,"|c%x+|Htrade:%d+:%d+:%d+:[0-9a-fA-F]+:([A-Za-z0-9+/]+)|h%[[^]]+%]|h|r")

			bitMapSizes[tradeIndex] = string.len(bitMap)
		end


		OnTradeSkillClose()
	end


	function TradeLink:BitmapEncode(data, mask)
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


	function TradeLink:BitmapDecode(data, bitmap, maskTable)
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


	function TradeLink:BitmapBitLogic(A,B,logic)
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


	function TradeLink:DumpSpells(data, bitmap)
		local index = 1
--		Config.testOut = {}

		for i=1, string.len(bitmap) do
			local b = decodedByte[string.byte(bitmap, i)]
			local v = 1

			for j=1,6 do
				if index <= #data then
					if bit.band(v, b) == v then
						DEFAULT_CHAT_FRAME:AddMessage("bit "..index.." = spell:"..data[index].." "..GetSpellLink(data[index]))
--						Config.testOut[#Config.testOut+1] = "bit "..index.." = spell:"..data[index].." ["..GetSpellInfo(data[index]).."]"
					end
				end
				v = v * 2

				index = index + 1
			end
		end
	end



	function TradeLink:BitmapCompress(bitmap)
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



-- the following only operate on COMPRESSED bitmaps
	function TradeLink:BitsShared(b1, b2)
		local sharedBits = 0
		local len = math.min(#b1,#b2)

		for i=1,len do
			result = bit.band(b1[i],b2[i] or 0)
--DEFAULT_CHAT_FRAME:AddMessage(tostring(b1[i]).." "..tostring(b2[i]).." result "..result)

			if result~=0 then
				for b=0,29 do
					if bit.band(result, 2^b)~=0 then
						sharedBits = sharedBits + 1
					end
				end
			end
		end
--DEFAULT_CHAT_FRAME:AddMessage("shared "..sharedBits)
		return sharedBits
	end


	function TradeLink:CountBits(bmap)
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

	GYP.TradeLink = TradeLink
end


