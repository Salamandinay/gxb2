local HouseSelectBox = class("HouseSelectBox", import("app.components.BaseComponent"))

function HouseSelectBox:ctor(parentGO)
	HouseSelectBox.super.ctor(self, parentGO)

	self.houseMap_ = xyd.HouseMap.get()
end

function HouseSelectBox:getPrefabPath()
	return "Prefabs/Components/house_select_box"
end

function HouseSelectBox:initUI()
	HouseSelectBox.super.initUI(self)

	local go = self.go
	self.groupMain_ = go:NodeByName("groupMain_").gameObject
	self.btnFlip_ = self.groupMain_:NodeByName("btnFlip_").gameObject
	self.btnOk_ = self.groupMain_:NodeByName("btnOk_").gameObject
	self.btnDetail_ = self.groupMain_:NodeByName("btnDetail_").gameObject
	self.btnDelete_ = self.groupMain_:NodeByName("btnDelete_").gameObject
	self.btnCancel_ = self.groupMain_:NodeByName("btnCancel_").gameObject
	self.imgbg_ = self.groupMain_:ComponentByName("imgbg_", typeof(UISprite))

	self:layout()
	self:registerEvent()
end

function HouseSelectBox:setInfo(item)
	self.houseItem_ = item

	self:updatePos()
	self:updateTouchEnable()
end

function HouseSelectBox:getItem()
	return self.houseItem_
end

function HouseSelectBox:getInfo()
	return self:getItem():getInfo()
end

function HouseSelectBox:updatePos()
	local itemInfo = self:getInfo()
	local item = self:getItem()
	local pos = item:getCenterPos()
	local x = pos.x
	local y = pos.y

	self:SetLocalPosition(x, y, 0)
end

function HouseSelectBox:updateTouchEnable()
	local info = self:getInfo()
	local flag = true
	local img = self.btnFlip_:ComponentByName("button_img", typeof(UISprite))

	if info.can_flip then
		xyd.applyOrigin(img)
	else
		flag = false

		xyd.applyGrey(img)
	end

	xyd.setTouchEnable(self.btnFlip_, flag)
end

function HouseSelectBox:layout()
	self.btnOk_:ComponentByName("button_label", typeof(UILabel)).text = __("SURE")
	self.btnFlip_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_26")
	self.btnCancel_:ComponentByName("button_label", typeof(UILabel)).text = __("CANCEL_2")
	self.btnDelete_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_27")
	self.btnDetail_:ComponentByName("button_label", typeof(UILabel)).text = __("ITEM_DETAIL")

	xyd.setUISpriteAsync(self.imgbg_, nil, "house_select_box_bg")
	xyd.setUISpriteAsync(self.btnOk_:GetComponent(typeof(UISprite)), nil, "house_select_btnbg")
	xyd.setUISpriteAsync(self.btnFlip_:GetComponent(typeof(UISprite)), nil, "house_select_btnbg")
	xyd.setUISpriteAsync(self.btnCancel_:GetComponent(typeof(UISprite)), nil, "house_select_btnbg")
	xyd.setUISpriteAsync(self.btnDelete_:GetComponent(typeof(UISprite)), nil, "house_select_btnbg")
	xyd.setUISpriteAsync(self.btnDetail_:GetComponent(typeof(UISprite)), nil, "house_select_btnbg")
	xyd.setUISpriteAsync(self.btnOk_:ComponentByName("button_img", typeof(UISprite)), nil, "house_select_btn2")
	xyd.setUISpriteAsync(self.btnFlip_:ComponentByName("button_img", typeof(UISprite)), nil, "house_select_btn1")
	xyd.setUISpriteAsync(self.btnCancel_:ComponentByName("button_img", typeof(UISprite)), nil, "house_select_btn5")
	xyd.setUISpriteAsync(self.btnDelete_:ComponentByName("button_img", typeof(UISprite)), nil, "house_select_btn4")
	xyd.setUISpriteAsync(self.btnDetail_:ComponentByName("button_img", typeof(UISprite)), nil, "house_select_btn3")
end

function HouseSelectBox:registerEvent()
	UIEventListener.Get(self.btnFlip_).onClick = handler(self, self.onTouchFlip)
	UIEventListener.Get(self.btnOk_).onClick = handler(self, self.onTouchOk)
	UIEventListener.Get(self.btnDetail_).onClick = handler(self, self.onTouchDetail)
	UIEventListener.Get(self.btnDelete_).onClick = handler(self, self.onTouchDel)
	UIEventListener.Get(self.btnCancel_).onClick = handler(self, self.onTouchCancel)
	UIEventListener.Get(self.imgbg_.gameObject).onDrag = handler(self, self.onTouchMove)
end

function HouseSelectBox:onTouchMove(go, delta)
	local item = self:getItem()

	item:onTouchMove(delta)
	self:updatePos()
	self:updateItemValid()
end

function HouseSelectBox:onTouchFlip(event)
	self.houseMap_:flipSelectItem()
	self:updateItemValid()
end

function HouseSelectBox:onTouchOk(event)
	self.houseMap_:confirmSelectItem()
	self.houseItem_:playSetEffect()
end

function HouseSelectBox:onTouchDetail(event)
	local info = self:getInfo()

	xyd.WindowManager.get():openWindow("house_item_detail_window", {
		wnd_type = xyd.HouseItemDetailWndType.NOAMAL,
		item_id = info.item_id
	})
end

function HouseSelectBox:onTouchCancel(event)
	self.houseMap_:cancelSelectItem()
end

function HouseSelectBox:onTouchDel(event)
	self.houseMap_:delectSelectItem()

	local wnd = xyd.WindowManager.get():getWindow("house_window")

	if wnd then
		wnd:updateHouseBox()
	end
end

function HouseSelectBox:updateItemValid()
	if not self.houseItem_ then
		return
	end

	local flag = true
	local img = self.btnOk_:ComponentByName("button_img", typeof(UISprite))

	if self.houseMap_:checkItemPosIsValid(self.houseItem_) then
		xyd.applyOrigin(img)
	else
		flag = false

		xyd.applyGrey(img)
	end

	xyd.setTouchEnable(self.btnOk_, flag)
end

function HouseSelectBox:playShowAction()
	local transform = self.groupMain_.transform

	transform:SetLocalScale(0.1, 0.1, 1)

	local w = self.groupMain_:GetComponent(typeof(UIWidget))
	w.alpha = 0.1
	local action = DG.Tweening.DOTween.Sequence()

	action:Append(transform:DOScale(Vector3(1.03, 1.03, 1), 0.2)):Join(xyd.getTweenAlpha(w, 1, 0.2)):Append(transform:DOScale(Vector3(0.98, 0.98, 1), 0.1)):Append(transform:DOScale(Vector3(1, 1, 1), 0.1))

	if self.hideAction_ then
		self.hideAction_:Pause()
		self.hideAction_:Kill()

		self.hideAction_ = nil
	end
end

function HouseSelectBox:playHideAction()
	local action = DG.Tweening.DOTween.Sequence()
	local transform = self.groupMain_.transform
	local w = self.groupMain_:GetComponent(typeof(UIWidget))

	action:Append(transform:DOScale(Vector3(0, 0, 1), 0.2)):Join(xyd.getTweenAlpha(w, 0, 0.2)):AppendCallback(function ()
		xyd.HouseMap.get():hideSelectBox()
	end)

	self.hideAction_ = action
end

return HouseSelectBox
