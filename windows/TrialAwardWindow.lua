local BaseWindow = import(".BaseWindow")
local TrialAwardWindow = class("TrialAwardWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local BaseComponent = import("app.components.BaseComponent")
local TrialBox = class("TrialBox", BaseComponent)
local GambleRewardsWindow = import("app.windows.GambleRewardsWindow")

function TrialAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.itemEffects = {}
	self.items = {}
	self.awards = {}
	self.isEffect = false
	self.isOnData = false

	self:initEffectConfig()
end

function TrialAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()
	self:setLayout()
end

function TrialAwardWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("content").gameObject
	local titleGroup = content:NodeByName("titleGroup").gameObject
	self.closeBtn = titleGroup:NodeByName("closeBtn").gameObject
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.groupItems = middleGroup:NodeByName("groupItems").gameObject
	local groupEffects = middleGroup:NodeByName("groupEffects").gameObject

	for i = 1, 5 do
		self["effect" .. i] = groupEffects:NodeByName("effect" .. i)
		self["label" .. i] = middleGroup:ComponentByName("label" .. i, typeof(UILabel))
	end

	self.progress = middleGroup:ComponentByName("progress", typeof(UIProgressBar))
	self.groupStage = middleGroup:NodeByName("groupStage").gameObject
	self.labelCurrent = self.groupStage:ComponentByName("labelCurrent", typeof(UILabel))
	self.groupTip = trans:NodeByName("groupTip").gameObject
	self.tipBg = self.groupTip:NodeByName("tipBg").gameObject
	self.mainGroup = self.groupTip:NodeByName("mainGroup").gameObject
	self.labelTipTitle = self.mainGroup:ComponentByName("labelTipTitle", typeof(UILabel))
	self.groupTipItems = self.mainGroup:NodeByName("groupTipItems").gameObject
	self.groupTipItemsTable = self.groupTipItems:GetComponent(typeof(UITable))
end

function TrialAwardWindow:register()
	TrialAwardWindow.super.register(self)

	UIEventListener.Get(self.tipBg).onClick = function ()
		self:onCloseTip()
	end

	self.eventProxy_:addEventListener(xyd.event.TRIAL_AWARD, handler(self, self.onAwarded))
end

function TrialAwardWindow:setLayout()
	self.groupTip:SetActive(false)
	self:setText()
	self:setItems()
	self:setEffect()
end

function TrialAwardWindow:initEffectConfig()
	local current_award = xyd.models.trial:getData().current_award
	local current = xyd.models.trial.currentStage
	local can_award = math.floor((current - 1) / 3)

	if current_award < can_award then
		self.noClose = true
		self.isEffect = true

		xyd.models.trial:reqAward()
	end

	self.canIndex = can_award
	self.currentIndex = current_award
end

function TrialAwardWindow:setEffect()
	if self.currentIndex < self.canIndex then
		self.noClose = true

		for i = self.currentIndex + 1, self.canIndex do
			self:createEffect(i)
		end

		self:createEffect(self.canIndex, function ()
			self:onAwarded()
		end)
	end
end

function TrialAwardWindow:createEffect(index, callback)
	self.items[index]:setIconVisible(false)

	local name = index <= 3 and "fx_ui_ptbx" or "fx_ui_gjbx"
	local itemEffect = xyd.Spine.new(self["effect" .. index])

	itemEffect:setInfo(name, function ()
		self:playAnimation(index, callback)
	end)

	self.itemEffects[index] = itemEffect
end

function TrialAwardWindow:playAnimation(index, callback)
	local itemEffect = self.itemEffects[index]

	itemEffect:playWithEvent("texiao01", 1, 1, function (name)
		if name == "texiao01" then
			itemEffect:play("texiao02", 1)
		else
			self.items[index]:SetActive(true)
			self.itemEffects[index]:SetActive(false)
			self.items[index]:setIconVisible(true)

			if callback then
				self.noClose = false

				UIEventListener.Get(self.winBg_).onClick = function ()
					self.onClickCloseButton()
				end

				callback()
			end
		end
	end)
end

function TrialAwardWindow:didOpen()
	self.labelTipTitle.text = __("TRIAL_TEXT07")
end

function TrialAwardWindow:setText()
	local digit = {
		3,
		6,
		9,
		12,
		15
	}

	for i = 1, 5 do
		self["label" .. i].text = digit[i]
	end

	local current = xyd.models.trial.currentStage

	self:setProgressValue(current - 1)

	self.labelCurrent.text = current - 1
end

function TrialAwardWindow:setItems()
	for i = 1, 5 do
		local item = TrialBox.new(self.groupItems, i)
		local w = item.go:GetComponent(typeof(UIWidget))
		self.items[i] = item

		item.go:SetLocalScale(86 / w.width, 86 / w.height, 1)

		UIEventListener.Get(item.go).onClick = function ()
			NGUITools.DestroyChildren(self.groupTipItems.transform)

			local awards = xyd.tables.trialNodeTable:getAwards(i)

			for j = 1, #awards do
				local cost = awards[j]
				local tipTtem = ItemIcon.new(self.groupTipItems, {
					itemID = cost[1],
					num = cost[2]
				})
				local groupTipItemsWidget = self.groupTipItems:GetComponent(typeof(UIWidget))
				local tipItemWidget = tipTtem.go:GetComponent(typeof(UIWidget))
				local scale = groupTipItemsWidget.height / tipItemWidget.height

				tipTtem.go:SetLocalScale(scale, scale, scale)
				tipTtem:setLabelNumScale(1.2)
			end

			XYDCo.WaitForFrame(1, function ()
				self.groupTipItemsTable:Reposition()
			end, nil)
			self:openAwardTip()
		end
	end
end

function TrialAwardWindow:onCloseTip()
	self:closeAwardTip()
end

function TrialAwardWindow:onAwarded(event)
	if event then
		self.awards = event.data.items
	end

	if self.isOnData then
		local items = self.awards

		if items and #items > 0 then
			xyd.WindowManager.get():openWindow("gamble_rewards_window", {
				data = items,
				wnd_type = GambleRewardsWindow.WindowType.NORMAL
			})
		end
	end

	self.isOnData = true
end

function TrialAwardWindow:setProgressValue(current)
	if current == 0 then
		self.progress.value = 0
	elseif current <= 3 then
		self.progress.value = current / 15 - 0.05
	elseif current <= 15 then
		self.progress.value = current / 15 - 0.05
	end

	if current == 15 then
		self.progress.value = 1
	end
end

function TrialAwardWindow:onClickCloseButton()
	if self.noClose then
		return
	end

	BaseWindow.onClickCloseButton(self)
end

function TrialAwardWindow:openAwardTip()
	if self.openAction then
		self.openAction:Kill(false)

		self.openAction = nil
	end

	local mainGroupWidget = self.mainGroup:GetComponent(typeof(UIWidget))
	self.tipBg:GetComponent(typeof(UIWidget)).alpha = 0.5
	mainGroupWidget.alpha = 0.5

	self.groupTip:SetActive(true)

	self.openAction = DG.Tweening.DOTween.Sequence()

	dump(self.mainGroup.transform)
	self.openAction:Append(self.mainGroup.transform:DOScale(1.03, 0.1))

	local getter, setter = xyd.getTweenAlphaGeterSeter(mainGroupWidget)

	self.openAction:Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
	self.openAction:Append(self.mainGroup.transform:DOScale(1, 0.1))
end

function TrialAwardWindow:closeAwardTip()
	if self.closeAction then
		self.closeAction:Kill(false)

		self.closeAction = nil
	end

	self.tipBg:GetComponent(typeof(UIWidget)).alpha = 0
	local mainGroupWidget = self.mainGroup:GetComponent(typeof(UIWidget))
	self.closeAction = DG.Tweening.DOTween.Sequence()
	local getter, setter = xyd.getTweenAlphaGeterSeter(mainGroupWidget)

	self.closeAction:Append(self.groupTip.transform:DOScale(1.05, 0.06))
	self.closeAction:Append(self.groupTip.transform:DOScale(0.5, 0.14))
	self.closeAction:Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.14))
	self.closeAction:AppendCallback(function ()
		self.closeAction:Kill(false)

		self.closeAction = nil
		self.groupTip.transform.localScale = Vector3(1, 1, 1)

		self.groupTip:SetActive(false)
	end)
