local BaseWindow = import(".BaseWindow")
local ProphetChoosePartnerWindow = class("ProphetChoosePartnerWindow", BaseWindow)
local PartnerFilter = import("app.components.PartnerFilter")
local HeroIcon = import("app.components.HeroIcon")
local ProphetAvatar = class("ProphetAvatar")

function ProphetAvatar:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.heroIcon = HeroIcon.new(go)

	self.heroIcon:setDragScrollView(parent.scrollView)
end

function ProphetAvatar:update(index, realIndex, partner)
	if not partner then
		self.go:SetActive(false)

		return
	end

	self.data = partner:getInfo()

	self.go:SetActive(true)

	local info = partner:getInfo()

	function info.callback()
		self.heroIcon.selected = false

		if xyd.showLockTips(partner) then
			return
		end

		local wnd = xyd.WindowManager:get():getWindow("prophet_window")

		if not wnd then
			return
		end

		wnd:setReplacePartner(partner)
	end

	self.heroIcon:setInfo(info)

	if partner:isLockFlag() then
		self.heroIcon.lock = true
	else
		self.heroIcon.lock = false
	end
end

function ProphetAvatar:getGameObject()
	return self.go
end

function ProphetChoosePartnerWindow:ctor(name, params)
	ProphetChoosePartnerWindow.super.ctor(self, name, params)
end

function ProphetChoosePartnerWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
end

function ProphetChoosePartnerWindow:getUIComponent()
	local winTrasn = self.window_.transform
	self.chooseGroup = winTrasn:NodeByName("chooseGroup").gameObject
	self.groupFilter = self.chooseGroup:NodeByName("groupFilter").gameObject
	self.scrollView = self.chooseGroup:ComponentByName("partnerScroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("partnerDataGroup", typeof(MultiRowWrapContent))
	local iconContainer = self.scrollView:NodeByName("iconContainer").gameObject

	iconContainer:SetActive(false)

	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, wrapContent, iconContainer, ProphetAvatar, self)
	self.bg = winTrasn:NodeByName("bg").gameObject
	self.originY = self.chooseGroup.transform.localPosition.y
	self.height = self.chooseGroup:GetComponent(typeof(UIWidget)).height

	self:setChildren()
end

function ProphetChoosePartnerWindow:setChildren()
	self:setGroupData()
	self:setFilter()
	self:dataChanged()
end

function ProphetChoosePartnerWindow:setGroupData()
	local p_model = xyd.models.slot
	local sortedPartners = p_model:getSortedPartners()
	self.partners = {
		[0] = {},
		{},
		{},
		{},
		{},
		{}
	}

	for _, partner_id in ipairs(sortedPartners[tostring(xyd.partnerSortType.LEV) .. "_0"]) do
		local p = p_model:getPartner(partner_id)

		if p and xyd.PartnerGroup.EMO > p:getGroup() then
			if p:getStar() == 4 or p:getStar() == 5 then
				table.insert(self.partners[0], p)
			end
		end
	end

	for i = xyd.PartnerGroup.YAOJING, xyd.PartnerGroup.EMO do
		for _, partner_id in ipairs(sortedPartners[tostring(xyd.partnerSortType.LEV) .. "_" .. tostring(i)]) do
			local p = p_model:getPartner(partner_id)

			if p:getStar() == 4 or p:getStar() == 5 then
				table.insert(self.partners[i], p)
			end
		end
	end

	self.multiWrap_:setInfos(self.partners[0], {})
end

function ProphetChoosePartnerWindow:dataChanged()
	self.multiWrap_:setInfos(self.partners[self.chosenGroup] or {}, {})
end

function ProphetChoosePartnerWindow:setFilter()
	self.chosenGroup = 0
	local params = {
		gap = 16,
		callback = handler(self, function (self, pickType)
			self.chosenGroup = pickType

			self:dataChanged()
		end)
	}
	local partnerFilter = PartnerFilter.new(self.groupFilter, params)

	partnerFilter:hideEvilAngel()

	self.partnerFilter = partnerFilter

	self.partnerFilter:setGap(90)
end

function ProphetChoosePartnerWindow:reset()
	self.chosenGroup = 0

	self:dataChanged()
	self.partnerFilter:reset()
	self:setTouchClose()
end

function ProphetChoosePartnerWindow:resetItem(partnerID)
	local p = xyd.models.slot:getPartner(partnerID)
	local group = p:getGroup()
	local source = self.partners[group]

	for i = 1, #source do
		if source[i]:getPartnerID() == partnerID then
			source[i] = xyd.models.slot:getPartner(partnerID)
		end
	end

	source = self.partners[0]

	for i = 1, #source do
		if source[i]:getPartnerID() == partnerID then
			source[i] = xyd.models.slot:getPartner(partnerID)
		end
	end

	self.multiWrap_:setInfos(self.partners[self.chosenGroup], {
		keepPosition = true
	})
end

function ProphetChoosePartnerWindow:setTouchClose()
	UIEventListener.Get(self.bg).onClick = function ()
		self:setVisibleEase(false)
	end
end

function ProphetChoosePartnerWindow:setVisibleEase(visible)
	local transform = self.chooseGroup.transform
	local widget = self.chooseGroup:GetComponent(typeof(UIWidget))

	if visible == true then
		local to = self.originY
		local from = to - widget.height / 2

		self.window_:SetActive(true)
		self.chooseGroup.transform:SetLocalPosition(transform.localPosition.x, from, 0)

		local action = DG.Tweening.DOTween.Sequence()

		action:Append(self.chooseGroup.transform:DOLocalMoveY(to, 0.14))
		action:AppendCallback(function ()
			action:Kill(false)

			action = nil
		end)

		return
	end

	local to = self.originY - widget.height / 2
	local action = DG.Tweening.DOTween.Sequence()

	action:Append(self.chooseGroup.transform:DOLocalMoveY(to, 0.14))
	action:AppendCallback(function ()
		action:Kill(false)

		action = nil

		self.window_:SetActive(false)
	end)
end

return ProphetChoosePartnerWindow
