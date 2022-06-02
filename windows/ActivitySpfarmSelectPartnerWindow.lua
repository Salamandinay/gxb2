local json = require("cjson")
local ActivitySpfarmSelectPartnerWindow = class("ActivitySpfarmSelectPartnerWindow", import(".BaseWindow"))
local MAX_NUM = 10
local PartnerFilter = import("app.components.PartnerFilter")
local HeroIconWithHP = class("HeroIconWithHP", import("app.components.HeroIcon"))
local FormationItem = class("FormationItem")
local FormationItemWithHP = class("FormationItemWithHP", FormationItem)

function FormationItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = nil

	if not self.parent_ then
		self.win_ = xyd.getWindow("battle_formation_window")
	else
		self.win_ = self.parent_
	end

	self.isFriend = false
end

function FormationItem:setIsFriend(isFriend)
	self.isFriend = isFriend
end

function FormationItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	if not self.heroIcon_ then
		self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_, self.parent_.partnerRenderPanel)
	end

	self.partner_ = info.partnerInfo
	self.partnerId_ = self.partner_.partner_id or self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false

	self.heroIcon_:setInfo(self.partner_)
	self:updateSelectState()
end

function FormationItem:updateSelectState()
	if self.partnerId_ and self.partnerId_ > 0 then
		local isSelect = self.parent_:isSelected(self.partnerId_)

		self:setIsChoose(isSelect)
	end
end

function FormationItem:onClick()
	self.parent_:onClickheroIcon(self.partner_, self.isSelected)
end

function FormationItem:setIsChoose(status)
	self.isSelected = status

	self.heroIcon_:setChoose(status)
end

function FormationItem:getHeroIcon()
	return self.heroIcon_
end

function FormationItem:getPartnerId()
	return self.partnerId_
end

function FormationItem:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function FormationItem:getGameObject()
	return self.uiRoot_
end

function HeroIconWithHP:initUI()
	HeroIconWithHP.super.initUI(self)

	self.progress = self:getPartExample("progress")
end

function FormationItemWithHP:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.progressBar = nil
end

function FormationItemWithHP:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	if not self.heroIcon_ then
		self.heroIcon_ = HeroIconWithHP.new(self.uiRoot_, self.parent_.selectPanel)
	end

	self.partner_ = info.partnerInfo
	self.partnerId_ = self.partner_.partner_id or self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false

	self.heroIcon_:setInfo(self.partner_)
	self.heroIcon_:setDargScrollView(self.parent_.selectScrollView)

	self.hp = info.hp
	self.heroIcon_.progress.value = self.hp / 100

	if self.hp <= 0 then
		xyd.applyChildrenGrey(self.uiRoot_)
	else
		xyd.applyChildrenOrigin(self.uiRoot_)
	end

	self.isSelected = true
end

function ActivitySpfarmSelectPartnerWindow:ctor(name, params)
	ActivitySpfarmSelectPartnerWindow.super.ctor(self, name, params)

	self.SlotModel = xyd.models.slot

	self:readStorageFormation()
end

function ActivitySpfarmSelectPartnerWindow:readStorageFormation()
	if self.defPartners and #self.defPartners > 0 then
		return
	end

	local dbVal = xyd.db.formation:getValue("spfram_select_partner_list")

	if not dbVal then
		self.defPartners = {}

		return
	end

	self.defPartners = json.decode(dbVal)
end

function ActivitySpfarmSelectPartnerWindow:initWindow()
	ActivitySpfarmSelectPartnerWindow.super.initWindow(self)
	self:getUIComponent()
	self:updateForceNum()
	self:updateTopList()
	self:setLabel()
	self:initPartnerList()
	self:register()
end

function ActivitySpfarmSelectPartnerWindow:register()
	UIEventListener.Get(self.sureBtn_).onClick = function ()
		self:saveLocalformation()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivitySpfarmSelectPartnerWindow:updateTopList(keepPosition)
	self.partnerMultiWrap_:setInfos(self.defPartners, {
		keepPosition = keepPosition
	})
