local ChooseSoulEquipWindow = class("ChooseSoulEquipWindow", import(".BaseWindow"))
local ItemRender = class("testItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function ChooseSoulEquipWindow:ctor(name, params)
	ChooseSoulEquipWindow.super.ctor(self, name, params)

	self.equipIDList = params.equipIDList
	self.needNum = params.needNum
	self.callbalck = params.callbalck
	self.chooseEquipIDs = params.chooseEquipIDs or {}
	self.chosenNum = 0

	for k, v in pairs(self.chooseEquipIDs) do
		self.chosenNum = self.chosenNum + 1
	end
end

function ChooseSoulEquipWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ChooseSoulEquipWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.noneGroup = self.groupAction:NodeByName("noneGroup").gameObject
	self.labelNone = self.noneGroup:ComponentByName("labelNone", typeof(UILabel))
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.scrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.wrapContent = self.scroller:NodeByName("wrapContent").gameObject
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.btnCancel = self.groupAction:NodeByName("btnCancel").gameObject
	self.labelCancel = self.btnCancel:ComponentByName("labelCancel", typeof(UILabel))
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
	self.item = self.groupAction:NodeByName("item").gameObject
	self.iconPos = self.item:NodeByName("iconPos").gameObject
	self.numText = self.item:ComponentByName("numText", typeof(UILabel))
	local wrapContent = self.scroller:ComponentByName("wrapContent", typeof(UIWrapContent))
	self.wrapContent_ = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.item, ItemRender, self)
end

function ChooseSoulEquipWindow:layout()
	self.labelNone.text = __("SOUL_EQUIP_TEXT33")
	self.title.text = __("SOUL_EQUIP_TEXT85")
	self.labelCancel.text = __("CANCEL")
	self.labelSure.text = __("SURE")

	if not self.equipIDList or #self.equipIDList <= 0 then
		self.noneGroup:SetActive(true)
		self.scrollView:SetActive(false)
	else
		self.wrapContent_:setInfos(self.equipIDList, {})
		self:waitForFrame(1, function ()
			self.scrollView:ResetPosition()
		end)
	end
end

function ChooseSoulEquipWindow:registerEvent()
	UIEventListener.Get(self.btnClose.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.btnCancel.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, function ()
		self.callbalck(self.chooseEquipIDs)
		self:close()
	end)
end

function ItemRender:ctor(go, parent)
	ItemRender.super.ctor(self, go, parent)

	self.parent = parent
end

function ItemRender:initUI()
	local go = self.go
	self.iconPos = self.go:NodeByName("iconPos").gameObject
end

function ItemRender:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info
	self.equip = xyd.models.slot:getSoulEquip(self.data.equipID)
	local params = {
		scale = 0.9166666666666666,
		uiRoot = self.iconPos,
		itemID = self.equip:getTableID(),
		soulEquipInfo = self.equip:getSoulEquipInfo(),
		partner_id = self.equip:getOwnerPartnerID(),
		callback = function ()
			self:onClickIcon()
		end
	}

	if self.icon then
		self.icon:setInfo(params)
		self.icon:SetActive(true)
	else
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self:checkChoose()
end

function ItemRender:onClickIcon()
	if self.equip:getIsLock() then
		return
	elseif self.parent.chooseEquipIDs[self.equip:getSoulEquipID()] then
		self.parent.chooseEquipIDs[self.equip:getSoulEquipID()] = nil
		self.parent.chosenNum = self.parent.chosenNum - 1
	else
		if self.parent.needNum <= self.parent.chosenNum then
			return
		end

		if self.equip:getOwnerPartnerID() and self.equip:getOwnerPartnerID() > 0 then
			local owner = xyd.models.slot:getPartner(self.equip:getOwnerPartnerID())

			if owner then
				xyd.alertYesNo(__("没配"), function (flag)
					if flag == true then
						owner:takeOffSoulEquip(self.equip:getSoulEquipID())

						self.parent.chooseEquipIDs[self.equip:getSoulEquipID()] = true
						self.parent.chosenNum = self.parent.chosenNum + 1
					else
						return
					end
				end, __("YES"), false, nil, , , , , )
			else
				self.parent.chooseEquipIDs[self.equip:getSoulEquipID()] = true
				self.parent.chosenNum = self.parent.chosenNum + 1
			end
		else
			self.parent.chooseEquipIDs[self.equip:getSoulEquipID()] = true
			self.parent.chosenNum = self.parent.chosenNum + 1
		end
	end

	self:checkChoose()
end

function ItemRender:checkChoose()
	if self.parent.chooseEquipIDs[self.equip:getSoulEquipID()] then
		self.icon:setLock(false)
		self.icon:setChoose(true)
	elseif self.equip:getIsLock() then
		self.icon:setLock(true)
		self.icon:setChoose(false)
	else
		self.icon:setLock(false)
		self.icon:setChoose(false)
	end
end

return ChooseSoulEquipWindow
