local BaseWindow = import(".BaseWindow")
local WishCapsuleSelectWindow = class("ProphetChoosePartnerWindow", BaseWindow)
local WishCapsuleSelectItem = class("WishCapsuleSelectItem")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local PartnerFilter = import("app.components.PartnerFilter")
local Partner = import("app.models.Partner")
local cjson = require("cjson")

function WishCapsuleSelectWindow:ctor(name, params)
	WishCapsuleSelectWindow.super.ctor(self, name, params)

	self.allParams = {}
	self.titleText = self.params_.titleText
	self.selectChoiceId = self.params_.selectChoiceId or -1
	local sortedPartners = xyd.tables.miscTable:split2Cost("wish_gacha_partners", "value", "|")

	for i in pairs(sortedPartners) do
		local np = Partner.new()

		np:populate({
			table_id = sortedPartners[i]
		})

		local param = {
			partnerID = sortedPartners[i],
			isSelected = sortedPartners[i] == self.selectChoiceId,
			partnerInfo = np
		}

		if param.isSelected == true then
			self.originInfo = param
			self.originIndex = i
		end

		table.insert(self.allParams, param)
	end
end

function WishCapsuleSelectWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initPartnerList()
	self:registerEvent()

	if self.selectChoiceId ~= -1 then
		self:selectPartner(self.originInfo, self.originIndex, true)
	end
end

function WishCapsuleSelectWindow:getUIComponent()
	local winTrasn = self.window_.transform
	self.showGroup = winTrasn:NodeByName("showGroup").gameObject
	self.textLabel = self.showGroup:ComponentByName("textLabel", typeof(UILabel))
	self.closeBtn = self.showGroup:NodeByName("closeBtn").gameObject
	self.effectCon = self.showGroup:NodeByName("effectCon").gameObject
	self.cancelBtn = self.showGroup:NodeByName("cancelBtn").gameObject
	self.cancelBtn_label = self.showGroup:ComponentByName("cancelBtn/label", typeof(UILabel))
	self.sureBtn = self.showGroup:NodeByName("sureBtn").gameObject
	self.sureBtn_label = self.showGroup:ComponentByName("sureBtn/label", typeof(UILabel))
	self.touchField = self.showGroup:NodeByName("touchField").gameObject

	self.touchField:SetActive(false)

	self.chooseGroup = winTrasn:NodeByName("chooseGroup").gameObject
	self.groupFilter = self.chooseGroup:NodeByName("groupFilter").gameObject
	self.scrollView = self.chooseGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.partnerScrollView = self.chooseGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.partnerRenderPanel = self.scrollView:GetComponent(typeof(UIPanel))
	local selectItem = self.chooseGroup:NodeByName("selectItem").gameObject
	local itemGroup = self.scrollView:ComponentByName("itemGroup", typeof(MultiRowWrapContent))
	local wrapContent = itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, selectItem, WishCapsuleSelectItem, self)
	self.textLabel.text = self.titleText and __(self.titleText) or __("WISH_GACHA_SELECT_PARTNER_WINDOW")
	self.cancelBtn_label.text = __("CANCEL_2")
	self.sureBtn_label.text = __("SURE")
end

function WishCapsuleSelectWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	self.showGroup:SetLocalPosition(0, 1200, 0)
	self.chooseGroup:SetLocalPosition(0, -1090, 0)

	self.top_tween = DG.Tweening.DOTween.Sequence()

	self.top_tween:Append(self.showGroup.transform:DOLocalMoveY(214, 0.5))
	self.top_tween:AppendCallback(function ()
		self:setWndComplete()

		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = DG.Tweening.DOTween.Sequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-405, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function WishCapsuleSelectWindow:playCloseAnimation(callback)
	if self.down_tween then
		self.down_tween:Kill(true)
	end

	if self.top_tween then
		self.top_tween:Kill(true)
	end

	WishCapsuleSelectWindow.super.playCloseAnimation(self, callback)
end

function WishCapsuleSelectWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.cancelBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.sureBtn.gameObject).onClick = handler(self, function ()
		if self.selectChoiceId == -1 then
			xyd.alertTips(__("WISH_GACHA_SELECT_PARTNER_TIPS_1"))
		else
			local sortedPartners = xyd.tables.miscTable:split2Cost("wish_gacha_partners", "value", "|")
			local selectId = -1

			for i in pairs(sortedPartners) do
				if tonumber(sortedPartners[i]) == self.selectChoiceId then
					selectId = i

					break
				end
			end

			if selectId ~= -1 then
				local params = {
					select_index = selectId,
					table_id = sortedPartners[selectId]
				}
				local data = cjson.encode(params)
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.WISH_CAPSULE
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			end
		end
	end)
end

