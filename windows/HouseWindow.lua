local HouseWindow = class("HouseWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local HouseBox = import("app.components.HouseBox")
local Input = UnityEngine.Input

function HouseWindow:ctor(name, params)
	HouseWindow.super.ctor(self, name, params)

	self.WndType = {
		MOVE = 3,
		SCALE = 2,
		DOUBLE_TOUCH = 4,
		NONE = 1
	}
	self.touchPos_ = {
		x = 0,
		y = 0
	}
	self.touchPoints = {}
	self.distance_ = 1
	self.minScale = 50
	self.defaultScale = 75
	self.curScale_ = 0
	self.houseBox_ = nil
	self.houseBoxStatus_ = true
	self.isInitMap_ = false
	self.isHide_ = false
	self.isSet_ = false
	self.isResetHide_ = true
	self.openAction_ = nil
	self.timeKeys_ = {}
	self.curFloor_ = 1

	if params then
		self.openShop = params.openShop
	end

	self.curWndType_ = self.WndType.NONE
	self.house = xyd.models.house
end

function HouseWindow:initWindow()
	HouseWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self.house:reqHouseInfo()
	xyd.CameraManager.get():setEnabled(true)
end

function HouseWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.mid_left = winTrans:NodeByName("mid_left").gameObject
	self.groupScale = winTrans:NodeByName("mid_left/groupScale").gameObject
	self.barScale_ = self.groupScale:ComponentByName("barScale_", typeof(UISlider))
	self.labelScale_ = self.groupScale:ComponentByName("labelScale_", typeof(UILabel))
	self.imgScale_ = self.groupScale:NodeByName("imgScale_").gameObject
	self.groupHide = winTrans:NodeByName("top_right/groupHide").gameObject
	self.btnHelp = self.groupHide:NodeByName("btnHelp").gameObject
	self.btnHide_ = self.groupHide:NodeByName("btnHide_").gameObject
	self.btnShare_ = self.groupHide:NodeByName("btnShare_").gameObject
	self.btnShare_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.groupTopLeft_ = winTrans:NodeByName("top_left/groupTopLeft_").gameObject
	self.btnHouseName_ = self.groupTopLeft_:NodeByName("btnHouseName_").gameObject
	self.btnPraiseNum_ = self.groupTopLeft_:NodeByName("btnPraiseNum_").gameObject
	self.btnComfort_ = self.groupTopLeft_:NodeByName("btnComfort_").gameObject
	self.btnComfortRedMark = self.btnComfort_:NodeByName("redMark").gameObject
	self.bottom_left = winTrans:NodeByName("bottom_left").gameObject
	local bottom_left = winTrans:NodeByName("bottom_left").gameObject
	self.btnManage_ = bottom_left:NodeByName("btnManage_").gameObject
	self.btnVisit_ = bottom_left:NodeByName("btnVisit_").gameObject
	self.btnShop_ = bottom_left:NodeByName("btnShop_").gameObject
	self.btnShopRedMark = self.btnShop_:ComponentByName("redMark", typeof(UISprite))

	self.btnShopRedMark:SetActive(false)

	self.btnFloor_ = bottom_left:NodeByName("btnFloor_").gameObject
	self.btnFloorImg_ = self.btnFloor_:ComponentByName("btn_img", typeof(UISprite))
	self.btnClearAll_ = bottom_left:NodeByName("btnClearAll_").gameObject
	self.btnCombine_ = bottom_left:NodeByName("btnCombine_").gameObject
	self.btnCancel_ = bottom_left:NodeByName("btnCancel_").gameObject
	self.bottom_right = winTrans:NodeByName("bottom_right").gameObject
	local bottom_right = winTrans:NodeByName("bottom_right").gameObject
	self.btnRest_ = bottom_right:NodeByName("btnRest_").gameObject
	self.btnRest_RedPoint = self.btnRest_:NodeByName("redPoint").gameObject
	self.btnShop2_ = bottom_right:NodeByName("btnShop2_").gameObject
	self.btnSave_ = bottom_right:NodeByName("btnSave_").gameObject
	self.btnPraise_ = bottom_right:NodeByName("btnPraise_").gameObject
	self.bottom_mid = winTrans:NodeByName("bottom_mid").gameObject
	local bottom_mid = winTrans:NodeByName("bottom_mid").gameObject
	self.groupBox_ = bottom_mid:NodeByName("groupBox_").gameObject
	self.btnBox_ = self.groupBox_:NodeByName("btnBox_").gameObject
	self.groupScroll_ = winTrans:NodeByName("groupScroll_").gameObject
	self.groupMain_ = self.groupScroll_:NodeByName("groupMain_").gameObject
	self.groupFurniture_ = self.groupMain_:NodeByName("groupFurniture_").gameObject

	for i = 1, 4 do
		self["imgBg" .. i] = self.groupMain_:ComponentByName("img" .. i, typeof(UITexture))
	end

	if not xyd.models.house:checkApkCanShare() then
		self.btnShare_:SetActive(false)
	end

	self.bgEffect_ = winTrans:NodeByName("bgEffect").gameObject
	self.effectChris1_ = xyd.WindowManager.get():setChristmasEffect(self.bgEffect_, true)
	self.change = winTrans:NodeByName("change").gameObject
	self.changeText = self.change:ComponentByName("changeText", typeof(UILabel))
	self.changeModel = self.change:NodeByName("changeModel").gameObject
end

function HouseWindow:layout()
	self:initMap()
	self:initResItem()
	self:initScale()

	self.btnBox_:ComponentByName("labelDisplay", typeof(UILabel)).text = __("HOUSE_TEXT_6")
	self.btnManage_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_8")
	self.btnShop_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_9")
	self.btnShop2_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_9")
	self.btnFloor_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_55")
	self.btnCombine_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_11")
	self.btnClearAll_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_12")
	self.btnVisit_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_FRIEND_LIST_WINDOW")

	xyd.setUISpriteAsync(self.btnRest_:GetComponent(typeof(UISprite)), "function_text_" .. xyd.lang, "house_btn_2_" .. xyd.lang)

	self.btnSave_:ComponentByName("button_label", typeof(UILabel)).text = __("SAVE")
	self.btnCancel_:ComponentByName("button_label", typeof(UILabel)).text = __("CANCEL_2")

	if xyd.Global.lang == "fr_fr" then
		self.btnShop_:ComponentByName("button_label", typeof(UILabel)).fontSize = 21
	end

	if self.house:getHangRedPoint() then
		self.btnComfortRedMark:SetActive(true)
	else
		self.btnComfortRedMark:SetActive(false)
	end

	self:updateShopRed()

	self.changeText.text = __("HOUSE_FLOOR_LOADING")
	self.effectChange = xyd.Spine.new(self.changeModel)

	self.effectChange:setInfo("loading", function ()
		self.effectChange:play("idle", 0)
		self.effectChange:SetLocalPosition(0, -60, 0)
	end)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.HOUSE_NEW_FLOOR_2,
		xyd.RedMarkType.SENPAI_FIRST_IN_HOUSE
	}, self.btnRest_RedPoint)
