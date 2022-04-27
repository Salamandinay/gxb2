local ActivityClockAwardPreviewWindow = class("ActivityClockAwardPreviewWindow", import(".BaseWindow"))
local ActivityClockSpecialtem = class("ActivityClockSpecialtem", import("app.common.ui.FixedWrapContentItem"))
local ActivityClockNormaItem = class("ActivityClockNormaItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function ActivityClockAwardPreviewWindow:ctor(name, params)
	ActivityClockAwardPreviewWindow.super.ctor(self, name, params)
end

function ActivityClockAwardPreviewWindow:initWindow()
	self:getUIComponent()

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CLOCK)
	self.normalItems = {}

	self:registerEvent()
	self:initUIComponent()
end

function ActivityClockAwardPreviewWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg_ = self.groupAction:ComponentByName("bg_", typeof(UISprite))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.normalGroup = self.groupAction:NodeByName("normalGroup").gameObject
	self.normal_item = self.normalGroup:NodeByName("normal_item").gameObject
	self.titleGroupNormal = self.normalGroup:NodeByName("titleGroup").gameObject
	self.labelTitleNormal = self.titleGroupNormal:ComponentByName("labelTitle", typeof(UILabel))
	self.normalItemGroup = self.normalGroup:NodeByName("itemGroup").gameObject
	self.normalItemGroupGrid = self.normalGroup:ComponentByName("itemGroup", typeof(UIGrid))
	self.specialGroup = self.groupAction:NodeByName("specialGroup").gameObject
	self.titleGroupSpecial = self.specialGroup:NodeByName("titleGroup").gameObject
	self.labelTitleSpecial = self.titleGroupSpecial:ComponentByName("labelTitle", typeof(UILabel))
	self.drag = self.specialGroup:NodeByName("drag").gameObject
	self.scroller = self.specialGroup:NodeByName("scroller").gameObject
	self.scrollView = self.specialGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.specialItemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.specialItemGroupGrid = self.scroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.special_item = self.scroller:NodeByName("special_item").gameObject
end

function ActivityClockAwardPreviewWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function ActivityClockAwardPreviewWindow:initUIComponent()
	self.labelWinTitle.text = __("ACTIVITY_CLOCK_CHOOSE_TITLE")
	self.labelTitleNormal.text = __("ACTIVITY_CLOCK_SHOW_TEXT03")
	self.labelTitleSpecial.text = __("ACTIVITY_CLOCK_SHOW_TEXT04")

	self:initNormalGroup()
	self:initSpecialGroup()
end

function ActivityClockAwardPreviewWindow:initNormalGroup()
	local datas = {}
	local normalCount = 1
	local specialCount = 1
	local round = self.activityData:getRound()
	local ids = self.activityData.detail.ids

	for i = 1, 9 do
		local data = {
			index = i,
			isSpecial = i <= 3
		}

		if data.isSpecial then
			data.id = ids[specialCount + 6]
			data.count = specialCount
			specialCount = specialCount + 1
		else
			data.id = ids[normalCount]
			data.count = normalCount
			normalCount = normalCount + 1
		end

		if not self.normalItems[i] then
			local itemObject = NGUITools.AddChild(self.normalItemGroup.gameObject, self.normal_item)
			local item = ActivityClockNormaItem.new(itemObject, self)
			self.normalItems[i] = item
		end

		self.normalItems[i]:setInfo(data)
		self.normalItemGroupGrid:Reposition()
	end
end

function ActivityClockAwardPreviewWindow:initSpecialGroup()
	self.datas = {}
	local idsByRound = xyd.tables.activityClockGambleTable:getIDsByRound()

	for i = 1, #idsByRound do
		local ids = idsByRound[i]

		table.insert(self.datas, {
			ids = ids,
			round = i
		})
	end

	local function sort_func(a, b)
		return a.round < b.round
	end

	table.sort(self.datas, sort_func)

	if self.wrapContent == nil then
		local wrapContent = self.specialItemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.special_item, ActivityClockSpecialtem, self)
	end

	self.wrapContent:setInfos(self.datas, {})
end

function ActivityClockNormaItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	ActivityClockNormaItem.super.ctor(self, go)
	self:initUI()
end

function ActivityClockNormaItem:initUI()
	self:getUIComponent()
end

function ActivityClockNormaItem:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.labelChange = self.go:ComponentByName("labelChange", typeof(UILabel))
	self.btnChoose = self.go:NodeByName("btnChoose").gameObject
end

