local ActivityContent = import(".ActivityContent")
local ActivitySpringNewYear = class("ActivitySpringNewYear", ActivityContent)
local ActivitySpringNewYearItem = class("ActivitySpringNewYearItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")

function ActivitySpringNewYear:ctor(name, params)
	ActivityContent.ctor(self, name, params)
	xyd.models.activity:reqActivityByID(xyd.ActivityID.SPRING_NEW_YEAR)
end

function ActivitySpringNewYear:getPrefabPath()
	return "Prefabs/Windows/activity/spring_new_year"
end

function ActivitySpringNewYear:initUI()
	self:getUIComponent()
	ActivitySpringNewYear.super.initUI(self)
	self:initData()
	self:initUIComponent()
end

function ActivitySpringNewYear:resizeToParent()
	ActivitySpringNewYear.super.resizeToParent(self)
	self:resizePosY(self.logoImg.gameObject, -84.2, -115)
	self:resizePosY(self.groupSelectNode.gameObject, -456.5, -631.3)
	self:resizePosY(self.lightGroup.gameObject, -530, -602)
	self:resizePosY(self.pole1.gameObject, 224.4, 205.1)
	self:resizePosY(self.pole2.gameObject, -22, -61.5)
	self:resizePosY(self.materialNode.gameObject, -194.9, -245)
end

function ActivitySpringNewYear:initData()
	self.lightItem = {}

	for i = 1, 6 do
		local item = ActivitySpringNewYearItem.new(self["lamp" .. i], i)

		table.insert(self.lightItem, item)
	end
end

function ActivitySpringNewYear:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UITexture))
	self.logoImg = self.go:ComponentByName("logoImg", typeof(UITexture))
	self.lightGroup = self.go:NodeByName("lightGroup").gameObject
	self.pole1 = self.lightGroup:NodeByName("pole1").gameObject

	for i = 1, 3 do
		self["lamp" .. i] = self.pole1:NodeByName("lamp" .. i).gameObject
	end

	self.pole2 = self.lightGroup:NodeByName("pole2").gameObject

	for i = 4, 6 do
		self["lamp" .. i] = self.pole2:NodeByName("lamp" .. i).gameObject
	end

	self.helpBtn = self.go:NodeByName("helpBtn").gameObject
	self.materialNode = self.go:NodeByName("materialNode").gameObject
	self.materialBg = self.materialNode:ComponentByName("materialBg", typeof(UITexture))
	self.materialUnit = self.materialNode:ComponentByName("materialUnit", typeof(UISprite))
	self.materialNum = self.materialNode:ComponentByName("materialNum", typeof(UILabel))
	self.materialAddBtn = self.materialNode:NodeByName("materialAddBtn").gameObject
	self.button_label = self.materialAddBtn:ComponentByName("button_label", typeof(UILabel))
	self.groupSelectNode = self.go:NodeByName("groupSelectNode").gameObject
	self.groupAward = self.groupSelectNode:NodeByName("progressCon/groupAward").gameObject
	self.groupGiftBox = self.groupAward:NodeByName("groupGiftBox").gameObject
	self.labelHasUnlocked = self.groupAward:ComponentByName("group/labelHasUnlocked", typeof(UILabel))
	self.progress = self.groupAward:ComponentByName("progress", typeof(UIProgressBar))

	for i = 1, 6 do
		self["group" .. i] = self.groupGiftBox:NodeByName("group" .. i).gameObject
		self["boxImg" .. i] = self["group" .. i]:ComponentByName("boxImg" .. i, typeof(UISprite))
		self["image" .. i] = self["group" .. i]:ComponentByName("image" .. i, typeof(UISprite))
		self["boxLabel" .. i] = self["group" .. i]:ComponentByName("boxLabel" .. i, typeof(UILabel))
	end
end

function ActivitySpringNewYear:initUIComponent()
	self.labelHasUnlocked.text = __("ALL_AWARD")
	self.allPoint = xyd.tables.activitySpringFestivalPointTable:getPoint(6)

	xyd.setUITextureByNameAsync(self.logoImg, "activity_spring_festival_exchange_logo_" .. xyd.Global.lang, true)
	self:updateLightItemShow()
	self:updateResrourse()
	self:updateProgress()
end

function ActivitySpringNewYear:updateResrourse()
	self.materialNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SPRING_NEW_YEAR)
end