end

function HouseWindow:updateShopRed()
	self.btnShopRedMark:SetActive(xyd.models.house:getShopRedPoint())
end

function HouseWindow:playOpenAnimation(callback)
	callback()
	self:playShowAction1(function ()
		if tolua.isnull(self.window_) or self.willClose_ then
			return
		end

		self:setWndComplete()
		self:initFurniture()
		self:checkGuide()
	end)
end

function HouseWindow:playShowAction1(callback)
	local action1 = self:getSequence()
	local topLeftTransform = self.groupTopLeft_.transform

	topLeftTransform:SetLocalPosition(0, 155, 0)
	action1:Append(topLeftTransform:DOLocalMove(Vector3(0, -74, 0), 0.2)):Append(topLeftTransform:DOLocalMove(Vector3(0, -61, 0), 0.1)):Append(topLeftTransform:DOLocalMove(Vector3(0, -64, 0), 0.1))

	local action2 = self:getSequence()
	local btnManageTransform = self.btnManage_.transform

	btnManageTransform:SetLocalPosition(69, -51, 0)
	action2:Append(btnManageTransform:DOLocalMove(Vector3(69, 93, 0), 0.2)):Append(btnManageTransform:DOLocalMove(Vector3(69, 80, 0), 0.1)):Append(btnManageTransform:DOLocalMove(Vector3(69, 83, 0), 0.1))

	local action3 = self:getSequence()
	local btnRestTransform = self.btnRest_.transform

	btnRestTransform:SetLocalPosition(-96, -75, 0)
	action3:Append(btnRestTransform:DOLocalMove(Vector3(-96, 95, 0), 0.2)):Append(btnRestTransform:DOLocalMove(Vector3(-96, 82, 0), 0.1)):Append(btnRestTransform:DOLocalMove(Vector3(-96, 85, 0), 0.1))

	local groupHideTransform = self.groupHide.transform

	groupHideTransform:SetLocalPosition(-51, 67, 0)

	local btnShopTransform = self.btnShop_.transform

	btnShopTransform:SetLocalPosition(194, -51, 0)

	local btnVisitTransform = self.btnVisit_.transform

	btnVisitTransform:SetLocalPosition(69, -51, 0)

	local btnFloorTransform = self.btnFloor_.transform

	btnFloorTransform:SetLocalPosition(319, -51, 0)
	self:waitForTime(0.1, function ()
		local action4 = self:getSequence()

		action4:Append(groupHideTransform:DOLocalMove(Vector3(-51, -98, 0), 0.2)):Append(groupHideTransform:DOLocalMove(Vector3(-51, -85, 0), 0.1)):Append(groupHideTransform:DOLocalMove(Vector3(-51, -88, 0), 0.1))

		local action5 = self:getSequence()

		action5:Append(btnShopTransform:DOLocalMove(Vector3(194, 93, 0), 0.2)):Append(btnShopTransform:DOLocalMove(Vector3(194, 80, 0), 0.1)):Append(btnShopTransform:DOLocalMove(Vector3(194, 83, 0), 0.1))
	end)
	self:waitForTime(0.3, function ()
		local action7 = self:getSequence()

		action7:Append(btnVisitTransform:DOLocalMove(Vector3(69, 221, 0), 0.2)):Append(btnVisitTransform:DOLocalMove(Vector3(69, 208, 0), 0.1)):Append(btnVisitTransform:DOLocalMove(Vector3(69, 211, 0), 0.1)):AppendCallback(function ()
			if callback then
				callback()
			end
		end)

		local action8 = self:getSequence()

		action8:Append(btnFloorTransform:DOLocalMove(Vector3(319, 93, 0), 0.2)):Append(btnFloorTransform:DOLocalMove(Vector3(319, 80, 0), 0.1)):Append(btnFloorTransform:DOLocalMove(Vector3(319, 83, 0), 0.1))
	end)
