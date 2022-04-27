local cjson = require("cjson")
local ActivityContent = import(".ActivityContent")
local ActivityCandyCollect = class("ActivityCandyCollect", ActivityContent)
local ActivityCandyCollectItem = class("ActivityCandyCollectItem", import("app.components.BaseComponent"))
local CollectTable = xyd.tables.activityCandyCollectTable
local Backpack = xyd.models.backpack

function ActivityCandyCollect:ctor(parentGO, params)
	ActivityCandyCollect.super.ctor(self, parentGO, params)
	self:layout()
	self:registerEvent()
	self.storyBtn:SetActive(false)
end

function ActivityCandyCollect:getPrefabPath()
	return "Prefabs/Windows/activity/activity_candy_collect"
end

function ActivityCandyCollect:initUI()
	self:getUIComponent()
	ActivityCandyCollect.super.initUI(self)
end

function ActivityCandyCollect:getUIComponent()
	local go = self.go
	self.headGroup = go:NodeByName("headGroup").gameObject

	for i = 1, 5 do
		self["head" .. i] = self.headGroup:NodeByName("head" .. i).gameObject
		self["headLabel" .. i] = self["head" .. i]:ComponentByName("label", typeof(UILabel))
		self["red" .. i] = self["head" .. i]:ComponentByName("red", typeof(UISprite))
		self["tick" .. i] = self["head" .. i]:ComponentByName("tick", typeof(UISprite))
	end

	self.topGroup = go:NodeByName("topGroup").gameObject
	self.titleImg = self.topGroup:ComponentByName("titleImg", typeof(UISprite))
	self.helpBtn = self.topGroup:NodeByName("helpBtn").gameObject
	self.storyBtn = self.topGroup:NodeByName("storyBtn").gameObject
	self.iconGroup = self.topGroup:NodeByName("iconGroup").gameObject
	self.iconLabel = self.iconGroup:ComponentByName("label", typeof(UILabel))
	self.iconBtn = self.iconGroup:NodeByName("btn").gameObject
end

function ActivityCandyCollect:layout()
	self.iconLabel.text = Backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2)

	for i = 1, 5 do
		self["headLabel" .. i].text = xyd.tables.activityCandyCollectTextTable:getTitle(i)
	end

	self:updateRedPoint()
end

function ActivityCandyCollect:resizeToParent()
	ActivityCandyCollect.super.resizeToParent(self)

	local height = self.go:GetComponent(typeof(UIWidget)).height

	self.headGroup:SetLocalPosition(0, -height / 2, 0)
end

function ActivityCandyCollect:registerEvent()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "CANDY_COLLECT_HELP"
		})
	end

	UIEventListener.Get(self.iconBtn).onClick = function ()
		local params = {
			showGetWays = true,
			itemID = xyd.ItemID.LOVE_LETTER2,
			itemNum = Backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, function ()
		self.iconLabel.text = tostring(Backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2))
	end))

	for i = 1, 5 do
		UIEventListener.Get(self["head" .. i]).onClick = function ()
			xyd.WindowManager.get():openWindow("activity_candy_collect_window", {
				id = i
			})
		end
	end

	UIEventListener.Get(self.storyBtn).onClick = handler(self, function ()
		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_SPROUTS_STORY_TIP"), function (yes_no)
			if yes_no then
				self:showStory()
			end
		end)
	end)

	self.eventProxyInner_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, self.onDetailWindowClose, self)
end

function ActivityCandyCollect:onDetailWindowClose(event)
	local data = event.params

	xyd.models.activity:reqActivityByID(xyd.ActivityID.CANDY_COLLECT)

	self.iconLabel.text = Backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2)
end

function ActivityCandyCollect:onAward(event)
	local data = event.data

	if data.activity_id == xyd.ActivityID.CANDY_COLLECT then
		local detail = require("cjson").decode(event.data.detail)

		self:layout()
	end
end

function ActivityCandyCollect:showStory(callback)
	xyd.WindowManager.get():openWindow("story_window", {
		is_back = true,
		story_type = xyd.StoryType.ACTIVITY,
		story_id = xyd.tables.activityTable:getPlotId(xyd.ActivityID.CANDY_COLLECT),
		callback = callback
	})
end

