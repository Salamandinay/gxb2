local ActivityContent = import(".ActivityContent")
local ActivityFireworkAward = class("ActivityFireworkAward", ActivityContent)
local CommonStaticList = import("app.common.ui.CommonStaticList")
local ShowItem = class("ShowItem", import("app.common.ui.CommonStaticListItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ActivityFireworkAward:ctor(parentGO, params, parent)
	ActivityFireworkAward.super.ctor(self, parentGO, params, parent)
end

function ActivityFireworkAward:getPrefabPath()
	return "Prefabs/Windows/activity/award_firework_award"
end

function ActivityFireworkAward:initUI()
	self:getUIComponent()
	ActivityFireworkAward.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityFireworkAward:getUIComponent()
	self.main = self.go:NodeByName("main").gameObject
	self.bg = self.main:ComponentByName("bg", typeof(UISprite))
	self.roundLabel = self.main:ComponentByName("roundLabel", typeof(UILabel))
	self.textImg = self.main:ComponentByName("textImg", typeof(UISprite))
	self.textLabel = self.main:ComponentByName("textLabel", typeof(UILabel))
	self.timerGroup = self.textImg:NodeByName("timerGroup").gameObject
	self.timerGroupUILayout = self.textImg:ComponentByName("timerGroup", typeof(UILayout))
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.itemCell = self.go:NodeByName("itemCell").gameObject
	self.scrollerBg = self.main:ComponentByName("scrollerBg", typeof(UISprite))
	self.scrollerBgUIWidget = self.main:ComponentByName("scrollerBg", typeof(UIWidget))
	self.scroller = self.main:NodeByName("scroller").gameObject
	self.scrollerUIScrollView = self.main:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.groupItemUIWrapContent = self.scroller:ComponentByName("groupItem", typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollerUIScrollView, self.groupItemUIWrapContent, self.itemCell, ShowItem, self)
	self.goBtn = self.main:NodeByName("goBtn").gameObject
	self.goBtnLabelCon = self.goBtn:NodeByName("goBtnLabelCon").gameObject
	self.goBtnUILayout = self.goBtn:ComponentByName("goBtnLabelCon", typeof(UILayout))
	self.goBtnlabel = self.goBtnLabelCon:ComponentByName("goBtnlabel", typeof(UILabel))
	self.arrowCon = self.goBtnLabelCon:NodeByName("arrowCon").gameObject
	self.arrowIcon = self.arrowCon:ComponentByName("arrowIcon", typeof(UISprite))
end

function ActivityFireworkAward:resizeToParent()
	ActivityFireworkAward.super.resizeToParent(self)

	self.scrollerBgUIWidget.height = 508 + 178 * self.scale_num_contrary
end

function ActivityFireworkAward:register()
	ActivityFireworkAward.super.onRegister(self)

	UIEventListener.Get(self.goBtn).onClick = function ()
		local fireworkData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FIREWORK)

		if fireworkData then
			xyd.goToActivityWindowAgain({
				activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_FIREWORK),
				select = xyd.ActivityID.ACTIVITY_FIREWORK
			})
		else
			xyd.alertTips(__("ACTIVITY_END_YET"))
		end
	end
end

function ActivityFireworkAward:initUIComponent()
	self.textLabel.text = __("FIREWORK_TEXT15")

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "ja_jp" then
		self.textLabel.spacingY = 2
	elseif xyd.Global.lang == "fr_fr" then
		self.textLabel.spacingY = 0
	elseif xyd.Global.lang == "de_de" then
		self.textLabel.spacingY = 3
	end

	self.roundLabel.text = __("FIREWORK_TEXT14") .. self.activityData:getRound()
	self.goBtnlabel.text = __("FIREWORK_TEXT16")

	self.goBtnUILayout:Reposition()
	self:initLogoCon()

	local params = {
		cloneItem = self.itemCell,
		parentClass = self,
		itemClass = ShowItem
	}
	local infos = {}
	local infos_yet = {}
	local ids = xyd.tables.activityFireworkRankAwardTable:getIDs()
	local round = self.activityData:getRound()

	for i in pairs(ids) do
		local info = {
			id = ids[i]
		}
		local point = xyd.tables.activityFireworkRankAwardTable:getPoint(info.id)

		if point <= round then
			table.insert(infos_yet, info)
		else
			table.insert(infos, info)
		end
	end

	for i in pairs(infos_yet) do
		table.insert(infos, infos_yet[i])
	end

	self.wrapContent:setInfos(infos)
	self.scrollerUIScrollView:ResetPosition()
end

function ActivityFireworkAward:initLogoCon()
	if self.timeLabelCount then
		return
	end

	self.endLabel.text = __("END")

	xyd.setUISpriteAsync(self.textImg, nil, "activity_firework_logo_" .. xyd.Global.lang)

	self.timeLabelCount = import("app.components.CountDown").new(self.timeLabel)
	local leftTime = self.activityData:getEndTime() - xyd.getServerTime()

	if leftTime > 0 then
		self.timeLabelCount:setInfo({
			duration = leftTime,
			callback = function ()
				self.timeLabel.text = "00:00:00"
			end
		})
	else
		self.timeLabel.text = "00:00:00"
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
		self.timeLabel.transform:SetSiblingIndex(1)
	end

	self.timerGroupUILayout:Reposition()
end

function ShowItem:initUI()
	ShowItem.super.initUI(self)

	self.itemArr = {}
end

function ShowItem:getUIComponent()
	self.itemCell = self.go
	self.progressBar = self.itemCell:ComponentByName("progressBar", typeof(UISprite))
	self.progressBarUIProgressBar = self.itemCell:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.itemsGroup = self.itemCell:NodeByName("itemsGroup").gameObject
	self.itemsGroupUILayout = self.itemCell:ComponentByName("itemsGroup", typeof(UILayout))
	self.labelTitle = self.itemCell:ComponentByName("labelTitle", typeof(UILabel))
end

function ShowItem:update(index, info)
	if not info then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	if self.id and self.id == info.id then
		return
	end

	self.id = info.id
	local awards = xyd.tables.activityFireworkRankAwardTable:getAwards(info.id)
	local point = xyd.tables.activityFireworkRankAwardTable:getPoint(info.id)
	local isComplete = point <= self.parent.activityData:getRound()

	for i in pairs(awards) do
		local param = {
			isAddUIDragScrollView = true,
			itemID = awards[i][1],
			num = awards[i][2],
			uiRoot = self.itemsGroup
		}

		if self.itemArr[i] then
			self.itemArr[i]:setInfo(param)
			self.itemArr[i]:setScale(0.65)

			if isComplete then
				self.itemArr[i]:setChoose(true)
			else
				self.itemArr[i]:setChoose(false)
			end
		else
			local icon = xyd.getItemIcon(param, xyd.ItemIconType.ADVANCE_ICON)

			table.insert(self.itemArr, icon)
			icon:setScale(0.65)

			if isComplete then
				icon:setChoose(true)
			else
				icon:setChoose(false)
			end
		end
	end

	self.itemsGroupUILayout:Reposition()

	self.labelTitle.text = __("FIREWORK_TEXT24", point)

	if isComplete then
		self.progressLabel.text = point .. "/" .. point
	else
		self.progressLabel.text = self.parent.activityData:getRound() .. "/" .. point
	end

	local value = self.parent.activityData:getRound() / point

	if value > 1 then
		value = 1
	end

	self.progressBarUIProgressBar.value = value
end

return ActivityFireworkAward
