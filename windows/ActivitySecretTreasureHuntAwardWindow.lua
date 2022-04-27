local BaseWindow = import(".BaseWindow")
local ActivitySecretTreasureHuntAwardWindow = class("ActivitySecretTreasureHuntAwardWindow", BaseWindow)
local ActivitySecretTreasureHuntTreasureItem = class("ActivitySecretTreasureHuntTreasureItem", import("app.common.ui.FixedWrapContentItem"))
local ActivitySecretTreasureHuntAwardItem = class("ActivitySecretTreasureHuntAwardItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ItemTable = xyd.tables.itemTable

function ActivitySecretTreasureHuntAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT)
end

function ActivitySecretTreasureHuntAwardWindow:getPrefabPath()
	return "Prefabs/Windows/activity_secret_treasure_hunt_award_window"
end

function ActivitySecretTreasureHuntAwardWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:Register()
	self:initUIComponent()
end

function ActivitySecretTreasureHuntAwardWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.tab_1 = self.nav:NodeByName("tab_1").gameObject
	self.tab_2 = self.nav:NodeByName("tab_2").gameObject
	self.redPoint = self.tab_2:ComponentByName("redPoint", typeof(UISprite))
	self.content = self.groupAction:NodeByName("content").gameObject
	self.content1Group = self.content:NodeByName("content1Group").gameObject
	self.awardContentGroup = self.content1Group:NodeByName("awardContentGroup").gameObject
	self.bg_ = self.awardContentGroup:ComponentByName("bg_", typeof(UISprite))
	self.drag = self.awardContentGroup:NodeByName("drag").gameObject
	self.treasureScroller = self.awardContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.treasureItemGroup = self.treasureScroller:NodeByName("itemGroup").gameObject
	self.treasure_item = self.treasureScroller:NodeByName("treasure_item").gameObject
	self.labelAward = self.awardContentGroup:ComponentByName("labelAward", typeof(UILabel))
	self.labelTreasure = self.awardContentGroup:ComponentByName("labelTreasure", typeof(UILabel))
	self.content2Group = self.content:NodeByName("content2Group").gameObject
	self.boxContentGroup = self.content2Group:NodeByName("boxContentGroup").gameObject
	self.scrollerBox = self.boxContentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.box_item = self.scrollerBox:NodeByName("box_item").gameObject
	self.specialGroup = self.scrollerBox:NodeByName("specialGroup").gameObject
	self.titleGroupSecial = self.specialGroup:NodeByName("titleGroup").gameObject
	self.labelTitleSecial = self.titleGroupSecial:ComponentByName("labelTitle", typeof(UILabel))
	self.itemGroupSecial = self.specialGroup:NodeByName("itemGroup").gameObject
	self.itemGroupSecial_Grid = self.specialGroup:ComponentByName("itemGroup", typeof(UIGrid))
	self.normalGroup = self.scrollerBox:NodeByName("normalGroup").gameObject
	self.titleGroupNormal = self.normalGroup:NodeByName("titleGroup").gameObject
	self.labelTitleNormal = self.titleGroupNormal:ComponentByName("labelTitle", typeof(UILabel))
	self.itemGroupNormal = self.normalGroup:NodeByName("itemGroup").gameObject
	self.itemGroupNormal_Grid = self.normalGroup:ComponentByName("itemGroup", typeof(UIGrid))
	self.tabBar = CommonTabBar.new(self.nav, 2, function (index)
		self.tabIndex = index

		if index == 1 then
			self.content1Group:SetActive(true)
			self.content2Group:SetActive(false)
			self:initData()
		else
			self.content1Group:SetActive(false)
			self.content2Group:SetActive(true)
			self:initData()
		end
	end, nil, , 15)
end

function ActivitySecretTreasureHuntAwardWindow:addTitle()
	self.labelWinTitle.text = __("ACTIVITY_TRICKORTREAT_TEXT02")
end

