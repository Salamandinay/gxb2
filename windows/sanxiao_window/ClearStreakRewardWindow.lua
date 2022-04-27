local ClearStreakRewardWindow = class("ClearStreakRewardWindow", import(".BaseWindow"))
local DisplayConstants = xyd.DisplayConstants
local MappingData = xyd.MappingData
local DBResManager = xyd.DBResManager
local Destroy = UnityEngine.Object.Destroy
local EffectConstants = xyd.EffectConstants
local SpineManager = xyd.SpineManager

function ClearStreakRewardWindow:ctor(name, params)
	ClearStreakRewardWindow.super.ctor(self, name, params)

	self.rewardItems = {
		{
			[1001.0] = 1
		},
		{
			[1006.0] = 1,
			[1001.0] = 1
		},
		{
			[1006.0] = 1,
			[1001.0] = 1,
			[1016.0] = 1
		},
		{
			[1006.0] = 2,
			[1001.0] = 1,
			[1016.0] = 1
		},
		{
			[1006.0] = 2,
			[1001.0] = 2,
			[1016.0] = 1
		}
	}
	self.display = {}
	self.twAnimation = {}

	if params and params.onComplete then
		self.callBack = params.onComplete
	end

	self.rewardLevel = xyd.SelfInfo.get():getClearStreak() or 0

	if self.rewardLevel > 5 then
		self.rewardLevel = 5
	end

	if self.rewardLevel > 0 then
		self.items = self.rewardItems[self.rewardLevel]
	end
end

function ClearStreakRewardWindow:initWindow()
	if self.rewardLevel <= 0 then
		self:close()
	end

	self:getUIComponents()
	self:initUIComponent()
end

function ClearStreakRewardWindow:getUIComponents()
	local winTrans = self.window_.transform
	self.parenGo = winTrans:NodeByName("e:Skin").gameObject
	self.effTarget = winTrans:ComponentByName("e:Skin/eff_target", typeof(UISprite))
	self.skip_btn = winTrans:NodeByName("e:Skin/group_bg/skip_btn").gameObject
	self.ok_btn = winTrans:NodeByName("e:Skin/group_bg/ok_btn").gameObject
	self.labelNumGo = winTrans:NodeByName("e:Skin/labelNum").gameObject
	self.banner = winTrans:ComponentByName("e:Skin/banner", typeof(UISprite))
end

function ClearStreakRewardWindow:initUIComponent()
	local itemCount = 0

	for itemid, _ in pairs(self.items) do
		itemCount = itemCount + 1
		local itemNum = self.items[itemid]
		local iconName = DisplayConstants.ItemSourceMap[itemid]

		if iconName and itemNum > 0 then
			self:setItemView(itemid, iconName)
		end
	end

	self:itemAnimationStep1(itemCount)
	self.ok_btn:SetActive(false)
	self.skip_btn:SetActive(true)
	xyd.setNormalBtnBehavior(self.ok_btn, self, self.onOKBtnClick)

	UIEventListener.Get(self.skip_btn).onClick = handler(self, self.onSkipBtnClick)

	self:setDefaultBgClick(nil)
	xyd.setUISpriteAsync(self.banner, MappingData.text_lianshengjiangli, "text_lianshengjiangli")
	self.banner:SetActive(false)
end

function ClearStreakRewardWindow:setItemView(itemid, iconName)
	local itemView = xyd.ViewResManager.get():newObjectView(self.parenGo, "normal")

	itemView.gameObject:SetActive(false)

	itemView.gameObject.transform.localPosition = Vector3(0, -200, 0)

	xyd.setUISprite(itemView.compSprite, MappingData[iconName], iconName)
	itemView.compSprite:MakePixelPerfect()

	itemView.compSprite.depth = 4

	if iconName == "icon_tili" then
		itemView.compSprite.transform.localScale = Vector3(0.5, 0.5, 0.5)
	end

	local itemNum = self.items[itemid]
	local timeLimit = 0

	if itemid == 1012 then
		timeLimit = 30
	elseif itemid == 1014 then
		timeLimit = 1
	elseif itemid == 1015 or itemid > 1999 and itemid < 3000 then
		timeLimit = 2
	end

	if timeLimit > 0 then
		local limitBg = xyd.ViewResManager.get():newObjectView(itemView.compWidget.gameObject, "bitmap")

		xyd.setUISprite(limitBg, MappingData.icon_time_limit, "icon_time_limit")
		limitBg:MakePixelPerfect()

		limitBg.transform.localPosition = Vector3(40, -40, 0)
		limitBg.depth = 5
		local timeUnit = ""
		timeUnit = timeLimit == 30 and "m" or "h"
		local Textgo = NGUITools.AddChild(itemView.compWidget.gameObject, self.labelNumGo)
		local label1 = Textgo:GetComponent(typeof(UILabel))
		label1.depth = 6
		label1.text = tostring(timeLimit) .. timeUnit
		label1.transform.localPosition = Vector3(40 - label1.width, -20, 0)
	elseif itemNum > 1 then
		local Textgo = NGUITools.AddChild(itemView.compWidget.gameObject, self.labelNumGo)
		Textgo.transform.localPosition = Vector3(25, -10, 0)
		local label = Textgo:GetComponent(typeof(UILabel))
		label.depth = 5
		label.text = tostring(itemNum)
	end

	table.insert(self.display, itemView)
