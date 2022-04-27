local BaseWindow = import(".BaseWindow")
local ActivityIceSecretSelectWindow = class("ActivityIceSecretSelectWindow", BaseWindow)
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local ActivityIceSecretSelectItem = class("ActivityIceSecretSelectItem", import("app.components.CopyComponent"))

function ActivityIceSecretSelectWindow:ctor(name, params)
	ActivityIceSecretSelectWindow.super.ctor(self, name, params)

	self.bigRewardList_ = params.bigRewardList
	self.round_ = params.round
	self.awardedList_ = params.awardedList
	self.selectId_ = params.select_id

	if self.selectId_ then
		self.chooseId_ = self.selectId_
	end

	self.callBack_ = params.callBack
	self.SlotModel = xyd.models.slot
	self.chosenItem = nil
end

function ActivityIceSecretSelectWindow:initWindow()
	ActivityIceSecretSelectWindow.super.initWindow(self)
	self:getUIComponent()
	ActivityIceSecretSelectWindow.super.initWindow(self)
	ActivityIceSecretSelectWindow.super.register(self)
	self:initLayout()
	self:registerEvent()
	self:initSelectedIcon()
	self:initData()
end

function ActivityIceSecretSelectWindow:playOpenAnimation(callback)
	ActivityIceSecretSelectWindow.super.playOpenAnimation(self, callback)
	self.groupTop:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -1090, 0)

	self.top_tween = self:getSequence()

	self.top_tween:Append(self.groupTop.transform:DOLocalMoveY(83, 0.5))
	self.top_tween:AppendCallback(function ()
		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = self:getSequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-399, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function ActivityIceSecretSelectWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainNode = winTrans:NodeByName("mainNode").gameObject
	self.showBtn = mainNode:NodeByName("groupTop/showBtn").gameObject
	self.mySelectIcon = mainNode:NodeByName("groupTop/selectedGroup/mySelectIconGroup/myAssistantIcon").gameObject
	self.mySelectIcon_uiPanel = mainNode:ComponentByName("groupTop/selectedGroup/mySelectIconGroup/myAssistantIcon", typeof(UIPanel))
	self.btnSure = mainNode:NodeByName("groupTop/selectedGroup/btnSure").gameObject
	self.btnSure_label = mainNode:ComponentByName("groupTop/selectedGroup/btnSure/button_label", typeof(UILabel))
	self.btnCancle = mainNode:NodeByName("groupTop/selectedGroup/btnCancle").gameObject
	self.btnCancle_label = mainNode:ComponentByName("groupTop/selectedGroup/btnCancle/button_label", typeof(UILabel))
	self.labelChoose = mainNode:ComponentByName("chooseGroup/labelChoose", typeof(UILabel))
	self.labelTips = mainNode:ComponentByName("chooseGroup/labelTips", typeof(UILabel))
	self.partnerScroller = mainNode:NodeByName("chooseGroup/scroller").gameObject
	self.partnerScroller_scroller = mainNode:ComponentByName("chooseGroup/scroller", typeof(UIScrollView))
	self.partnerScroller_uiPanel = mainNode:ComponentByName("chooseGroup/scroller", typeof(UIPanel))
	self.partnerContainer = mainNode:NodeByName("chooseGroup/scroller/container").gameObject
	self.partnerContainer_MultiRowWrapContent = mainNode:ComponentByName("chooseGroup/scroller/container", typeof(MultiRowWrapContent))
	self.labelWinTitle_ = mainNode:ComponentByName("groupTop/labelWinTitle", typeof(UILabel))
	self.groupTop = mainNode:NodeByName("groupTop").gameObject
	self.chooseGroup = mainNode:NodeByName("chooseGroup").gameObject
	self.closeBtn = mainNode:NodeByName("groupTop/closeBtn").gameObject
	self.icon_root = mainNode:NodeByName("chooseGroup/icon_root").gameObject
	self.partnerScroller_uiPanel.depth = winTrans:GetComponent(typeof(UIPanel)).depth + 1
	self.mySelectIcon_uiPanel.depth = self.partnerScroller_uiPanel.depth + 1
	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScroller_scroller, self.partnerContainer_MultiRowWrapContent, self.icon_root, ActivityIceSecretSelectItem, self)
