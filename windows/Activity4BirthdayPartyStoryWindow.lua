local BaseWindow = import(".BaseWindow")
local Activity4BirthdayPartyStoryWindow = class("Activity4BirthdayPartyStoryWindow", BaseWindow)
local Activity4BirthdayPartyStoryItem = class("Activity4BirthdayPartyStoryItem", import("app.components.CopyComponent"))

function Activity4BirthdayPartyStoryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY)
end

function Activity4BirthdayPartyStoryWindow:getPrefabPath()
	return "Prefabs/Windows/activity_secret_treasure_hunt_event_window"
end

function Activity4BirthdayPartyStoryWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:Register()
	self:initData()
	self:initUIComponent()
end

function Activity4BirthdayPartyStoryWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelTips = self.groupAction:ComponentByName("labelTips", typeof(UILabel))
	self.content = self.groupAction:NodeByName("content")

	for i = 1, 7 do
		self["storyItem" .. i] = self.content:NodeByName("storyItem" .. i).gameObject
	end
end

function Activity4BirthdayPartyStoryWindow:initUIComponent()
	self.labelTips.text = __("POTENTIALITY_CLICK_CLOSE")
end

function Activity4BirthdayPartyStoryWindow:initData()
	local ids = xyd.tables.activity4birthdayStoryTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(i)

		if self.items == nil then
			self.items = {}
		end

		if self.items[i] == nil then
			local item = Activity4BirthdayPartyStoryItem.new(self["storyItem" .. i])

			item:setInfo({
				id = id
			})

			self.items[i] = item
		else
			self.items[i]:setInfo({
				id = id
			})
		end
	end
end

function Activity4BirthdayPartyStoryWindow:Register()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refresResItems))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY then
			self:initData()
		end
	end)
end

function Activity4BirthdayPartyStoryItem:ctor(go)
	self.go = go
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY)

	self:getUIComponent()
end

function Activity4BirthdayPartyStoryItem:getUIComponent()
	self.lockImg = self.go:ComponentByName("lockImg", typeof(UISprite))
	self.labeDesc = self.go:ComponentByName("labeDesc", typeof(UILabel))
	self.redPoint = self.go:ComponentByName("redPoint", typeof(UISprite))
	self.bg1 = self.labeDesc:ComponentByName("bg1", typeof(UISprite))
	self.bg2 = self.labeDesc:ComponentByName("bg2", typeof(UISprite))
	self.labeIndex = self.bg2:ComponentByName("labeIndex", typeof(UILabel))

	UIEventListener.Get(self.go.gameObject).onClick = function ()
		if self.state == 1 then
			xyd.alertTips(__("ACTIVITY_4BIRTHDAY_PLOT_TIPS01", xyd.getRoughDisplayTime(-xyd.getServerTime() + self.activityData:startTime() + (self.id - 1) * 24 * 60 * 60)))

			return
		elseif self.state == 2 then
			self.activityData:readPartyStory(self.id)

			local storyId = xyd.tables.activity4birthdayStoryTable:getBeginPlotId(self.id)

			xyd.WindowManager.get():openWindow("story_window", {
				is_back = true,
				story_type = xyd.StoryType.ACTIVITY_4BIRTHDAY_PARTY,
				story_id = storyId
			})
		elseif self.state == 3 then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				hideGroupChoose = true,
				type = "activity_4birthday_party_story",
				callback = function ()
					local storyId = xyd.tables.activity4birthdayStoryTable:getBeginPlotId(self.id)

					xyd.WindowManager.get():openWindow("story_window", {
						is_back = true,
						story_type = xyd.StoryType.ACTIVITY_4BIRTHDAY_PARTY,
						story_id = storyId
					})
				end,
				closeCallback = function ()
				end,
				text = __("ACTIVITY_4BIRTHDAY_PLOT_TEXT01"),
				btnYesText_ = __("YES"),
				btnNoText_ = __("NO")
			})
		end
	end
end

function Activity4BirthdayPartyStoryItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.id = params.id
	local storyId = xyd.tables.activity4birthdayStoryTable:getBeginPlotId(self.id)

	if not self.isInitLabel then
		self.labeDesc.width = xyd.tables.miscTable:split2num("activity_4birthday_plot_" .. xyd.Global.lang, "value", "|")[self.id]
		self.labeDesc.text = xyd.tables.activity4birthdayPlotTextTable:getTitle(storyId)
		self.isInitLabel = true
	end

	self.state = self.activityData:getStoryState(self.id)

	self.lockImg:SetActive(self.state == 1)
	self.redPoint:SetActive(self.state == 2)

	local helpArr1 = {
		"activity_4birthday_party_bg_jqtc_dhk_zh",
		"activity_4birthday_party_bg_jqtc_dhk_zc",
		"activity_4birthday_party_bg_jqtc_dhk_zc"
	}

	xyd.setUISpriteAsync(self.bg1, nil, helpArr1[self.state])

	local helpArr2 = {
		"activity_4birthday_party_bg_jqtc_dhksz_zh",
		"activity_4birthday_party_bg_jqtc_dhksz_zc",
		"activity_4birthday_party_bg_jqtc_dhksz_zc"
	}

	xyd.setUISpriteAsync(self.bg2, nil, helpArr2[self.state])

	self.labeIndex.text = self.id

	if self.state == 1 then
		self.labeIndex.color = Color.New2(2122088191)
		self.labeIndex.effectStyle = UILabel.Effect.None
		self.labeDesc.effectColor = Color.New2(2593496831.0)
	else
		self.labeIndex.color = Color.New2(4294967295.0)
		self.labeIndex.effectStyle = UILabel.Effect.Outline8
		self.labeIndex.effectColor = Color.New2(2423309823.0)
		self.labeDesc.effectColor = Color.New2(4294967295.0)
	end

	if self.labeDesc.height <= self.labeDesc.fontSize + self.labeDesc.spacingY then
		self.labeDesc.overflowMethod = UILabel.Overflow.ResizeFreely
	end
end

return Activity4BirthdayPartyStoryWindow
