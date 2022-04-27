local BaseWindow = import(".BaseWindow")
local RechargeAwardWindow = class("RechargeAwardWindow", BaseWindow)

function RechargeAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fx_name_ = "libaofankui"
	self.animation_name1_ = "texiao01"
	self.animation_name2_ = "texiao02"
	self.items_ = params.items
	self.giftbag_id_ = params.giftbag_id
	self.spineEffect = nil

	self:checkSpecial()

	self.allItems_ = params.items
end

function RechargeAwardWindow:playOpenAnimation(callback)
	RechargeAwardWindow.super:playOpenAnimation(function ()
		self:initLayout()

		if callback then
			callback()
		end
	end)
end

function RechargeAwardWindow:update(params)
	RechargeAwardWindow.super.update(params)

	self.giftbag_id_ = params.giftbag_id
	self.items_ = params.items

	self:checkSpecial()

	self.allItems_ = xyd.arrayMerge(self.allItems_, params.items)
end

function RechargeAwardWindow:checkSpecial()
	for i = 1, #self.items_ do
		local itemID = tonumber(self.items_[i].item_id)

		if itemID == 117 then
			self.items_[i].item_id = 223
		end
	end
end

function RechargeAwardWindow:initLayout()
	self:getUIComponent()
	self:initText()
	self:initItem()
	self:initSpine()
end

function RechargeAwardWindow:getUIComponent()
	local win = self.window_.transform
	self.effect = win:NodeByName("effect").gameObject
	self.itemGroup = win:NodeByName("itemGroup").gameObject
	self.labelTop = win:ComponentByName("labelTop", typeof(UILabel))
	self.labelBottom = win:ComponentByName("labelBottom", typeof(UILabel))
end

function RechargeAwardWindow:initText()
	self.labelTop.text = __("PACK_FEEDBACK_TEXT01", xyd.tables.giftBagTextTable:getShowName(self.giftbag_id_))
	self.labelBottom.text = __("PACK_FEEDBACK_TEXT02")
end

function RechargeAwardWindow:initSpine()
	local theScale = 1

	if #self.items_ >= 7 then
		theScale = 0.85
	end

	if self.spineEffect then
		self.itemGroup:SetLocalScale(0.01, 0.01, 1)
		self.itemGroup:SetActive(true)
		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

		local action = self:getSequence()

		action:Append(self.itemGroup.transform:DOScale(Vector3(theScale, theScale, 1), 0.6))

		return
	end

	local effect = xyd.Spine.new(self.effect)

	effect:setInfo(self.fx_name_, function ()
		effect:play(self.animation_name1_, 1, 1, function ()
			effect:play(self.animation_name2_, 0)
		end)
		self.itemGroup:SetLocalScale(0.01, 0.01, 1)
		self.itemGroup:SetActive(true)

		local action = self:getSequence()

		action:Append(self.itemGroup.transform:DOScale(Vector3(theScale, theScale, 1), 0.6))
	end)

	self.spineEffect = effect
end

function RechargeAwardWindow:initItem()
	local items = self.items_

	NGUITools.DestroyChildren(self.itemGroup.transform)
	self.itemGroup:SetActive(false)

	for i = 1, #items do
		if items[i].item_id ~= xyd.ItemID.VIP_EXP then
			local itemID = tonumber(self.items_[i].item_id)
			local iconType = nil
			local type = xyd.tables.itemTable:getType(itemID)

			if type == xyd.ItemType.ACTIVITY_SPACE_EXPLORE then
				iconType = xyd.ItemIconType.ACTIVITY_SPACE_EXPLORE_ICON
				itemID = xyd.tables.miscTable:getNumber("adventure_giftbag_limit_partner", "value")
			end

			local icon = xyd.getItemIcon({
				noClick = true,
				uiRoot = self.itemGroup,
				itemID = itemID,
				num = tonumber(items[i].item_num)
			}, iconType)
		end
	end

	local itemGroup_UILayout = self.itemGroup:GetComponent(typeof(UILayout))

	if #items >= 6 then
		itemGroup_UILayout.gap = Vector2(8, 0)
	end

	itemGroup_UILayout:Reposition()
end

function RechargeAwardWindow:didClose()
	xyd.itemFloat(self.allItems_, nil, , 7000)
end

return RechargeAwardWindow
