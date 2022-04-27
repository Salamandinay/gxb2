local HouseVisitWindow = class("HouseVisitWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function HouseVisitWindow:ctor(name, params)
	HouseVisitWindow.super.ctor(self, name, params)

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
	self.houseBoxStatus_ = false
	self.isInitMap_ = false
	self.isHide_ = false
	self.isSet_ = false
	self.isResetHide_ = true
	self.openAction_ = nil
	self.timeKeys_ = {}
	self.otherPlayerID = 0
	self.data_ = nil
	self.curWndType_ = self.WndType.NONE
	self.house = xyd.models.house
	self.closeBackHouse = params.close_back_house
	self.otherPlayerID = params.other_player_id
	self.data_ = self.house:getOtherDormInfo(self.otherPlayerID)
	self.curFloor_ = 1
end

function HouseVisitWindow:initWindow()
	HouseVisitWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self.house:reqOtherDormInfo(self.otherPlayerID)
	xyd.CameraManager.get():setEnabled(true)
end

function HouseVisitWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupScale = winTrans:NodeByName("mid_left/groupScale").gameObject
	self.barScale_ = self.groupScale:ComponentByName("barScale_", typeof(UISlider))
	self.labelScale_ = self.groupScale:ComponentByName("labelScale_", typeof(UILabel))
	self.imgScale_ = self.groupScale:NodeByName("imgScale_").gameObject
	self.groupHide = winTrans:NodeByName("top_right/groupHide").gameObject
	self.btnHelp = self.groupHide:NodeByName("btnHelp").gameObject
	self.btnHide_ = self.groupHide:NodeByName("btnHide_").gameObject
	self.btnShare_ = self.groupHide:NodeByName("btnShare_").gameObject
	self.groupTopLeft_ = winTrans:NodeByName("top_left/groupTopLeft_").gameObject
	self.btnHouseName_ = self.groupTopLeft_:NodeByName("btnHouseName_").gameObject
	self.btnPraiseNum_ = self.groupTopLeft_:NodeByName("btnPraiseNum_").gameObject
	self.btnComfort_ = self.groupTopLeft_:NodeByName("btnComfort_").gameObject
	local bottom_left = winTrans:NodeByName("bottom_left").gameObject
	self.btnManage_ = bottom_left:NodeByName("btnManage_").gameObject
	self.btnVisit_ = bottom_left:NodeByName("btnVisit_").gameObject
	self.btnShop_ = bottom_left:NodeByName("btnShop_").gameObject
	self.btnDate_ = bottom_left:NodeByName("btnDate_").gameObject
	self.btnFloor_ = bottom_left:NodeByName("btnFloor_").gameObject
	self.btnFloorImg_ = self.btnFloor_:ComponentByName("btn_img", typeof(UISprite))
	self.btnClearAll_ = bottom_left:NodeByName("btnClearAll_").gameObject
	self.btnCombine_ = bottom_left:NodeByName("btnCombine_").gameObject
	self.btnCancel_ = bottom_left:NodeByName("btnCancel_").gameObject
	local bottom_right = winTrans:NodeByName("bottom_right").gameObject
	self.btnRest_ = bottom_right:NodeByName("btnRest_").gameObject
	self.btnShop2_ = bottom_right:NodeByName("btnShop2_").gameObject
	self.btnSave_ = bottom_right:NodeByName("btnSave_").gameObject
	self.btnPraise_ = bottom_right:NodeByName("btnPraise_").gameObject
	local bottom_mid = winTrans:NodeByName("bottom_mid").gameObject
	self.groupBox_ = bottom_mid:NodeByName("groupBox_").gameObject
	self.btnBox_ = self.groupBox_:NodeByName("btnBox_").gameObject
	self.groupScroll_ = winTrans:NodeByName("groupScroll_").gameObject
	self.groupMain_ = self.groupScroll_:NodeByName("groupMain_").gameObject
	self.groupFurniture_ = self.groupMain_:NodeByName("groupFurniture_").gameObject

	for i = 1, 4 do
		self["imgBg" .. i] = self.groupMain_:ComponentByName("img" .. i, typeof(UITexture))
	end

	self.bgEffect_ = winTrans:NodeByName("bgEffect").gameObject
	self.effectChris1_ = xyd.WindowManager.get():setChristmasEffect(self.bgEffect_, true)
end

function HouseVisitWindow:layout()
	self:initMap()
	self:initResItem()
	self:initScale()
	self.btnComfort_:SetActive(false)
	self.btnPraiseNum_:SetActive(true)
	self.btnPraise_:SetActive(true)
	self.btnShare_:SetActive(false)
	self.btnManage_:SetActive(false)
	self.btnShop_:SetActive(false)
	self.btnDate_:SetActive(false)
	self.btnRest_:SetActive(false)
	self.btnFloor_:SetLocalPosition(69, 70, 0)

	self.btnPraise_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_45")
	self.btnFloor_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_55")
	self.btnVisit_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_FRIEND_LIST_WINDOW")

	self:updatePraise()
end

function HouseVisitWindow:updatePraise()
	if not self.data_ then
		return
	end

	self.btnPraiseNum_:ComponentByName("button_label", typeof(UILabel)).text = self.data_.like_num or 0
end

function HouseVisitWindow:playOpenAnimation(callback)
	callback()
	self:playShowAction1(function ()
		if tolua.isnull(self.window_) then
			return
		end

		self:setWndComplete()
		self:initFurniture()
	end)
end

function HouseVisitWindow:playShowAction1(callback)
	local action1 = DG.Tweening.DOTween.Sequence()
	local topLeftTransform = self.groupTopLeft_.transform

	topLeftTransform:SetLocalPosition(0, 155, 0)
	action1:Append(topLeftTransform:DOLocalMove(Vector3(0, -74, 0), 0.2)):Append(topLeftTransform:DOLocalMove(Vector3(0, -61, 0), 0.1)):Append(topLeftTransform:DOLocalMove(Vector3(0, -64, 0), 0.1))

	local action3 = DG.Tweening.DOTween.Sequence()
	local btnPraiseTransform = self.btnPraise_.transform

	btnPraiseTransform:SetLocalPosition(-69, -145, 0)
	action3:Append(btnPraiseTransform:DOLocalMove(Vector3(-69, 85, 0), 0.2)):Append(btnPraiseTransform:DOLocalMove(Vector3(-69, 67, 0), 0.1)):Append(btnPraiseTransform:DOLocalMove(Vector3(-69, 70, 0), 0.1))

	local btnFloorTransform = self.btnFloor_.transform

	btnFloorTransform:SetLocalPosition(69, -145, 0)

	local action8 = self:getSequence()

	action8:Append(btnFloorTransform:DOLocalMove(Vector3(69, 85, 0), 0.2)):Append(btnFloorTransform:DOLocalMove(Vector3(69, 67, 0), 0.1)):Append(btnFloorTransform:DOLocalMove(Vector3(69, 70, 0), 0.1))

	local groupHideTransform = self.groupHide.transform

	groupHideTransform:SetLocalPosition(-51, 67, 0)
	XYDCo.WaitForTime(0.1, function ()
		local action4 = DG.Tweening.DOTween.Sequence()

		action4:Append(groupHideTransform:DOLocalMove(Vector3(-51, -98, 0), 0.2)):Append(groupHideTransform:DOLocalMove(Vector3(-51, -85, 0), 0.1)):Append(groupHideTransform:DOLocalMove(Vector3(-51, -88, 0), 0.1)):AppendCallback(function ()
			if callback then
				callback()
			end
		end)
	end, "")
end

function HouseVisitWindow:playCloseAnimation(callback)
	self:playHideAction1(callback)
end

function HouseVisitWindow:playHideAction1(callback)
	local action1 = DG.Tweening.DOTween.Sequence()

	action1:Append(self.groupTopLeft_.transform:DOLocalMove(Vector3(0, 91, 0), 0.2)):AppendCallback(function ()
		if callback then
			callback()
		end
	end)

	local function hideObj(obj, pos)
		local action = DG.Tweening.DOTween.Sequence()

		action:Append(obj.transform:DOLocalMove(pos, 0.2))
	end

	hideObj(self.groupHide, Vector3(-51, 67, 0))
	hideObj(self.btnPraise_, Vector3(-69, -145, 0))
	hideObj(self.btnFloor_, Vector3(69, -145, 0))
end

function HouseVisitWindow:initScale()
	self.barScale_.value = 0
	self.curScale_ = self.defaultScale

	self:updateScaleBar()
end

function HouseVisitWindow:updateScaleBar()
	local height = 500
	local percent = 2 * (self.curScale_ - self.minScale)
	self.barScale_.value = percent / 100
	local offY = height * (1 - percent / 100)

	self.imgScale_:SetLocalPosition(25, 250 - offY, 0)
	self:updateScale()
end

function HouseVisitWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_, 6000, true)
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

