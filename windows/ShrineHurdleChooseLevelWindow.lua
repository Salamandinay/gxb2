local ShrineHurdleChooseLevelWindow = class("ShrineHurdleChooseLevelWindow", import(".BaseWindow"))
local PngNum = import("app.components.PngNum")
local WindowTop = import("app.components.WindowTop")

function ShrineHurdleChooseLevelWindow:ctor(name, params)
	ShrineHurdleChooseLevelWindow.super.ctor(self, name, params)

	self.route_id_ = params.route_id
	self.numList_ = {}
end

function ShrineHurdleChooseLevelWindow:initWindow()
	ShrineHurdleChooseLevelWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLevel()
	self:updateBtnState()
	self:initTop()

	self.windowTop = WindowTop.new(self.window_, self.name_, -10, true)

	self:register()
end

function ShrineHurdleChooseLevelWindow:register()
	UIEventListener.Get(self.btnTips_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHRINE_HURDLE_DIFFICULTY_HELP"
		})
	end

	UIEventListener.Get(self.btnUp_).onClick = function ()
		self:changeDiff(1)
	end

	UIEventListener.Get(self.btnDown_).onClick = function ()
		self:changeDiff(-1)
	end

	UIEventListener.Get(self.btnUp_).onPress = function (go, isPresse)
		self:levUpLongTouchUp(isPresse, 1)
	end

	UIEventListener.Get(self.btnDown_).onPress = function (go, isPresse)
		self:levUpLongTouchUp(isPresse, -1)
	end

	UIEventListener.Get(self.confirmBtn_).onClick = handler(self, self.onClickSure)
end

function ShrineHurdleChooseLevelWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.groupLevelNum_ = winTrans:NodeByName("groupLevelNum").gameObject
	self.numLabel = PngNum.new(self.groupLevelNum_)
	self.btnUp_ = winTrans:NodeByName("btnUp").gameObject
	self.btnUpBox_ = self.btnUp_:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnUpImg_ = self.btnUp_:GetComponent(typeof(UISprite))
	self.btnDown_ = winTrans:NodeByName("btnDown").gameObject
	self.btnDownImg_ = self.btnDown_:GetComponent(typeof(UISprite))
	self.btnDownBox_ = self.btnDown_:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnTips_ = winTrans:NodeByName("groupTips/btnTips").gameObject
	self.labelTips_ = winTrans:ComponentByName("groupTips/labelTips", typeof(UILabel))
	self.confirmBtn_ = winTrans:NodeByName("confirmBtn").gameObject
	self.confirmBtnLabel_ = self.confirmBtn_:ComponentByName("label", typeof(UILabel))
end

function ShrineHurdleChooseLevelWindow:initLevel()
	self.maxDiff = xyd.models.shrineHurdleModel:getMaxDiff(self.route_id_) or 1
	local changeMaxNum = xyd.tables.miscTable:getNumber("shrine_hurdle_difficulty_float", "value")
	self.historyDiff_ = self.maxDiff - changeMaxNum

	if self.historyDiff_ <= 0 then
		self.historyDiff_ = 1
	end

	self.labelTips_.text = __("SHRINE_HURDLE_TEXT06", self.historyDiff_)
	local dif = xyd.models.shrineHurdleModel:getLastDiff(self.route_id_)
	self.diffNow_ = self.historyDiff_

	if xyd.models.shrineHurdleModel:checkInGuide() then
		self.diffNow_ = 0
	end

	self:setLevelNum(self.diffNow_)

	self.confirmBtnLabel_.text = __("SURE")
end

function ShrineHurdleChooseLevelWindow:changeDiff(changeNum)
	if self.diffNow_ + changeNum >= 1 and self.diffNow_ + changeNum <= self.maxDiff then
		self.diffNow_ = self.diffNow_ + changeNum

		self:setLevelNum(self.diffNow_)
	end

	self:updateBtnState()
end

function ShrineHurdleChooseLevelWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 100, false)

	self.windowTop:hideBg()

	local items = {
		{
			hidePlus = false,
			id = xyd.ItemID.SHRINE_TICKET
		}
	}

	self.windowTop:setItem(items)
end

function ShrineHurdleChooseLevelWindow:updateBtnState()
	if self.diffNow_ <= 1 then
		xyd.setUISpriteAsync(self.btnDownImg_, nil, "partner_detail_arrow_grey")

		self.btnDownBox_.enabled = false
	else
		xyd.setUISpriteAsync(self.btnDownImg_, nil, "partner_detail_arrow")

		self.btnDownBox_.enabled = true
	end

	if self.maxDiff <= self.diffNow_ then
		xyd.setUISpriteAsync(self.btnUpImg_, nil, "partner_detail_arrow_grey")

		self.btnUpBox_.enabled = false
	else
		xyd.setUISpriteAsync(self.btnUpImg_, nil, "partner_detail_arrow")

		self.btnUpBox_.enabled = true
	end
end

function ShrineHurdleChooseLevelWindow:setLevelNum(num)
	self.numLabel:setInfo({
		iconName = "shrine",
		num = num
	})
end

function ShrineHurdleChooseLevelWindow:levUpLongTouchUp(isPressed, num)
	local longTouchFunc = nil

	function longTouchFunc()
		self:changeDiff(num)

		if self.upLongTouchFlag == true then
			XYDCo.WaitForTime(0.1, function ()
				if not self or not self.window_ or self.window_.activeSelf == false then
					return
				end

				longTouchFunc()
			end, "levUpLongTouch")
		end
	end

	XYDCo.StopWait("levUpLongTouch")

	if isPressed then
		self.upLongTouchFlag = true

		XYDCo.WaitForTime(0.5, function ()
			if not self then
				return
			end

			if self.upLongTouchFlag then
				longTouchFunc()
			end
		end, "levUpLongTouch")
	else
		self.upLongTouchFlag = false
	end
end

function ShrineHurdleChooseLevelWindow:onClickSure()
	local function reqFunction()
		if self.diffNow_ == 0 then
			xyd.models.shrineHurdleModel:setFlag(nil, 1)

			self.hasReq_ = true

			xyd.WindowManager.get():closeWindow("shrine_hurdle_choose_way_window")
			xyd.WindowManager.get():closeWindow("shrine_hurdle_choose_level_window")
			xyd.WindowManager.get():openWindow("shrine_hurdle_window", {})

			local win = xyd.WindowManager.get():getWindow("shrine_hurdle_entrance_window")

			if win then
				win:showMid()
			end
		else
			self.hasReq_ = true

			xyd.models.shrineHurdleModel:selectRt(self.route_id_, self.diffNow_)
		end
	end

	if self.diffNow_ - self.historyDiff_ >= 1 then
		xyd.alertYesNo(__("SHRINE_HURDLE_TEXT07"), function (yes_no)
			if yes_no then
				reqFunction()
			end
		end)
	else
		reqFunction()
	end
end

function ShrineHurdleChooseLevelWindow:willClose()
	ShrineHurdleChooseLevelWindow.super.willClose(self)

	if not self.hasReq_ then
		xyd.WindowManager.get():openWindow("shrine_hurdle_choose_way_window", {})
	end
end

return ShrineHurdleChooseLevelWindow
