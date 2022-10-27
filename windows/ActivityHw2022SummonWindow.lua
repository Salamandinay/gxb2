local ActivityHw2022SummonWindow = class("ActivityHw2022SummonWindow", import(".BaseWindow"))
local SelectNum = import("app.components.SelectNum")

function ActivityHw2022SummonWindow:ctor(name, params)
	ActivityHw2022SummonWindow.super.ctor(self, name, params)

	self.type_ = params.type
	self.callback_ = params.callback
	self.curNum_ = 1
end

function ActivityHw2022SummonWindow:initWindow()
	ActivityHw2022SummonWindow.super.initWindow(self)
	self:getUIComponent()
	self:updateLayout()
end

function ActivityHw2022SummonWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.labelTips_ = winTrans:ComponentByName("labelTips", typeof(UILabel))
	self.selectRoot_ = winTrans:NodeByName("selectRoot").gameObject
	self.resItem1Img_ = winTrans:ComponentByName("res_item1/res_icon", typeof(UISprite))
	self.resItem1Label_ = winTrans:ComponentByName("res_item1/res_num_label", typeof(UILabel))
	self.resItem2Img_ = winTrans:ComponentByName("res_item2/res_icon", typeof(UISprite))
	self.resItem2Label_ = winTrans:ComponentByName("res_item2/res_num_label", typeof(UILabel))
	self.sureBtn_ = winTrans:NodeByName("sureBtn").gameObject
	self.sureBtnLabel_ = winTrans:ComponentByName("sureBtn/label", typeof(UILabel))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.sureBtn_).onClick = handler(self, self.touchSure)
	self.titleLabel_.text = __("ACTIVITY_HALLOWEEN2022_GAMBLE_TEXT02")
	self.labelTips_.text = __("ACTIVITY_HALLOWEEN2022_GAMBLE_TEXT03")
	self.sureBtnLabel_.text = __("SURE")
	self.selectNum_ = SelectNum.new(self.selectRoot_, "minmax")
end

function ActivityHw2022SummonWindow:updateLayout()
	local costs = xyd.tables.activityHw2022GambleTable:getCost(self.type_)

	dump(costs, "costs")

	local maxNum = tonumber(xyd.tables.miscTable:getVal("activity_halloween2022_gamble_max"))

	for index, cost in ipairs(costs) do
		print("index   ", index)

		local img = xyd.tables.itemTable:getIcon(cost[1])

		xyd.setUISpriteAsync(self["resItem" .. index .. "Img_"], nil, img)

		self["resItem" .. index .. "Label_"].text = self.curNum_ * cost[2] .. "/" .. xyd.models.backpack:getItemNumByID(cost[1])
		maxNum = math.min(math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]), maxNum)
	end

	self.useMaxNum = maxNum

	local function callback(num)
		self.curNum_ = num

		for index = 1, 2 do
			self["resItem" .. index .. "Label_"].text = self.curNum_ * costs[index][2] .. "/" .. xyd.models.backpack:getItemNumByID(costs[index][1])
		end
	end

	self.selectNum_:setInfo({
		maxNum = self.useMaxNum,
		curNum = math.min(1, self.useMaxNum),
		callback = callback
	})
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -350)

	local value = 1

	self.selectNum_:setPrompt(value)
	self.selectNum_:setMaxNum(self.useMaxNum)
	self.selectNum_:setCurNum(1)
	self.selectNum_:changeCurNum()
end

function ActivityHw2022SummonWindow:touchSure()
	local costs = xyd.tables.activityHw2022GambleTable:getCost(self.type_)

	for index, cost in ipairs(costs) do
		if xyd.models.backpack:getItemNumByID(cost[1]) < self.curNum_ * cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end
	end

	if self.callback_ then
		self.callback_(self.curNum_)
		self:close()
	end
end

return ActivityHw2022SummonWindow