end

function HouseWindow:playShowAction2(callback)
	local btnCancelTransform = self.btnCancel_.transform

	btnCancelTransform:SetLocalPosition(-45, 441, 0)

	local action1 = self:getSequence()

	action1:Append(btnCancelTransform:DOLocalMove(Vector3(95, 441, 0), 0.2)):Append(btnCancelTransform:DOLocalMove(Vector3(82, 441, 0), 0.1)):Append(btnCancelTransform:DOLocalMove(Vector3(85, 441, 0), 0.1))

	local btnSaveTransform = self.btnSave_.transform

	btnSaveTransform:SetLocalPosition(45, 441, 0)

	local action2 = self:getSequence()

	action2:Append(btnSaveTransform:DOLocalMove(Vector3(-95, 441, 0), 0.2)):Append(btnSaveTransform:DOLocalMove(Vector3(-82, 441, 0), 0.1)):Append(btnSaveTransform:DOLocalMove(Vector3(-85, 441, 0), 0.1))

	local btnCombineTransform = self.btnCombine_.transform

	btnCombineTransform:SetLocalPosition(-24, 536, 0)

	local btnShop2Transform = self.btnShop2_.transform

	btnShop2Transform:SetLocalPosition(24, 548, 0)

	local btnClearAllTransform = self.btnClearAll_.transform

	btnClearAllTransform:SetLocalPosition(-24, 647, 0)
	self:waitForTime(0.1, function ()
		local action3 = self:getSequence()

		action3:Append(btnCombineTransform:DOLocalMove(Vector3(73, 536, 0), 0.2)):Append(btnCombineTransform:DOLocalMove(Vector3(60, 536, 0), 0.1)):Append(btnCombineTransform:DOLocalMove(Vector3(63, 536, 0), 0.1))

		local action4 = self:getSequence()

		action4:Append(btnShop2Transform:DOLocalMove(Vector3(-79, 548, 0), 0.2)):Append(btnShop2Transform:DOLocalMove(Vector3(-66, 548, 0), 0.1)):Append(btnShop2Transform:DOLocalMove(Vector3(-69, 548, 0), 0.1))
	end)
	self:waitForTime(0.2, function ()
		local action5 = self:getSequence()

		action5:Append(btnClearAllTransform:DOLocalMove(Vector3(73, 647, 0), 0.2)):Append(btnClearAllTransform:DOLocalMove(Vector3(60, 647, 0), 0.1)):Append(btnClearAllTransform:DOLocalMove(Vector3(63, 647, 0), 0.1)):AppendCallback(function ()
			if callback then
				callback()
			end
		end)
	end)
end

function HouseWindow:playCloseAnimation(callback)
	self.isHide_ = true

	self:playHideAction1(function ()
		self:showHideView()

		if callback then
			callback()
		end
	end)
end

function HouseWindow:playHideAction1(callback)
	local action1 = self:getSequence()

	action1:Append(self.groupTopLeft_.transform:DOLocalMove(Vector3(0, 91, 0), 0.2)):AppendCallback(function ()
		if callback then
			callback()
		end
	end)

	local function hideObj(obj, pos)
		local action = self:getSequence()

		action:Append(obj.transform:DOLocalMove(pos, 0.2))
	end

	hideObj(self.btnManage_, Vector3(69, -242, 0))
	hideObj(self.btnShop_, Vector3(194, -242, 0))
	hideObj(self.btnFloor_, Vector3(319, -242, 0))
	hideObj(self.btnVisit_, Vector3(69, -105, 0))
	hideObj(self.groupHide, Vector3(-51, 67, 0))
	hideObj(self.btnRest_, Vector3(-96, -231, 0))
end

function HouseWindow:playHideAction2(callback)
	local action1 = self:getSequence()
	local positionY1 = self.btnClearAll_.transform.localPosition.y

	action1:Append(self.btnClearAll_.transform:DOLocalMove(Vector3(-24, positionY1, 0), 0.2)):AppendCallback(function ()
		if callback then
			callback()
		end
	end)

	local function hideObj(obj, pos)
		local action = self:getSequence()
		local positionY = obj.transform.localPosition.y
		pos = pos + Vector3(0, positionY, 0)

		action:Append(obj.transform:DOLocalMove(pos, 0.2))
	end

	hideObj(self.btnCombine_, Vector3(-24, 0, 0))
	hideObj(self.btnShop2_, Vector3(30, 0, 0))
	hideObj(self.btnCancel_, Vector3(-45, 0, 0))
	hideObj(self.btnSave_, Vector3(45, 0, 0))
end

function HouseWindow:initScale()
	self.barScale_.value = 0
	self.curScale_ = self.defaultScale

	self:updateScaleBar()
end

function HouseWindow:updateScaleBar()
	local height = 500
	local percent = 2 * (self.curScale_ - self.minScale)
	self.barScale_.value = percent / 100
	local offY = height * (1 - percent / 100)

	self.imgScale_:SetLocalPosition(25, 250 - offY, 0)
	self:updateScale()
end

