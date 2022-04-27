local ItemRewardWindow = class("ItemRewardWindow", import(".BaseWindow"))
local DisplayConstants = xyd.DisplayConstants
local EffectConstants = xyd.EffectConstants
local DBResManager = xyd.DBResManager
local Destroy = UnityEngine.Object.Destroy
local SpineManager = xyd.SpineManager

function ItemRewardWindow:ctor(name, params)
	ItemRewardWindow.super.ctor(self, name, params)

	self._display = {}
	self._bagX = xyd.getFixedWidth() / 2 - 200
	self._bagY = -500
	self._animationCenterX = 0
	self._animationCenterY = -200
	self._distance = 600
	self._displayTargetLabel = {}
	self._tw = {}
	self._twAnimtions = {}
	self._from = ""
	self._params = params

	if params and params.onComplete then
		self._callBack = params.onComplete
	end

	if params and params.items then
		self._items = params.items
	end

	if params and params.from then
		self._from = params.from
	end

	if params and params.progress then
		self._progress = params.progress
	end
end

function ItemRewardWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.ok_btn = winTrans:NodeByName("e:Skin/group_bg/ok_btn").gameObject
	self.root = winTrans:NodeByName("e:Skin").gameObject
	self.itemGroup = winTrans:NodeByName("e:Skin/itemGroup").gameObject
	self.bagImg = winTrans:NodeByName("e:Skin/bagImg").gameObject
	self.skip_btn = winTrans:NodeByName("e:Skin/group_bg/skip_btn").gameObject
	self.rt = winTrans:ComponentByName("e:Skin/rt", typeof(UISprite))
	self.ok_btn.transform:ComponentByName("start_btn_text", typeof(UILabel)).text = __("OK")
end

function ItemRewardWindow:initWindow()
	ItemRewardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function ItemRewardWindow:initUIComponent()
	self:setDefaultBgClick(nil)

	local function initItems()
		for itemid in pairs(self._items) do
			local itemNum = self._items[itemid]
			local iconName = DisplayConstants.ItemSourceMap[tonumber(itemid)]

			if iconName and itemNum > 0 then
				local id = tonumber(itemid)
				local timeLimit = 0

				if id == 1012 then
					timeLimit = 30
				elseif id == 1014 then
					timeLimit = 1
				elseif id == 1015 then
					timeLimit = 2
				elseif id > 1999 and id < 3000 then
					timeLimit = 2
				end

				local itemGroup = NGUITools.AddChild(self.root, self.itemGroup)
				local trans = itemGroup.transform
				local timeNum = trans:NodeByName("timeNum")
				local normalNum = trans:NodeByName("normalNum")
				local limitNum = trans:ComponentByName("timeNum/limitNum", typeof(UILabel))
				local labelNum = trans:ComponentByName("normalNum/labelNum", typeof(UILabel))
				local icon = trans:ComponentByName("icon", typeof(UISprite))

				xyd.setUISpriteAsync(icon, xyd.MappingData[iconName], iconName)

				if timeLimit > 0 then
					timeNum:SetActive(true)

					limitNum.text = tostring(timeLimit)

					if timeLimit == 30 then
						limitNum.text = limitNum.text .. "m"
					else
						limitNum.text = limitNum.text .. "h"
					end
				else
					normalNum:SetActive(true)

					if itemNum > 1 then
						labelNum.text = tostring(itemNum)
					end
				end

				itemGroup:SetActive(false)
				table.insert(self._display, itemGroup)
			end
		end

		self:itemAnimation()
		xyd.setDarkenBtnBehavior(self.ok_btn, self, self.OKBtnClick)

		UIEventListener.Get(self.skip_btn).onClick = handler(self, self.skipBtnClick)
	end

	if self._from == "quest" and self._progress == 100 then
		SpineManager.get():newEffect(self.root, EffectConstants.TEXT_END_DAY, function (success, eff)
			if success then
				self._textEff = eff
				self._textEff.transform.localScale = Vector3(100, 100, 100)
				eff.transform.localPosition = Vector3(0, 0, -1)
				local SpineController = eff:GetComponent(typeof(SpineAnim))
				SpineController.RenderTarget = self.rt

				SpineController:play("texiao", 1)

				local onComplete = nil

				function onComplete()
					initItems()
				end

				SpineController:addListener("Complete", onComplete)
			else
				initItems()
			end
		end)
	else
		initItems()
	end
end

function ItemRewardWindow:OKBtnClick()
	self:setDefaultBgClick(nil)
	self.ok_btn:SetActive(false)

	if self._eff then
		self._eff:SetActive(false)
	end

	self:step2()
end

