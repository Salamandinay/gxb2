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
end

function BattleTipsWindow:layout()
	self.labelTitle_.text = __("BATTLE_TIPS_TITLE")
	self.labelDesc.text = __("BATTLE_TIPS_DESC2")
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
	local allSprites = self.window_:GetComponentsInChildren(typeof(UISprite), true)

	for i = 0, allSprites.Length - 1 do
		local sprite = allSprites[i]

		xyd.setUISprite(sprite, nil, sprite.spriteName .. "_ios_test")
	end

	self.closeBtn:GetComponent(typeof(UISprite)).height = 18
	self.closeBtn:GetComponent(typeof(UISprite)).width = 18
	self.labelTitle_.color = Color.New2(4294967295.0)
	self.labelTitle_.effectStyle = UILabel.Effect.None
	self.labelDesc.color = Color.New2(4294967295.0)
	local groupChildren = self.groupAction:NodeByName("group1").gameObject:GetComponentsInChildren(typeof(UISprite), true)
	local xyz = {
		{
			-174,
			-66
		},
		{
			-65,
			39
		},
		{
			-174,
			44
		},
		{
			-65,
			-70
		},
		{
			-38,
			-16
		},
		{
			-122,
			-93
		},
		{
			-204,
			-16
		},
		{
			-122,
			66
		}
	}

	for i = 0, 3 do
		groupChildren[i].height = 58
		groupChildren[i].width = 58
	end

	for i = 0, groupChildren.Length - 1 do
		groupChildren[i]:SetLocalPosition(xyz[i + 1][1], xyz[i + 1][2], 0)
	end
end

return BattleTipsWindow
