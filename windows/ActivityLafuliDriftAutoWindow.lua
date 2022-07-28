local BaseWindow = import(".BaseWindow")
local ActivityLafuliDriftAutoWindow = class("ActivityLafuliDriftAutoWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function ActivityLafuliDriftAutoWindow:ctor(name, params)
	ActivityLafuliDriftAutoWindow.super.ctor(self, name, params)

	self.purchaseNum = 0
	self.parent = params.parent
	self.backpack = xyd.models.backpack
	self.itemID = params.itemID or xyd.ItemID.LAFULI_SIMPLE_DICE
	self.callback = params.callback
	self.itemNum = params.itemNum or xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE)
	self.titleLabel = params.titleLabel
	self.desc = params.descLabel
end

function ActivityLafuliDriftAutoWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:registerEvent()
end

function ActivityLafuliDriftAutoWindow:getUIComponent()
	local winTrans = self.window_.transform
	local allGroup = winTrans:NodeByName("groupAction").gameObject
	self.bgImg = allGroup:NodeByName("e:Image").gameObject
	local upGroup = allGroup:NodeByName("upGroup").gameObject
	self.labelTitle = upGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = upGroup:NodeByName("closeBtn").gameObject
	self.groupItem = allGroup:NodeByName("groupItem").gameObject
	self.descLabel = allGroup:ComponentByName("label", typeof(UILabel))
	self.textInputCon = allGroup:NodeByName("textInput").gameObject
	self.btnSure = allGroup:NodeByName("btnSure").gameObject
	self.btnSure_button_label = allGroup:ComponentByName("btnSure/button_label", typeof(UILabel))
end

function ActivityLafuliDriftAutoWindow:setLayout()
	local icon = xyd.getItemIcon({
		itemID = self.itemID,
		num = self.itemNum,
		uiRoot = self.groupItem.gameObject
	})
	self.labelTitle.text = self.titleLabel or __("ACTIVITY_LAFULI_DRIFT_AUTO_WINDOW")
	self.descLabel.text = self.desc or __("ACTIVITY_LAFULI_DRIFT_AUTO_TIP")
	local curNum_ = 1
	self.selectNum = SelectNum.new(self.textInputCon, "minmax", {})

	self.selectNum:setKeyboardPos(0, -357)
	self.selectNum:setInfo({
		minNum = 1,
		maxNum = self.itemNum,
		curNum = curNum_,
		maxCallback = function ()
		end,
		isTouchMaxCallback = function ()
		end,
		callback = function (num)
			self.purchaseNum = num

			self:updateLayout()
		end
	})
	self.selectNum:setCurNum(curNum_)

	self.btnSure_button_label.text = __("SPIRIT_BEGIN")
end

function ActivityLafuliDriftAutoWindow:updateLayout()
	local limitNum = self.itemNum

	if limitNum < self.purchaseNum then
		self.selectNum:setCurNum(limitNum)

		self.purchaseNum = limitNum

		if xyd.WindowManager.get():isOpen("alert_window") == true then
			xyd.WindowManager.get():closeWindow("alert_window")
		end
	elseif self.purchaseNum <= 0 then
		self.selectNum:setCurNum(0)

		self.purchaseNum = 0
	end
end

function ActivityLafuliDriftAutoWindow:registerEvent()
	ActivityLafuliDriftAutoWindow.super.register(self)

	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, self.onTouch)
end

function ActivityLafuliDriftAutoWindow:onTouch(evt)
	if self.callback then
		self.callback(self.purchaseNum)
	else
		self.parent:startAutoPlay(self.purchaseNum)
	end

	xyd.closeWindow(self.name_)
end

return ActivityLafuliDriftAutoWindow