function ItemRewardWindow:skipBtnClick()
	self.skip_btn:SetActive(false)

	for _, sq in ipairs(self._twAnimtions) do
		sq:Kill(true)
	end

	XYDCo.StopWait("step1")

	if self._eff then
		self._effAnimComponent:play("texiao02", -1)
	end

	if self._textEff and not tolua.isnull(self._textEff) then
		local SpineController = self._textEff:GetComponent(typeof(SpineAnim))

		SpineController:stop()
		self._textEff:SetActive(false)
	end

	self.ok_btn:SetActive(true)

	local perAngle = 0.1111111111111111 * math.pi

	for i = 1, #self._display do
		local angle = -((#self._display - 1) / 2) * perAngle + (i - 1) * perAngle
		local pointx = math.sin(angle) * self._distance
		local pointy = math.cos(angle) * self._distance

		self._display[i]:SetActive(true)

		local trans = self._display[i].transform
		trans.localScale = Vector3(1, 1)
		trans.localPosition = Vector3(self._animationCenterX + pointx, self._animationCenterY + pointy)
		local sequence = DG.Tweening.DOTween.Sequence()

		sequence:Append(trans:DOLocalMove(Vector3(self._animationCenterX + pointx, self._animationCenterY + pointy - 5), 10 * xyd.TweenDeltaTime))
		sequence:Append(trans:DOLocalMove(Vector3(self._animationCenterX + pointx, self._animationCenterY + pointy), 10 * xyd.TweenDeltaTime))
		sequence:SetLoops(-1)
		table.insert(self._twAnimtions, sequence)
	end

	self:setDefaultBgClick(function ()
		self:OKBtnClick()
	end)
end

function ItemRewardWindow:itemAnimation()
	local itemCount = 0

	for key in pairs(self._items) do
		itemCount = itemCount + 1
	end

	if itemCount == 1 then
		self._distance = 460
	end

	SpineManager.get():newEffect(self.root, EffectConstants.NEW_ITEM_REWARD, function (success, go)
		if success then
			self._eff = go
			self._eff.transform.localScale = Vector3(100, 100, 100)
			self._eff.transform.localPosition = Vector3(0, -240, -1)
			local SpineController = self._eff:GetComponent(typeof(SpineAnim))
			self._effAnimComponent = SpineController
			SpineController.RenderTarget = self.rt

			SpineController:play("texiao01", 1)

			local function onComplete()
				SpineController:play("texiao02", -1)
			end

			SpineController:addListener("Complete", onComplete)
		end
	end)
	XYDCo.WaitForTime(0.9, function ()
		self:step1()
	end, "step1")
end

function ItemRewardWindow:step1()
	local perAngle = 0.1111111111111111 * math.pi

	for i = 1, #self._display do
		self._display[i]:SetActive(true)

		local trans = self._display[i].transform
		trans.localScale = Vector3(0.5, 0.5)
		local sequenceFirst = DG.Tweening.DOTween.Sequence()
		local sequence = DG.Tweening.DOTween.Sequence()
		local angle = -((#self._display - 1) / 2) * perAngle + (i - 1) * perAngle
		local pointx = math.sin(angle) * self._distance
		local pointy = math.cos(angle) * self._distance

		sequenceFirst:Insert(0, trans:DOLocalMove(Vector3(self._animationCenterX + pointx, self._animationCenterY + pointy), 10 * xyd.TweenDeltaTime))
		sequenceFirst:Insert(0, trans:DOScale(Vector3(1, 1), 10 * xyd.TweenDeltaTime))
		sequenceFirst:AppendCallback(function ()
			self.ok_btn:SetActive(true)
		end)
		sequence:Insert(10 * xyd.TweenDeltaTime, trans:DOLocalMove(Vector3(self._animationCenterX + pointx, self._animationCenterY + pointy - 5), 10 * xyd.TweenDeltaTime))
		sequence:Insert(20 * xyd.TweenDeltaTime, trans:DOLocalMove(Vector3(self._animationCenterX + pointx, self._animationCenterY + pointy), 10 * xyd.TweenDeltaTime))
		sequence:SetLoops(-1)
		table.insert(self._twAnimtions, sequence)
		table.insert(self._twAnimtions, sequenceFirst)
	end
end

function ItemRewardWindow:step2()
	for _, sq in ipairs(self._twAnimtions) do
		if sq then
			sq:Kill(true)
		end
	end

	self._twAnimtions = {}
	self.bagImg.transform.localPosition = Vector3(self._bagX, self._bagY)

	self.bagImg:SetActive(true)
	self.skip_btn:SetActive(false)

	for i = 1, #self._display do
		self._display[i]:SetActive(true)

		local trans = self._display[i].transform
		local sequence = DG.Tweening.DOTween.Sequence()

		table.insert(self._twAnimtions, sequence)
		sequence:Insert(0, trans:DOLocalMove(Vector3(self._animationCenterX, self._animationCenterY + self._distance), 8 * xyd.TweenDeltaTime))
		sequence:Insert(11 * xyd.TweenDeltaTime, trans:DOLocalMove(Vector3(self._bagX, self._bagY), 10 * xyd.TweenDeltaTime))
		sequence:InsertCallback(21 * xyd.TweenDeltaTime, function ()
			self._display[i]:SetActive(false)
		end)

		local bagTrans = self.bagImg.transform

		sequence:Append(bagTrans:DOScale(Vector3(1, 0.5), 2 * xyd.TweenDeltaTime))
		sequence:Append(bagTrans:DOScale(Vector3(1, 1), 2 * xyd.TweenDeltaTime))
		sequence:AppendCallback(function ()
			self:step3()
		end)
	end

	if #self._display == 0 then
		self:step3()

		return
	end
end

function ItemRewardWindow:step3()
	xyd.WindowManager.get():closeWindow("item_reward_window")
end

function ItemRewardWindow:willClose()
	if self._eff then
		Destroy(self._eff)

		self._eff = nil
	end

	if self._textEff then
		Destroy(self._textEff)

		self._textEff = nil
	end

	ItemRewardWindow.super.willClose(self)
end

function ItemRewardWindow:dispose()
	for _, sq in ipairs(self._twAnimtions) do
		if sq then
			sq:Kill(true)
		end
	end

	self._twAnimtions = {}

	if self._callBack then
		self._callBack()
	end

	ItemRewardWindow.super.dispose(self)
end

return ItemRewardWindow