function HouseWindow:initResItem()
	local function closecallback()
		self:onClickCloseButton()
	end

	self.windowTop = WindowTop.new(self.window_, self.name_, 9800, true, closecallback)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function HouseWindow:checkGuide()
	local res = xyd.db.misc:getValue("house_guide")

	if res then
		if self.openShop then
			xyd.WindowManager.get():openWindow("house_shop_window", {
				shopType = xyd.ShopType.SHOP_HOUSE_FURNITURE
			})

			self.openShop = nil
		end

		return
	else
		xyd.WindowManager:get():openWindow("friend_team_boss_guide_window", {
			wnd = self,
			table = xyd.tables.houseGuideTable,
			guide_type = xyd.GuideType.HOUSE
		})
		xyd.db.misc:setValue({
			value = "1",
			key = "house_guide"
		})
	end
end

function HouseWindow:registerEvent()
	UIEventListener.Get(self.imgScale_).onDragStart = function ()
		self:onScaleTouchBegin()
	end

	UIEventListener.Get(self.imgScale_).onDrag = function (go, delta)
		self:scaleMove(delta)
	end

	UIEventListener.Get(self.imgScale_).onDragEnd = function (go)
		self:onTouchEnd()
	end

	UIEventListener.Get(self.groupScroll_).onDragStart = function ()
		self:onScrollTouchBegin()
	end

	UIEventListener.Get(self.groupScroll_).onDrag = function (go, delta)
		self:onTouchMove(delta)
	end

	UIEventListener.Get(self.groupScroll_).onDragEnd = function (go)
		self:onTouchEnd()
	end

	UIEventListener.Get(self.btnShop_).onClick = handler(self, self.onShopTouch)
	UIEventListener.Get(self.btnShop2_).onClick = handler(self, self.onShopTouch)
	UIEventListener.Get(self.btnBox_).onClick = handler(self, self.onBoxTouch)
	UIEventListener.Get(self.btnSave_).onClick = handler(self, self.onSaveTouch)
	UIEventListener.Get(self.btnCancel_).onClick = handler(self, self.onCancelTouch)
	UIEventListener.Get(self.btnManage_).onClick = handler(self, self.onManageTouch)
	UIEventListener.Get(self.btnFloor_).onClick = handler(self, self.onBtnFloorTouch)
	UIEventListener.Get(self.btnClearAll_).onClick = handler(self, self.onClearAllTouch)
	UIEventListener.Get(self.btnCombine_).onClick = handler(self, self.onCombineTouch)
	UIEventListener.Get(self.btnComfort_).onClick = handler(self, self.onComfortTouch)
	UIEventListener.Get(self.btnRest_).onClick = handler(self, self.onRestTouch)
	UIEventListener.Get(self.btnHide_).onClick = handler(self, self.onHideTouch)
	UIEventListener.Get(self.btnShare_).onClick = handler(self, self.onShareTouch)
	UIEventListener.Get(self.btnHelp).onClick = handler(self, self.onHelpTouch)
	UIEventListener.Get(self.btnVisit_).onClick = handler(self, self.onVisitTouch)
	UIEventListener.Get(self.btnHouseName_).onClick = handler(self, self.onBtnHouseNameTouch)

	self.eventProxy_:addEventListener(xyd.event.HOUSE_SET_PARTNER, handler(self, self.updateBtnRes))
	self.eventProxy_:addEventListener(xyd.event.HOUSE_GET_INFO, handler(self, self.initFurniture))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refresItems))
	self.eventProxy_:addEventListener(xyd.event.HOUSE_EDIT_NAME, handler(self, self.onUpdateHouseName))
	self.eventProxy_:addEventListener(xyd.event.HANDLE_MAP_ZOOM, handler(self, self.onScaleEvent))
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.HOUSE_SHOP, self.btnShopRedMark)
end

function HouseWindow:onOpenDormFloor()
	self:changeFloor()
end

function HouseWindow:onBtnHouseNameTouch()
	xyd.WindowManager.get():openWindow("house_edit_name_window")
end

function HouseWindow:onHelpTouch()
	xyd.WindowManager.get():openWindow("help_table_window", {
		isFlow = true,
		key = "HOUSE_TEXT_38"
	})
end

function HouseWindow:onVisitTouch()
	xyd.WindowManager.get():openWindow("house_friend_list_window")
end

function HouseWindow:onBtnFloorTouch()
	if not self:isWndComplete() then
		return
	end

	if not self.house:checkCanOpenFloor() then
		xyd.alertTips(__("HOUSE_TEXT_57", self.house:getOpenComfortNum()))

		return
	end

	self:changeFloor()
end

function HouseWindow:changeFloor()
	self.change:SetActive(true)

	local function resGroupSetter(value)
		self.effectChange:setAlpha(value)
	end

	local w = self.change:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(w)
	local sequence = self:getSequence()

	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0))
	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 1))
	sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 0.01, 1, 1):SetEase(DG.Tweening.Ease.Linear))
	sequence:AppendCallback(function ()
		if not self:isWndComplete() then
			return
		end

		self.curFloor_ = self.curFloor_ == 1 and 2 or 1

		xyd.setUISpriteAsync(self.btnFloorImg_, nil, "house_btn_8_" .. self.curFloor_)
		self.houseMap:clearAll()

		local items = self.house:getFurnitures(self.curFloor_)

		self.houseMap:initOtherFloorFurniture(self.house:getOtherFurnitureNum(self.curFloor_))
		self.houseMap:initItems(items)
		self.houseMap:setManage(false)
		self:initHeros()
		self:updateBtnRes()

		if self.initHeroTimeKey_ then
			XYDCo.StopWait(self.initHeroTimeKey_)

			self.initHeroTimeKey_ = nil
		end
	end)
	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 1))
	sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 1, 0.01, 1):SetEase(DG.Tweening.Ease.Linear))
	sequence:AppendCallback(function ()
		self.change:SetActive(false)
	end)
