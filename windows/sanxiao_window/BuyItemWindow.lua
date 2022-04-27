local BuyItemWindow = class("BuyItemWindow", import(".BaseWindow"))
local DisplayConstants = xyd.DisplayConstants
local ItemConstants = xyd.ItemConstants

function BuyItemWindow:ctor(name, params, callback)
	BuyItemWindow.super.ctor(self, name, params)

	self.touch_count = 0
	self.item_id = tonumber(params.id)
	self.callback = callback
end

function BuyItemWindow:initWindow()
	BuyItemWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function BuyItemWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_bg = winTrans:NodeByName("e:Skin/group_bg").gameObject
	self._title = winTrans:ComponentByName("e:Skin/group_bg/_title", typeof(UILabel))
	self._buyBtn = winTrans:NodeByName("e:Skin/group_bg/_buyBtn").gameObject
	self._price = winTrans:ComponentByName("e:Skin/group_bg/_buyBtn/_price", typeof(UILabel))
	self.item_pic = winTrans:ComponentByName("e:Skin/group_bg/item_pic", typeof(UISprite))
	self.item_desc = winTrans:ComponentByName("e:Skin/group_bg/item_desc", typeof(UILabel))
	self._closeBtn = winTrans:NodeByName("e:Skin/group_bg/_closeBtn").gameObject
	self.fail_label = winTrans:ComponentByName("e:Skin/group_bg/fail_bg/fail_label", typeof(UILabel))
	self.fail_bg = winTrans:ComponentByName("e:Skin/group_bg/fail_bg", typeof(UISprite))
	self.fail_label.text = __("NO_DIAMOND")
end

function BuyItemWindow:initUIComponent()
	xyd.setDarkenBtnBehavior(self._closeBtn, self, self._onClose)
	xyd.setDarkenBtnBehavior(self._buyBtn, self, self._onBuy)

	local picName = DisplayConstants.ItemSourceMap[self.item_id]

	xyd.setUISprite(self.item_pic, xyd.MappingData[picName], picName)

	self._title.text = __("ITEM_NAME_" .. tostring(self.item_id))
	self.item_desc.text = __("BOOSTER_DESC_" .. tostring(self.item_id))
	self._price.text = tostring(ItemConstants.ITEM_PRICE[self.item_id])
end

function BuyItemWindow:_onClose()
	self:close()

	if self.callback then
		self.callback()
	end
end

function BuyItemWindow:_onBuy()
	if self.touch_count > 0 then
		return
	end

	self.touch_count = self.touch_count + 1

	if xyd.SelfInfo.get()._gems < ItemConstants.ITEM_PRICE[self.item_id] then
		local group = self.fail_bg
		local sequence = DG.Tweening.DOTween.Sequence()

		group:SetActive(true)

		group.transform.localScale = Vector3(0.5, 0.5)
		group:GetComponent(typeof(UIWidget)).alpha = 0.5

		local function getter()
			return group:GetComponent(typeof(UIWidget)).color
		end

		local function setter(value)
			group:GetComponent(typeof(UIWidget)).color = value
		end

		sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 4 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
		sequence:Insert(0, group.transform:DOScale(Vector3(1.1, 1.1), 4 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
		sequence:Insert(4 * xyd.TweenDeltaTime, group.transform:DOScale(Vector3(0.97, 0.97), 4 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
		sequence:Insert(8 * xyd.TweenDeltaTime, group.transform:DOScale(Vector3(1, 1), 5 * xyd.TweenDeltaTime):SetEase(DG.Tweening.Ease.Linear))
		sequence:AppendInterval(0.6)
		sequence:AppendCallback(function ()
			self:_onClose()
		end)

		return
	end

	xyd.SelfInfo:buyItemByID(self.item_id)

	local backpackModel = xyd.ModelManager.get():loadModel(xyd.ModelType.BACKPACK)

	xyd.SelfInfo.get():syncItem(backpackModel.items)
	self:_onClose()
end

return BuyItemWindow