function HouseVisitWindow:registerEvent()
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

	UIEventListener.Get(self.btnHide_).onClick = handler(self, self.onHideTouch)
	UIEventListener.Get(self.btnPraise_).onClick = handler(self, self.onBtnPraiseTouch)
	UIEventListener.Get(self.btnHelp).onClick = handler(self, self.onHelpTouch)
	UIEventListener.Get(self.btnFloor_).onClick = handler(self, self.onBtnFloorTouch)
	UIEventListener.Get(self.btnVisit_).onClick = handler(self, self.onVisitTouch)

	self.eventProxy_:addEventListener(xyd.event.HOUSE_GET_OTHER_DORM_INFO, handler(self, self.onGetInfo))
	self.eventProxy_:addEventListener(xyd.event.HOUSE_LIKE_DORM, handler(self, self.onLikeDorm))
	self.eventProxy_:addEventListener(xyd.event.HANDLE_MAP_ZOOM, handler(self, self.onScaleEvent))
end

function HouseVisitWindow:onBtnPraiseTouch()
	if self.house:isHasPraise(self.otherPlayerID) then
		xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_46"))

		return
	end

	self.house:reqLikeDorm(self.otherPlayerID)
end

function HouseVisitWindow:onBtnFloorTouch()
	if not self:isWndComplete() then
		return
	end

	self.curFloor_ = self.curFloor_ == 1 and 2 or 1

	xyd.setUISpriteAsync(self.btnFloorImg_, nil, "house_btn_8_" .. self.curFloor_)
	self.houseMap:clearAll()

	local items = self:getFurnitures(self.curFloor_)

	self.houseMap:initItems(items)
	self:initHeros()
