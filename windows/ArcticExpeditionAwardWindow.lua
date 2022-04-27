local BaseWindow = import(".BaseWindow")
local ArcticExpeditionAwardWindow = class("ArcticExpeditionAwardWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.CopyComponent"))
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaAwardItem.new(go, parent.navScroller1)

	self.item:setDragScrollView(parent.navScroller1)
end

function ItemRender:update(index, id)
	if not id then
		self.go:SetActive(false)

		return
	end

	self.item.data = id

	self.go:SetActive(true)
	self.item:setInfo(id)
end

function ItemRender:getGameObject()
	return self.go
end

function ArcticExpeditionAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)
	self.awardList = {}
	self.seasonAwardList = {}
end

function ArcticExpeditionAwardWindow:playOpenAnimation(callback)
	function self.onClickCloseButton()
	end

	ArcticExpeditionAwardWindow.super.playOpenAnimation(self, function ()
		function self.onClickCloseButton()
			if self.params_ and self.params_.lastWindow and self.name_ ~= "smithy_window" and self.name_ ~= "enhance_window" then
				xyd.WindowManager.get():openWindow(self.params_.lastWindow)
			end

			self:close()
		end

		callback()
	end)
end

function ArcticExpeditionAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	local guideWin = xyd.WindowManager.get():getWindow("exskill_guide_window")

	if guideWin then
		function self.onClickEscBack()
		end
	end

	self:register()

	self.labelNav1 = self.nav1Label
	self.labelNav2 = self.nav2Label
	self.labelTitle.text = __("MAIL_AWAED_TEXT")
	self.labelRankText.text = tostring(__("ARCTIC_EXPEDITION_TEXT_28")) .. " : "
	self.labelSelfRankText.text = __("ARCTIC_EXPEDITION_TEXT_29") .. " :"
	self.labelNowAward.text = __("NOW_AWARD")
	self.labelNav1.text = __("ARCTIC_EXPEDITION_TEXT_31")
	self.labelNav2.text = __("ARCTIC_EXPEDITION_TEXT_32")
	self.labelDesc1.text = __("ARCTIC_EXPEDITION_TEXT_33")
	self.labelDesc2.text = __("ARCTIC_EXPEDITION_TEXT_34")
	self.labelText1.text = __("PARTNER_CHALLENGE_CHESS_TEXT08")
	self.labelText2.text = __("ARCTIC_EXPEDITION_TEXT_29")

	for i = 1, 3 do
		self["labelText" .. i + 2].text = __("ARCTIC_EXPEDITION_TEXT_30", i)
	end

	local effect = xyd.Spine.new(self.clock.gameObject)
	local effect2 = xyd.Spine.new(self.clock2.gameObject)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)
	effect2:setInfo("fx_ui_shizhong", function ()
		effect2:SetLocalScale(1, 1, 1)
		effect2:SetLocalPosition(0, 0, 0)
		effect2:play("texiao1", 0)
	end)
	self:updateDDL1()
	self:updateDDL2()
	self:onclickNav(1)
	self:layoutAward()

	if not self.activityData_:reqRankList() then
		self:initSelfRank()
	end
end

function ArcticExpeditionAwardWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.guidePos = content
	local titleGroup = content:NodeByName("titleGroup").gameObject
	self.backBtn = titleGroup:NodeByName("backBtn").gameObject
	self.labelTitle = titleGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.helpBtn_ = titleGroup:NodeByName("helpBtn").gameObject
	local navGroup = content:NodeByName("navGroup").gameObject
	self.nav1 = navGroup:NodeByName("nav1").gameObject
	self.nav1ChooseImg = navGroup:NodeByName("nav1/chooseImg").gameObject
	self.nav1Label = self.nav1:ComponentByName("label", typeof(UILabel))
	self.nav2 = navGroup:NodeByName("nav2").gameObject
	self.nav2Label = self.nav2:ComponentByName("label", typeof(UILabel))
	self.nav2ChooseImg = navGroup:NodeByName("nav2/chooseImg").gameObject
	self.group1 = content:NodeByName("group1").gameObject
	local middleGroup = self.group1:NodeByName("middleGroup").gameObject
	local rankGroup = middleGroup:NodeByName("rankGroup").gameObject
	self.labelRankText = rankGroup:ComponentByName("labelRankText", typeof(UILabel))
	self.labelRank = rankGroup:ComponentByName("labelRank", typeof(UILabel))
	self.labelSelfRankText = rankGroup:ComponentByName("labelSelfRankText", typeof(UILabel))
	self.labelSelfRank = rankGroup:ComponentByName("labelSelfRank", typeof(UILabel))
	self.labelNowAward = rankGroup:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAwardRoot = rankGroup:NodeByName("nowAward").gameObject
	self.labelDesc1 = middleGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = middleGroup:ComponentByName("clock", typeof(UITexture))
	local ddl1Label = middleGroup:ComponentByName("ddl1", typeof(UILabel))
	self.ddl1 = CountDown.new(ddl1Label)

	for i = 1, 5 do
		self["labelText" .. i] = self.group1:ComponentByName("labelText" .. i, typeof(UILabel))
	end

	self.navScroller1 = self.group1:ComponentByName("navScroller1", typeof(UIScrollView))
	local wrapContent1 = self.navScroller1:ComponentByName("awardContainer1", typeof(UIWrapContent))
	local awardItemRoot = self.group1:NodeByName("awardItemRoot").gameObject
	self.wrapContent1 = FixedWrapContent.new(self.navScroller1, wrapContent1, awardItemRoot, ItemRender, self)
	self.group2 = content:NodeByName("group2").gameObject
	self.upGroup = self.group2:NodeByName("upGroup").gameObject
	self.upGroupBg = self.upGroup:ComponentByName("upGroupBg", typeof(UITexture))
	self.upGroupPanel = self.upGroup:NodeByName("upGroupPanel").gameObject

	for i = 1, 3 do
		self["personCon" .. i] = self.upGroupPanel:NodeByName("personCon" .. i).gameObject
		self["defaultCon" .. i] = self["personCon" .. i]:NodeByName("defaultCon" .. i).gameObject
		self["showCon" .. i] = self["personCon" .. i]:NodeByName("showCon" .. i).gameObject
		self["cellIconImg" .. i] = self["showCon" .. i]:ComponentByName("cellIconImg", typeof(UISprite))
		self["serverInfo" .. i] = self["showCon" .. i]:NodeByName("serverInfo" .. i).gameObject
		self["serverId" .. i] = self["serverInfo" .. i]:ComponentByName("serverId" .. i, typeof(UILabel))
		self["groupIcon" .. i] = self["serverInfo" .. i]:ComponentByName("groupIcon" .. i, typeof(UISprite))
		self["labelDesText" .. i] = self["showCon" .. i]:ComponentByName("labelDesText" .. i, typeof(UILabel))
		self["labelCurrentNum" .. i] = self["showCon" .. i]:ComponentByName("labelCurrentNum" .. i, typeof(UILabel))
	end

	self.labelDesc2 = self.group2:ComponentByName("labelDesc", typeof(UILabel))
	self.clock2 = self.group2:ComponentByName("clock", typeof(UITexture))
	local ddl2Label = self.group2:ComponentByName("ddl2", typeof(UILabel))
	self.ddl2 = CountDown.new(ddl2Label)

	for i = 1, 3 do
		self["groupAwardRoot" .. i] = self.group2:NodeByName("showGroup/grid/awardItem" .. i .. "/awardItemList").gameObject
	end
end

function ArcticExpeditionAwardWindow:layoutAward()
	local rankIDs = xyd.tables.arcticExpeditionRankAwardTable:getIDs()

	self.wrapContent1:setInfos(rankIDs, {})

	for i = 1, 3 do
		local awards = xyd.tables.arcticExpeditionGroupRankAwardTable:getAwards(i)

		for j = 1, #awards do
			local item = awards[j]
			local icon = xyd.getItemIcon({
				labelNumScale = 1.6,
				hideText = true,
				uiRoot = self["groupAwardRoot" .. i],
				itemID = item[1],
				num = item[2]
			})

			icon:SetLocalScale(0.7, 0.7, 1)
		end

		self["groupAwardRoot" .. i]:GetComponent(typeof(UILayout)):Reposition()
	end

	local iconList = {
		"arctic_expedition_cell_icon6",
		"arctic_expedition_cell_icon7",
		"arctic_expedition_cell_icon5"
	}

	for i = 1, 3 do
		local groupData = self.activityData_:getGroupByRank(i)
		local group_id = groupData.group

		xyd.setUISpriteAsync(self["cellIconImg" .. i], nil, iconList[group_id])
		xyd.setUISpriteAsync(self["groupIcon" .. i], nil, "arctic_expedition_cell_group_icon_" .. group_id)

		self["labelDesText" .. i].text = __("ACTIVITY_GROWTH_PLAN_TEXT08")
		self["serverId" .. i].text = __("ARCTIC_EXPEDITION_GROUP_" .. group_id)
		self["labelCurrentNum" .. i].text = groupData.score

		if xyd.Global.lang == "zh_tw" then
			self["serverId" .. i].fontSize = 20
		end
	end
end