end

function ActivitySpfarmSelectPartnerWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.selectGroup_ = winTrans:NodeByName("selectGroup")
	self.closeBtn_ = self.selectGroup_:NodeByName("closeBtn").gameObject
	self.titleLabel_ = self.selectGroup_:ComponentByName("labelTitle", typeof(UILabel))
	self.labelTips_ = self.selectGroup_:ComponentByName("labelTips", typeof(UILabel))
	self.heroRoot_ = self.selectGroup_:NodeByName("heroRoot").gameObject
	self.selectScrollView = self.selectGroup_:ComponentByName("scroller", typeof(UIScrollView))
	self.selectPanel = self.selectGroup_:ComponentByName("scroller", typeof(UIPanel))
	self.itemGroup = self.selectGroup_:ComponentByName("scroller/itemGroup", typeof(MultiRowWrapContent))
	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.selectScrollView, self.itemGroup, self.heroRoot_, FormationItemWithHP, self)
	self.sureBtn_ = self.selectGroup_:NodeByName("sureBtn").gameObject
	self.sureBtnLabel_ = self.sureBtn_:ComponentByName("button_label", typeof(UILabel))
	self.chooseGroup = winTrans:Find("choose_group")
	self.chooseGroupWidget = self.chooseGroup:GetComponent(typeof(UIWidget))
	local height = xyd.Global.getRealHeight()
	self.chooseGroupWidget.height = (height - 1280) / 279 * 169 + 464
	self.fGroup = self.chooseGroup:Find("f_group")
	self.partnerScrollView = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIScrollView))
	self.partnerRenderPanel = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIPanel))
	self.partnerScroller_uiPanel = self.chooseGroup:ComponentByName("partner_scroller", typeof(UIPanel))
	self.partnerListWarpContent_ = self.chooseGroup:ComponentByName("partner_scroller/partner_container", typeof(MultiRowWrapContent))

	self:waitForFrame(1, function ()
		self.selectScrollView:ResetPosition()
	end)
end

function ActivitySpfarmSelectPartnerWindow:initPartnerList()
	local scale = 0.9
	local params = {
		isCanUnSelected = 1,
		chosenGroup = 0,
		gap = 20,
		callback = handler(self, function (self, group)
			self:onSelectGroup(group)
		end),
		width = self.fGroup:GetComponent(typeof(UIWidget)).width,
		scale = scale
	}
	local partnerFilter = PartnerFilter.new(self.fGroup.gameObject, params)
	self.partnerFilter = partnerFilter
	self.partnerListWarpContent_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot_, FormationItem, self)

	self:iniPartnerData(0)
end

function ActivitySpfarmSelectPartnerWindow:iniPartnerData(groupID, keepPosition)
	local partnerDataList = self:initNormalPartnerData(groupID)
	self.partnerScrollView.enabled = true
	self.partnerDataList_ = partnerDataList

	self.partnerListWarpContent_:setInfos(partnerDataList, {})
end

function ActivitySpfarmSelectPartnerWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	self.selectGroup_ = group
	self.currentGroup_ = group

	if self.filterGroupArctic then
		self.sortByPartnerArctic = false

		self.filterGroupArcticChooseImg:SetActive(false)
	end

	self:iniPartnerData(group, false)
end

function ActivitySpfarmSelectPartnerWindow:initNormalPartnerData(groupID)
	local partnerList = self.SlotModel:getSortedPartners()
	local lvSortedList = partnerList[tostring(xyd.partnerSortType.isCollected) .. "_0"]
	local partnerDataList = {}
	self.power = 0

	for _, partnerId in ipairs(lvSortedList) do
		if partnerId ~= 0 then
			local partnerInfo = self.SlotModel:getPartner(tonumber(partnerId))
			partnerInfo.noClick = true
			local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.tableID)
			local isS = self:isSelected(partnerId)
			local data = {
				callbackFunc = handler(self, function (a, callbackPInfo, callbackIsChoose)
					self:onClickheroIcon(callbackPInfo, callbackIsChoose)
				end),
				partnerInfo = partnerInfo,
				isSelected = isS
			}

			if isS then
				table.insert(partnerDataList, data)
			elseif groupID == 0 or pGroupID == groupID then
				table.insert(partnerDataList, data)
			end
		end
	end

	return partnerDataList
