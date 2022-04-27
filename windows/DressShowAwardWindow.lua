local BaseWindow = import(".BaseWindow")
local DressShowAwardWindow = class("DressShowAwardWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local BaseComponent = import("app.components.BaseComponent")
local DressShowAwardItem = class("DressShowAwardItem", import("app.common.ui.FixedWrapContentItem"))
local AdvanceIcon = import("app.components.AdvanceIcon")

function DressShowAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.dressShow
	self.curGroup = params.group
	self.awardItemList = {}
end

function DressShowAwardWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.bg = self.topGroup:ComponentByName("bg", typeof(UISprite))
	self.rankGroup = self.topGroup:NodeByName("rankGroup").gameObject
	self.bg1 = self.rankGroup:ComponentByName("bg1", typeof(UITexture))
	self.bg2 = self.rankGroup:ComponentByName("bg2", typeof(UITexture))
	self.group1 = self.rankGroup:NodeByName("group1").gameObject
	self.labelCurRank = self.group1:ComponentByName("labelCurRank", typeof(UILabel))
	self.labelCurRankNum = self.group1:ComponentByName("labelCurRankNum", typeof(UILabel))
	self.group2 = self.rankGroup:NodeByName("group2").gameObject
	self.labelCurScore = self.group2:ComponentByName("labelCurRank", typeof(UILabel))
	self.labelCurScoreNum = self.group2:ComponentByName("labelCurRankNum", typeof(UILabel))
	self.group3 = self.rankGroup:NodeByName("group3").gameObject
	self.labelNowAward = self.group3:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAwards = self.group3:ComponentByName("nowAwards", typeof(UILayout))
	self.labelDesc = self.topGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.clockEffectPos = self.topGroup:ComponentByName("clockEffectPos", typeof(UITexture))
	self.labelTime = self.topGroup:ComponentByName("labelTime", typeof(UILabel))
	self.scroller = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.award_item = self.scroller:NodeByName("award_item").gameObject
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller, self.itemGroup, self.award_item, DressShowAwardItem, self)
end

function DressShowAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	xyd.setUITextureAsync(self.bgImage1, "Textures/arena_web/arena_award_bg")
	xyd.setUITextureAsync(self.bgImage2, "Textures/arena_web/arena_award_bg")

	self.labelTitle.text = __("AWARD2")
	self.labelCurScore.text = __("SHOW_WINDOW_TEXT20")
	local curScore = self.activityData:getScore(self.curGroup)
	self.labelCurRank.text = __("SHOW_WINDOW_TEXT19")
	self.labelNowAward.text = __("SHOW_WINDOW_TEXT21")
	self.labelDesc.text = __("SHOW_WINDOW_TEXT22")
	local curRank = self.activityData:getLevelByScore(curScore)
	self.labelCurRankNum.text = curScore
	local rankText = {
		"E",
		"D",
		"C",
		"B",
		"A",
		"S"
	}
	local rankColor = {
		1549556991,
		1549556991,
		1944887551,
		1820916223,
		4268112895.0,
		2874471423.0
	}
	self.labelCurScoreNum.text = rankText[curRank]
	self.labelCurScoreNum.color = Color.New2(rankColor[curRank])
	local effect = xyd.Spine.new(self.clockEffectPos.gameObject)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	local datas = {}
	self.curAwardData = nil
	local ids = xyd.tables.dressShowAwardTable:getGroupIds(self.curGroup)

	for i = 1, #ids do
		local tableID = ids[i]
		local data = {
			point = xyd.tables.dressShowAwardTable:getPoint(tableID),
			awards = xyd.tables.dressShowAwardTable:getAwards(tableID)
		}

		if curScore < data.point and i > 1 and not self.curAwardData then
			self.curAwardData = xyd.tables.dressShowAwardTable:getAwards(ids[i - 1])
		end

		table.insert(datas, data)
	end

	if curScore < datas[1].point then
		self.curAwardData = nil
	end

	self.wrapContent:setInfos(datas, {})

	self.countDownTime = CountDown.new(self.labelTime)

	self.countDownTime:setInfo({
		duration = xyd.getTomorrowTime() - xyd.getServerTime()
	})
	self:initCurAward(self.curAwardData)
	self:register()
end

function DressShowAwardWindow:initCurAward(datas)
	if not datas then
		return
	end

	for i = 1, #datas do
		local item = datas[i]
		local icon = xyd.getItemIcon({
			labelNumScale = 1.6,
			hideText = true,
			uiRoot = self.nowAwards.gameObject,
			itemID = item[1],
			num = item[2]
		})

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	self.nowAwards:Reposition()
end

function DressShowAwardWindow:register()
	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function DressShowAwardItem:ctor(go, parent, scrollView)
	DressShowAwardItem.super.ctor(self, go, parent)

	self.scrollView = scrollView

	self:getUIComponent()
end

function DressShowAwardItem:getUIComponent()
	local go = self.go
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.awardGroupLayout = self.awardGroup:GetComponent(typeof(UILayout))
end

function DressShowAwardItem:updateInfo()
	local data = self.data
	self.labelRank.text = data.point

	if not self.advanceIconList then
		self.advanceIconList = {}
	else
		for i = 1, #self.advanceIconList do
			self.advanceIconList[i]:SetActive(false)
		end
	end

	dump(data)

	for i = 1, #data.awards do
		local params = {
			labelNumScale = 1.2,
			noClickSelected = true,
			hideText = true,
			scale = 0.7,
			itemID = data.awards[i][1],
			num = data.awards[i][2],
			dragScrollView = self.parent.scroller
		}

		if not self.advanceIconList[i] then
			params.uiRoot = self.awardGroup
			local icon = AdvanceIcon.new(params)

			table.insert(self.advanceIconList, icon)
			self.advanceIconList[i]:SetActive(true)
		else
			self.advanceIconList[i]:SetActive(true)
			self.advanceIconList[i]:setInfo(params)
		end
	end

	self.awardGroupLayout:Reposition()
end

return DressShowAwardWindow
