-- The BugSack and BugGrabber team is:
-- Current Developer: Rabbit
-- Past Developers: Rowne, Ramble, industrial, Fritti, kergoth
-- Testers: Ramble, Sariash
--
-- Credits to AceGUI & LuaPad for the scrollbar knowledge.
--[[

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

]]

local L = LibStub("AceLocale-3.0"):GetLocale("BugSack")
local media = LibStub("LibSharedMedia-3.0", true)
local cbh = LibStub("CallbackHandler-1.0")
local icon = LibStub("LibDBIcon-1.0", true)

BugSack = LibStub("AceAddon-3.0"):NewAddon("BugSack", "AceComm-3.0", "AceSerializer-3.0")

local BugSack = BugSack
local BugGrabber = BugGrabber
local BugGrabberDB = BugGrabberDB

local isEventsRegistered = nil

-- Frame state variables
local sackCurrent = nil

local defaults = {
	profile = {
		mute = nil,
		auto = nil,
		showmsg = nil,
		chatframe = nil,
		filterAddonMistakes = true,
		soundMedia = "BugSack: Fatality",
		minimap = {
			hide = false,
		},
	},
}

local show = nil
do
	local window, sourceLabel, countLabel, sessionLabel, textArea = nil, nil, nil, nil, nil
	local nextButton, prevButton = nil, nil
	local function closeWindow()
		window:Hide()
	end

	local function createTipFrame()
		window = CreateFrame("Frame", nil, UIParent)
		window:SetWidth(500)
		window:SetHeight(400)
		window:SetPoint("CENTER")
		window:SetMovable(true)
		window:EnableMouse(true)
		window:SetClampedToScreen(true)
		window:RegisterForDrag("LeftButton")
		window:SetScript("OnDragStart", window.StartMoving)
		window:SetScript("OnDragStop", window.StopMovingOrSizing)

		local titlebg = window:CreateTexture(nil, "BACKGROUND")
		titlebg:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background")
		titlebg:SetPoint("TOPLEFT", 9, -6)
		titlebg:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", -28, -24)

		local dialogbg = window:CreateTexture(nil, "BACKGROUND")
		dialogbg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
		dialogbg:SetPoint("TOPLEFT", 8, -24)
		dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
		dialogbg:SetVertexColor(0, 0, 0, .75)

		local topleft = window:CreateTexture(nil, "BORDER")
		topleft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
		topleft:SetWidth(64)
		topleft:SetHeight(64)
		topleft:SetPoint("TOPLEFT")
		topleft:SetTexCoord(0.501953125, 0.625, 0, 1)

		local topright = window:CreateTexture(nil, "BORDER")
		topright:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
		topright:SetWidth(64)
		topright:SetHeight(64)
		topright:SetPoint("TOPRIGHT")
		topright:SetTexCoord(0.625, 0.75, 0, 1)

		local top = window:CreateTexture(nil, "BORDER")
		top:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
		top:SetHeight(64)
		top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
		top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
		top:SetTexCoord(0.25, 0.369140625, 0, 1)

		local bottomleft = window:CreateTexture(nil, "BORDER")
		bottomleft:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
		bottomleft:SetWidth(64)
		bottomleft:SetHeight(64)
		bottomleft:SetPoint("BOTTOMLEFT")
		bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)

		local bottomright = window:CreateTexture(nil, "BORDER")
		bottomright:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
		bottomright:SetWidth(64)
		bottomright:SetHeight(64)
		bottomright:SetPoint("BOTTOMRIGHT")
		bottomright:SetTexCoord(0.875, 1, 0, 1)

		local bottom = window:CreateTexture(nil, "BORDER")
		bottom:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
		bottom:SetHeight(64)
		bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
		bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
		bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

		local left = window:CreateTexture(nil, "BORDER")
		left:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
		left:SetWidth(64)
		left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
		left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
		left:SetTexCoord(0.001953125, 0.125, 0, 1)

		local right = window:CreateTexture(nil, "BORDER")
		right:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Border")
		right:SetWidth(64)
		right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
		right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
		right:SetTexCoord(0.1171875, 0.2421875, 0, 1)

		local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", 2, 1)
		close:SetScript("OnClick", closeWindow)

		local title = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		title:SetAllPoints(titlebg)
		title:SetJustifyH("CENTER")
		title:SetText("BugSack")

		sessionLabel = window:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		sessionLabel:SetPoint("TOPLEFT", 16, -32)
		sessionLabel:SetWidth(158)
		sessionLabel:SetJustifyH("LEFT")
		sessionLabel:SetText("Session: #####")
		
		countLabel = window:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		countLabel:SetPoint("TOPRIGHT", -12, -32)
		countLabel:SetWidth(158)
		countLabel:SetJustifyH("RIGHT")
		countLabel:SetText("X/X")
		
		sourceLabel = window:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		sourceLabel:SetPoint("TOPLEFT", sessionLabel)
		sourceLabel:SetPoint("TOPRIGHT", countLabel)
		sourceLabel:SetJustifyH("CENTER")
		sourceLabel:SetText("")

		nextButton = CreateFrame("Button", "BugSackNextButton", window, "UIPanelButtonTemplate2")
		nextButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -10, 12)
		nextButton:SetHeight(32)
		nextButton:SetWidth(130)
		nextButton:SetText("Next >")
		nextButton:SetScript("OnClick", function()
			sackCurrent = sackCurrent + 1
			BugSack:UpdateSack()
		end)
		
		prevButton = CreateFrame("Button", "BugSackPrevButton", window, "UIPanelButtonTemplate2")
		prevButton:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 12, 12)
		prevButton:SetHeight(32)
		prevButton:SetWidth(130)
		prevButton:SetText("< Previous")
		prevButton:SetScript("OnClick", function()
			sackCurrent = sackCurrent - 1
			BugSack:UpdateSack()
		end)
		
		sendButton = CreateFrame("Button", "BugSackSendButton", window, "UIPanelButtonTemplate2")
		sendButton:SetPoint("TOPLEFT", prevButton, "TOPRIGHT", 4)
		sendButton:SetPoint("BOTTOMRIGHT", nextButton, "BOTTOMLEFT", -4)
		sendButton:SetText("Send errors")
		sendButton:SetScript("OnClick", function()
			local db = BugGrabber:GetDB()
			local eo = db[sackCurrent]
			local popup = StaticPopup_Show("BugSackSendBugs", eo.session)
			popup.data = eo.session
			window:Hide()
		end)

		local scroll = CreateFrame("ScrollFrame", "BugSackFrameScroll2", window, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", sessionLabel, "BOTTOMLEFT", 0, -12)
		scroll:SetPoint("BOTTOMRIGHT", nextButton, "TOPRIGHT", -24, 8)

		textArea = CreateFrame("EditBox", "BugSackFrameScrollText2", scroll)
		textArea:SetAutoFocus(false)
		textArea:SetMultiLine(true)
		textArea:SetFontObject(GameFontHighlightSmall)
		textArea:SetMaxLetters(99999)
		textArea:EnableMouse(true)
		textArea:SetScript("OnEscapePressed", textArea.ClearFocus)
		-- XXX why the fuck doesn't SetPoint work on the editbox?
		textArea:SetWidth(450)
		textArea:SetHeight(310)
		
		scroll:SetScrollChild(textArea)
	end

	local sessionFormat = "Session %d (%s)" -- Session: 123 (Today)
	local countFormat = "%d/%d" -- 1/10
	local sourceFormat = "Sent by %s (%s)"
	local localFormat = "Local (%s)"

	function show(eo)
		if not window then createTipFrame() end
		if not eo or sackCurrent == 0 then
			sourceLabel:SetText()
			countLabel:SetText()
			sessionLabel:SetText(sessionFormat:format(BugGrabberDB.session, "Today"))
			textArea:SetText(L["You have no errors, yay!"])
			nextButton:Disable()
			prevButton:Disable()
			sendButton:Disable()
		else
			local db = BugGrabber:GetDB()
			if eo.source then sourceLabel:SetText(sourceFormat:format(eo.source, eo.type))
			else sourceLabel:SetText(localFormat:format(eo.type)) end
			if eo.session == BugGrabberDB.session then
				sessionLabel:SetText(sessionFormat:format(eo.session, "Today"))
			else
				sessionLabel:SetText(sessionFormat:format(eo.session, eo.time))
			end
			countLabel:SetText(countFormat:format(sackCurrent, #db))
			textArea:SetText(BugSack:FormatError(eo))
			if sackCurrent >= #db then
				nextButton:Disable()
			else
				nextButton:Enable()
			end
			if sackCurrent <= 1 then
				prevButton:Disable()
			else
				prevButton:Enable()
			end
			sendButton:Enable()
		end
		window:Show()
	end
end

local function print(t)
	DEFAULT_CHAT_FRAME:AddMessage("BugSack: " .. t)
end

function BugSack:OnInitialize()
	local popup = _G.StaticPopupDialogs
	if type(popup) ~= "table" then popup = {} end
	if type(popup["BugSackSendBugs"]) ~= "table" then
		popup["BugSackSendBugs"] = {
			text = "Send your errors from the currently viewed session (%d) in the sack to another player.",
			button1 = "Send",
			button2 = CLOSE,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			hasEditBox = true,
			OnAccept = function(self, data)
				local recipient = self.editBox:GetText()
				BugSack:SendBugsToUser(recipient, data)
			end,
			OnShow = function(self)
				self.button1:Disable()
			end,
			EditBoxOnTextChanged = function(self, data)
				if self:GetText():len() > 1 then
					self:GetParent().button1:Enable()
				else
					self:GetParent().button1:Disable()
				end
			end,
			enterClicksFirstButton = true,
		}
	end

	self.callbacks = cbh:New(self)
	self.db = LibStub("AceDB-3.0"):New("BugSackDB", defaults, true)

	if media then
		media:Register("sound", "BugSack: Fatality", "Interface\\AddOns\\BugSack\\Media\\error.wav")
	end
end

function BugSack:OnEnable()
	-- Make sure we grab any errors fired before bugsack loaded.
	local session = self:GetErrors(BugGrabberDB.session)
	if #session > 0 then self:OnError() end

	self:RegisterComm("BugSack", "OnBugComm")

	-- Set up our error event handler
	BugGrabber.RegisterCallback(self, "BugGrabber_BugGrabbed", "OnError")
	BugGrabber.RegisterCallback(self, "BugGrabber_AddonActionEventsRegistered")

	if not self:GetFilter() then
		BugGrabber.RegisterCallback(self, "BugGrabber_EventGrabbed", "OnError")
		isEventsRegistered = true
		BugGrabber:RegisterAddonActionEvents()
	else
		BugGrabber:UnregisterAddonActionEvents()
	end
end

function BugSack:Taint(addon)
	if type(addon) ~= "string" then return end
	local printer = AceLibrary("AceConsole-2.0")
	local result = {}
	for k,v in pairs(_G) do
		local secure, tainter = issecurevariable(k)
		if not secure and tainter and tainter:find(addon) then
			result[#result + 1] = tostring(k)
		end
	end
	if #result > 0 then
		table.sort(result)
		printer:Print("Globals found for " .. addon .. ":")
		printer:Print(table.concat(result, ", "))
	else
		printer:Print("No taint found for " .. addon .. ".")
	end
end

local justUnregistered = nil
local function clearJustUnregistered() justUnregistered = nil end
function BugSack:BugGrabber_AddonActionEventsRegistered()
	if self:GetFilter() and not justUnregistered then
		BugGrabber:UnregisterAddonActionEvents()
		justUnregistered = true
		self:ScheduleEvent(clearJustUnregistered, 10)
	end
end

do
	local errors = {}
	function BugSack:GetErrors(sessionId)
		-- XXX I've never liked this function, maybe a BugGrabber redesign is in order, where we have one subtable in the DB per session ID.
		if sessionId then
			wipe(errors)
			local db = BugGrabber:GetDB()
			for i, e in next, db do
				if sessionId == e.session then
					errors[#errors + 1] = e
				end
			end
			return errors
		else
			return BugGrabber:GetDB()
		end
	end
end

function BugSack:GetFilter()
	return self.db.profile.filterAddonMistakes
end

function BugSack:ToggleFilter()
	self.db.profile.filterAddonMistakes = not self.db.profile.filterAddonMistakes
	if not self.db.profile.filterAddonMistakes and not isEventsRegistered then
		BugGrabber.RegisterCallback(self, "BugGrabber_EventGrabbed", "OnError")
		isEventsRegistered = true
		BugGrabber:RegisterAddonActionEvents()
	elseif self.db.profile.filterAddonMistakes and isEventsRegistered then
		BugGrabber.UnregisterCallback(self, "BugGrabber_EventGrabbed")
		isEventsRegistered = nil
		BugGrabber:UnregisterAddonActionEvents()
	end
end

function BugSack:OpenSack()
	-- XXX we should show the most recent error (from this session) that has not previously been shown in the sack
	-- XXX so, 5 errors are caught, the user clicks the icon, we start it at the first of those 5 errors.

	-- Show the most recent error
	sackCurrent = #BugGrabber:GetDB()
	self:UpdateSack()
end

function BugSack:UpdateSack()
	local eo = BugGrabber:GetDB()[sackCurrent]
	show(eo)
end

-- XXX I think a better format is needed that more clearly shows the _source_ component of the error.
-- XXX especially if it's NOT "local".
local errorFormat = [[|cff999999[%s-x%d@%s]|r: %s]]

function BugSack:FormatError(err)
	local m = err.message
	if type(m) == "table" then
		m = table.concat(m, "")
	end
	return errorFormat:format(err.time or "unknown", err.counter or -1, err.source or "local", self:ColorError(m or ""))
end

function BugSack:ColorError(err)
	local ret = err
	ret = ret:gsub("|([^chHr])", "||%1") -- pipe char
	ret = ret:gsub("|$", "||") -- pipe char
	ret = ret:gsub("\nLocals:\n", "\n|cFFFFFFFFLocals:|r\n")
	ret = ret:gsub("[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee]\\[Aa][Dd][Dd][Oo][Nn][Ss]\\", "")
	ret = ret:gsub("%{\n +%}", "{}") -- locals: empty table spanning lines
	ret = ret:gsub("([ ]-)([%a_][%a_%d]+) = ", "%1|cffffff80%2|r = ") -- local
	ret = ret:gsub("= (%d+)\n", "= |cffff7fff%1|r\n") -- locals: number
	ret = ret:gsub("<function>", "|cffffea00<function>|r") -- locals: function
	ret = ret:gsub("<table>", "|cffffea00<table>|r") -- locals: table
	ret = ret:gsub("= nil\n", "= |cffff7f7fnil|r\n") -- locals: nil
	ret = ret:gsub("= true\n", "= |cffff9100true|r\n") -- locals: true
	ret = ret:gsub("= false\n", "= |cffff9100false|r\n") -- locals: false
	ret = ret:gsub("= \"([^\n]+)\"\n", "= |cff8888ff\"%1\"|r\n") -- locals: string
	ret = ret:gsub("defined %@(.-):(%d+)", "@ |cffeda55f%1|r:|cff00ff00%2|r:") -- Files/Line Numbers of locals
	ret = ret:gsub("\n(.-):(%d+):", "\n|cffeda55f%1|r:|cff00ff00%2|r:") -- Files/Line Numbers
	ret = ret:gsub("%-%d+%p+.-%\\", "|cffffff00%1|cffeda55f") -- Version numbers
	ret = ret:gsub("%(.-%)", "|cff999999%1|r") -- Parantheses
	ret = ret:gsub("([`'])(.-)([`'])", "|cff8888ff%1%2%3|r") -- Other quotes
	return ret
end

function BugSack:Reset()
	BugGrabber:Reset()
	print(L["All errors were wiped."])

	if BugSackLDB then
		BugSackLDB:Update()
	end
end

-- The Error catching function.
do
	local lastError = nil
	function BugSack:OnError()
		if not lastError or GetTime() > (lastError + 2) then
			if media then
				local sound = media:Fetch("sound", self.db.profile.soundMedia) or "Interface\\AddOns\\BugSack\\Media\\error.wav"
				PlaySoundFile(sound)
			elseif not self.db.profile.mute then
				PlaySoundFile("Interface\\AddOns\\BugSack\\Media\\error.wav")
			end
			if self.db.profile.auto then
				self:OpenSack()
			end
			if self.db.profile.chatframe then
				print(L["An error has been recorded."])
			end
			lastError = GetTime()
		end
		if BugSackLDB then
			BugSackLDB:Update()
		end
	end
end

-- Sends the current session errors to another player using AceComm-3.0
function BugSack:SendBugsToUser(player, session)
	if type(player) ~= "string" or player:trim():len() < 2 then
		error("Player needs to be a valid string.")
	end

	local errors = self:GetErrors(session)
	if not errors or #errors == 0 then return end
	local sz = self:Serialize(errors)
	self:SendCommMessage("BugSack", sz, "WHISPER", player, "BULK")

	print(L["%d errors has been sent to %s. He must have BugSack to be able to read them."]:format(#errors, player))
end

function BugSack:OnBugComm(prefix, message, distribution, sender)
	if prefix ~= "BugSack" then return end

	local good, deSz = self:Deserialize(message)
	if not good then
		print("Failure to deserialize incoming data from " .. sender .. ".")
		return
	end

	-- Store recieved errors in the current session database with a source set to the sender
	for i, err in next, deSz do
		err.source = sender
		err.session = BugGrabberDB.session
		BugGrabber:StoreError(err)
	end

	-- XXX slash command doesn't work like that any more
	print(L["You've received %d errors from %s, you can show them with /bugsack show received."]:format(#deSz, sender))

	wipe(deSz)
	deSz = nil
end

-- vim:set ts=4:
