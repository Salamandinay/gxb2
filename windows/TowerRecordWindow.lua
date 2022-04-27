local BaseWindow = import(".BaseWindow")
local TowerRecordWindow = class("TowerRecordWindow", BaseWindow)
local BaseComponent = import("app.components.BaseComponent")
local TowerRecordItem = class("TowerRecordItem", BaseComponent)
local HeroIcon = import("app.components.HeroIcon")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.towerRecordItem = TowerRecordItem.new(go)

	self.towerRecordItem:setDragScrollView(parent.scrollView)
	self.go:SetActive(false)
end

function ItemRender:update(index, id)
	if not id then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	if id ~= self.towerRecordItem.data then
		self.towerRecordItem.data = id

		self.towerRecordItem:dataChanged()
	end
end

function ItemRender:getGameObject()
	return self.go
end

function TowerRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.MAX_RECORD_NUM = 100
	self.start_stage = xyd.models.towerMap.startRecordStage
	self.end_stage = xyd.models.towerMap.endRecordStage
end

function TowerRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
end

function TowerRecordWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.titleLabel = content:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = content:NodeByName("closeBtn").gameObject
	local scrollerGroup = content:NodeByName("scrollerGroup").gameObject
	self.scrollView = scrollerGroup:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("dataGroupStage", typeof(UIWrapContent))
	local iconContainer = scrollerGroup:NodeByName("container").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, iconContainer, ItemRender, self)
	self.groupNone_ = scrollerGroup:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
end

function TowerRecordWindow:setLayout()
	self.titleLabel.text = __("BATTLE_RECORD")
	self.labelNoneTips_.text = __("TOWER_RECORD_TIP_1")

	if self.start_stage == 0 or self.end_stage == 0 or self.end_stage < self.start_stage then
		self.groupNone_:SetActive(true)

		return
	end

	self.groupNone_:SetActive(false)

	local minStage = math.max(self.start_stage, self.end_stage - self.MAX_RECORD_NUM)
	local list = {}

	for i = self.end_stage, minStage, -1 do
		table.insert(list, i)
	end

	self.wrapContent:setInfos(list, {})
end

function TowerRecordWindow:showNoReportTips()
	xyd.alert(xyd.AlertType.TIPS, __("TOWER_RECORD_TIP_1"))
end

function TowerRecordItem:ctor(parentGo)
	TowerRecordItem.super.ctor(self, parentGo)

	self.MAX_RECORD_NUM = 100
	self.start_stage = xyd.models.towerMap.startRecordStage
	self.end_stage = xyd.models.towerMap.endRecordStage
end

function TowerRecordItem:getPrefabPath()
	return "Prefabs/Components/tower_record_item"
end

function TowerRecordItem:initUI()
	local go = self.go
	self.towerStage = go:ComponentByName("towerStage", typeof(UILabel))
	self.btnPractice_ = go:NodeByName("btnPractice_").gameObject
	self.btnRecord_ = go:NodeByName("btnRecord_").gameObject
	self.groupMonster_1 = go:NodeByName("groupMonster_1").gameObject
	self.groupMonster_2 = go:NodeByName("groupMonster_2").gameObject
	self.btnPractice_uiSprite = self.btnPractice_:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.btnPractice_uiSprite, nil, "btn_tower_practice")

	self.btnRecord_uiSprite = self.btnRecord_:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.btnRecord_uiSprite, nil, "btn_tower_video")
	self:setChildren()
end

function TowerRecordItem:setChildren()
	UIEventListener.Get(self.btnRecord_).onClick = function ()
		self:onRecordTouch()
	end

	UIEventListener.Get(self.btnPractice_).onClick = function ()
		self:onPracticeTouch()
	end
end

function TowerRecordItem:dataChanged()
	NGUITools.DestroyChildren(self.groupMonster_1.transform)
	NGUITools.DestroyChildren(self.groupMonster_2.transform)

	local battleID = xyd.tables.towerTable:getBattleID(self.data)
	local monsters = xyd.tables.battleTable:getMonsters(battleID)
	local minStage = math.max(self.start_stage, self.end_stage - self.MAX_RECORD_NUM)

	if self.data <= self.end_stage and minStage <= self.data then
		self.towerStage.text = __("TOWER_LEVEL", self.data)

		for i = 1, #monsters do
			local group = i <= 2 and self.groupMonster_1 or self.groupMonster_2
			local tableID = monsters[i]
			local id = xyd.tables.monsterTable:getPartnerLink(tableID)
			local lev = xyd.tables.monsterTable:getShowLev(tableID)
			local icon = HeroIcon.new(group)

			icon:setInfo({
				noClick = true,
				tableID = id,
				lev = lev
			})

			local w = icon.go:GetComponent(typeof(UIWidget))
			local scale = 86 / w.height

			icon.go:SetLocalScale(scale, scale, scale)
		end

		self.groupMonster_1:GetComponent(typeof(UIGrid)):Reposition()
		self.groupMonster_2:GetComponent(typeof(UIGrid)):Reposition()
	end
end

function TowerRecordItem:onRecordTouch()
	if xyd.models.towerMap:getMyTowerReport(self.data) then
		local data = xyd.models.towerMap:getMyTowerReport(self.data)

		if not xyd.checkReportVer(data.battle_report) then
			return
		end

		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.TOWER_SELF_REPORT,
			data = data
		})
	else
		xyd.models.towerMap:reqMyTowerReport(self.data)
	end
end

function TowerRecordItem:onPracticeTouch()
	xyd.WindowManager.get():openWindow("tower_campaign_detail_window", {
		id = self.data,
		type = xyd.BattleType.TOWER_PRACTICE
	})
end

return TowerRecordWindow