function ActivitySecretTreasureHuntAwardWindow:initUIComponent()
	self.tabBar.tabs[1].label.text = __("ACTIVITY_SECTRETTREASURE_TEXT12")
	self.tabBar.tabs[2].label.text = __("ACTIVITY_SECTRETTREASURE_TEXT13")
	self.labelTreasure.text = __("ACTIVITY_SECTRETTREASURE_TEXT33")
	self.labelAward.text = __("ACTIVITY_SECTRETTREASURE_TEXT34")
	self.labelTitleSecial.text = __("ACTIVITY_SECTRETTREASURE_TEXT14")
	self.labelTitleNormal.text = __("ACTIVITY_SECTRETTREASURE_TEXT32")

	if xyd.Global.lang == "ko_kr" then
		self.labelTitleSecial.width = 280
	elseif xyd.Global.lang == "ja_jp" then
		self.labelTitleSecial.width = 280
	elseif xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" then
		self.labelTitleSecial.width = 360
	end
end

function ActivitySecretTreasureHuntAwardWindow:initData()
	local times = self.activityData.detail.round
	self.data1 = {}
	local ids = xyd.tables.activitySecretTreasureAwardTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(i)
		local awarded = false
		local award = xyd.tables.activitySecretTreasureAwardTable:getAward(id)
		local light = xyd.tables.activitySecretTreasureAwardTable:getLight(id)

		if id <= times then
			awarded = true
		end

		table.insert(self.data1, {
			id = tonumber(id),
			award = award,
			awarded = awarded,
			light = light
		})
	end

	local function sort_func(a, b)
		if a.awarded == b.awarded then
			return a.id < b.id
		elseif a.awarded == true then
			return false
		else
			return true
		end
	end

	table.sort(self.data1, sort_func)

	if self.wrapContent1 == nil then
		local wrapContent = self.treasureItemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent1 = FixedWrapContent.new(self.treasureScroller, wrapContent, self.treasure_item, ActivitySecretTreasureHuntTreasureItem, self)
	end

	self.wrapContent1:setInfos(self.data1, {})

	self.normalAwardDatas = {}
	local box_id = 1310101
	local ids = xyd.tables.dropboxShowTable:getIdsByBoxId(box_id).list
	local allWeight = xyd.tables.dropboxShowTable:getIdsByBoxId(box_id).all_weight

	for key, value in pairs(ids) do
		local itemData = xyd.tables.dropboxShowTable:getItem(value)
		local id = tonumber(value)
		local item_id = itemData[1]
		local change = xyd.tables.dropboxShowTable:getWeight(value) / allWeight
		local item_num = itemData[2]

		table.insert(self.normalAwardDatas, {
			id = tonumber(id),
			item_id = item_id,
			item_num = item_num,
			change = change,
			dragScrollView = self.scrollerBox
		})
	end

	for i = 1, #ids do
	end

	local function sort_func(a, b)
		return a.id < b.id
	end

	table.sort(self.normalAwardDatas, sort_func)

	self.specialAwardDatas = {}
	local box_id = 1310102
	local ids = xyd.tables.dropboxShowTable:getIdsByBoxId(box_id).list
	local allWeight = xyd.tables.dropboxShowTable:getIdsByBoxId(box_id).all_weight

	for key, value in pairs(ids) do
		local id = tonumber(value)
		local item_id = xyd.tables.dropboxShowTable:getItem(value)[1]
		local change = xyd.tables.dropboxShowTable:getWeight(value) / allWeight
		local item_num = xyd.tables.dropboxShowTable:getItem(value)[2]

		table.insert(self.specialAwardDatas, {
			id = tonumber(id),
			item_id = item_id,
			item_num = item_num,
			change = change,
			dragScrollView = self.scrollerBox
		})
	end

	local function sort_func(a, b)
		return a.id < b.id
	end

	table.sort(self.specialAwardDatas, sort_func)

	if self.normalAwardItems == nil then
		self.normalAwardItems = {}

		for i = 1, #self.normalAwardDatas do
			local normalAwardItem = NGUITools.AddChild(self.itemGroupNormal, self.box_item)
			local item = ActivitySecretTreasureHuntAwardItem.new(normalAwardItem)

			item:setInfo(self.normalAwardDatas[i])
			table.insert(self.normalAwardItems, item)
		end
	else
		for i = 1, #self.normalAwardDatas do
			self.normalAwardItems[i]:setInfo(self.normalAwardDatas[i])
		end
	end

	self.itemGroupNormal_Grid:Reposition()

	if self.specialAwardItems == nil then
		self.specialAwardItems = {}

		for i = 1, #self.specialAwardDatas do
			local secialAwardItem = NGUITools.AddChild(self.itemGroupSecial, self.box_item)
			local item = ActivitySecretTreasureHuntAwardItem.new(secialAwardItem)

			item:setInfo(self.specialAwardDatas[i])
			table.insert(self.specialAwardItems, item)
		end
	else
		for i = 1, #self.specialAwardDatas do
			self.specialAwardItems[i]:setInfo(self.specialAwardDatas[i])
		end
	end

	self.itemGroupSecial_Grid:Reposition()