function WishCapsuleSelectWindow:initPartnerList()
	local params = {
		isCanUnSelected = 1,
		chosenGroup = 0,
		scale = 1,
		gap = 20,
		callback = handler(self, function (self, group)
			self:onSelectGroup(group)
		end),
		width = self.groupFilter:GetComponent(typeof(UIWidget)).width
	}
	local partnerFilter = PartnerFilter.new(self.groupFilter.gameObject, params)
	self.partnerFilter = partnerFilter

	self:setGroupData(0)
end

function WishCapsuleSelectWindow:setGroupData(group, isSetKeepPositon)
	if group == nil then
		group = 0
	end

	local setDataArr = {}

	for i in pairs(self.allParams) do
		if group == 0 then
			table.insert(setDataArr, self.allParams[i])
		else
			local pGroupID = xyd.tables.partnerTable:getGroup(self.allParams[i].partnerID)

			if pGroupID == group then
				table.insert(setDataArr, self.allParams[i])
			end
		end
	end

	self.nowPartnerList = setDataArr

	self.wrapContent:setInfos(setDataArr, {
		keepPosition = isSetKeepPositon
	})
end

function WishCapsuleSelectWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	self.selectGroup_ = group

	self:setGroupData(group)
end

function WishCapsuleSelectWindow:updateFormationItemInfo(info, realIndex)
	local partnerId = info.partnerID
	local isSelected = info.isSelected
	local isS = self:isSelected(partnerId)

	if isSelected ~= isS then
		info.isSelected = isS

		self.wrapContent:updateInfo(realIndex, info)
	end
end

function WishCapsuleSelectWindow:isSelected(partnerId)
	for i in pairs(self.allParams) do
		if self.allParams[i].partnerID == partnerId then
			return self.allParams[i].isSelected
		end
	end
end

function WishCapsuleSelectWindow:selectPartner(info, realIndex, isSelected)
	local isShowEffect = false

	for i in pairs(self.allParams) do
		if self.allParams[i].partnerID == info.partnerID then
			self.allParams[i].isSelected = isSelected
			info.isSelected = isSelected
			isShowEffect = isSelected
		elseif self.allParams[i].isSelected == true then
			self.allParams[i].isSelected = false
		end
	end

	if isShowEffect then
		self.selectChoiceId = info.partnerID

		self:showEffect(info.partnerID)
		self.touchField:SetActive(true)

		UIEventListener.Get(self.touchField).onClick = handler(self, function ()
			xyd.WindowManager.get():openWindow("partner_info", {
				notShowWays = true,
				table_id = info.partnerID
			})
		end)
	else
		if self.effect then
			self.effect:destroy()

			self.effect = nil
		end

		self.touchField:SetActive(false)
	end

	self.wrapContent:updateInfo(realIndex, info)
	self:setGroupData(self.selectGroup_, true)
end

function WishCapsuleSelectWindow:showEffect(heroID)
	local modelID = xyd.tables.partnerTable:getModelID(heroID)
	local name = xyd.tables.modelTable:getModelName(modelID)

	if self.effect and self.effect:getName() == name then
		return
	end

	local scale = 1

	if self.effect then
		self.effect:destroy()

		self.effect = nil
	end

	self.effect = xyd.Spine.new(self.effectCon.gameObject)

	self.effect:setInfo(name, function ()
		self.effect:setRenderTarget(self.effectCon:GetComponent(typeof(UITexture)), 1)
		self.effect:SetLocalScale(scale, scale, scale)
		self.effect:play("idle", 0, 1)
	end)
end

function WishCapsuleSelectItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = nil

	if not self.parent_ then
		self.win_ = xyd.getWindow("battle_formation_window")
	else
		self.win_ = self.parent_
	end
end

function WishCapsuleSelectItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	if realIndex ~= nil then
		self.parent_:updateFormationItemInfo(info, realIndex)
	end

	self.realIndex = realIndex

	if not self.heroIcon_ then
		self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_, self.parent_.partnerRenderPanel)
	end

	self.uiRoot_:SetActive(true)

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc
	self.info = info

	self:setIsChoose(info.isSelected)

	self.partnerId_ = info.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.noClick = false
	self.partner_.hideLev = false

	self.heroIcon_:setInfo(self.partner_)
end

function WishCapsuleSelectItem:setIsChoose(status)
	self.isSelected = status

	self.heroIcon_:setChoose(status)
end

function WishCapsuleSelectItem:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function WishCapsuleSelectItem:getGameObject()
	return self.uiRoot_
end

function WishCapsuleSelectItem:onClick()
	if self.info then
		self.heroIcon_:setChoose(not self.info.isSelected)
		self.win_:selectPartner(self.info, self.realIndex, not self.info.isSelected)
	end
end

return WishCapsuleSelectWindow