end

function HouseVisitWindow:onLikeDorm()
	if not self.data_ then
		return
	end

	self.data_.like_num = self.data_.like_num + 1

	self:updatePraise()
	xyd.alert(xyd.AlertType.TIPS, __("HOUSE_TEXT_51"))
end

function HouseVisitWindow:onHelpTouch()
	xyd.WindowManager.get():openWindow("help_table_window", {
		isFlow = true,
		key = "HOUSE_TEXT_38"
	})
end

function HouseVisitWindow:onVisitTouch()
	xyd.WindowManager.get():openWindow("house_friend_list_window")
end

function HouseVisitWindow:onGetInfo()
	self.data_ = self.house:getOtherDormInfo(self.otherPlayerID)

	if self:isWndComplete() then
		self:initFurniture()
	end
end

function HouseVisitWindow:onHideTouch()
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

function HouseVisitWindow:showHideView()
	self.groupTopLeft_:SetActive(not self.isHide_)
	self.groupScale:SetActive(self.isHide_)
	self.btnHelp:SetActive(not self.isHide_)
	self.btnHide_:SetActive(not self.isHide_)
	self.btnShare_:SetActive(false)
	self:checkCanShowGroupScale()
end

function HouseVisitWindow:checkCanShowGroupScale()
	if not XYDUtils.IsTest() then
		self.groupScale:SetActive(false)
	end
end

function HouseVisitWindow:onScrollTouchTap()
	self:onHideTouch()

	UIEventListener.Get(self.groupScroll_).onClick = nil
end

function HouseVisitWindow:onScaleTouchBegin(event)
	self.curWndType_ = self.WndType.SCALE
end

function HouseVisitWindow:onScrollTouchBegin(event)
	self.curWndType_ = self.WndType.MOVE
end

function HouseVisitWindow:onTouchBegin(event)
end

function HouseVisitWindow:getTouchDistance()
	if #self.touchPoints ~= 2 then
		return 0
	end

	local ans = 0
	ans = egret.Point:distance(self.touchPoints[1].point, self.touchPoints[2].point)

	return ans
end

function HouseVisitWindow:getTouchPoint(id)
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

function HouseVisitWindow:delTouchPoint(id)
	local i = #self.touchPoints - 1

	while i >= 0 do
		if self.touchPoints[i + 1].id == id then
			__TS__ArraySplice(self.touchPoints, i, 1)

			break
		end

		i = i - 1
	end
end

function HouseVisitWindow:onScaleEvent(event)
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

function HouseVisitWindow:onTouchMove(delta)
	if self.curWndType_ == self.WndType.SCALE then
		self:scaleMove(delta)
	elseif self.curWndType_ == self.WndType.MOVE then
		self:scrollMove(delta)
	elseif self.curWndType_ == self.WndType.DOUBLE_TOUCH then
		self:doubleTouchMove(delta)
	end
end

function HouseVisitWindow:onTouchEnd(event)
	self.curWndType_ = self.WndType.NONE
end

function HouseVisitWindow:scaleMove(event)
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

function HouseVisitWindow:updateScale()
	self.labelScale_.text = tostring(self.curScale_) .. "%"
	local scale = self.curScale_ / xyd.PERCENT_BASE

	self.groupMain_:SetLocalScale(scale, scale, 1)
end

function HouseVisitWindow:scrollMove(delta)
	local pos = self.groupMain_.transform.localPosition
	local endY = pos.y + delta.y
	local endX = pos.x + delta.x

	self:updatePos(endX, endY)
end

