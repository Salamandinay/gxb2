local BaseWindow = import(".BaseWindow")
local ChoosePartnerWithFilterWindow = class("ChoosePartnerWithFilterWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")
local PartnerIcon = class("PartnerIcon")

function ChoosePartnerWithFilterWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.filterIndex = 0
	self.items = {}
	self.selected = params.partners or {}
	self.choosePartners = {}

	for _, id in pairs(self.selected) do
		self.choosePartners[id] = true
	end

	self.confirmCallback = params.confirmCallback
	self.needNum = params.needNum or #self.params.benchPartners
	self.closeCallback = params.closeCallback
end

function ChoosePartnerWithFilterWindow:initWindow()
	self:getUIComponent()
	ChoosePartnerWithFilterWindow.super.initWindow(self)
	self:updateData()
	self:initUIComponent()
	self:register()
end

function ChoosePartnerWithFilterWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("wrapContent", typeof(MultiRowWrapContent))
	local partnerContainer = self.scrollView:NodeByName("partnerContainer").gameObject

	partnerContainer:SetActive(false)

	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, wrapContent, partnerContainer, PartnerIcon, self)
	local filterGroup = groupAction:NodeByName("filterGroup").gameObject

	for i = 0, 6 do
		self["filter" .. i] = filterGroup:NodeByName("group" .. i).gameObject
		self["filterChosen" .. i] = self["filter" .. i]:NodeByName("chosen").gameObject
	end

	self.sureBtn = groupAction:NodeByName("sureBtn").gameObject
	self.sureBtnLabel = self.sureBtn:ComponentByName("button_label", typeof(UILabel))
	self.groupNone = groupAction:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function ChoosePartnerWithFilterWindow:initUIComponent()
	self.labelTitle.text = __("SHENXUE_TEXT04")
	self.sureBtnLabel.text = __("CONFIRM")
	self.labelNoneTips.text = __("NO_PARTNER")

	for i = 0, 6 do
		self["filterChosen" .. i]:SetActive(i == self.filterIndex)
	end

	self:updateData()
end

function ChoosePartnerWithFilterWindow:updateData()
	self.infos = {}

	dump(self.params.benchPartners)

	for key in pairs(self.params.benchPartners) do
		local partner = self.params.benchPartners[key]

		if self.filterIndex == 0 or partner:getGroup() == self.filterIndex then
			self:addPartnerToContainer(partner)
		end
	end

	if #self.infos <= 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)
	end

	self.multiWrap_:setInfos(self.infos, {})
	self.multiWrap_:resetPosition()
	self.scrollView:ResetPosition()
end

function ChoosePartnerWithFilterWindow:addPartnerToContainer(partner)
	local partnerID = partner:getPartnerID()
	local params = partner:getInfo()
	params.choose = false
	params.noClickSelected = true
	local lockType = partner:getLockType()
	params.lockType = lockType
	params.isShowLovePoint = true

	if self.isShowLovePoint_ ~= nil then
		params.isShowLovePoint = self.isShowLovePoint_
	end

	function params.callback(icon)
		local lockType = partner:getLockType()

		if lockType ~= 0 then
			if xyd.checkLast(partner) then
				xyd.showToast(__("UNLOCK_FAILED"))
			elseif xyd.checkDateLock(partner) then
				xyd.showToast(__("DATE_LOCK_FAIL"))
			elseif xyd.checkQuickFormation(partner) then
				xyd.showToast(__("QUICK_FORMATION_TEXT21"))
			elseif xyd.checkGalaxyFormation(partner) then
				xyd.showToast(__("GALAXY_TRIP_TIPS_20"))
			else
				local str = __("IF_UNLOCK_HERO_3")

				xyd.alert(xyd.AlertType.YES_NO, str, function (yes_no)
					if yes_no then
						local succeed = xyd.partnerUnlock(partner)
						partner = xyd.models.slot:getPartner(partner:getPartnerID())

						if succeed then
							icon.lock = false
						else
							xyd.showToast(__("UNLOCK_FAILED"))
						end
					end
				end)
			end

			return
		end

		local choose = self.choosePartners[partnerID]

		if #self.selected < self.needNum then
			choose = not choose or false

			if choose then
				self:addToSelected(partnerID)
			else
				self:remFromSelected(partnerID)
			end
		else
			choose = not choose or false

			if choose then
				choose = false
			else
				self:remFromSelected(partnerID)
			end
		end

		icon.choose = choose
		self.choosePartners[partnerID] = choose
	end

	table.insert(self.infos, params)
end

function ChoosePartnerWithFilterWindow:onClickFilter(filterIndex)
	self.filterIndex = filterIndex

	for i = 0, 6 do
		self["filterChosen" .. i]:SetActive(i == self.filterIndex)
	end

	self:updateData()
end

function ChoosePartnerWithFilterWindow:addToSelected(partnerID)
	table.insert(self.selected, partnerID)
end

function ChoosePartnerWithFilterWindow:remFromSelected(partnerID)
	for id = #self.selected, 1, -1 do
		if partnerID == self.selected[id] then
			table.remove(self.selected, id)
		end
	end
end

function ChoosePartnerWithFilterWindow:getSelected(partnerID)
	return self.selected
end

function ChoosePartnerWithFilterWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	for i = 0, 6 do
		UIEventListener.Get(self["filter" .. i]).onClick = function ()
			self:onClickFilter(i)
		end
	end

	UIEventListener.Get(self.sureBtn).onClick = function ()
		self.confirmCallback()
		self:close()
	end
end

function ChoosePartnerWithFilterWindow:willClose()
	self:closeCallback()
	BaseWindow.willClose(self)
end

function PartnerIcon:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.heroIcon = HeroIcon.new(go)

	self.heroIcon:setDragScrollView(parent.scrollView)
end

function PartnerIcon:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self.heroIcon:setInfo(info)

	if self.parent.choosePartners[info.partnerID] then
		self.heroIcon.choose = true
	else
		self.heroIcon.choose = false
	end

	if info.lockType ~= 0 then
		self.heroIcon.lock = true
	else
		self.heroIcon:setLockImgVisible(false)
	end
end

function PartnerIcon:getGameObject()
	return self.go
end

return ChoosePartnerWithFilterWindow