end

function ActivitySecretTreasureHuntAwardWindow:Register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_secret_treasure_hunt_award_window")
	end
end

function ActivitySecretTreasureHuntAwardItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ActivitySecretTreasureHuntAwardItem:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.labelChange = self.go:ComponentByName("labelChange", typeof(UILabel))
end

function ActivitySecretTreasureHuntAwardItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.dragScrollView = params.dragScrollView
	self.item_id = params.item_id
	self.item_num = params.item_num
	self.change = params.change
	local type = xyd.tables.itemTable:getType(self.item_id)

	if not self.icon then
		self.itemIcon = xyd.getItemIcon({
			scale = 0.8981481481481481,
			uiRoot = self.iconPos,
			dragScrollView = self.dragScrollView
		})
		self.heroIcon = xyd.getItemIcon({
			scale = 0.8981481481481481,
			uiRoot = self.iconPos,
			dragScrollView = self.dragScrollView
		}, xyd.ItemIconType.HERO_ICON)
	end

	if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
		self.heroIcon:getIconRoot():SetActive(true)

		self.icon = self.heroIcon

		self.itemIcon:getIconRoot():SetActive(false)
	else
		self.heroIcon:getIconRoot():SetActive(false)

		self.icon = self.itemIcon

		self.itemIcon:getIconRoot():SetActive(true)
	end

	self.icon:setInfo({
		scale = 0.8981481481481481,
		itemID = self.item_id,
		num = self.item_num,
		dragScrollView = self.dragScrollView
	})

	self.labelChange.text = self.change * 100 .. "%"
end

function ActivitySecretTreasureHuntTreasureItem:ctor(go, parent)
	ActivitySecretTreasureHuntTreasureItem.super.ctor(self, go, parent)
end

function ActivitySecretTreasureHuntTreasureItem:initUI()
	local go = self.go
	self.bg_ = self.go:ComponentByName("bg_", typeof(UISprite))
	self.treasureGroup = self.go:ComponentByName("treasureGroup", typeof(UISprite))
	self.labelTreasureIndex = self.treasureGroup:ComponentByName("labelTreasureIndex", typeof(UILabel))
	self.tresureItemGroup = self.go:NodeByName("tresureItemGroup").gameObject
	self.tresureItemGroup_layout = self.go:ComponentByName("tresureItemGroup", typeof(UILayout))
	self.line = self.go:ComponentByName("line", typeof(UISprite))
end

function ActivitySecretTreasureHuntTreasureItem:updateInfo()
	self.id = self.data.id
	self.award = self.data.award
	self.awarded = self.data.awarded
	self.light = self.data.light
	self.labelTreasureIndex.text = self.id
	local type = xyd.tables.itemTable:getType(self.award[1])

	if self.icon == nil then
		self.itemIcon = xyd.getItemIcon({
			scale = 0.7037037037037037,
			uiRoot = self.tresureItemGroup,
			dragScrollView = self.parent.treasureScroller
		})
		self.heroIcon = xyd.getItemIcon({
			scale = 0.7037037037037037,
			uiRoot = self.tresureItemGroup,
			dragScrollView = self.parent.treasureScroller
		}, xyd.ItemIconType.HERO_ICON)
	end

	if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
		self.heroIcon:getIconRoot():SetActive(true)

		self.icon = self.heroIcon

		self.itemIcon:getIconRoot():SetActive(false)
	else
		self.heroIcon:getIconRoot():SetActive(false)

		self.icon = self.itemIcon

		self.itemIcon:getIconRoot():SetActive(true)
	end

	local params = {
		show_has_num = false,
		scale = 0.7037037037037037,
		itemID = self.award[1],
		num = self.award[2],
		dragScrollView = self.parent.treasureScroller
	}

	self.icon:setEffectState(false)

	if self.light == 1 then
		params.effect = "bp_available"
	end

	self.icon:setInfo(params)
	self.icon:setMask(self.awarded)
	self.icon:setChoose(self.awarded)
end

return ActivitySecretTreasureHuntAwardWindow
