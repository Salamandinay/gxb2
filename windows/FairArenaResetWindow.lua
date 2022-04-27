local BaseWindow = import(".BaseWindow")
local FairArenaResetWindow = class("FairArenaResetWindow", BaseWindow)
local FairArenaResetItem = class("FairArenaResetItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local HeroIcon = import("app.components.HeroIcon")

function FairArenaResetWindow:ctor(name, params)
	FairArenaResetWindow.super.ctor(self, name, params)

	self.type = params.type
end

function FairArenaResetWindow:playOpenAnimation(callback)
	FairArenaResetWindow.super.playOpenAnimation(self, callback)
	self.topGroup:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -1090, 0)

	self.top_tween = self:getSequence()

	self.top_tween:Append(self.topGroup.transform:DOLocalMoveY(150, 0.5))
	self.top_tween:AppendCallback(function ()
		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = self:getSequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-280, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function FairArenaResetWindow:initWindow()
	FairArenaResetWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function FairArenaResetWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.topGroup = winTrans:NodeByName("topGroup").gameObject
	self.titleLabel_ = self.topGroup:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.selectGroup = self.topGroup:NodeByName("selectGroup").gameObject
	self.selectLabel_ = self.selectGroup:ComponentByName("selectLabel_", typeof(UILabel))
	self.resetBtn_ = self.selectGroup:NodeByName("resetBtn_").gameObject
	self.resetBtnLabel_ = self.resetBtn_:ComponentByName("button_label", typeof(UILabel))
	self.myIcon_ = self.selectGroup:NodeByName("myIconGroup/myIcon_").gameObject
	self.chooseGroup = winTrans:NodeByName("chooseGroup").gameObject
	self.tipsLabel1_ = self.chooseGroup:ComponentByName("tipsLabel1_", typeof(UILabel))
	self.tipsLabel2_ = self.chooseGroup:ComponentByName("tipsLabel2_", typeof(UILabel))
	self.scrollerView = self.chooseGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = self.chooseGroup:NodeByName("scroller_/itemGroup").gameObject
	self.hero_root = self.chooseGroup:NodeByName("scroller_/hero_root").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollerView, wrapContent, self.hero_root, FairArenaResetItem, self)
end

function FairArenaResetWindow:initUIComponent()
	self.titleLabel_.text = __("RESET")
	self.selectLabel_.text = __("FAIR_ARENA_DESC_RESET")
	self.resetBtnLabel_.text = __("SURE")
	self.tipsLabel1_.text = __("FAIR_ARENA_TEAM_PARTNER2")
	self.tipsLabel2_.text = __("FAIR_ARENA_NOTES_PRESS")
	self.partners = xyd.models.fairArena:getPartners()
	local collection = {}

	for i = 1, #self.partners do
		local p = self.partners[i]

		table.insert(collection, {
			id = p:getPartnerID(),
			box_table_id = p.box_table_id,
			info = p:getInfo()
		})
	end

	self.wrapContent:setInfos(collection, {})
end

function FairArenaResetWindow:register()
	FairArenaResetWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_RESET, handler(self, function ()
		xyd.WindowManager.get():closeWindow("fair_arena_reset_window")
	end))

	UIEventListener.Get(self.myIcon_).onClick = handler(self, self.onClickSelectedHeroIcon)
	UIEventListener.Get(self.resetBtn_).onClick = handler(self, self.onReset)

	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_EQUIP, handler(self, self.updateEquipShow))
end

function FairArenaResetWindow:updateEquipShow()
	local items = self.wrapContent:getItems()

	for i in pairs(items) do
		items[i]:updateShowEquip()
	end

	if self.copyIcon then
		self:updateTopPartnerEquipShow()
	end
end

function FairArenaResetWindow:setSelectedPartnerIcon(heroIcon)
	self.selectedIcon = heroIcon
end

