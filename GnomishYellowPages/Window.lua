




local Window = {}

--[[
 the SetBackdrop system has some texture coordinate problems, so i wrote this to emulate

 i'm creating an invisible frame for sizing simplicity, but the textures are actually parented to the real frame (so they are place in the correct drawing layer)
 even tho they are referenced from this invisible frame (as indices into the frame table)
]]

do
	local textureQuads = {
		LEFT = 0,
		RIGHT = 1,
		TOP = 2,
		BOTTOM = 3,
		TOPLEFT = 4,
		TOPRIGHT = 5,
		BOTTOMLEFT = 6,
		BOTTOMRIGHT = 7,
	}

	local function ResizeBetterBackdrop(frame)
		if not frame then
			return
		end

		local w,h = frame:GetWidth()-frame.edgeSize*2, frame:GetHeight()-frame.edgeSize*2

		for k,i in pairs({"LEFT", "RIGHT"}) do
			local t = frame["texture"..i]

			local y = h/frame.edgeSize

			local q = textureQuads[i]

			t:SetTexCoord(q*.125, q*.125+.125, 0, y)
		end

		for k,i in pairs({"TOP", "BOTTOM"}) do
			local t = frame["texture"..i]

			local y = w/frame.edgeSize

			local q = textureQuads[i]

			local x1 = q*.125
			local x2 = q*.125+.125

			t:SetTexCoord(x1,0, x2,0, x1,y, x2, y)
		end

		frame.textureBG:SetTexCoord(0,w/frame.tileSize, 0,h/frame.tileSize)
	end



	function Window:SetBetterBackdrop(frame, bd)
		if not frame.backDrop then
			frame.backDrop = CreateFrame("Frame", nil, frame)


			for k,i in pairs({"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "RIGHT", "TOP", "BOTTOM"}) do
				frame.backDrop["texture"..i] =  frame:CreateTexture(nil, "BACKGROUND")
			end

			frame.backDrop.textureBG = frame:CreateTexture(nil,"BACKGROUND")
		end

		frame.backDrop.edgeSize = bd.edgeSize
		frame.backDrop.tileSize = bd.tileSize

		frame.backDrop:SetPoint("TOPLEFT",frame,"TOPLEFT",-bd.insets.left/2, bd.insets.top/2)
		frame.backDrop:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",bd.insets.right/2, -bd.insets.bottom/2)

		local w,h = frame:GetWidth()-bd.edgeSize*2, frame:GetHeight()-bd.edgeSize*2

		frame.backDrop.textureBG:SetTexture(bd.bgFile, bd.tile)

		for k,i in pairs({"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}) do
			local t = frame.backDrop["texture"..i]

			t:SetTexture(bd.edgeFile)
			t:SetPoint(i, frame.backDrop)
			t:SetWidth(bd.edgeSize)
			t:SetHeight(bd.edgeSize)

			local q = textureQuads[i]

			t:SetTexCoord(q*.125,q*.125+.125, 0,1)

		end

		for k,i in pairs({"LEFT", "RIGHT"}) do
			local t = frame.backDrop["texture"..i]

			t:SetTexture(bd.edgeFile, true)
			t:SetPoint(i, frame.backDrop)
			t:SetPoint("BOTTOM", frame.backDrop, "BOTTOM", 0, bd.edgeSize)
			t:SetPoint("TOP", frame.backDrop, "TOP", 0, -bd.edgeSize)
			t:SetWidth(bd.edgeSize)

			local y = h/bd.edgeSize

			local q = textureQuads[i]

			t:SetTexCoord(q*.125, q*.125+.125, 0, y)
		end

		for k,i in pairs({"TOP", "BOTTOM"}) do
			local t = frame.backDrop["texture"..i]

			t:SetTexture(bd.edgeFile, true)
			t:SetPoint(i, frame.backDrop)
			t:SetPoint("LEFT", frame.backDrop, "LEFT", bd.edgeSize, 0)
			t:SetPoint("RIGHT", frame.backDrop, "RIGHT", -bd.edgeSize, 0)
			t:SetHeight(bd.edgeSize)

			local y = w/bd.edgeSize

			local q = textureQuads[i]

			local x1 = q*.125
			local x2 = q*.125+.125

			t:SetTexCoord(x1,0, x2,0, x1,y, x2, y)
		end

		frame.backDrop.textureBG:SetPoint("TOPLEFT", frame.backDrop, "TOPLEFT", bd.edgeSize, -bd.edgeSize)
		frame.backDrop.textureBG:SetPoint("BOTTOMRIGHT", frame.backDrop, "BOTTOMRIGHT", -bd.edgeSize, bd.edgeSize)


		frame.backDrop.textureBG:SetTexCoord(0,w/bd.tileSize, 0,h/bd.tileSize)

		frame.backDrop:SetScript("OnSizeChanged", ResizeBetterBackdrop)
	end



	local function GetSizingPoint(frame)
		local x,y = GetCursorPosition()
		local s = frame:GetEffectiveScale()

		local left,bottom,width,height = frame:GetRect()

		x = x/s - left
		y = y/s - bottom

		if x < 10 then
			if y < 10 then return "BOTTOMLEFT" end

			if y > height-10 then return "TOPLEFT" end

			return "LEFT"
		end

		if x > width-10 then
			if y < 10 then return "BOTTOMRIGHT" end

			if y > height-10 then return "TOPRIGHT" end

			return "RIGHT"
		end

		if y < 10 then return "BOTTOM" end

		if y > height-10 then return "TOP" end

		return "UNKNOWN"
	end



	function Window:CreateResizableWindow(frameName,windowTitle, width, height, resizeFunction)
		local frame = CreateFrame("Frame",frameName,UIParent)
		frame:Hide()

		frame:SetFrameStrata("DIALOG")


		frame:SetResizable(true)
		frame:SetMovable(true)
--		frame:SetUserPlaced(true)
		frame:EnableMouse(true)

		if not GYPConfig.window then
			GYPConfig.window = {}
		end

		if not GYPConfig.window[frameName] then
			GYPConfig.window[frameName] = { x = 0, y = 0, width = width, height = height}
		end

		local x, y = GYPConfig.window[frameName].x, GYPConfig.window[frameName].y
		local width, height = GYPConfig.window[frameName].width, GYPConfig.window[frameName].height


		frame:SetPoint("CENTER",x,y)
		frame:SetWidth(width)
		frame:SetHeight(height)


		self:SetBetterBackdrop(frame,{bgFile = "Interface\\AddOns\\GnomishYellowPages\\Art\\newFrameBackground.tga",
												edgeFile = "Interface\\AddOns\\GnomishYellowPages\\Art\\newFrameBorder.tga",
												tile = true, tileSize = 48, edgeSize = 48,
												insets = { left = 8, right = 8, top = 8, bottom = 8 }})


		frame:SetScript("OnSizeChanged", function() resizeFunction() end)

		frame.SavePosition = function(f)
			local frameName = f:GetName()

			if frameName then
				GYPConfig.window[frameName].width = f:GetWidth()
				GYPConfig.window[frameName].height = f:GetHeight()

				local cx, cy = f:GetCenter()
				local ux, uy = UIParent:GetCenter()

				GYPConfig.window[frameName].x = cx - ux
				GYPConfig.window[frameName].y = cy - uy
			end
		end


		frame:SetScript("OnMouseDown", function() frame:StartSizing(GetSizingPoint(frame)) end)
		frame:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() frame:SavePosition() end)
		frame:SetScript("OnHide", function() frame:StopMovingOrSizing() frame:SavePosition() end)


		local windowMenu = {
			{ text = "Raise Frame", func = function() frame:SetFrameStrata("DIALOG")  frame.title:SetFrameStrata("DIALOG") end },
			{ text = "Lower Frame", func = function() frame:SetFrameStrata("LOW") frame.title:SetFrameStrata("LOW") end },
		}

		windowMenuFrame = CreateFrame("Frame", "GYPWindowMenuFrame", getglobal("UIParent"), "UIDropDownMenuTemplate")


		local mover = CreateFrame("Frame",frameName.."Mover",frame)
		mover:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
		mover:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)

		mover:EnableMouse(true)

		mover:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				frame:StartMoving()
			else
				local x, y = GetCursorPosition()
				local uiScale = UIParent:GetEffectiveScale()

				EasyMenu(windowMenu, windowMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
			end
		end)
		mover:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() frame:SavePosition() end)
		mover:SetScript("OnHide", function() frame:StopMovingOrSizing() frame:SavePosition() end)


		mover:SetHitRectInsets(10,10,10,10)

		frame.mover = mover

		local title = CreateFrame("Button",nil,UIParent)

		title:SetHeight(30)

		title.textureLeft = title:CreateTexture()
		title.textureLeft:SetTexture("Interface\\AddOns\\GnomishYellowPages\\Art\\headerTexture.tga")
		title.textureLeft:SetPoint("LEFT",0,0)
		title.textureLeft:SetWidth(60)
		title.textureLeft:SetHeight(30)
		title.textureLeft:SetTexCoord(0, 1, 0, .5)

		title.textureRight = title:CreateTexture()
		title.textureRight:SetTexture("Interface\\AddOns\\GnomishYellowPages\\Art\\headerTexture.tga")
		title.textureRight:SetPoint("RIGHT",0,0)
		title.textureRight:SetWidth(60)
		title.textureRight:SetHeight(30)
		title.textureRight:SetTexCoord(0, 1.0, 0.5, 1.0)


		title.textureCenter = title:CreateTexture()
		title.textureCenter:SetTexture("Interface\\AddOns\\GnomishYellowPages\\Art\\headerTextureCenter.tga", true)
		title.textureCenter:SetHeight(30)
--		title.textureCenter:SetWidth(30)
		title.textureCenter:SetPoint("LEFT",60,0)
		title.textureCenter:SetPoint("RIGHT",-60,0)
		title.textureCenter:SetTexCoord(0.0, 1.0, 0.0, 1.0)


		title:SetPoint("BOTTOM",frame,"TOP",0,0)

		title:EnableMouse(true)

		title:Hide()

		title:SetFrameStrata("DIALOG")

		title:SetScript("OnDoubleClick", function(self, button)
			if button == "LeftButton" then
				PlaySound("igMainMenuOptionCheckBoxOn")
				if frame:IsVisible() then
					frame:Hide()
				else
					frame:Show()
				end
			end
		end)

		title:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				frame:StartMoving()
			else
				local x, y = GetCursorPosition()
				local uiScale = UIParent:GetEffectiveScale()

				EasyMenu(windowMenu, windowMenuFrame, getglobal("UIParent"), x/uiScale,y/uiScale, "MENU", 5)
			end
		end)
		title:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() frame:SavePosition() end)
		title:SetScript("OnHide", function() frame:StopMovingOrSizing() frame:SavePosition() end)



		local text = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetJustifyH("CENTER")
		text:SetPoint("CENTER",0,0)
		text:SetTextColor(1,1,.4)
		text:SetText(windowTitle)

		title:SetWidth(text:GetStringWidth()+120)


		local w = title.textureCenter:GetWidth()
		local h = title.textureCenter:GetHeight()
		title.textureCenter:SetTexCoord(0.0, (w/h), 0.0, 1.0)



		frame.title = title



--[[
		local x = frame:CreateTexture(nil,"ARTWORK")

		x:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		x:SetTexture("Interface/DialogFrame/UI-DialogBox-Corner")
		x:SetWidth(32)
		x:SetHeight(32)
]]

		local closeButton = CreateFrame("Button",nil,frame,"UIPanelCloseButton")
		closeButton:SetPoint("TOPRIGHT",6,6)
		closeButton:SetScript("OnClick", function() frame:Hide() frame.title:Hide() end)
		closeButton:SetFrameLevel(closeButton:GetFrameLevel()+10)
		closeButton:SetHitRectInsets(8,8,8,8)

		return frame
	end

	GYP.Window = Window
end