end

function HouseWindow:refresItems(event)
	local items = event.data.items
	local flag = false
	local ItemTable = xyd.tables.itemTable

	for i = 1, #items do
		local item = items[i]
		local item_id = item.item_id
		local type = ItemTable:getType(item_id)

		if type == xyd.ItemType.HOUSE_FURNITURE then
			flag = true

			break
		end
	end

	if flag then
		self:updateBtnRes()
		self:updateBtnFloor()

		if self.houseBox_ then
			self.houseBox_:setBuyFuniture(true)
		end
	end
end

function HouseWindow:onHideTouch()
	if self.isNotOnHide then
		return
	end

	if self.isHide_ then
		self.isNotOnHide = true

		self:waitForTime(0.8, function ()
			self.isNotOnHide = false
		end)
	else
		self.isNotOnHide = true

		self:waitForTime(0.3, function ()
			self.isNotOnHide = false
		end)
	end

	self.isHide_ = not self.isHide_

	if self.isHide_ then
		self:playHideAction1(function ()
			if tolua.isnull(self.window_) then
				return
			end

			self:showHideView()

			UIEventListener.Get(self.groupScroll_).onClick = handler(self, self.onScrollTouchTap)
		end)
	else
		self:showHideView()
		self:playShowAction1()
	end
end

function HouseWindow:showHideView()
	self.groupTopLeft_:SetActive(not self.isHide_)
	self.groupScale:SetActive(self.isHide_)

	if self.mid_left_height then
		self.mid_left.gameObject:Y(self.mid_left_height)
	end

	self.mid_left:Y(0)
	self.btnHelp:SetActive(not self.isHide_)
	self.btnHide_:SetActive(not self.isHide_)

	if not xyd.models.house:checkApkCanShare() then
		self.btnShare_:SetActive(false)
	else
		self.btnShare_:SetActive(not self.isHide_)
	end

	self:checkCanShowGroupScale()
end

function HouseWindow:checkCanShowGroupScale()
	if not XYDUtils.IsTest() then
		self.groupScale:SetActive(false)
	end
end

function HouseWindow:onScrollTouchTap()
	if not self.isNotOnHide then
		UIEventListener.Get(self.groupScroll_).onClick = nil
	end

	self:onHideTouch()
end

function HouseWindow:onRestTouch()
	xyd.WindowManager.get():openWindow("house_select_heros_window", {
		floor = self.curFloor_,
		closeCallBack = function ()
			if self.openShop then
				xyd.WindowManager.get():openWindow("house_shop_window", {
					shopType = xyd.ShopType.SHOP_HOUSE_FURNITURE
				})

				self.openShop = nil
			end
		end
	})
end

function HouseWindow:onShopTouch()
	xyd.WindowManager.get():openWindow("house_shop_window", {
		shopType = xyd.ShopType.SHOP_HOUSE_FURNITURE
	})
end

function HouseWindow:onSaveTouch()
	if self.houseMap:checkNeedSave() == false then
		self:playHideAction2(function ()
			if tolua.isnull(self.window_) then
				return
			end

			self.houseMap:hideSetView()
			self:hideSetView()
			self.houseMap:updateHeros()
			self.houseMap:setManage(false)
			self:playShowAction1()
		end)

		return
	end

	if not self.houseMap:checkCanSave() then
		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("HOUSE_TEXT_32"), function (yes)
		if yes then
			self:playHideAction2(function ()
				if tolua.isnull(self.window_) then
					return
				end

				self.houseMap:hideSetView()
				self.houseMap:saveJson(self.curFloor_)
				self:hideSetView()
				self.houseMap:updateHeros()
				self.houseMap:setManage(false)
				self:playShowAction1()
			end)
		end
	end)
end

function HouseWindow:onCancelTouch()
	if self.houseMap:checkNeedSave() == false then
		self.houseMap:hideSetView()
		self:playHideAction2(function ()
			self:hideSetView()
			self.houseMap:updateHeros()
			self.houseMap:setManage(false)
			self:playShowAction1()
		end)

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("HOUSE_TEXT_33"), function (yes)
		if yes then
			self.houseMap:hideSetView()
			self:playHideAction2(function ()
				self.houseMap:clearAll()

				local items = self.house:getFurnitures(self.curFloor_)

				self.houseMap:initItems(items)
				self:hideSetView()
				self.houseMap:updateHeros()
				self.houseMap:setManage(false)
				self:updateHouseBox()
				self:playShowAction1()
			end)
		end
	end)
end

function HouseWindow:hideSetView()
	self.btnManage_:SetActive(true)
	self.btnVisit_:SetActive(true)
	self.btnShop_:SetActive(true)
	self.btnFloor_:SetActive(true)
	self.btnRest_:SetActive(true)
	self.btnClearAll_:SetActive(false)
	self.btnCombine_:SetActive(false)
	self.btnShop2_:SetActive(false)
	self.btnCancel_:SetActive(false)
	self.btnSave_:SetActive(false)
	self.groupScale:SetActive(false)
	self.groupBox_:SetActive(false)
	self.btnHide_:SetActive(true)

	if not xyd.models.house:checkApkCanShare() then
		self.btnShare_:SetActive(false)
	else
		self.btnShare_:SetActive(true)
	end

	self.isSet_ = false

	if self.houseBox_ then
		self.houseBox_:setHide(true)
	end
end

