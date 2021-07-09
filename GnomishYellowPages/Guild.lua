



local faction = UnitFactionGroup("player")
local realmName = GetRealmName()

local serverKey = realmName.."-"..faction

GYP.guild = {}

local player = UnitName("player")

local SECONDS_PER_CLIENT = 5

local commVersion = 0.1

GYPDEBUG = true

local function debugSpam(...)
	if GYPDEBUG then
		print(...)
	end
end


do
	local masterClient = nil
	local uploadQueue = {}
	local broadcastQueue = {}
	local clientTimeOffset = {}
	local clientContact = {}

	local clientList = {}


	local maxClients = 0

	local status


	local guildSyncFrame


	local processQueues = false




	local function UnregisterEvent(frame, event, func)
		if not frame.events then
			frame.events = {}
		end

		if not frame.events[event] then
			frame.events[event] = {}
		end

		for i=1,#frame.events[event] do
			if frame.events[event][i] == func then
				frame.events[event][i] = nil
			end
		end
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




	local function AddToBroadcastQueue(player, trade, ad, position)
		local entry = {player=player, trade=trade, ad=ad }

		table.insert(broadcastQueue, entry)
	end

	local function RefreshBroadcastQueue()
		broadcastQueue = {}

		for trade, adList in pairs(YPData[serverKey]) do
			for player, ad in pairs(adList) do
				AddToBroadcastQueue(trade,player, ad)
			end
		end
	end

	local function BroadcastNextRecord()
		if processQueues then
			local q = table.remove(uploadQueue,1)

			if q then
				local record = (time() - q.ad.time)..","..q.player..","..q.ad.link..","..q.ad.message

				SendAddonMessage("GYP:NewRecord", record, "GUILD")

				return
			end
		end

		SendAddonMessage("GYP:Master", time(), "GUILD")
	end



	local function AddToUploadQueue(player, trade, ad, position)
		local entry = {player=player, trade=trade, ad=ad }

		table.insert(uploadQueue, entry)
	end


	local function UploadNextRecord()
		if processQueues then
			if not masterClient then
				local q = table.remove(uploadQueue,1)

				if q then
					local record = (time() - q.ad.time)..","..q.player..","..q.ad.link..","..q.ad.message

					SendAddonMessage("GYP:NewRecord", record, "WHISPER", masterClient)
				end
			end
		end

		SendAddonMessage("GYP:Client", time(), "GUILD")
	end


	local function RefreshUploadQueue()
		uploadQueue = {}

		for trade, adList in pairs(YPData[serverKey]) do
			for player, ad in pairs(adList) do
				AddToUploadQueue(trade,player, ad)
			end
		end
	end



	local function RestartProcessing()
		processQueues = true
	end


	local function PauseProcessing()
		processQueues = false
	end


	local function StopProcessing()
		processQueues = false

		uploadQueue = {}
		broadcastQueue = {}
	end

	local function BeginSlaveProcessing()
debugSpam("slave started")
		status:SetText("slave client ("..tostring(masterClient)..")")

		RefreshUploadQueue()
		RestartProcessing()
	end

	local function BeginMasterProcessing()
debugSpam("master started")
		masterClient = player

		GYP.timer.CreateTimer("HeartBeat", 2, HeartBeat, 2)

		status:SetText("master client")

		RefreshBroadcastQueue()
		RestartProcessing()
	end



	local function HeartBeat()
--debugSpam("heart beat")

		local now = time()
		local numClients = #clientList
-- debugSpam("num clients = "..numClients)

		for i=1,numClients do
			local client = clientList[i]
debugSpam("client: "..client.." last contact "..clientContact[client]-now.." seconds ago")

			if client and client ~= player then
				local delay = numClients * SECONDS_PER_CLIENT * 3

				if clientContact[client]-now > delay then
					clientList[i] = clientList[numClients]
					clientList[numClients] = nil

					clientContact[client] = nil
					clientTimeOFfset[client] = nil

					if client == masterClient then
						masterClient = nil

						status:SetText("master offline")
						StopProcessing()
					end
				end
			end
		end

		if masterClient then
			if masterClient == player then
				if #clientList == 0 then
					status:SetText("solo client")
					masterClient = nil
				else
					status:SetText("master client")

					BroadcastNextRecord()
				end
			else
				UploadNextRecord()
			end
		else
			table.sort(clientList)

			if player == clientList[1] then
				SendAddonMessage("GYP:Master", time(), "GUILD")
			end
		end
	end



	local function AddonMessageParse(prefix, message, channel, sender)
