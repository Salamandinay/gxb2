local ActivityRepairConsoleAwardWindow = class("ActivityRepairConsoleAwardWindow", import(".BaseWindow"))
local ShowItem = class("ShowItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CommonTabBar = require("app.common.ui.CommonTabBar")

function ActivityRepairConsoleAwardWindow:ctor(name, params)
	ActivityRepairConsoleAwardWindow.super.ctor(self, name, params)
end

function ActivityRepairConsoleAwardWindow:initWindow()
	self:getUIComponent()
	ActivityRepairConsoleAwardWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ActivityRepairConsoleAwardWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.titleText = self.groupAction:ComponentByName("titleText", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.scrollView1 = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollView_ = self.groupAction:NodeByName("scrollView").gameObject
	self.gridList = self.groupAction:NodeByName("scrollView/award_item_grid_list").gameObject
	self.awardItem_1 = self.groupAction:NodeByName("scrollView/award_item").gameObject
	self.scrollView2 = self.groupAction:ComponentByName("scrollView2", typeof(UIScrollView))
	self.scrollView2_ = self.groupAction:NodeByName("scrollView2").gameObject
	self.gridList2 = self.groupAction:NodeByName("scrollView2/award_item_grid_list").gameObject
	self.awardItem_2 = self.groupAction:NodeByName("scrollView2/award_item").gameObject
	self.showLittleItem = self.groupAction:NodeByName("showItem").gameObject
	self.iconItem = self.groupAction:NodeByName("showItem").gameObject
	self.award_item_list = self.groupAction:NodeByName("award_item_list").gameObject
end

function ActivityRepairConsoleAwardWindow:registerEvent()
	UIEventListener.Get(self.btnClose).onClick = function ()
		self:close()
	end
end

function ActivityRepairConsoleAwardWindow:layout()
	self.titleText.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.index = 1

	self:initAwardItem(1, self.awardItem_1)
	self:initNav()
end

function ActivityRepairConsoleAwardWindow:initNav()
	local labelStates = {
		chosen = {
			color = Color.New2(4278124287.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.smallTab = CommonTabBar.new(self.nav.gameObject, 2, function (index)
		self:updateNav(index)
	end, nil, labelStates)
	local texts = {
		__("ACTIVITY_REPAIR_CONSOLE_TEXT05"),
		__("ACTIVITY_REPAIR_CONSOLE_TEXT06")
	}

	self.smallTab:setTexts(texts)
	self.smallTab:setTabActive(1, true, false)
end

function ActivityRepairConsoleAwardWindow:updateNav(index)
	if self.index == index then
		return
	end

	self.index = index

	if self.index == 1 then
		self:initAwardItem(1, self.awardItem_1)
	else
		self:initAwardItem(1, self.awardItem_2)
	end
end

function ActivityRepairConsoleAwardWindow:getInfos()
	return xyd.tables.activityRepairConsoleAwardTable:getShowViewInfos(self.index)
end

function ActivityRepairConsoleAwardWindow:initAwardItem(id, go)
	local awardList = go:NodeByName("list_grid").gameObject
	local awardsData = self:getInfos()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_REPAIR_CONSOLE)
	self.round = tonumber(activityData.detail_.round)
	self.maxRound = tonumber(xyd.tables.miscTable:getVal("activity_repair_console_max_time", "value"))

	if self.index == 1 then
		self:initItems(awardList, awardsData, self.scrollView1)
	else
		self:initItems(awardList, awardsData, self.scrollView2)
	end
end

function ActivityRepairConsoleAwardWindow:initItems(parentGo, awardsData, scrollView)
	NGUITools.DestroyChildren(parentGo.transform)
	NGUITools.DestroyChildren(self.gridList.transform)
	NGUITools.DestroyChildren(self.gridList2.transform)

	if self.index == 1 then
		self.scrollView2:SetActive(false)
		self.scrollView1:SetActive(true)

		self.scrollView1.enabled = false

		self.scrollView1:ResetPosition()
	else
		self.scrollView1:SetActive(false)
		self.scrollView2:SetActive(true)

		self.scrollView2.enabled = true

		self.scrollView2:ResetPosition()
	end

	if self.index == 1 then
		for _, data in ipairs(awardsData) do
			local go = NGUITools.AddChild(parentGo, self.iconItem)
			local rateItem = ShowItem.new(go, self)

			rateItem:setInfo(data, _, scrollView, 1, self.round)
			go:SetActive(true)
		end

		local grid = parentGo:GetComponent(typeof(UIGrid))

		grid:Reposition()
	else
		for id, data in ipairs(awardsData) do
			local awardItemList = NGUITools.AddChild(self.gridList2, self.award_item_list)

			awardItemList.transform:Y((id - 1) * -272 + 270)
			awardItemList.transform:X(0)
			awardItemList:SetActive(true)

			local grids = awardItemList:NodeByName("list_grid").gameObject

			for id, data_ in pairs(awardsData[id]) do
				local go_ = NGUITools.AddChild(grids, self.iconItem)
				local rateItem = ShowItem.new(go_, self)

				rateItem:setInfo(data_, 1, scrollView, 2, self.round)
				go_:SetActive(true)
			end

			local grid_ = grids:GetComponent(typeof(UIGrid))
			grid_.cellHeight = 112

			grid_:Reposition()

			self.awardRoundText = awardItemList:ComponentByName("title_bg/title_label", typeof(UILabel))

			if id == 1 then
				self.awardRoundText.text = __("ACTIVITY_REPAIR_CONSOLE_AWARDS_TEXT01")
			elseif id == 2 then
				self.awardRoundText.text = __("ACTIVITY_REPAIR_CONSOLE_AWARDS_TEXT02")
			else
				self.awardRoundText.text = __("ACTIVITY_REPAIR_CONSOLE_AWARDS_TEXT03")
			end
		end
	end

	self.scrollView1:ResetPosition()
	self.scrollView2:ResetPosition()
end

function ShowItem:ctor(goItem, parent)
	ShowItem.super.ctor(self, goItem)

	self.parent = parent
	self.maxRound = tonumber(xyd.tables.miscTable:getVal("activity_repair_console_max_time", "value"))
end

function ShowItem:initUI()
	self.iconNode = self.go:NodeByName("itemCon").gameObject
	self.itemLabel = self.go:ComponentByName("itemLabel", typeof(UILabel))
	self.bubble = self.go:ComponentByName("bubble", typeof(UISprite))
	self.selectImg = self.go:NodeByName("selectImg").gameObject
	self.maskImg = self.go:NodeByName("maskImg").gameObject
end

function ShowItem:setInfo(info, index, scrollView, type, round)
	local itemData = info

	if self.maxRound < round then
		round = self.maxRound
	end

	if type == 2 then
		self.itemLabel:SetActive(false)
	elseif index == round then
		xyd.setUISpriteAsync(self.bubble, nil, "activity_repair_console_bubble_" .. xyd.Global.lang)
		self.bubble:SetActive(true)
	else
		self.bubble:SetActive(false)
	end

	if type == 1 and index < round then
		self.selectImg:SetActive(true)
		self.maskImg:SetActive(true)
	else
		self.selectImg:SetActive(false)
		self.maskImg:SetActive(false)
	end

	if type == 1 and index == self.maxRound then
		self.itemLabel.text = __("ACTIVITY_REPAIR_CONSOLE_TEXT08", index)
	else
		self.itemLabel.text = __("ACTIVITY_REPAIR_CONSOLE_TEXT07", index)
	end

	xyd.getItemIcon({
		scale = 0.9074074074074074,
		uiRoot = self.iconNode,
		itemID = itemData[1],
		num = itemData[2],
		dragScrollView = scrollView
	})
end

return ActivityRepairConsoleAwardWindow