end

function ClearStreakRewardWindow:itemAnimationStep1(itemCount)
	SpineManager.get():newEffect(self.parenGo, EffectConstants.NEW_ITEM_REWARD, function (success, go)
		if success then
			self._eff = go
			self._eff.transform.localScale = Vector3(100, 100, 100)
			self._eff.transform.localPosition = Vector3(0, -200)
			local SpineController = self._eff:GetComponent(typeof(SpineAnim))
			self._effAnimComponent = SpineController
			SpineController.RenderTarget = self.effTarget

			SpineController:play("texiao01", 1)

			local function onComplete()
				SpineController:play("texiao02", -1)
			end

			SpineController:addListener("Complete", onComplete)
		end
	end)
	XYDCo.WaitForTime(0.9, function ()
		self.skip_btn:SetActive(false)
		self:itemAnimationStep2()
	end, "step2")
end

function ClearStreakRewardWindow:itemAnimationStep2()
	local perAngle = 0.1388888888888889 * math.pi

	for i = 1, #self.display do
		local itemView = self.display[i]

		itemView.gameObject:SetActive(true)

		itemView.gameObject.transform.localScale = Vector3(0.5, 0.5, 1)
		local angle = -((#self.display - 1) / 2) * perAngle + (i - 1) * perAngle
		local pointX = math.sin(angle) * 300
		local pointY = math.cos(angle) * 300
		local sequence1 = DG.Tweening.DOTween.Sequence()
		local trans = itemView.gameObject.transform

		sequence1:Insert(0, trans:DOLocalMove(Vector3(pointX, pointY, 0), 10 * xyd.TweenDeltaTime))
		sequence1:Insert(0, trans:DOScale(Vector3(1, 1, 1), 10 * xyd.TweenDeltaTime))
		sequence1:AppendCallback(function ()
			self.skip_btn:SetActive(false)

			local sequence2 = DG.Tweening.DOTween.Sequence()

			sequence2:Insert(0, trans:DOLocalMoveY(trans.localPosition.y - 5, 12 * xyd.TweenDeltaTime))
			sequence2:SetLoops(-1, DG.Tweening.LoopType.Yoyo)
			table.insert(self.twAnimation, sequence2)
		end)
	end

	self:setDefaultBgClick(function ()
		self:onOKBtnClick()
	end)
	self.ok_btn:SetActive(true)
	self.banner:SetActive(true)
end

function ClearStreakRewardWindow:onOKBtnClick()
	self.ok_btn:SetActive(false)
	self.banner:SetActive(false)
	self.skip_btn:SetActive(false)
	self:setDefaultBgClick(nil)

	for _, sequence in ipairs(self.twAnimation) do
		sequence:Kill()
	end

	for i = 1, #self.display do
		local itemView = self.display[i]

		itemView.gameObject:SetActive(true)

		local trans = itemView.gameObject.transform
		local sequence = DG.Tweening.DOTween.Sequence()
		local twTime = 10 * xyd.TweenDeltaTime + (i - 1) * 3 * xyd.TweenDeltaTime

		sequence:Insert(twTime, trans:DOScale(Vector3.zero, 10 * xyd.TweenDeltaTime))
		sequence:AppendCallback(function ()
			itemView.gameObject:SetActive(false)
		end)

		if i == #self.display then
			sequence:AppendCallback(function ()
				self:close()

				if self.callBack then
					self.callBack()
				end
			end)
		end
	end

	if self._eff then
		self._effAnimComponent:play("texiao03", 1)

		local function onComplete()
			self._eff:SetActive(false)
		end

		self._effAnimComponent:addListener("Complete", onComplete)
	end
end

function ClearStreakRewardWindow:onSkipBtnClick()
	self.skip_btn:SetActive(false)

	for _, sequence in ipairs(self.twAnimation) do
		sequence:Kill()
	end

	XYDCo.StopWait("step2")

	if self._eff then
		self._effAnimComponent:play("texiao02", -1)
	end

	self:itemAnimationStep2()
end

function ClearStreakRewardWindow:dispose()
	if self.eff and not tolua.isnull(self.eff) then
		Destroy(self.eff)

		self.eff = nil
	end

	ClearStreakRewardWindow.super.dispose(self)
end

return ClearStreakRewardWindow
