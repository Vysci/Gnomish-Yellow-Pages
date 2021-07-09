



local TradeButton = {}

do
	local tradeButtonParent

	local function OnLeave(frame)
		GameTooltip:Hide()
	end


	local function OnEnter(frame)
		GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")

		GameTooltip:ClearLines()
		GameTooltip:AddLine(frame.tradeName,1,1,1)
		GameTooltip:AddLine("click to shop",.7,.7,.7)

		GameTooltip:Show()
	end


	local function OnClick(frame, button)
		local link = frame.tradeLink
		local tradeString = string.match(link, "(trade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+)")

		getglobal("GYPFrame"):SetFrameStrata("LOW")
--		SetItemRef(tradeString,link,button)
--		OpenTradeLink(tradeString)
		ItemRefTooltip:SetHyperlink(tradeString)
	end


	function TradeButton:Create(tradeSkillList, parentFrame, spellList)
		local buttonSize = 36
		local position = 0 -- pixel

		local guid = UnitGUID("player")
		local playerGUID = string.gsub(guid,"0x0+", "")


		local frameName = "GYPTradeButtons"
		local frame = CreateFrame("Frame", frameName, parentFrame)


		frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 30,-66)
		frame:SetWidth(buttonSize * #tradeSkillList + 5 * (#tradeSkillList-1))
		frame:SetHeight(buttonSize)

		frame:Show()

		frame:SetScale(0.7)

		tradeButtonParent = frame

		for i=1,#tradeSkillList,1 do					-- iterate thru all skills in defined order for neatness (professions, secondary, class skills)
			local tradeID = tradeSkillList[i].tradeID
			local spellName = GetSpellInfo(tradeID)
			local tradeLink

			local recipeList = spellList[tradeID]

			local encodingLength = floor((#recipeList+5) / 6)

			local encodedString = string.rep("/",encodingLength)

			tradeLink = "|cffffd00|Htrade:"..tradeID..":450:450:"..playerGUID..":"..encodedString.."|h["..spellName.."]|h|r"


			local spellName, _, spellIcon = GetSpellInfo(tradeID)

			local buttonName = "GYPTradeButton-"..tradeID
			local button = CreateFrame("CheckButton", buttonName, frame, "ActionButtonTemplate")

--			button:SetCheckedTexture("")
			button:SetAlpha(0.8)
			button:SetWidth(buttonSize)
			button:SetHeight(buttonSize)

			button:ClearAllPoints()
			button:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", position, 0)

			local buttonIcon = getglobal(button:GetName().."Icon")
			buttonIcon:SetAllPoints(button)
			buttonIcon:SetTexture(spellIcon)

			button.tradeLink = tradeLink
			button.tradeName = spellName
			button.tradeID = tradeID

			button:SetScript("OnClick", OnClick)
			button:SetScript("OnEnter", OnEnter)
			button:SetScript("OnLeave", OnLeave)

			position = position + (button:GetWidth()+5)
			button:Show()

--[[
				if tradeID == self.currentTrade then
					button:SetChecked(1)

					if Skillet.data.skillList[player][tradeID].scanned then
						buttonIcon:SetVertexColor(1,1,1)
					else
						buttonIcon:SetVertexColor(1,0,0)
					end
				else
					button:SetChecked(0)
				end
]]

		end
	end



	local function updateButtons(trade, button, ...)
		if button then
			if button.tradeID == trade then
				button:SetChecked(1)
			else
				button:SetChecked(0)
			end

			updateButtons(trade, ...)
		end
	end


	function TradeButton:Update(trade)
		if tradeButtonParent then
			updateButtons(trade, tradeButtonParent:GetChildren())
		end
	end


	GYP.TradeButton = TradeButton
end
