local BattleTipsWindow = class("BattleTipsWindow", import(".BaseWindow"))

function BattleTipsWindow:ctor(name, params)
	BattleTipsWindow.super.ctor(self, name, params)

	self.guideKey = nil
	self.isGuide_ = false
	self.callback = params.callback
end

function BattleTipsWindow:willClose()
	BattleTipsWindow.super.willClose(self)

	if self.callback ~= nil then
		self:callback()
	end

	if self.isGuide_ then
		XYDCo.StopWait("battle_tips_time_key")
		xyd.GuideController.get():completeOneGuide()
	end
end

function BattleTipsWindow:initWindow()
	BattleTipsWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function BattleTipsWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDesc = self.groupAction:ComponentByName("labelDesc", typeof(UILabel))
	self.handNode_ = self.groupAction:NodeByName("handNode_").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject

	for i = 1, 4 do
		self["label" .. i] = self.groupAction:ComponentByName("group1/group" .. i .. "/label" .. i, typeof(UILabel))
	end

	for i = 5, 6 do
		self["label" .. i] = self.groupAction:ComponentByName("group2/group" .. i .. "/label" .. i, typeof(UILabel))
	end

	for i = 7, 7 do
		self["label" .. i] = self.groupAction:ComponentByName("group3/group" .. i .. "/label" .. i, typeof(UILabel))
	end

	self.group7 = self.groupAction:NodeByName("group3/group7").gameObject
	self.group7Desc = self.groupAction:ComponentByName("group3/group7Desc", typeof(UILabel))
end

function BattleTipsWindow:layout()
	self.labelTitle_.text = __("BATTLE_TIPS_TITLE")
	self.labelDesc.text = __("BATTLE_TIPS_DESC2")

	for i = 1, xyd.GROUP_NUM do
		self["label" .. i].text = __("GROUP_" .. i)
	end

	self.group7Desc.text = __("BATTLE_TIPS_DESC3")

	if xyd.Global.lang == "fr_fr" then
		self.group7Desc.width = 216

		self.group7Desc.gameObject:X(50)
		self.group7Desc.gameObject:Y(-7)
		self.group7:X(-124)
	elseif xyd.Global.lang == "de_de" then
		self.group7Desc.width = 280

		self.group7Desc.gameObject:X(57)
		self.group7:X(-140)
	end
end

function BattleTipsWindow:showGuideHand()
	self:initHand()

	self.isGuide_ = true
end

function BattleTipsWindow:initHand()
	if self.handNode_ and not self.isNotInitHand_ then
		self.isNotInitHand_ = true
		local hand = xyd.Spine.new(self.handNode_)

		hand:setInfo("fx_ui_dianji", function ()
			hand:play("texiao01", 0)
		end)
		self.handNode_:SetActive(false)
		self:waitForTime(2, function ()
			self.handNode_:SetActive(true)
		end, "battle_tips_time_key")
	end
end

function BattleTipsWindow:iosTestChangeUI()
end

return BattleTipsWindow