function ActivityCandyCollect:updateRedPoint()
	local awarded = self.activityData.detail.awarded

	if awarded == nil then
		return
	end

	local selfNum = Backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2)
	local listLength = {}

	for i = 1, #awarded do
		local splitStr = xyd.split(awarded[i], "#")

		if #splitStr == 1 then
			if tonumber(splitStr[1]) == 0 then
				listLength[i] = 0
			else
				listLength[i] = #splitStr
			end
		else
			listLength[i] = #splitStr
		end
	end

	local max = listLength[1]

	for i = 2, #listLength do
		if max < listLength[i] then
			max = listLength[i]
		end
	end

	for i = 1, 5 do
		local award = awarded[i]
		local awardSplit = xyd.split(award, "#")
		local flag = false

		self["red" .. i]:SetActive(flag)
		self["tick" .. i]:SetActive(flag)

		for j = 1, 4 do
			local skip = false

			for k = 1, #awardSplit do
				if tonumber(awardSplit[k]) == j then
					skip = true

					break
				end
			end

			if not skip then
				local cost = CollectTable:getCost(i, j)

				if cost[2] <= selfNum then
					flag = true

					break
				end
			end
		end

		if not flag then
			for k = 1, #awardSplit do
				if tonumber(awardSplit[k]) > 0 then
					self["tick" .. i]:SetActive(true)
				end
			end
		else
			if #awardSplit == 1 then
				if tonumber(awardSplit[1]) == 0 then
					flag = true
				elseif max <= #awardSplit then
					flag = false
				end
			elseif max <= #awardSplit then
				flag = false
			end

			local isAllEquil = true

			for i = 1, #listLength - 1 do
				if listLength[i] ~= listLength[i + 1] then
					isAllEquil = false
				end
			end

			if isAllEquil then
				flag = true
			end

			self["red" .. i]:SetActive(flag)
			self["tick" .. i]:SetActive(not flag)
		end
	end
end

function ActivityCandyCollectItem:ctor(parentGO)
	ActivityCandyCollectItem.super.ctor(self, parentGO)
end

function ActivityCandyCollectItem:getPrefabPath()
	return "Prefabs/Components/make_cake_item"
end

function ActivityCandyCollectItem:initUI()
	ActivityCandyCollectItem.super.initUI(self)
	self:getComponent()
end

function ActivityCandyCollectItem:getComponent()
	local go = self.go
	self.imgIcon_ = go:ComponentByName("imgIcon", typeof(UISprite))
	self.label = go:ComponentByName("label", typeof(UILabel))
	self.mask = self.label:ComponentByName("mask", typeof(UISprite))
	self.imgLock_ = self.label:ComponentByName("imgLock", typeof(UISprite))
	self.imgRed_ = self.label:ComponentByName("imgRed", typeof(UISprite))

	self.imgRed_:SetActive(false)
end

function ActivityCandyCollectItem:setInfo(params)
	self.id_ = params.id
	self.times_ = params.times
	self.lock_ = params.lock

	self:layout()
	self:onRegister()
end

function ActivityCandyCollectItem:onRegister()
	UIEventListener.Get(self.imgIcon_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("make_cake_exchange_window", {
			lock = self.lock_,
			times = self.times_,
			id = self.id_
		})
	end
end

function ActivityCandyCollectItem:setRedPos(x, y)
	self.imgRed_.gameObject:SetLocalPosition(x, y, 0)
end

function ActivityCandyCollectItem:setRedPoint(flag)
	self.imgRed_.gameObject:SetActive(flag)
end

function ActivityCandyCollectItem:setLockPos(x, y)
	self.imgLock_.gameObject:SetLocalPosition(x, y, 0)
end

function ActivityCandyCollectItem:setLabelPos(x, y)
	self.label.gameObject:SetLocalPosition(x, y, 0)
end

function ActivityCandyCollectItem:update(lock, times)
	self.lock_ = lock
	self.times_ = times

	self:layout()
end

function ActivityCandyCollectItem:layout()
	if self.lock_ then
		xyd.setUISpriteAsync(self.imgIcon_, nil, "make_cake_summer_icon" .. self.id_, function ()
			self.imgIcon_:MakePixelPerfect()
		end)
		self.imgLock_:SetActive(true)
		self.mask:SetActive(true)
	else
		xyd.setUISpriteAsync(self.imgIcon_, nil, "make_cake_summer_icon" .. self.id_, function ()
			self.imgIcon_:MakePixelPerfect()
		end)
		self.imgLock_:SetActive(false)
		self.mask:SetActive(false)
	end

	self.label.text = __("MAKE_CAKE_ITEM_TEXT" .. self.id_)
end

return ActivityCandyCollect
