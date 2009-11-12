local icons, data = {}, {}

local helper = CreateFrame("Frame", nil, WorldMapDetailFrame)
helper:SetAllPoints(WorldMapDetailFrame)
helper:SetFrameLevel(2)
helper.tex = helper:CreateTexture()
helper.tex:SetTexture(0, 0, 0, 0.8)
helper.tex:SetAllPoints(helper)
helper:Hide()

local numShown = 0
local width, height = WorldMapDetailFrame:GetWidth(), WorldMapDetailFrame:GetHeight()
local used, unused = {}, {}

local function removePOI(poi)
	poi:Hide()
	poi:ClearAllPoints()
	if(poi.hud) then poi.hud:Disable() poi.hud = nil end
	used[poi] = nil
	unused[#unused+1] = poi
	numShown = numShown-1
	if(numShown == 0 and helper) then helper:Hide() end
end

local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	if(self.caption) then
		GameTooltip:AddLine(self.caption)
	end
	GameTooltip:AddLine(self.x..", "..self.y, 1,1,1)
	GameTooltip:Show()
end
local function OnLeave() GameTooltip:Hide() end
local function OnClick(self, button)
	if(not IsShiftKeyDown()) then
		for k in pairs(used) do removePOI(k) end
	else
		removePOI(self)
	end
end

local function createPOI()
	local poi = CreateFrame("Button", nil, WorldMapDetailFrame)
	poi:RegisterForClicks("RightButtonUp")
	poi:SetWidth(16)
	poi:SetHeight(16)
	poi:SetScript("OnEnter", OnEnter)
	poi:SetScript("OnLeave", OnLeave)
	poi:SetScript("OnClick", OnClick)
	poi.tex = poi:CreateTexture(nil, "OVERLAY")
	poi.tex:SetAllPoints()
	return poi
end

local function plot(x, y, icon, caption)
	local poi = tremove(unused) or createPOI()
	used[poi] = true
	numShown = numShown+1
	poi.x, poi.y = x, y
	poi.caption = caption
	if(icon) then
		poi.tex:SetTexture(icon)
		poi.tex:SetTexCoord(0, 1, 0, 1)
	else
		poi.tex:SetTexture("Interface\\Minimap\\POIIcons")
		poi.tex:SetTexCoord(13/16, 14/16, 2/16, 3/16)
	end
	if(Coordinator) then
		poi.hud = Coordinator:CreateTarget(caption, x/100, y/100, 0)
	end
	poi:Show()
	poi:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", x/100*width, -y/100*height)
	if(numShown == 1 and helper) then helper:Show() end
end

local function translateShort(msg, ...)
	if(tonumber(msg) and msg:len() % 6 == 0) then
		for i=1, msg:len(), 6 do
			x = msg:sub(i, i+2)
			y = msg:sub(i+3, i+5)
			x, y = tonumber(x)/10, tonumber(y)/10
			if(x and y) then plot(x, y, ...) end
		end
		return true
	end
end

local function doSearch(self, msg)
	msg = msg:trim():lower()
	if(msg == "clear") then
		for k in pairs(used) do removePOI(k) end
	elseif(msg == "me") then
		local x, y = GetPlayerMapPosition("player")
		if(not x or not y) then return print("|cffee8800FindYourWay:|r Where are you?") end
		print("|cffee8800FindYourWay:|r "..("%.2f, %.2f"):format(x*100, y*100))
	elseif(msg) then
		local x, y = msg:match("([0-9%.]+)[/, ]+([0-9%.]+)")
		x, y = tonumber(x), tonumber(y)
		if(x and y) then return plot(x, y) end

		local wowheadURL = msg:match(":?([%d]+)$")
		if(not (wowheadURL and translateShort(wowheadURL))) then
			local zone = GetMapInfo()
			local db = zone and data[zone] or data.Other
			if(db) then
				msg = msg:gsub(" ", "(.-)")
				for name, coords in pairs(db) do
					if(name:lower():match(msg)) then
						translateShort(coords, icons[name], name)
					end
				end
			end
		end
	end
end
FindYourWay = setmetatable({Icons = icons, Data = data}, {__call = doSearch})

SlashCmdList['FINDYOURWAY'] = FindYourWay
SLASH_FINDYOURWAY1 = "/way"
SLASH_FINDYOURWAY2 = "/fyw"
SLASH_FINDYOURWAY3 = "/findyourway"
SLASH_FINDYOURWAY4 = "/find"

local FIND_YOUR_WAY = "Find Your Way!"
WorldMapZoneMinimapDropDown:Hide()
WorldMapZoneMinimapDropDown.Show = function() end

local editbox = CreateFrame("EditBox", nil, WorldMapFrame)
editbox:SetAutoFocus(nil)
editbox:SetText(FIND_YOUR_WAY)
editbox:SetHeight(32)
editbox:SetFontObject("GameFontHighlight")
editbox:SetPoint("LEFT", WorldMapZoneMinimapDropDown, "LEFT")
editbox:SetPoint("RIGHT", WorldMapZoneMinimapDropDown, "RIGHT")

local left = editbox:CreateTexture(nil, "BACKGROUND")
left:SetWidth(8) left:SetHeight(20)
left:SetPoint("LEFT", -5, 0)
left:SetTexture("Interface\\Common\\Common-Input-Border")
left:SetTexCoord(0, 0.0625, 0, 0.625)

local right = editbox:CreateTexture(nil, "BACKGROUND")
right:SetWidth(8)
right:SetHeight(20)
right:SetPoint("RIGHT", 0, 0)
right:SetTexture("Interface\\Common\\Common-Input-Border")
right:SetTexCoord(0.9375, 1, 0, 0.625)

local center = editbox:CreateTexture(nil, "BACKGROUND")
center:SetHeight(20)
center:SetPoint("RIGHT", right, "LEFT", 0, 0)
center:SetPoint("LEFT", left, "RIGHT", 0, 0)
center:SetTexture("Interface\\Common\\Common-Input-Border")
center:SetTexCoord(0.0625, 0.9375, 0, 0.625)

editbox:SetScript("OnEscapePressed", function(self)
	self:SetText(FIND_YOUR_WAY)
	self:ClearFocus()
end)
editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
editbox:SetScript("OnEnterPressed", function(self)
	FindYourWay(self:GetText())
	self:SetText(FIND_YOUR_WAY)
	self:ClearFocus()
end)

if(select(4, GetBuildInfo()) >= 30300) then
	hooksecurefunc("WorldMap_ToggleSizeUp", function() editbox:Show() end)
	hooksecurefunc("WorldMap_ToggleSizeDown", function() editbox:Hide() end)
end