function ActivityClockNormaItem:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.params = params
	self.index = params.index
	self.id = params.id
	self.count = params.count
	self.isSpecial = params.isSpecial

	if self.isSpecial then
		self.chooseIndex = self.parent.activityData:getChooseIndex(self.count)

		print(self.chooseIndex)
		print(self.id)

		if self.chooseIndex and self.chooseIndex > 0 then
			self.award = xyd.tables.activityClockGambleTable:getAwards(self.id)[self.chooseIndex]
		else
			self.award = nil
		end

		self.btnChoose:SetActive(true)

		self.labelChange.color = Color.New2(3480496895.0)
		self.labelChange.text = xyd.fixNum(self.parent.activityData:getRadio(self.count + (self.count - 1) * 2) * 100) .. "%"
	else
		self.award = xyd.tables.activityClockGambleTable:getAwards(self.id)[1]

		self.btnChoose:SetActive(false)

		self.labelChange.text = xyd.fixNum(self.parent.activityData:getRadio(self.count + math.ceil(self.count / 2)) * 100) .. "%"
	end

	if self.award then
		local params1 = {
			notShowGetWayBtn = true,
			notShowWays = true,
			scale = 0.8981481481481481,
			uiRoot = self.iconPos,
			itemID = self.award[1],
			num = self.award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		if params1.itemID == 7159 or params1.itemID == 7158 or params1.itemID == 7162 then
			params1.wndType = xyd.ItemTipsWndType.ACTIVITY
		end

		if self.awardIcon then
			self.awardIcon:SetActive(true)
			self.awardIcon:setInfo(params1)
		else
			self.awardIcon = AdvanceIcon.new(params1)
		end

		if self.labelChange.text == "0%" then
			self.awardIcon:setMask(true)
			self.awardIcon:setChoose(true)
		else
			self.awardIcon:setMask(false)
			self.awardIcon:setChoose(false)
		end
	end
end

function ActivityClockSpecialtem:ctor(go, parent)
	ActivityClockSpecialtem.super.ctor(self, go, parent)
end

function ActivityClockSpecialtem:initUI()
	self.bg_ = self.go:ComponentByName("bg_", typeof(UISprite))
	self.labelTitle = self.go:ComponentByName("labelTitle", typeof(UILabel))
	self.ItemGroup = self.go:NodeByName("ItemGroup").gameObject
	self.ItemGroupLayout = self.go:ComponentByName("ItemGroup", typeof(UILayout))

	for i = 1, 3 do
		self["award_item" .. i] = self.ItemGroup:NodeByName("award_item" .. i).gameObject
		self["IconGroup" .. i] = self["award_item" .. i]:NodeByName("IconGroup").gameObject
		self["IconGroupLayout" .. i] = self["award_item" .. i]:ComponentByName("IconGroup", typeof(UILayout))
		self["bg" .. i] = self["award_item" .. i]:ComponentByName("bg_", typeof(UISprite))
		self["labelTitle" .. i] = self["award_item" .. i]:ComponentByName("labelTitle", typeof(UILabel))
	end

	self.icons = {}
end

function ActivityClockSpecialtem:updateInfo()
	self.ids = self.data.ids
	self.round = self.data.round
	self.labelTitle.text = __("ACTIVITY_CLOCK_SHOW_TEXT05", self.round)

	if self.round == 5 then
		self.labelTitle.text = __("ACTIVITY_CLOCK_SHOW_TEXT06")
	end

	local helpCount = 1
	local multyCount = 2
	local iconsCount = {
		0,
		0,
		0
	}

	for i = 1, #self.icons do
		self.icons[i]:SetActive(false)
	end

	for i = 1, 3 do
		local id = self.ids[i]
		local awards = xyd.tables.activityClockGambleTable:getAwards(id)

		if #awards == 1 then
			local award = awards[1]
			local params = {
				notShowWays = true,
				notShowGetWayBtn = true,
				show_has_num = false,
				scale = 0.5925925925925926,
				uiRoot = self.IconGroup1,
				itemID = award[1],
				num = award[2],
				dragScrollView = self.parent.scrollView,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			if params.itemID == 7159 or params.itemID == 7158 or params.itemID == 7162 then
				params.wndType = xyd.ItemTipsWndType.ACTIVITY
			end

			if self.icons[helpCount] then
				self.icons[helpCount]:SetActive(true)
				self.icons[helpCount]:setInfo(params)
			else
				self.icons[helpCount] = AdvanceIcon.new(params)
			end

			helpCount = helpCount + 1
			iconsCount[1] = iconsCount[1] + 1
		else
			for j = 1, #awards do
				local award = awards[j]
				local params = {
					notShowWays = true,
					notShowGetWayBtn = true,
					show_has_num = false,
					scale = 0.5925925925925926,
					uiRoot = self["IconGroup" .. multyCount],
					itemID = award[1],
					num = award[2],
					dragScrollView = self.parent.scrollView,
					wndType = xyd.ItemTipsWndType.ACTIVITY
				}

				if params.itemID == 7159 or params.itemID == 7158 or params.itemID == 7162 then
					params.wndType = xyd.ItemTipsWndType.ACTIVITY
				end

				if self.icons[helpCount] then
					self.icons[helpCount]:SetActive(true)
					self.icons[helpCount]:setInfo(params)
				else
					self.icons[helpCount] = AdvanceIcon.new(params)
				end

				helpCount = helpCount + 1
				iconsCount[multyCount] = iconsCount[multyCount] + 1
			end

			multyCount = multyCount + 1
		end
	end

	for i = 1, 3 do
		self["award_item" .. i]:ComponentByName("", typeof(UIWidget)).width = 80 * iconsCount[i]

		self["award_item" .. i]:SetActive(iconsCount[i] > 0)

		self["labelTitle" .. i].text = __("ACTIVITY_CLOCK_SHOW_TEXT02")

		self["IconGroupLayout" .. i]:Reposition()
	end

	self.labelTitle1.text = __("ACTIVITY_CLOCK_SHOW_TEXT01")

	self.ItemGroupLayout:Reposition()
end

return ActivityClockAwardPreviewWindow