function HouseWindow:showSetView()
	self.btnManage_:SetActive(false)
	self.btnVisit_:SetActive(false)
	self.btnShop_:SetActive(false)
	self.btnFloor_:SetActive(false)
	self.btnRest_:SetActive(false)
	self.btnClearAll_:SetActive(true)
	self.btnCombine_:SetActive(true)
	self.btnShop2_:SetActive(true)
	self.btnCancel_:SetActive(true)
	self.btnSave_:SetActive(true)
	self.groupScale:SetActive(true)
	self.groupBox_:SetActive(true)
	self.btnHide_:SetActive(false)
	self.btnShare_:SetActive(false)

	self.isSet_ = true

	self:checkCanShowGroupScale()

	if self.houseBox_ then
		self.houseBox_:setHide(false)
	end
end

function HouseWindow:onManageTouch()
	self.houseMap:hideHeros()
	self.houseMap:setManage(true)
	self.houseMap:setNeedSave(false)
	self:showSetView()
	self:showBox(true, false)
	self:playShowAction2(function ()
		self:initBox()
	end)
end

function HouseWindow:onShareTouch()
	if self.house:checkCanShare() == false then
		xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_53"))

		return
	end

	local tex = XYDUtils.CameraCapture(xyd.WindowManager.get():getUICamera(), UnityEngine.Rect(0, 365, 1000, 730), 1000, 1559)

	xyd.WindowManager.get():openWindow("house_share_window", {
		height = 730,
		width = 1000,
		uploadImg = tex
	})
end

function HouseWindow:onClearAllTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("HOUSE_TEXT_20"), function (yes)
		if yes then
			self.houseMap:clearAll()
			self.houseMap:setNeedSave(true)
			self:updateHouseBox()
		end
	end)
end

function HouseWindow:onCombineTouch()
	if xyd.models.house:checkApkCanGetShot() then
		self:onCombineHide(false)
		xyd.WindowManager.get():getTopEffectNode():SetActive(false)
		self:waitForFrame(1, function ()
			local tex = XYDUtils.CameraCapture(xyd.WindowManager.get():getUICamera(), UnityEngine.Rect(0, 365, 1000, 730), 1000, 1559)

			xyd.WindowManager.get():openWindow("house_combine_window", {
				floor = self.curFloor_,
				uploadImg = tex
			})
		end)
	else
		xyd.WindowManager.get():openWindow("house_combine_window", {
			floor = self.curFloor_
		})
	end
end

function HouseWindow:onCombineHide(flag)
	if not flag then
		self.mid_left_height = self.mid_left.transform.localPosition.y
	end

	self.mid_left:SetActive(flag)
	self.bottom_left:SetActive(flag)
	self.bottom_right:SetActive(flag)
	self.bottom_mid:SetActive(flag)

	if self.mid_left_height then
		self.mid_left:Y(self.mid_left_height)
	end
end

function HouseWindow:onComfortTouch()
	self.btnComfortRedMark:SetActive(false)
	self.house:setHangRedPoint(false)
	xyd.WindowManager.get():openWindow("house_comfort_window")
end

function HouseWindow:onBoxTouch()
	self.houseBoxStatus_ = not self.houseBoxStatus_

	if self.houseBoxStatus_ then
		self:showBox(true)
	else
		self:showBox(false)
	end
end

function HouseWindow:onScaleTouchBegin(go, isPress)
	self.curWndType_ = self.WndType.SCALE
end

function HouseWindow:onScrollTouchBegin(event)
	self.curWndType_ = self.WndType.MOVE
end

function HouseWindow:onTouchBegin(event)
	dump(Input.mousePosition)
end

function HouseWindow:getTouchDistance()
	if #self.touchPoints ~= 2 then
		return 0
	end

	local ans = 0
	ans = egret.Point:distance(self.touchPoints[1].point, self.touchPoints[2].point)

	return ans
end

function HouseWindow:getTouchPoint(id)
	local selectItem = nil
	local ____TS_array = self.touchPoints

	for ____TS_index = 1, #____TS_array do
		local item = ____TS_array[____TS_index]

		if item.id == id then
			selectItem = item

			break
		end
	end

	return selectItem
end

function HouseWindow:delTouchPoint(id)
	local i = #self.touchPoints - 1

	while i >= 0 do
		if self.touchPoints[i + 1].id == id then
			__TS__ArraySplice(self.touchPoints, i, 1)

			break
		end

		i = i - 1
	end
end

function HouseWindow:onScaleEvent(event)
	local params = event.params
	local delta = params.delta
	local centerPos = params.centerPos

	if not params.double_touch then
		self.centerPoint = nil

		return
	end

	if not self.centerPoint then
		self.centerPoint = {
			worldPos = centerPos,
			oldX = self.groupMain_:X(),
			oldY = self.groupMain_:Y(),
			scale = self.curScale_
		}
	end

	local rate = math.floor((delta - 1) * 100)

	if math.abs(rate) < 1 then
		return
	end

	local newScale = Mathf.Clamp(self.curScale_ + rate, self.minScale, 100)
	self.curScale_ = newScale

	self:updateScaleBar()

	local addScale = self.centerPoint.scale - self.curScale_
	local localPos = self.groupScroll_.transform:InverseTransformPoint(self.centerPoint.worldPos)
	local changeX = localPos.x * addScale / 100
	local changeY = localPos.y * addScale / 100

	self:updatePos(self.centerPoint.oldX + changeX, self.centerPoint.oldY - changeY)
