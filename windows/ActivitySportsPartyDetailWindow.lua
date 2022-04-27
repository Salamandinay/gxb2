local ActivitySportsPartyDetailWindow = class("ActivitySportsPartyDetailWindow", import(".BaseWindow"))
local PartnerStationBattleDetailItem = class("PartnerStationBattleDetailItem", import("app.components.BaseComponent"))
local Monster = import("app.models.Monster")
local HeroIcon = import("app.components.HeroIcon")

function ActivitySportsPartyDetailWindow:ctor(name, params)
	ActivitySportsPartyDetailWindow.super.ctor(self, name, params)

	self.nowGroup_ = params.group
end

function ActivitySportsPartyDetailWindow:initWindow()
	ActivitySportsPartyDetailWindow.super.initWindow(self)
	self:getComponent()

	self.labelTitle.text = __("ACTIVITY_SPORTS_PARTY_DETAIL_WINDOW")
	self.changeBtnLabel.text = __("ACTIVITY_SPORTS_EXCHANGE_GROUP")

	self:updateGroupShow()
	self:initDataGroup()
	self:updateNowGroup()
end

function ActivitySportsPartyDetailWindow:getComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.changeBtn = self.groupAction:NodeByName("changeBtn").gameObject
	self.changeBtnLabel = self.groupAction:ComponentByName("changeBtn/label", typeof(UILabel))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.tipWords = self.groupAction:ComponentByName("tipWords", typeof(UILabel))
	self.scrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid = self.groupAction:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.scrollView2 = self.groupAction:ComponentByName("scrollView2", typeof(UIScrollView))
	self.grid2 = self.groupAction:ComponentByName("scrollView2/grid", typeof(UIGrid))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.changeBtn).onClick = function ()
		if self.nowGroup_ == 1 then
			self.nowGroup_ = 2
		else
			self.nowGroup_ = 1
		end

		self:updateNowGroup()
		self:updateGroupShow()
	end
end

function ActivitySportsPartyDetailWindow:updateNowGroup()
	self.scrollView2.gameObject:SetActive(self.nowGroup_ == 2)
	self.scrollView.gameObject:SetActive(self.nowGroup_ == 1)

	if self.nowGroup_ == 1 then
		self.grid:Reposition()
		self.scrollView:ResetPosition()
	else
		self.grid2:Reposition()
		self.scrollView2:ResetPosition()
	end
end

function ActivitySportsPartyDetailWindow:updateGroupShow()
	local str = nil

	if self.nowGroup_ == 1 then
		str = __("ACTIVITY_SPORTS_NOW_LOOK_GROUP", __("ACTIVITY_SPORTS_RED"))
	else
		str = __("ACTIVITY_SPORTS_NOW_LOOK_GROUP", __("ACTIVITY_SPORTS_BLUE"))
	end

	self.tipWords.text = str
end

function ActivitySportsPartyDetailWindow:initDataGroup()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPORTS)
	local dayIndex = activityData:getDayIndex()
	local monster1, monster2 = nil
	monster1 = xyd.tables.activityDemoFightTable:getMonster1(dayIndex)
	monster2 = xyd.tables.activityDemoFightTable:getMonster2(dayIndex)

	for i = 1, #monster1 do
		local partner = Monster.new()

		partner:populateWithTableID(monster1[i])
		PartnerStationBattleDetailItem.new(self.grid.gameObject, {
			info = partner
		})
	end

	for i = 1, #monster2 do
		local partner = Monster.new()

		partner:populateWithTableID(monster2[i])
		PartnerStationBattleDetailItem.new(self.grid2.gameObject, {
			info = partner
		})
	end
end

function PartnerStationBattleDetailItem:ctor(parentGo, params)
	PartnerStationBattleDetailItem.super.ctor(self, parentGo)

	self.info = params.info

	self:registerEvent()
	self:layout()
end

function PartnerStationBattleDetailItem:getPrefabPath()
	return "Prefabs/Components/partner_station_battle_detail_item"
end

function PartnerStationBattleDetailItem:initUI()
	PartnerStationBattleDetailItem.super.initUI(self)

	local go = self.go
	self.attr = go:NodeByName("attr").gameObject
	self.labelLife = self.attr:ComponentByName("labelLife", typeof(UILabel))
	self.labelAtk = self.attr:ComponentByName("labelAtk", typeof(UILabel))
	self.labelDef = self.attr:ComponentByName("labelDef", typeof(UILabel))
	self.labelSpeed = self.attr:ComponentByName("labelSpeed", typeof(UILabel))
	self.btnAttrDetail = self.attr:NodeByName("btnAttrDetail").gameObject
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))
end

function PartnerStationBattleDetailItem:registerEvent()
	UIEventListener.Get(self.btnAttrDetail).onClick = function ()
		local wnd = xyd.WindowManager.get():getWindow("partner_station_battle_detail_window")

		if wnd then
			wnd:updateGroupAllAttr(self.info)
			wnd:setGroupAttrVisible(true)
		end

		local wnd2 = xyd.WindowManager.get():getWindow("activity_sports_party_detail_window")

		if wnd2 then
			xyd.WindowManager.get():openWindow("partner_info", {
				partner = self.info
			})
		end
	end
end

function PartnerStationBattleDetailItem:layout()
	local wnd = xyd.WindowManager.get():getWindow("partner_station_battle_detail_window")
	local partner = self.info
	local info = partner:getInfo()
	local attrs = partner:getBattleAttrs()
	local icon = HeroIcon.new(self.groupIcon)
	info.noClick = true

	icon:setInfo(info)
	icon:setScale(0.76)

	if wnd then
		icon:setPetFrame(wnd:getPetId())
	end

	self.labelName.text = xyd.tables.partnerTable:getName(info.tableID)
	self.labelLife.text = ": " .. tostring(math.floor(attrs.hp))
	self.labelAtk.text = ": " .. tostring(math.floor(attrs.atk))
	self.labelDef.text = ": " .. tostring(math.floor(attrs.arm))
	self.labelSpeed.text = ": " .. tostring(math.floor(attrs.spd))
end

return ActivitySportsPartyDetailWindow
