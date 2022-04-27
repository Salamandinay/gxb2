local BaseWindow = import(".BaseWindow")
local DebrisSummonWindow = class("DebrisSummonWindow", BaseWindow)
local ItemTable = xyd.tables.itemTable
local HeroIcon = require("app.components.HeroIcon")
local ItemIcon = require("app.components.ItemIcon")
local SelectNum = require("app.components.SelectNum")
local Summon = xyd.models.summon
local Slot = xyd.models.slot

function DebrisSummonWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params
	self.itemID = params.itemID or 0
	self.itemNum = params.itemNum or 0
	self.curNum_ = 1

	if self.itemID then
		self.type = ItemTable:getType(self.itemID)
	end

	if self.type ~= xyd.ItemType.ARTIFACT_DEBRIS and self.type ~= xyd.ItemType.DRESS_DEBRIS then
		self.partnerCost = ItemTable:partnerCost(self.itemID)
	elseif self.type == xyd.ItemType.DRESS_DEBRIS then
		local dress_summon_id = xyd.tables.itemTable:getSummonID(self.itemID)
		self.partnerCost = xyd.tables.summonDressTable:getCost(dress_summon_id)
	else
		self.partnerCost = ItemTable:treasureCost(self.itemID)
	end
end

function DebrisSummonWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function DebrisSummonWindow:getUIComponent()
	local go = self.window_
	self.bg = go:ComponentByName("main/bg", typeof(UISprite))
	self.groupIcon_ = go:NodeByName("main/groupIcon_").gameObject
	self.bar_ = go:ComponentByName("main/bar_", typeof(UIProgressBar))
	self.labelbar = go:ComponentByName("main/bar_/labelDisplay", typeof(UILabel))
	self.selectNumPos = go:NodeByName("main/selectNumPos").gameObject
	self.btnSummon_ = go:NodeByName("main/btnSummon_").gameObject
	self.labelBtn = go:ComponentByName("main/btnSummon_/button_label", typeof(UILabel))
	self.labelName_ = go:ComponentByName("main/labelName_", typeof(UILabel))
end

function DebrisSummonWindow:initUIComponent()
	local name = ItemTable:getName(self.itemID)
	self.labelName_.text = name
	self.selectNum_ = SelectNum.new(self.selectNumPos, "default")

	xyd.labelQulityColor(self.labelName_, self.itemID)

	self.maxNum = math.floor(self.itemNum / self.partnerCost[2])
	self.labelBtn.text = __("ITEM_SUMMON")

	self:initIcon()
	self:initbar()
	self:initTextInput()
end

function DebrisSummonWindow:initIcon()
	local params = {
		noClick = true,
		itemID = self.itemID
	}
	local icon = nil

	if self.type == xyd.ItemType.HERO_DEBRIS or self.type == xyd.ItemType.HERO_RANDOM_DEBRIS then
		icon = HeroIcon.new(self.groupIcon_)

		icon:setInfo(params)
	else
		icon = ItemIcon.new(self.groupIcon_)

		icon:setInfo(params)
	end
end

function DebrisSummonWindow:initbar()
	self.bar_.value = self.itemNum / self.partnerCost[2]
	self.labelbar.text = self.itemNum .. "/" .. self.partnerCost[2]
end

function DebrisSummonWindow:initTextInput()
	local function callback(num)
		self.curNum_ = num
	end

	self.selectNum_:setInfo({
		minNum = 1,
		maxNum = self.maxNum,
		curNum = self.maxNum,
		callback = callback
	})
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setPrompt(self.maxNum)
	self.selectNum_:setKeyboardPos(0, -310)
end

function DebrisSummonWindow:registerEvent()
	local callback = nil

	if self.type == xyd.ItemType.ARTIFACT_DEBRIS then
		callback = self.summonArtifact
	elseif self.type == xyd.ItemType.DRESS_DEBRIS then
		callback = self.summonDress
	else
		callback = self.summonTouch
	end

	xyd.setDarkenBtnBehavior(self.btnSummon_, self, callback)
end

function DebrisSummonWindow:summonArtifact()
	local summonID = ItemTable:getSummonID(self.itemID)
	local num = self.curNum_

	Summon:summonPartner(summonID, num)
	self:close()

	if xyd.WindowManager.get():isOpen("item_tips_window") then
		xyd.WindowManager.get():closeWindow("item_tips_window")
	end
end

function DebrisSummonWindow:summonDress()
	local summonID = ItemTable:getSummonID(self.itemID)
	local num = self.curNum_

	Summon:reqSummonDress(summonID, num)
	self:close()

	if xyd.WindowManager.get():isOpen("item_tips_window") then
		xyd.WindowManager.get():closeWindow("item_tips_window")
	end
end

function DebrisSummonWindow:summonTouch()
	if self.curNum_ > 0 and self.curNum_ <= self.itemNum then
		if Slot:getCanSummonNum() > 0 then
			local summonID = ItemTable:getSummonID(self.itemID)

			Summon:summonPartner(summonID, self.curNum_)
			self:close()

			if xyd.WindowManager.get():isOpen("item_tips_window") then
				xyd.WindowManager.get():closeWindow("item_tips_window")
			end
		else
			xyd.openWindow("partner_slot_increase_window")
		end
	end
end

function DebrisSummonWindow:iosTestChangeUI()
	xyd.setUISprite(self.bg, nil, "9gongge26_ios_test")
	xyd.setUISprite(self.btnSummon_:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
	xyd.setUISprite(self.window_:ComponentByName("main/bar_/bg", typeof(UISprite)), nil, "bp_bar_bg_ios_test")
	xyd.setUISprite(self.window_:ComponentByName("main/bar_/thumb", typeof(UISprite)), nil, "bp_bar_green_ios_test")
end

return DebrisSummonWindow