if prefix:match("GYP") and GYPDEBUG then
	DEFAULT_CHAT_FRAME:AddMessage(tostring(prefix)..","..tostring(message)..","..tostring(channel)..","..tostring(sender))
end

		if sender ~= player then
			clientContact[sender] = time()

			if prefix == "GYP:NewRecord"  then
				if clientTimeOffset[sender] then
					local age, player, link, notes = strsplit(",",message)

					local color,tradeID,level,playerID,tradeName = string.match(link,"(|c%x+)|Htrade:(%d+):(%d+):%d+:([0-9a-fA-F]+):[A-Za-z0-9+/]+|h%[([^]]+)%]|h|r")

					local basicTrade = GetSpellInfo(GYP.basicTradeID[tradeID])

					age = tonumber(age) + clientTimeOffset[client]


					local ad = GYP.ads.SaveAdvertisement(player,basicTrade,level,link,message,age)

					if ad then
						if masterClient == player then
							AddToBroadcastQueue(player, basicTrade, ad)
						end
					end
				end
			end

			if prefix == "GYP:Master"  then									-- new master
				if not masterClient or sender < masterClient then
					local localTime = tonumber(message)

					masterClient = sender

					if not clientTimeOffset[sender] then
						clientList[#clientList+1] = sender

						GYP.timer.CreateTimer("HeartBeat", math.random(#clientList*SECONDS_PER_CLIENT), HeartBeat, #clientList*SECONDS_PER_CLIENT)
					end

					clientTimeOffset[sender] = time() - localTime

					GYP.timer.CreateTimer("BeginSlave", 5, BeginSlaveProcessing)
				else
					if player == masterClient then
						GYP.timer.CreateTimer("ReclaimMaster", 2, function() SendAddonMessage("GYP:Master", time(), "GUILD") end)
					end
				end
			end


			if prefix == "GYP:Client" then										-- client heartbeat
				local localTime = tonumber(message)

				if not clientTimeOffset[sender] then
					clientList[#clientList+1] = sender

					GYP.timer.CreateTimer("HeartBeat", math.random(#clientList*SECONDS_PER_CLIENT), HeartBeat, #clientList*SECONDS_PER_CLIENT)
				end

				clientTimeOffset[sender] = time() - localTime
			end


			if prefix == "GYP:Comm" then
				local comm, gypVersion = strsplit(":",message)

				comm = tonumber(comm)

				if comm > commVersion then
					status:SetText("gyp needs update")

					UnregisterEvent(master, "CHAT_MSG_ADDON", AddonMessageParse)

					DEFAULT_CHAT_FRAME:AddMessage("GYP guild sync error: "..sender.." reports updated communication protocol.  please update GYP.")
				elseif comm < commVersion then
					if player == masterClient then
						SendAddonMessage("GYP:Comm", commVersion..":"..GYP.version, "WHISPER", sender)
					end
				else
					if not masterClient or player == masterClient then
						SendAddonMessage("GYP:Master", time(), "WHISPER", sender)

						if not masterClient then
							BeginMasterProcessing()
						end
					end
				end
			end
		end
	end



	function GYP.guild:Initialize(frame, master)
		masterClient = nil												-- initially, this client is solo


		guildSyncFrame = CreateFrame("Frame")
		guildSyncFrame:SetParent(frame)
		guildSyncFrame:SetFrameLevel(frame:GetFrameLevel()+5)



		guildSyncFrame:SetPoint("TOPRIGHT",-40,-15)
		guildSyncFrame:SetWidth(100)
		guildSyncFrame:SetHeight(20)


		status = guildSyncFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

		status:SetJustifyH("RIGHT")
		status:SetPoint("RIGHT",0,0)
		status:SetTextColor(1,1,1)
		status:SetText("solo client")
		status:SetHeight(20)
		status:SetWidth(100)

		guildSyncFrame.statusText = status

		guildSyncFrame:Show()
		status:Show()


--		RegisterEvent(master, "CHAT_MSG_SYSTEM", SystemMessageParse)
		RegisterEvent(master, "CHAT_MSG_ADDON", AddonMessageParse)

		GYP.timer.CreateTimer("HeartBeat", 10, HeartBeat, 15)

--		SendAddonMessage("GYP:Client", time(), "GUILD")						-- broadcast to see if a master responds

		SendAddonMessage("GYP:Comm", commVersion..":"..GYP.version, "GUILD")
	end


	function GYP:BroadcastMaster()
		SendAddonMessage("GYP:Master", time(), "GUILD")
	end

	function GYP:RunAsMaster()
		BeginMasterProcessing()
	end

	function GYP:RunAsSlave(master)
		masterClient = master
		BeginSlaveProcessing()
	end

end