end

function HouseWindow:onTouchMove(delta)
	if self.willClose_ then
		return
	end

	if self.curWndType_ == self.WndType.SCALE then
		self:scaleMove(delta)
	elseif self.curWndType_ == self.WndType.MOVE then
		self:scrollMove(delta)
	elseif self.curWndType_ == self.WndType.DOUBLE_TOUCH then
		self:doubleTouchMove(delta)
	end
end

function HouseWindow:onTouchEnd(event)
	self.curWndType_ = self.WndType.NONE
end

function HouseWindow:scaleMove(delta)
	local height = 500
	local mouseLocalPos = xyd.mouseToLocalPos(self.groupScale.transform)
	local offY = mouseLocalPos.y
	offY = Mathf.Clamp(250 + offY, 0, height)
	local val = math.floor(100 * offY / height)

	if val % 2 == 1 then
		val = val - 1
	end

	self.barScale_.value = val / 100
	self.curScale_ = self.minScale + val / 2

	self.imgScale_:SetLocalPosition(25, offY - 250, 0)
	self:updateScale()

	local pos = self.groupMain_.transform.localPosition

	self:updatePos(pos.x, pos.y)
end

function HouseWindow:updateScale()
	self.labelScale_.text = tostring(self.curScale_) .. "%"
	local scale = self.curScale_ / xyd.PERCENT_BASE

	self.groupMain_:SetLocalScale(scale, scale, 1)
end

function HouseWindow:scrollMove(delta)
	local pos = self.groupMain_.transform.localPosition
	local endY = pos.y + delta.y
	local endX = pos.x + delta.x

	self:updatePos(endX, endY)
end

function HouseWindow:updatePos(endX, endY)
	local scale = self.curScale_ / xyd.PERCENT_BASE
	local detalY = (xyd.Global.getRealHeight() - 1280) / 178
	local minY = 50 + detalY * 90 - (scale - 0.5) * 1000
	local maxY = 330 - detalY * 80 + (scale - 0.5) * 1740
	endY = Mathf.Clamp(endY, minY, maxY)
	local maxX = 300 + (scale - 0.5) * 1400
	endX = Mathf.Clamp(endX, -maxX, maxX)

	self.groupMain_:SetLocalPosition(endX, endY, 0)
end

function HouseWindow:doubleTouchMove(event)
	local tmpID = event.touchPointID
	local recordItem = self:getTouchPoint(tmpID)

	if not recordItem then
		return
	end

	event:stopPropagation()

	local newDistance = self:getTouchDistance()
	local rate = math.floor(newDistance / self.distance_ + 0.5)

	if newDistance < self.distance_ then
		rate = -rate
	end

	local newScale = Mathf.Clamp(self.curScale_ + rate, self.minScale, 100)
	self.curScale_ = newScale

	self:updateScaleBar()

	local addScale = self.centerPoint.scale - self.curScale_
	local changeX = self.centerPoint.x * addScale / xyd.PERCENT_BASE
	local changeY = self.centerPoint.y * addScale / xyd.PERCENT_BASE
	self.groupMain_.horizontalCenter = self.centerPoint.oldX + changeX
	self.groupMain_.verticalCenter = self.centerPoint.oldY + changeY
end

function HouseWindow:initGrid()
	self.houseGrid = xyd.HouseGrid.get()

	self.houseGrid:init()
end

function HouseWindow:initMap()
	self.houseMap = xyd.HouseMap.get()

	self.houseMap:init(self.groupFurniture_, self)
	self:initGrid()
end

function HouseWindow:initFurniture()
	if self.isInitMap_ or self:isWndComplete() == false then
		return
	end

	local items = self.house:getFurnitures(self.curFloor_)

	if #items <= 0 then
		return
	end

	self.isInitMap_ = true

	self.houseMap:initOtherFloorFurniture(self.house:getOtherFurnitureNum(self.curFloor_))
	self.houseMap:initItems(items)
	self:updateBtnRes()
	self:updateHouseName()
	self.houseMap:setManage(false)
	self:updateBtnFloor()

	self.initHeroTimeKey_ = self:waitForTime(0.5, function ()
		self:initHeros()
	end)
end

function HouseWindow:updateBtnFloor()
	if not self.house:checkCanOpenFloor() then
		xyd.applyChildrenGrey(self.btnFloor_)
	else
		xyd.applyChildrenOrigin(self.btnFloor_)
	end
end

function HouseWindow:setHouseBackground(tableId)
	local imgSources = xyd.tables.houseFurnitureTable:getImg(tableId)

	for i = 1, 4 do
		xyd.setUITextureByNameAsync(self["imgBg" .. i], imgSources[i], false)
	end
end

function HouseWindow:updateHouseName()
	local dormName = self.house:getHouseName()
	self.btnHouseName_:ComponentByName("button_label", typeof(UILabel)).text = dormName
end

function HouseWindow:onUpdateHouseName()
	xyd.alert(xyd.AlertType.TIPS, __("PERSON_NAME_SUCCEED"))
	self:updateHouseName()
end

function HouseWindow:initHeros()
	if not tolua.isnull(self.window_) then
		local partnerIDs = self.house:getHeroInfos(self.curFloor_)

		self.houseMap:setHerosInfo(partnerIDs)

		if self.houseMap:canSetHeros() then
			self.houseMap:updateHeros(1)
		end

		self.btnShare_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end
end

