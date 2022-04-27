local BaseWindow = import(".BaseWindow")
local OneClickClearanceWindow = class("OneClickClearanceWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function OneClickClearanceWindow:ctor(name, params)
	OneClickClearanceWindow.super.ctor(self, name, params)

	self.fortId = params.fortId
	self.currentStage = params.currentStage
	self.noCallback = params.noCallback
	self.fortTable_ = xyd.tables.academyAssessmentNewTable
	local time = xyd.tables.miscTable:getVal("school_practise_switch_time")

	if tonumber(time) <= xyd.getServerTime() then
		self.fortTable_ = xyd.tables.academyAssessmentNewTable2
	end
end

function OneClickClearanceWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:registerEvent()

	self.labelTitle.text = __("SCHOOL_PRACTISE_QUICK1")
end

function OneClickClearanceWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.upGroup = self.groupAction:NodeByName("upGroup").gameObject
	self.labelTitle = self.upGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.upGroup:NodeByName("closeBtn").gameObject
	self.textInput = self.groupAction:NodeByName("textInput").gameObject
	self.btnYes = self.groupAction:NodeByName("btnYes").gameObject
	self.labelYes = self.btnYes:ComponentByName("button_label", typeof(UILabel))
	self.numGroup1 = self.groupAction:NodeByName("numGroup1").gameObject
	self.ImgExchange1 = self.numGroup1:ComponentByName("ImgExchange", typeof(UISprite))
	self.labelTotal1 = self.numGroup1:ComponentByName("labelCost", typeof(UILabel))
	self.labelSplit1 = self.numGroup1:ComponentByName("labelSplit", typeof(UILabel))
	self.labelCost1 = self.numGroup1:ComponentByName("labelTotal", typeof(UILabel))
	self.numConBg1 = self.numGroup1:ComponentByName("numConBg", typeof(UISprite))
	self.labelDesc = self.groupAction:ComponentByName("labelDesc", typeof(UILabel))
	self.labelExtra = self.groupAction:ComponentByName("labelExtra", typeof(UILabel))
	self.numGroup2 = self.groupAction:NodeByName("numGroup2").gameObject
	self.ImgExchange2 = self.numGroup2:ComponentByName("ImgExchange", typeof(UISprite))
	self.labelTotal2 = self.numGroup2:ComponentByName("labelCost", typeof(UILabel))
	self.labelSplit2 = self.numGroup2:ComponentByName("labelSplit", typeof(UILabel))
	self.labelCost2 = self.numGroup2:ComponentByName("labelTotal", typeof(UILabel))
	self.numConBg2 = self.numGroup2:ComponentByName("numConBg", typeof(UISprite))
	self.btnNo = self.groupAction:NodeByName("btnNo").gameObject
	self.labelNo = self.btnNo:ComponentByName("button_label", typeof(UILabel))
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
end

function OneClickClearanceWindow:setLayout()
	self.labelYes.text = __("SCHOOL_PRACTISE_QUICK8")
	self.labelNo.text = __("SCHOOL_PRACTISE_QUICK4")
	self.labelTitle.text = __("SCHOOL_PRACTISE_QUICK1")
	self.labelExtra.text = __("SCHOOL_PRACTISE_QUICK3")
	self.cost = nil
	self.costRes1 = {
		xyd.ItemID.ASSESSMENT_TICKET,
		1
	}
	self.costRes2 = {
		xyd.ItemID.CRYSTAL,
		xyd.tables.miscTable:split2num("school_practise_ticket02_buy", "value", "#")[2]
	}
	self.current_stage = self.currentStage - 1
	local historyMaxStageID = xyd.models.academyAssessment:getMaxStage(self.fortId)
	local allIds = self.fortTable_:getIdsByFort(self.fortId)
	local checkNum = 0

	for i in pairs(allIds) do
		if historyMaxStageID == allIds[i] then
			checkNum = checkNum + 1

			break
		else
			checkNum = checkNum + 1
		end
	end

	local historyMaxStage = checkNum
	local skipStage = xyd.tables.miscTable:getNumber("school_practise_quick2", "value")
	self.left_stage = historyMaxStage - skipStage - self.current_stage
	self.canBuy1 = math.floor(xyd.models.academyAssessment:getChallengeTimes() / self.costRes1[2])
	self.canBuy2 = math.floor(xyd.models.backpack:getItemNumByID(self.costRes2[1]) / self.costRes2[2])
	self.maxCanBuy = self.canBuy1 + self.canBuy2
	self.minNum = 0

	if self.titleText == nil then
		self.labelTitle.text = self.titleText
	end

	self.selectNum = SelectNum.new(self.textInput, "minmax", {})

	self.selectNum:setMaxAndMinBtnPos(234)
	self.selectNum:setKeyboardPos(0, -357)

	local curNum_ = 1

	if self.maxCanBuy and self.maxCanBuy == 0 then
		self.purchaseNum = 0
		curNum_ = 0
	else
		self.purchaseNum = 1
		curNum_ = 1
	end

	local maxNum = math.min(self.maxCanBuy, self.left_stage)
	self.maxNum = maxNum

	self.selectNum:setInfo({
		delForceZero = true,
		minNum = 0,
		splitMode = true,
		maxNum = maxNum,
		curNum = curNum_,
		maxCallback = function ()
			self.onTouchMax = true

			self:updateLayout()
		end,
		minCallback = function ()
			self.onTouchMin = true

			self:updateLayout()
		end,
		isTouchMaxCallback = function ()
			self.isTouchMax = true
		end,
		callback = function (num)
			self.purchaseNum = num

			self:updateLayout()
		end,
		ShowMaxNumOfSplitMode = self.left_stage
	})
	self.selectNum:setCurNum(curNum_)
	xyd.setUISpriteAsync(self.ImgExchange1, nil, "icon_" .. self.costRes1[1])

	self.labelTotal1.text = xyd.models.academyAssessment:getChallengeTimes()

	xyd.setUISpriteAsync(self.ImgExchange2, nil, "icon_" .. self.costRes2[1])

	self.labelTotal2.text = xyd.models.backpack:getItemNumByID(self.costRes2[1])
	self.labelCost1.text = math.min(self.purchaseNum, self.canBuy1) * self.costRes1[2]

	if self.canBuy1 < self.purchaseNum then
		self.labelCost2.text = (self.purchaseNum - self.canBuy1) * self.costRes2[2]
	else
		self.labelCost2.text = 0
	end

	self.labelDesc.text = __("SCHOOL_PRACTISE_QUICK2", self.left_stage)
end

function OneClickClearanceWindow:registerEvent()
	OneClickClearanceWindow.super.register(self)

	UIEventListener.Get(self.btnYes).onClick = handler(self, self.onTouchBtnYes)
	UIEventListener.Get(self.btnNo).onClick = handler(self, self.onTouchBtnNo)
	UIEventListener.Get(self.btnHelp).onClick = handler(self, self.onTouchBtnHelp)
end

function OneClickClearanceWindow:onTouchBtnYes()
	if self.purchaseNum == 0 then
		xyd.alertTips(__("SCHOOL_PRACTISE_QUICK5"))

		return nil
	end

	local function callback()
		local params = require("cjson").encode({
			fort_id = self.fortId,
			num = self.purchaseNum
		})
		local msg = messages_pb:school_batch_fake_fight_req()
		msg.fort_id = self.fortId
		msg.num = self.purchaseNum

		xyd.Backend.get():request(xyd.mid.SCHOOL_BATCH_FAKE_FIGHT, msg)
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	if self.canBuy1 < self.purchaseNum then
		local costnum = (self.purchaseNum - self.canBuy1) * self.costRes2[2]

		xyd.alert(xyd.AlertType.YES_NO, __("SCHOOL_PRACTISE_QUICK6", costnum), function (yes)
			if yes then
				callback()
			end
		end)
	else
		callback()
	end
end

function OneClickClearanceWindow:onTouchBtnNo(event)
	self.noCallback()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function OneClickClearanceWindow:onTouchBtnHelp()
	xyd.WindowManager:get():openWindow("help_window", {
		key = "SCHOOL_PRACTISE_QUICK_HELP"
	})
end

function OneClickClearanceWindow:onGetMsg(event)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function OneClickClearanceWindow:updateLayout()
	if self.onTouchMax == true then
		self.selectNum:setCurNum(self.maxNum)

		self.purchaseNum = self.maxNum

		if self.left_stage <= self.purchaseNum then
			xyd.alertTips(__("SCHOOL_PRACTISE_QUICK7"))
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.costRes2[1])))
		end

		self.labelCost1.text = math.min(self.purchaseNum, self.canBuy1) * self.costRes1[2]

		if self.canBuy1 < self.purchaseNum then
			self.labelCost2.text = (self.purchaseNum - self.canBuy1) * self.costRes2[2]
		else
			self.labelCost2.text = 0
		end

		self.onTouchMax = false

		return nil
	end

	if self.onTouchMin == true then
		self.selectNum:setCurNum(self.minNum)

		self.purchaseNum = self.minNum
		self.labelCost1.text = math.min(self.purchaseNum, self.canBuy1) * self.costRes1[2]

		if self.canBuy1 < self.purchaseNum then
			self.labelCost2.text = (self.purchaseNum - self.canBuy1) * self.costRes2[2]
		else
			self.labelCost2.text = 0
		end

		self.onTouchMin = false

		return nil
	end

	if self.maxNum < self.purchaseNum then
		print(self.maxNum)
		self.selectNum:setCurNum(self.maxNum)

		self.purchaseNum = self.maxNum

		if self.left_stage <= self.purchaseNum then
			xyd.alertTips(__("11111"))
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.costRes2[1])))
		end
	end

	self.labelCost1.text = math.min(self.purchaseNum, self.canBuy1) * self.costRes1[2]

	if self.canBuy1 < self.purchaseNum then
		self.labelCost2.text = (self.purchaseNum - self.canBuy1) * self.costRes2[2]
	else
		self.labelCost2.text = 0
	end
end

return OneClickClearanceWindow
