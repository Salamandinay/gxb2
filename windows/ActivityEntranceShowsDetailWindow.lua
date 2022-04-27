local ActivityEntranceShowsDetailWindow = class("ActivityEntranceShowsDetailWindow", import(".BaseWindow"))
local PartnerStationBattleDetailItem = class("PartnerStationBattleDetailItem", import("app.components.BaseComponent"))
local Monster = import("app.models.Monster")
local HeroIcon = import("app.components.HeroIcon")

function ActivityEntranceShowsDetailWindow:ctor(name, params)
	ActivityEntranceShowsDetailWindow.super.ctor(self, name, params)

	self.nowGroup_ = params.group
end

function ActivityEntranceShowsDetailWindow:initWindow()
	ActivityEntranceShowsDetailWindow.super.initWindow(self)
	self:getComponent()

	self.labelTitle.text = __("ACTIVITY_SPORTS_PARTY_DETAIL_WINDOW")
	self.changeBtnLabel.text = __("ACTIVITY_SPORTS_EXCHANGE_GROUP")

	self:updateGroupShow()
	self:initDataGroup()
	self:updateNowGroup()
end

function ActivityEntranceShowsDetailWindow:getComponent()
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

function ActivityEntranceShowsDetailWindow:updateNowGroup()
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

function ActivityEntranceShowsDetailWindow:updateGroupShow()
	local str = nil

	if self.nowGroup_ == 1 then
		str = __("ACTIVITY_SPORTS_NOW_LOOK_GROUP", __("ACTIVITY_SPORTS_RED"))
	else
		str = __("ACTIVITY_SPORTS_NOW_LOOK_GROUP", __("ACTIVITY_SPORTS_BLUE"))
	end

	self.tipWords.text = str
end

function ActivityEntranceShowsDetailWindow:initDataGroup()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	local dayIndex = activityData:getDayIndex()
	local monster1 = xyd.tables.activityEntranceTestGuessBattle:getMonster1(dayIndex)
	local monster2 = xyd.tables.activityEntranceTestGuessBattle:getMonster2(dayIndex)
	self.pInfoList1_ = {}
	self.pInfoList2_ = {}

	for i = 1, #monster1 do
		local partnerInfo = xyd.tables.activityEntranceTestMonsterTable:getPartnerData(monster1[i])

		table.insert(self.pInfoList1_, partnerInfo)
		PartnerStationBattleDetailItem.new(self.grid.gameObject, {
			info = partnerInfo,
			list = self.pInfoList1_,
			index = i
		})
	end

	for i = 1, #monster2 do
		local partnerInfo = xyd.tables.activityEntranceTestMonsterTable:getPartnerData(monster2[i])

		table.insert(self.pInfoList2_, partnerInfo)
		PartnerStationBattleDetailItem.new(self.grid2.gameObject, {
			info = partnerInfo,
			list = self.pInfoList2_,
			index = i
		})
	end
end

function PartnerStationBattleDetailItem:ctor(parentGo, params, parent)
	PartnerStationBattleDetailItem.super.ctor(self, parentGo)

	self.parent_ = parent
	self.info = params.info
	self.list = params.list
	self.index = params.index

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
		local np = self.info
		local table_id = np.tableID
		local params = {
			hide_btn = true,
			partner = self.info,
			table_id = table_id,
			partner_list = self.list,
			index = self.index
		}

		xyd.WindowManager.get():openWindow("activity_entrance_test_partner_window", params)
	end
end

function PartnerStationBattleDetailItem:layout()
	local partner = self.info
	local info = partner:getInfo()
	local attrs = partner:getBattleAttrs()
	local icon = HeroIcon.new(self.groupIcon)
	info.noClick = true

	icon:setInfo(info)
	icon:setScale(0.76)

	self.labelName.text = xyd.tables.partnerTable:getName(info.tableID)
	self.labelLife.text = ": " .. tostring(math.floor(attrs.hp))
	self.labelAtk.text = ": " .. tostring(math.floor(attrs.atk))
	self.labelDef.text = ": " .. tostring(math.floor(attrs.arm))
	self.labelSpeed.text = ": " .. tostring(math.floor(attrs.spd))
end

return ActivityEntranceShowsDetailWindow