function HouseWindow:updateBtnRes()
	local ids = self.house:getHeroInfos(self.curFloor_)
	self.btnRest_:ComponentByName("button_label", typeof(UILabel)).text = tostring(#ids) .. "/5"
	self.btnComfort_:ComponentByName("button_label", typeof(UILabel)).text = tostring(self.house:getComfortNum())
end

function HouseWindow:testPos()
	local img = eui.Image.new(true)
	img.source = "50031043_sleep_png"

	self.groupFurniture_:addChild(img)

	local pos = xyd:posRotation({
		x = 0,
		y = 0
	}, {
		x = self.groupFurniture_.width / 2,
		y = self.groupFurniture_.height / 2
	}, 45)
	img.x = pos.x
	img.y = pos.y
end

function HouseWindow:showBox(isShow, isAction)
	if isAction == nil then
		isAction = true
	end

	local imgIcon = self.btnBox_:NodeByName("imgIcon").gameObject
	local boxTransform = self.groupBox_.transform
	local btnClearAllTransform = self.btnClearAll_.transform
	local btnCombineTransform = self.btnCombine_.transform
	local btnCanceleTransform = self.btnCancel_.transform
	local btnShop2Transform = self.btnShop2_.transform
	local btnSaveTransform = self.btnSave_.transform
	local midLeftTransform = self.mid_left.transform
	local action = self:getSequence()

	if not isShow then
		imgIcon:SetLocalScale(1, -1, 1)

		if isAction then
			action:Append(boxTransform:DOLocalMove(Vector3(0, 0, 0), 0.5)):Join(btnClearAllTransform:DOLocalMove(Vector3(63, 278, 0), 0.5)):Join(btnCombineTransform:DOLocalMove(Vector3(63, 167, 0), 0.5)):Join(btnCanceleTransform:DOLocalMove(Vector3(85, 72, 0), 0.5)):Join(btnShop2Transform:DOLocalMove(Vector3(-69, 179, 0), 0.5)):Join(btnSaveTransform:DOLocalMove(Vector3(-85, 72, 0), 0.5)):Join(midLeftTransform:DOLocalMove(Vector3(-360, 0, 0), 0.5))
		else
			boxTransform:SetLocalPosition(0, 0, 0)
			midLeftTransform:SetLocalPosition(-360, 0, 0)
		end

		if self.houseBox_ then
			self.houseBox_.topBtns_:SetActive(false)
		end
	else
		imgIcon:SetLocalScale(1, 1, 1)

		if not self.houseBox_ then
			self:initBox()
		end

		self.houseBox_.topBtns_:SetActive(true)

		if isAction then
			action:Append(boxTransform:DOLocalMove(Vector3(0, 365, 0), 0.5)):Join(btnClearAllTransform:DOLocalMove(Vector3(63, 647, 0), 0.5)):Join(btnCombineTransform:DOLocalMove(Vector3(63, 536, 0), 0.5)):Join(btnCanceleTransform:DOLocalMove(Vector3(85, 441, 0), 0.5)):Join(btnShop2Transform:DOLocalMove(Vector3(-69, 548, 0), 0.5)):Join(btnSaveTransform:DOLocalMove(Vector3(-85, 441, 0), 0.5)):Join(midLeftTransform:DOLocalMove(Vector3(-360, 260, 0), 0.5))
		else
			boxTransform:SetLocalPosition(0, 365, 0)
			midLeftTransform:SetLocalPosition(-360, 260, 0)
		end
	end
end

function HouseWindow:initBox()
	if self.houseBox_ then
		self.houseBox_:checkRefresh()

		return
	end

	local boxObj = self.groupBox_:NodeByName("house_box").gameObject

	boxObj:SetActive(true)

	self.houseBox_ = HouseBox.new(boxObj)
	local width = self.window_:GetComponent(typeof(UIPanel)).width

	self.houseBox_:setInfo(width)
end

function HouseWindow:willClose()
	if self.effectChris1_ then
		self.effectChris1_:destroy()
	end

	HouseWindow.super.willClose(self)
	self.houseMap:clearAll(true)
	xyd.CameraManager.get():setEnabled(false)

	if self.initHeroTimeKey_ then
		XYDCo.StopWait(self.initHeroTimeKey_)

		self.initHeroTimeKey_ = nil
	end
end

function HouseWindow:updateHouseBox()
	if self.houseBox_ then
		self.houseBox_:updateBySetFuniture()
	end
end

function HouseWindow:getCenterStagePoint()
	local point = self.window_.transform.position

	return point
end

function HouseWindow:moveToSelectItem(item)
	local point = item:getGameObject().transform.position
	local wndPos = self.window_.transform:InverseTransformPoint(point)
	local panel = self.window_:GetComponent(typeof(UIPanel))
	local halfW = panel.width / 2
	local halfH = panel.height / 2

	if wndPos.x + halfW < 0 or wndPos.y + halfH < 0 or halfW < wndPos.x or halfH < wndPos.y then
		self:playMoveToItem(item)
	end
end

function HouseWindow:playMoveToItem(item)
	local point = item:getGameObject().transform.position
	local curPos = self.groupMain_.transform:InverseTransformPoint(point)
	local x = -curPos.x
	local y = -curPos.y
	local action = self:getSequence()

	action:Append(self.groupMain_.transform:DOLocalMove(Vector3(x, y, 0), 0.5))
end

function HouseWindow:getScreenShotOfHouse()
end

function HouseWindow:getCurFloor()
	return self.curFloor_
end

return HouseWindow
