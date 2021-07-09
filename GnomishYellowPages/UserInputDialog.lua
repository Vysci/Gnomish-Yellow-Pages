



local UserInputDialog = {}

do
	local frame
	local dialogBackdrop = {bgFile = "Interface/Tooltips/UI-Tooltip-Background",
							edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
							tile = true, tileSize = 16, edgeSize = 16,
							insets = { left = 4, right = 4, top = 4, bottom = 4 }}

	local buttonBackdrop = {bgFile = "Interface/Buttons/UI-SliderBar-Background",
							edgeFile = "Interface/Buttons/UI-SliderBar-Border",
							tile = true, tileSize = 4, edgeSize = 8,
							insets = { left = 2, right = 2, top = 2, bottom = 2 }}


	function UserInputDialog:Show(message, ...)
		if not frame then
			frame = CreateFrame("Frame")

			frame:SetBackdrop(dialogBackdrop)
			frame:SetBackdropColor(0,0,0,1)

			frame:SetFrameStrata("DIALOG")

			frame.buttons = {}

			frame:EnableMouse(true)
		end

		frame:SetWidth(320)
		frame:SetHeight(100)

		frame:SetPoint("CENTER",0,200)

		if not frame.messageText then
			frame.messageText = frame:CreateFontString(nil,nil,"GameFontNormal")

			frame.messageText:SetPoint("TOPLEFT", 5,-5)
			frame.messageText:SetPoint("BOTTOMRIGHT", -5, 50)
		end

		frame.messageText:SetText(message)


		local args = {...}
		local bwidth = 300 / math.ceil(#args/2)
		local buttonPosition = -(150 - bwidth/2)

		for i=1,#args,2 do
			if not frame.buttons[i] then
				local b = CreateFrame("Button",nil,frame)
				b:SetPoint("CENTER",buttonPosition, -35)
				b:SetBackdrop(buttonBackdrop)
				b:SetBackdropColor(0,0,0,1)
				b:SetBackdropBorderColor(1,1,1,1)

				b:SetHeight(22)
				b:SetWidth(bwidth)

				b:SetNormalFontObject("GameFontNormalSmall")
				b:SetHighlightFontObject("GameFontHighlightSmall")

				b:SetScript("OnClick", function(button)
					frame:Hide()
					if b.callBack then
						b.callBack()
					end
				end)

				frame.buttons[i] = b
			end

			frame.buttons[i]:SetText(args[i])
			frame.buttons[i].callBack = args[i+1]
			buttonPosition = buttonPosition + bwidth
		end

		frame:Show()

		frame:SetFrameStrata("FULLSCREEN_DIALOG")
	end

	GYP.UserInputDialog = UserInputDialog
end