end

function TrialBox:ctor(parentGo, index)
	TrialBox.super.ctor(self, parentGo)

	self.index = index

	self:setChildren()
end

function TrialBox:getPrefabPath()
	return "Prefabs/Components/trial_box"
end

function TrialBox:initUI()
	TrialBox.super.initUI(self)

	local go = self.go
	self.imgQuality = go:ComponentByName("imgQuality", typeof(UISprite))
	self.imgQuality0 = go:ComponentByName("imgQuality0", typeof(UISprite))
	self.imgIcon = go:ComponentByName("imgIcon", typeof(UISprite))
	self.imgMask = go:NodeByName("imgMask").gameObject
	self.imgSelect = go:NodeByName("imgSelect").gameObject
	self.imgSelect_uiSprite = self.imgSelect:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.imgSelect_uiSprite, nil, "select02")
end

function TrialBox:setChildren()
	self:setState()

	if self.index > 3 then
		xyd.setUISprite(self.imgIcon, nil, "trial_icon04")
	else
		xyd.setUISprite(self.imgIcon, nil, "trial_icon06")
	end
end

function TrialBox:setState()
	local current = xyd.models.trial.currentStage

	if current > self.index * 3 then
		self.imgMask:SetActive(true)
		self.imgSelect:SetActive(true)
	else
		self.imgMask:SetActive(false)
		self.imgSelect:SetActive(false)
	end
end

function TrialBox:setIconVisible(visible)
	self.imgIcon:SetActive(visible)

	if visible then
		self:setState()
	else
		self.imgMask:SetActive(false)
		self.imgSelect:SetActive(false)
	end
end

return TrialAwardWindow