end

function ActivityIceSecretSelectWindow:initLayout()
	self.labelWinTitle_.text = __("ACTIVITY_ICE_SECRET_MAXAWARD_WINDOW")

	if xyd.Global.lang == "de_de" then
		self.labelWinTitle_.fontSize = 24
	end

	self.labelChoose.text = __("ACTIVITY_ICE_SECRET_ROUNDS", self.round_)
	self.btnSure_label.text = __("SURE")
	self.btnCancle_label.text = __("PROPHET_BTN_CANCEL")
	self.labelTips.text = __("ACTIVITY_ICE_SECRET_ITEM_TIPS")
end

function ActivityIceSecretSelectWindow:registerEvent()
	UIEventListener.Get(self.mySelectIcon.gameObject).onClick = handler(self, self.onClickSelectedIcon)
	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, self.onSelectedTouch)

	UIEventListener.Get(self.btnCancle.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.showBtn).onClick = handler(self, self.onClickShowBtn)
end

function ActivityIceSecretSelectWindow:onClickShowBtn()
	local data = nil
	local infos = self.partnerMultiWrap_:getInfos()

	for i in pairs(infos) do
		if infos[i] and infos[i] and infos[i].id == self.chooseId_ then
			data = infos[i]

			break
		end
	end

	if data then
		local params = {
			notShowGetWayBtn = true,
			show_has_num = true,
			itemID = data.award[1],
			itemNum = data.award[2] or 0,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityIceSecretSelectWindow:onClickSelectedIcon()
	if self.chooseId_ == nil then
		return
	end

	self:updateSelect()

	if self.copyIcon_tween then
		self.copyIcon_tween:Kill(true)
	end

	self.chosenItem = nil
	self.chooseId_ = nil

	NGUITools.DestroyChildren(self.mySelectIcon.transform)
end

function ActivityIceSecretSelectWindow:updateSelect()
	local items = self.partnerMultiWrap_:getItems()
	local issearch = false

	for i in pairs(items) do
		if items[i] and items[i]:getInfo() and items[i]:getInfo().id == self.chooseId_ then
			items[i]:refreshNum()
			items[i]:setChoose(false)

			issearch = true

			break
		end
	end

	if not issearch then
		local infos = self.partnerMultiWrap_:getInfos()

		for i in pairs(infos) do
			if infos[i] and infos[i] and infos[i].id == self.chooseId_ then
				local isChoosing = self:isIconSelected(infos[i].id)

				if isChoosing then
					infos[i].hasGotNum = infos[i].hasGotNum - 1

					break
				end

				infos[i].hasGotNum = infos[i].hasGotNum + 1

				break
			end
		end
	end
end

function ActivityIceSecretSelectWindow:initSelectedIcon()
	if not self.selectId_ or self.selectId_ <= 0 then
		return
	end

	NGUITools.DestroyChildren(self.mySelectIcon.transform)

	local award = xyd.tables.activityIceSecretAwardsTable:getAwards(self.selectId_)
	self.selectedIcon_ = xyd.getItemIcon({
		noClick = true,
		uiRoot = self.mySelectIcon,
		num = award[2],
		itemID = award[1]
	})
	self.chooseId_ = self.selectId_
end

function ActivityIceSecretSelectWindow:initData()
	self.selectAwardsList_ = {}
	local tempList = {}

	for _, id in ipairs(self.bigRewardList_) do
		local data = {
			id = id,
			award = xyd.tables.activityIceSecretAwardsTable:getAwards(id),
			limit = xyd.tables.activityIceSecretAwardsTable:getLimit(id),
			level = xyd.tables.activityIceSecretAwardsTable:getLevel(id),
			round = self.round_
		}

		if self.chooseId_ == id then
			data.hasGotNum = 1
		else
			data.hasGotNum = 0
		end

		tempList[id] = data
	end

	for _, id in ipairs(self.awardedList_) do
		if tempList[id] then
			tempList[id].hasGotNum = tempList[id].hasGotNum + 1
		end
	end

	for _, id in ipairs(self.bigRewardList_) do
		local data = tempList[id]

		table.insert(self.selectAwardsList_, data)
	end

	table.sort(self.selectAwardsList_, function (a, b)
		local canSelectA = a.hasGotNum < a.limit
		local canSelectB = b.hasGotNum < b.limit
		local hasLockA = tonumber(a.level) <= a.round
		local hasLockB = tonumber(b.level) <= b.round
		local wightA = 0
		local wightB = 0
		wightA = xyd.checkCondition(hasLockA, wightA + 1000, wightA)
		wightB = xyd.checkCondition(hasLockB, wightB + 1000, wightB)
		wightA = xyd.checkCondition(canSelectA, wightA + 100, wightA)
		wightB = xyd.checkCondition(canSelectB, wightB + 100, wightB)

		if wightA ~= wightB then
			return wightB < wightA
		else
			return tonumber(a.id) < tonumber(b.id)
		end
	end)
	self.partnerMultiWrap_:setInfos(self.selectAwardsList_, {})
end

function ActivityIceSecretSelectWindow:onClickheroIcon(itemIcon, needAnimation)
	local itemData = itemIcon:getInfo()
	local awardData = itemData.award

	if self.chooseId_ ~= nil then
		if self.chooseId_ == itemData.id then
			itemIcon:refreshNum()

			self.chooseId_ = nil

			itemIcon:setChoose(false)

			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end

			NGUITools.DestroyChildren(self.mySelectIcon.transform)

			self.chosenItem = nil

			return
		else
			NGUITools.DestroyChildren(self.mySelectIcon.transform)
			self:updateSelect()

			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end

			self.chosenItem = itemIcon
		end
	else
		self.chosenItem = itemIcon
	end

	itemIcon:refreshNum()

	self.chooseId_ = itemData.id

	itemIcon:setChoose(true)

	local copyIcon = xyd.getItemIcon({
		uiRoot = self.mySelectIcon,
		itemID = awardData[1],
		num = awardData[2]
	})
	self.selectedIcon_ = itemIcon

	if needAnimation then
		local nowVectoryPos = self.mySelectIcon.transform.position
		copyIcon:getIconRoot().transform.position = itemIcon:getIconRoot().transform.position
		self.copyIcon_tween = self:getSequence()

		self.copyIcon_tween:Append(copyIcon:getIconRoot().transform:DOMove(nowVectoryPos, 0.2))
		self.copyIcon_tween:AppendCallback(function ()
			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end
		end)
	end
end

function ActivityIceSecretSelectWindow:isIconSelected(id)
	if self.chooseId_ ~= nil and id == self.chooseId_ then
		return true
	else
		return false
	end
end

function ActivityIceSecretSelectWindow:onSelectedTouch()
	if self.chooseId_ and (self.chooseId_ ~= self.selectId_ or not self.selectId_) then
		self.callBack_(self.chooseId_)
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	elseif self.chooseId_ and self.chooseId_ == self.selectId_ then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	elseif not self.chooseId_ then
		xyd.showToast(__("ACTIVITY_ICE_SECRET_MAXAWARD_ERROR"))

		return
	end
end

function ActivityIceSecretSelectItem:ctor(parentGo, parent)
	self.parent_ = parent

	ActivityIceSecretSelectItem.super.ctor(self, parentGo)
end

function ActivityIceSecretSelectItem:getIconRoot()
	return self.go
end

function ActivityIceSecretSelectItem:initUI()
	ActivityIceSecretSelectItem.super.initUI(self)

	self.labelNum_ = self.go:ComponentByName("labelNum", typeof(UILabel))
	UIEventListener.Get(self.go).onClick = handler(self, self.onClick)

	UIEventListener.Get(self.go).onPress = function (go, isPressed)
		if isPressed then
			self:waitForTime(1, function ()
				local params = {
					notShowGetWayBtn = true,
					show_has_num = true,
					itemID = self.data_.award[1],
					itemNum = self.data_.award[2] or 0,
					wndType = xyd.ItemTipsWndType.ACTIVITY
				}

				xyd.WindowManager.get():openWindow("item_tips_window", params)
			end, "activity_ice_secret_select_pressed")
		else
			XYDCo.StopWait("activity_ice_secret_select_pressed")
		end
	end
end

function ActivityIceSecretSelectItem:update(_, _, info)
	if not info or not info.id then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data_ = info
	self.labelNum_.text = self.data_.limit - self.data_.hasGotNum .. "/" .. self.data_.limit
	self.labelNum_.color = Color.New2(1583978239)
	self.num_ = info.hasGotNum
	local params = {
		noClick = true,
		uiRoot = self.go,
		itemID = info.award[1],
		num = info.award[2]
	}

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon(params)
	else
		NGUITools.Destroy(self.itemIcon_.go)

		self.itemIcon_ = xyd.getItemIcon(params)
	end

	if info.round < info.level then
		self.itemIcon_:setLock(true)
	elseif info.limit <= info.hasGotNum then
		xyd.setTouchEnable(self.itemIcon_.go, false)
		xyd.applyChildrenGrey(self.itemIcon_.go)

		self.labelNum_.color = Color.New2(3422556671.0)
	else
		xyd.setTouchEnable(self.itemIcon_.go, true)
		xyd.applyChildrenOrigin(self.itemIcon_.go)
		self.itemIcon_:setChoose(false)
		self.itemIcon_:setLock(false)
	end

	local isChoosing = self.parent_:isIconSelected(self.data_.id)

	if isChoosing then
		self.itemIcon_:setChoose(true)

		self.parent_.chosenItem = self
	end
end

function ActivityIceSecretSelectItem:setChoose(flag)
	self.itemIcon_:setChoose(flag)
end

function ActivityIceSecretSelectItem:getInfo()
	return self.data_
end

function ActivityIceSecretSelectItem:onClick()
	local isChoosing = self.parent_:isIconSelected(self.data_.id)

	if self.data_.round < self.data_.level then
		xyd.showToast(__("ACTIVITY_ICE_SECRET_MAXAWARD_TIP", self.data_.level))

		return
	elseif self.data_.limit <= self.num_ and not isChoosing then
		return
	else
		self.parent_:onClickheroIcon(self, true)
	end
end

function ActivityIceSecretSelectItem:refreshNum()
	local isChoosing = self.parent_:isIconSelected(self.data_.id)

	if isChoosing then
		self.data_.hasGotNum = self.data_.hasGotNum - 1
	else
		self.data_.hasGotNum = self.data_.hasGotNum + 1
	end

	self.num_ = self.data_.hasGotNum
	self.labelNum_.text = self.data_.limit - self.data_.hasGotNum .. "/" .. self.data_.limit

	if self.data_.limit - self.data_.hasGotNum <= 0 then
		xyd.setTouchEnable(self.itemIcon_.go, false)
		xyd.applyChildrenGrey(self.itemIcon_.go)

		self.labelNum_.color = Color.New2(3422556671.0)
	else
		xyd.setTouchEnable(self.itemIcon_.go, true)
		xyd.applyChildrenOrigin(self.itemIcon_.go)

		self.labelNum_.color = Color.New2(1583978239)
	end
end

function ActivityIceSecretSelectItem:getData()
	return self.data_
end

return ActivityIceSecretSelectWindow