function ArcticExpeditionAwardWindow:initSelfRank()
	local groupRank = self.activityData_:getGroupRank()
	local selfRankData = self.activityData_:getSelfAwardData()
	self.labelRank.text = groupRank
	local selfRank = selfRankData.self_rank
	selfRank = selfRank and selfRank + 1
	self.labelSelfRank.text = selfRank or " - "
	local selfAwardItem = xyd.tables.arcticExpeditionRankAwardTable:getAwardByRank(selfRank, groupRank)

	for i = 1, #selfAwardItem do
		local item = selfAwardItem[i]
		local icon = xyd.getItemIcon({
			labelNumScale = 1.6,
			hideText = true,
			uiRoot = self.nowAwardRoot,
			itemID = item[1],
			num = item[2]
		})

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	self.nowAwardRoot:GetComponent(typeof(UILayout)):Reposition()
end

function ArcticExpeditionAwardWindow:willClose()
	ArcticExpeditionAwardWindow.super.willClose(self)

	local guideValue = xyd.db.misc:getValue("arctic_expedition_guide")
	local eraID = self.activityData_:getEra()
	local win = xyd.WindowManager.get():getWindow("arctic_expedition_main_window")

	if eraID == 2 and tonumber(guideValue) < 2 then
		win:showGuideEra2()
	elseif eraID == 3 and tonumber(guideValue) < 3 then
		win:showGuideEra3()
	end
end

function ArcticExpeditionAwardWindow:register()
	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARCTIC_EXPEDITION_HELP_AWARD"
		})
	end

	UIEventListener.Get(self.nav1).onClick = function ()
		self:onclickNav(1)
	end

	UIEventListener.Get(self.nav2).onClick = function ()
		self:onclickNav(2)
	end

	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_GET_RANK_LIST, handler(self, self.initSelfRank))
end

function ArcticExpeditionAwardWindow:onclickNav(index)
	if index == 1 then
		self.group1:SetActive(true)
		self.group2:SetActive(false)
		self.nav1ChooseImg:SetActive(true)
		self.nav2ChooseImg:SetActive(false)

		self.nav1Label.color = Color.New2(4294967295.0)
		self.nav1Label.effectColor = Color.New2(1012112383)
		self.nav2Label.color = Color.New2(960513791)
		self.nav2Label.effectColor = Color.New2(4294967295.0)
	else
		self.group1:SetActive(false)
		self.group2:SetActive(true)
		self.nav1ChooseImg:SetActive(false)
		self.nav2ChooseImg:SetActive(true)

		self.nav2Label.color = Color.New2(4294967295.0)
		self.nav2Label.effectColor = Color.New2(1012112383)
		self.nav1Label.color = Color.New2(960513791)
		self.nav1Label.effectColor = Color.New2(4294967295.0)
	end
end

function ArcticExpeditionAwardWindow:updateDDL1()
	local serverTime = xyd.getServerTime()
	local endTime = self.activityData_:startTime() + xyd.DAY_TIME * 13
	local duration = nil

	if endTime <= serverTime then
		duration = 0
	else
		duration = endTime - serverTime
	end

	self.ddl1:setInfo({
		duration = duration
	})
end

function ArcticExpeditionAwardWindow:updateDDL2()
	local serverTime = xyd.getServerTime()
	local endTime = self.activityData_:startTime() + xyd.DAY_TIME * 13
	local duration = nil

	if endTime <= serverTime then
		duration = 0
	else
		duration = endTime - serverTime
	end

	self.ddl2:setInfo({
		duration = duration
	})
end

function ArenaAwardItem:ctor(parentGo, scrollView)
	ArenaAwardItem.super.ctor(self, parentGo)

	self.scrollView = scrollView

	self:getUIComponent()
end

function ArenaAwardItem:getPrefabPath()
	return "Prefabs/Components/arena_award_item"
end

function ArenaAwardItem:getUIComponent()
	local go = self.go
	self.rank1 = go:ComponentByName("rank1", typeof(UILabel))
	self.rank2 = go:ComponentByName("rank2", typeof(UILabel))
	self.rank3 = go:ComponentByName("rank3", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardRoot").gameObject
	self.awardGroupLayout = self.awardGroup:GetComponent(typeof(UILayout))
end

function ArenaAwardItem:setInfo(id)
	local id = id
	local awards = xyd.tables.arcticExpeditionRankAwardTable:getAwards(id)

	for i = 1, 3 do
		self["rank" .. i].text = xyd.tables.arcticExpeditionRankAwardTable:getShowIndex(id, i)
	end

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #awards do
		local item = awards[i]
		local icon = xyd.getItemIcon({
			noClickSelected = true,
			labelNumScale = 1.2,
			hideText = true,
			uiRoot = self.awardGroup,
			itemID = item[1],
			num = item[2],
			dragScrollView = self.scrollView
		})

		icon:SetLocalScale(0.7, 0.7, 1)
	end

	self.awardGroupLayout:Reposition()
end

return ArcticExpeditionAwardWindow