end

function ActivitySpfarmSelectPartnerWindow:isSelected(partnerId)
	for _, info in ipairs(self.defPartners) do
		if partnerId == info.partnerInfo.partnerID then
			return true
		end
	end

	return false
end

function ActivitySpfarmSelectPartnerWindow:onClickheroIcon(partnerInfo, isChoose)
	xyd.SoundManager.get():playSound("2037")

	if isChoose then
		for index, info in ipairs(self.defPartners) do
			if partnerInfo.partnerID == info.partnerInfo.partnerID then
				table.remove(self.defPartners, index)

				break
			end
		end

		self:updateTopList(true)
	else
		local hp = 100
		local params = {
			hp = hp,
			partnerInfo = partnerInfo
		}
		local deadList = {}
		local liveList = {}

		for _, info in ipairs(self.defPartners) do
			if info.hp > 0 then
				table.insert(liveList, info)
			else
				table.insert(deadList, info)
			end
		end

		if hp > 0 then
			table.insert(liveList, params)
		else
			table.insert(deadList, params)
		end

		self.defPartners = xyd.arrayMerge(liveList, deadList)

		self:updateTopList(true)
	end

	local items = self.partnerListWarpContent_:getItems()

	for _, item in ipairs(items) do
		if item.partnerId_ and item.partnerId_ == partnerInfo.partnerID then
			item:updateSelectState()

			break
		end
	end

	self:updateForceNum()
end

function ActivitySpfarmSelectPartnerWindow:updateForceNum()
	self.labelTips_.text = "出战战姬" .. #self.defPartners .. "/" .. MAX_NUM
end

function ActivitySpfarmSelectPartnerWindow:setLabel()
	self.titleLabel_.text = "战姬选择"
	self.sureBtnLabel_.text = __("SURE")
end

function ActivitySpfarmSelectPartnerWindow:longPressIcon(copyIcon)
	self:showPartnerDetail(copyIcon:getPartnerInfo())
end

function ActivitySpfarmSelectPartnerWindow:showPartnerDetail(partnerInfo)
	if xyd.GuideController.get():isPlayGuide() then
		return
	end

	if not partnerInfo then
		return
	end

	local closeBefore = false
	local params = {
		unable_move = true,
		isLongTouch = true,
		sort_key = "0_0",
		not_open_slot = true,
		partner_id = partnerInfo.partnerID,
		table_id = partnerInfo.tableID,
		battleData = self.params_,
		ifSchool = self.battleType == xyd.BattleType.ACADEMY_ASSESSMENT,
		skin_id = partnerInfo.skin_id
	}
	local wndName = "partner_detail_window"
	local showTime = xyd.tables.partnerPictureTable:getShowTime(params.skin_id)

	if params.skin_id and showTime and xyd.getServerTime() < showTime then
		params.skin_id = nil
	end

	self:saveLocalformation()
	xyd.openWindow(wndName, params, function ()
		if closeBefore then
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)
end

function ActivitySpfarmSelectPartnerWindow:saveLocalformation()
	local dbParams = {
		key = "spfram_select_partner_list",
		value = json.encode(self.defPartners)
	}

	xyd.db.formation:addOrUpdate(dbParams)
end

function ActivitySpfarmSelectPartnerWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	self.selectGroup_:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -858, 0)

	local y1 = 517
	self.top_tween = self:getSequence()

	self.top_tween:Append(self.selectGroup_.transform:DOLocalMoveY(y1, 0.5))
	self.top_tween:AppendCallback(function ()
		self:setWndComplete()

		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = self:getSequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-78, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

return ActivitySpfarmSelectPartnerWindow