function ActivitySpringNewYear:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		self.activityData = xyd.models.activity:getActivity(self.id)
		local sendValues = {}

		for i in pairs(self.activityData.detail.tasks) do
			table.insert(sendValues, tonumber(self.activityData.detail.tasks[i].complete_times))
		end

		xyd.WindowManager.get():openWindow("help_window", {
			key = "SPRING_FESTIVAL_HELP",
			values = sendValues
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	for i = 1, 6 do
		UIEventListener.Get(self["boxImg" .. i].gameObject).onClick = handler(self, function ()
			xyd.WindowManager.get():openWindow("activity_award_preview_window", {
				awards = xyd.tables.activitySpringFestivalPointTable:getAwards(i)
			})
		end)
	end

	UIEventListener.Get(self.materialAddBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.SPRING_NEW_YEAR,
			activityID = xyd.ActivityID.SPRING_NEW_YEAR
		})
	end
end

function ActivitySpringNewYear:onAward()
	self.activityData = xyd.models.activity:getActivity(self.id)

	self:updateLightItemShow()

	local activity_spring_festival_exchange_choose_window = xyd.WindowManager.get():getWindow("activity_spring_festival_exchange_choose_window")

	if activity_spring_festival_exchange_choose_window then
		xyd.WindowManager.get():closeWindow("activity_spring_festival_exchange_choose_window")
	end

	self:updateResrourse()
	self:updateProgress()
end

function ActivitySpringNewYear:updateLightItemShow()
	for i, timesIndex in pairs(self.activityData.detail.limits) do
		self.lightItem[i]:updateItemIcon(timesIndex)
	end
end

function ActivitySpringNewYear:updateProgress()
	self.progress.value = math.min(tonumber(self.activityData.detail.point) / self.allPoint, 1)

	for i = 1, 6 do
		local imgPoint = xyd.tables.activitySpringFestivalPointTable:getPoint(i)

		if imgPoint <= self.activityData.detail.point then
			local imgName = ""

			if i <= 2 then
				imgName = "activity_jigsaw_icon01_1"
			elseif i <= 4 then
				imgName = "activity_jigsaw_icon02_1"
			else
				imgName = "activity_jigsaw_open_icon"
			end

			xyd.setUISpriteAsync(self["boxImg" .. i], nil, imgName, nil, )
		else
			local imgName = ""

			if i <= 2 then
				imgName = "activity_jigsaw_icon01_0"
			elseif i <= 4 then
				imgName = "activity_jigsaw_icon02_0"
			else
				imgName = "trial_icon04"
			end

			xyd.setUISpriteAsync(self["boxImg" .. i], nil, imgName, nil, )
		end
	end
end

function ActivitySpringNewYearItem:ctor(go, id)
	self.id = id

	ActivitySpringNewYearItem.super.ctor(self, go)
end

function ActivitySpringNewYearItem:initUI()
	self.needClickEffectCon = self.go:ComponentByName("needClickEffectCon", typeof(UITexture))
	self.itemCon = self.go:NodeByName("itemCon").gameObject
	self.groupMark = self.go:ComponentByName("groupMark", typeof(UITexture))
	self.choose_img = self.go:ComponentByName("choose_img", typeof(UITexture))

	UIEventListener.Get(self.go.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_spring_festival_exchange_choose_window", {
			group_id = self.id
		})
	end

	self.groupEffect = xyd.Spine.new(self.needClickEffectCon.gameObject)
	local effentId = "1"

	if self.id == 1 then
		effentId = "6"
	elseif self.id == 2 then
		effentId = "3"
	elseif self.id == 3 then
		effentId = "5"
	elseif self.id == 4 then
		effentId = "4"
	elseif self.id == 5 then
		effentId = "1"
	elseif self.id == 6 then
		effentId = "2"
	end

	self.groupEffect:setInfo("lantern_faction_icon", function ()
		self.groupEffect:play("texiao0" .. effentId, 0)
	end)
end

function ActivitySpringNewYearItem:updateItemIcon(timesIndex)
	if timesIndex > 0 then
		local awards = xyd.tables.activitySpringFestivalAwardTble:getAwards(self.id)
		local params = {
			show_has_num = true,
			isShowSelected = false,
			itemID = awards[timesIndex][1],
			num = awards[timesIndex][2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			scale = Vector3(0.74, 0.74, 1),
			uiRoot = self.itemCon.gameObject,
			callback = function ()
				xyd.WindowManager.get():openWindow("activity_spring_festival_exchange_choose_window", {
					group_id = self.id
				})
			end
		}

		if not self.group_item then
			self.group_item = xyd.getItemIcon(params)
		end

		self.group_item:setInfo(params)
		self.itemCon:SetActive(true)
		self.choose_img:SetActive(true)
		self.needClickEffectCon:SetActive(false)
		xyd.applyChildrenGrey(self.itemCon.gameObject)
	else
		self.itemCon:SetActive(false)
		self.choose_img:SetActive(false)
		self.needClickEffectCon:SetActive(true)
	end
end

return ActivitySpringNewYear