function FairArenaResetWindow:onClickheroIcon(id, table_id, heroIcon, needAnimation)
	local heroInfo = heroIcon:getPartnerInfo()

	if self.selectedId ~= nil then
		if self.selectedId == heroInfo.partnerID then
			self.selectedId = nil
			self.selectedTableId = nil
			heroIcon.choose = false

			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end

			NGUITools.DestroyChildren(self.myIcon_.transform)

			return
		else
			return
		end
	end

	self.selectedId = id
	self.selectedTableId = table_id
	heroIcon.choose = true
	local copyIcon = HeroIcon.new(self.myIcon_)
	local partnerInfo = heroIcon:getPartnerInfo()
	self.selectedIcon = heroIcon

	copyIcon:setInfo(partnerInfo)

	self.copyIcon = copyIcon

	self:updateTopPartnerEquipShow()

	if needAnimation then
		local nowVectoryPos = self.myIcon_.transform.position
		copyIcon:getIconRoot().transform.position = heroIcon:getIconRoot().transform.position
		self.copyIcon_tween = self:getSequence()

		self.copyIcon_tween:Append(copyIcon:getIconRoot().transform:DOMove(nowVectoryPos, 0.2))
		self.copyIcon_tween:AppendCallback(function ()
			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end
		end)
	end
end

function FairArenaResetWindow:onClickSelectedHeroIcon()
	if not self.selectedId then
		return
	end

	self.selectedId = nil
	self.selectedTableId = nil

	if self.selectedIcon then
		self.selectedIcon.choose = false
	end

	NGUITools.DestroyChildren(self.myIcon_.transform)

	self.copyIcon = nil
end

function FairArenaResetWindow:isSelected(partnerId)
	if self.selectedId and partnerId == self.selectedId then
		return true
	else
		return false
	end
end

function FairArenaResetWindow:onReset()
	if not self.selectedId then
		xyd.alertTips(__("FAIR_ARENA_RESET_NEED_ONE"))

		return
	end

	if self.type > 1 and #self.partners == 1 then
		xyd.alertTips(__("ALTAR_DECOMPOSE_TIP2"))

		return
	end

	local ind = self:checkIsUp()

	local function callback()
		for i = 1, #self.nowPartnerList do
			if self.selectedId < self.nowPartnerList[i] then
				self.nowPartnerList[i] = self.nowPartnerList[i] - 1
			end
		end

		local formation = {
			partners = self.nowPartnerList
		}

		xyd.models.fairArena:saveLocalformation(formation)
	end

	if ind > 0 then
		xyd.alertYesNo(__("FAIR_ARENA_TIPS_RESET_UNLOCK"), function (yes)
			if yes then
				self.nowPartnerList[ind] = 0

				xyd.models.fairArena:reqReset(self.type, self.selectedId, self.selectedTableId)
				callback()
			end
		end)
	else
		xyd.models.fairArena:reqReset(self.type, self.selectedId, self.selectedTableId)
		callback()
	end
end

function FairArenaResetWindow:checkIsUp()
	if not self.nowPartnerList then
		self.nowPartnerList = xyd.models.fairArena:readStorageFormation()
	end

	return xyd.arrayIndexOf(self.nowPartnerList, self.selectedId)
end

function FairArenaResetWindow:updateTopPartnerEquipShow()
	if self.copyIcon then
		local need_partner_info = xyd.models.fairArena:getPartnerByID(self.selectedId)
		self.equipID = need_partner_info:getEquipment()[6] or 0

		self.copyIcon:initEquipId(self.equipID)
	end
end

function FairArenaResetItem:ctor(go, parent)
	FairArenaResetItem.super.ctor(self, go, parent)

	self.heroIcon = HeroIcon.new(self.go)
end

function FairArenaResetItem:updateInfo()
	self.id = self.data.id
	self.box_table_id = self.data.box_table_id
	self.info = self.data.info
	self.info.noClick = true
	self.info.isShowSelected = false

	self.heroIcon:setInfo(self.info)
	self:updateShowEquip()

	local isChoose = self.parent:isSelected(self.id)
	self.heroIcon.choose = isChoose

	if isChoose then
		self.parent:setSelectedPartnerIcon(self.heroIcon)
	end
end

function FairArenaResetItem:registerEvent()
	UIEventListener.Get(self.go).onClick = handler(self, function ()
		self.parent:onClickheroIcon(self.id, self.box_table_id, self.heroIcon, not self.heroIcon.choose)
	end)

	UIEventListener.Get(self.go).onLongPress = function (go)
		xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
			partnerID = self.id,
			list = xyd.models.fairArena:getPartnerIds()
		})
	end
end

function FairArenaResetItem:updateShowEquip()
	if self.id and self.id > 0 then
		local need_partner_info = xyd.models.fairArena:getPartnerByID(self.id)
		self.equipID = need_partner_info:getEquipment()[6] or 0

		self.heroIcon:initEquipId(self.equipID)
	end
end

return FairArenaResetWindow
