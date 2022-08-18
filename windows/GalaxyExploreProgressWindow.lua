local BaseWindow = import(".BaseWindow")
local GalaxyExploreProgressWindow = class("GalaxyExploreProgressWindow", BaseWindow)

function GalaxyExploreProgressWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.totalProgreeValue = params.totalProgreeValue
	self.missionProgreeValues = params.missionProgreeValues
	self.mapID = params.mapID
end

function GalaxyExploreProgressWindow:initWindow()
	self:getUIComponent()
	GalaxyExploreProgressWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function GalaxyExploreProgressWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.content_ = self.groupAction:NodeByName("content_").gameObject
	self.contentLayout = self.groupAction:ComponentByName("content_", typeof(UILayout))
	self.imgProgress = self.content_:ComponentByName("imgProgress", typeof(UISprite))
	self.labelTotalProgree = self.content_:ComponentByName("labelProgree", typeof(UILabel))
	self.labelMapName = self.content_:ComponentByName("labelName", typeof(UILabel))
	self.bottomGroup = self.content_:NodeByName("bottomGroup").gameObject
	self.labelTitle = self.bottomGroup:ComponentByName("labelTitle", typeof(UILabel))

	for i = 1, 3 do
		self["group" .. i] = self.bottomGroup:NodeByName("group" .. i).gameObject
		self["labelDesc" .. i] = self["group" .. i]:ComponentByName("labelDesc", typeof(UILabel))
		self["labelLimit" .. i] = self["group" .. i]:ComponentByName("labelLimit", typeof(UILabel))
	end
end

function GalaxyExploreProgressWindow:initUIComponent()
	self.labelTitle_.text = __("GALAXY_TRIP_TEXT35")
	self.labelTitle.text = __("GALAXY_TRIP_TEXT36")
	local textID = xyd.tables.galaxyTripMapTable:getNameTextId(self.mapID)
	self.labelMapName.text = xyd.tables.galaxyTripMapTextTable:getDesc(textID)
	self.imgProgress.fillAmount = self.totalProgreeValue
	self.labelTotalProgree.text = self.totalProgreeValue * 100 .. "%"

	if xyd.Global.lang == "de_de" then
		self.labelTitle.width = 400
	end

	self:updateContent()
end

function GalaxyExploreProgressWindow:updateContent()
	for i = 1, 3 do
		local textID = xyd.tables.galaxyTripMapUnlockTable:getTextId(i)
		local desc = xyd.tables.galaxyTripMapUnlockTextTable:getDesc(textID)
		local params1 = self.missionProgreeValues[i] or 0
		local params2 = xyd.tables.galaxyTripMapUnlockTable:getComplete(i)

		if not params2 or params2 <= 0 then
			local eventType = xyd.tables.galaxyTripMapUnlockTable:getEventTypeId(i)
			params2 = xyd.models.galaxyTrip:getNeedChestMaxNum(self.mapID, eventType)
		end

		self["labelDesc" .. i].text = desc
		self["labelLimit" .. i].text = "(" .. params1 .. "/" .. params2 .. ")"

		if self["labelDesc" .. i].fontSize < self["labelDesc" .. i].height then
			if self["labelDesc" .. i].height > 2 * self["labelDesc" .. i].fontSize then
				self["labelDesc" .. i].overflowMethod = UILabel.Overflow.ShrinkContent
				self["labelDesc" .. i].height = 2 * self["labelDesc" .. i].fontSize
			end

			self["labelLimit" .. i]:Y(-(self["labelDesc" .. i].height - self["labelDesc" .. i].fontSize) / 2)
		end
	end
end

function GalaxyExploreProgressWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.closeWindow(self.name_)
	end
end

function GalaxyExploreProgressWindow:willClose()
	BaseWindow.willClose(self)
end

return GalaxyExploreProgressWindow