function HouseVisitWindow:updatePos(endX, endY)
	local scale = self.curScale_ / xyd.PERCENT_BASE
	local detalY = (xyd.Global.getRealHeight() - 1280) / 178
	local minY = 50 + detalY * 90 - (scale - 0.5) * 1000
	local maxY = 330 - detalY * 80 + (scale - 0.5) * 1740
	endY = Mathf.Clamp(endY, minY, maxY)
	local maxX = 300 + (scale - 0.5) * 1400
	endX = Mathf.Clamp(endX, -maxX, maxX)

	self.groupMain_:SetLocalPosition(endX, endY, 0)
end

function HouseVisitWindow:doubleTouchMove(event)
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

	local newScale = clamp(self.curScale_ + rate, self.minScale, 100)
	self.curScale_ = newScale

	self:updateScaleBar()

	local addScale = self.centerPoint.scale - self.curScale_
	local changeX = self.centerPoint.x * addScale / xyd.PERCENT_BASE
	local changeY = self.centerPoint.y * addScale / xyd.PERCENT_BASE
	self.groupMain_.horizontalCenter = self.centerPoint.oldX + changeX
	self.groupMain_.verticalCenter = self.centerPoint.oldY + changeY
end

function HouseVisitWindow:initGrid()
	self.houseGrid = xyd.HouseGrid.get()

	self.houseGrid:init()
end

function HouseVisitWindow:initMap()
	self.houseMap = xyd.HouseMap.get()

	self.houseMap:init(self.groupFurniture_, self)
	self.houseMap:setIsVisit(true)
	self:initGrid()
end

function HouseVisitWindow:getFurnitures(floor)
	local info = {}

	if self.data_ then
		if floor == 1 then
			info = self.data_.furniture_infos or {}
		elseif tostring(self.data_.ex_floor_infos) ~= "" then
			info = self.data_.ex_floor_infos[floor].furniture_infos or {}
		end
	end

	return info
end

function HouseVisitWindow:initFurniture()
	if self.isInitMap_ or self:isWndComplete() == false then
		return
	end

	local items = self:getFurnitures(self.curFloor_)

	if #items <= 0 then
		return
	end

	if self.data_ and self.data_.floor_num and self.data_.floor_num == 2 then
		self.btnFloor_:SetActive(true)
	else
		self.btnFloor_:SetActive(false)
	end

	self.isInitMap_ = true

	self.houseMap:initItems(items, self)
	self:updateHouseName()
	self:updatePraise()
	self.houseMap:setManage(false)
	self:waitForFrame(0.5, function ()
		self:initHeros()
	end, "")
end

function HouseVisitWindow:setHouseBackground(tableId)
	local imgSources = xyd.tables.houseFurnitureTable:getImg(tableId)

	for i = 1, 4 do
		xyd.setUITextureByNameAsync(self["imgBg" .. i], imgSources[i], false)
	end
end

function HouseVisitWindow:getHouseName()
	local dormName = ""

	if self.data_ then
		dormName = self.data_.dorm_name or ""
	end

	if not dormName or dormName == "" then
		dormName = __("HOUSE_TEXT_50")
	end

	return dormName
end

function HouseVisitWindow:updateHouseName()
	local dormName = self:getHouseName()
	self.btnHouseName_:ComponentByName("button_label", typeof(UILabel)).text = dormName
end

function HouseVisitWindow:getHeroInfos(floor)
	if not self.data_ then
		return {}
	end

	local partnerInfos = self.data_.partner_infos or {}
	local info = {}
	local start = (floor - 1) * 5 + 1
	local end_ = floor * 5

	for i = start, end_ do
		local item = partnerInfos[i]

		if item and item.table_id and item.table_id > 0 then
			table.insert(info, self:getHeroItemInfo(item))
		end
	end

	return info
end

function HouseVisitWindow:getHeroItemInfo(item)
	local params = {
		tableID = item.table_id,
		table_id = item.table_id,
		star = item.star,
		lev = item.lev,
		partnerID = item.partner_id,
		equipments = item.equipments,
		grade = item.grade,
		awake = item.awake,
		lovePoint = item.love_point,
		isVowed = item.is_vowed,
		show_id = item.show_id
	}

	if item.equips[7] > 0 then
		params.skin_id = item.show_id
	end

	return params
end

function HouseVisitWindow:initHeros()
	local partnerInfos = self:getHeroInfos(self.curFloor_)

	self.houseMap:setHerosInfo(partnerInfos)

	if self.houseMap:canSetHeros() then
		self.houseMap:updateHeros()
	end
end

function HouseVisitWindow:willClose()
	if self.effectChris1_ then
		self.effectChris1_:destroy()
	end

	HouseVisitWindow.super.willClose(self)
	self.houseMap:clearAll(true)
	xyd.CameraManager.get():setEnabled(false)
end

function HouseVisitWindow:excuteCallBack(isCloseAll)
	HouseVisitWindow.super.excuteCallBack(self, isCloseAll)

	if not isCloseAll and self.closeBackHouse then
		xyd.WindowManager.get():openWindow("house_window")
	end
end

return HouseVisitWindow
