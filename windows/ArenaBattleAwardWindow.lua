local BaseWindow = import(".BaseWindow")
local ArenaBattleAwardWindow = class("ArenaBattleAwardWindow", BaseWindow)

function ArenaBattleAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.flag = false
	self.isCanSelect_ = false
	self.items = params.items
	self.index = params.index

	if params.delayedTop then
		self.delayedTop = params.delayedTop
	end

	self.effects_ = {}
	self.isCheckShowType = params.isCheckShowType
end

function ArenaBattleAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bg = winTrans:ComponentByName("bg", typeof(UISprite))
	self.mask_ = winTrans:ComponentByName("mask_", typeof(UISprite))
	self.groupMain = winTrans:NodeByName("groupMain").gameObject

	for i = 1, 3 do
		self["award" .. i] = self.groupMain:NodeByName("award" .. i).gameObject
		self["awardG" .. i] = self["award" .. i]:ComponentByName("g" .. i, typeof(UIWidget))
	end

	self.groupSelect = winTrans:NodeByName("groupSelect").gameObject
	self.groupChoose = self.groupSelect:NodeByName("groupChoose").gameObject
	self.groupChoose_UILayout = self.groupSelect:ComponentByName("groupChoose", typeof(UILayout))
	self.img = self.groupChoose:ComponentByName("img", typeof(UISprite))
	self.imgSelect = self.img:ComponentByName("imgSelect", typeof(UISprite))
	self.labelNever = self.groupChoose:ComponentByName("labelNever", typeof(UILabel))
	self.selectMask = self.groupSelect:NodeByName("selectMask").gameObject
end

function ArenaBattleAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.bg.alpha = 0.01

	self.mask_:SetActive(false)

	local resources = {
		"fx_ui_kapai",
		"fx_ui_kaipaitexiao"
	}

	xyd.Spine:downloadAssets(resources, function ()
		if tolua.isnull(self.window_) then
			return
		end

		self:initLayout()
		self:registerEvent()
	end)

	if self.isCheckShowType and xyd.BattleController.get():getIsNeedControllerOverCardArr()[self.isCheckShowType] then
		self.groupSelect.gameObject:SetActive(true)
		self.imgSelect.gameObject:SetActive(false)

		if xyd.Global.lang == "fr_fr" then
			self.labelNever.fontSize = 19
		end

		self.labelNever.text = __("NEW_ARENA_ALL_SERVER_TEXT_16")

		self.groupChoose_UILayout:Reposition()

		UIEventListener.Get(self.selectMask.gameObject).onClick = function ()
			self.imgSelect.gameObject:SetActive(not self.imgSelect.gameObject.activeSelf)
		end
	else
		self.groupSelect.gameObject:SetActive(false)
	end
end

function ArenaBattleAwardWindow:initLayout()
	self.bg.alpha = 0.7

	for i = 1, 3 do
		local effect = xyd.Spine.new(self["award" .. tostring(i)])

		effect:setInfo("fx_ui_kapai", function ()
			effect:play("texiao01", 1, 1, function ()
				effect:play("texiao02", 0)

				self.isCanSelect_ = true
			end)
		end)

		self.effects_[i] = effect
	end

	self:registerEvent()
end

function ArenaBattleAwardWindow:flop(index, icon, isChosen)
	local effect = self.effects_[index]

	icon:SetActive(false)
	effect:playWithEvent("texiao03", 1, 1, {
		hit = function ()
			if tolua.isnull(self.window_) then
				return
			end

			local g2 = self["awardG" .. index].transform

			g2:SetLocalScale(0.15, 1, 1)

			if not isChosen then
				g2:NodeByName("gMask"):SetActive(true)
			end

			icon:SetActive(true)

			local sequence = self:getSequence()

			sequence:AppendInterval(0.02):Append(g2:DOScaleX(1.15, 0.15)):Append(g2:DOScaleX(1, 0.1))
		end
	})

	if isChosen then
		local effect2 = xyd.Spine.new(self["award" .. index])

		effect2:setInfo("fx_ui_kaipaitexiao", function ()
			effect2:setPlayNeedStop(true)
			effect2:SetLocalScale(1.075, 1.075, 1)
			effect2:play("texiao01", 1, 1, function ()
				effect2:play("texiao02", 0)
			end)
		end)
	end
end

function ArenaBattleAwardWindow:layoutItem(touchIndex)
	self.flag = true

	xyd.setTouchEnable(self["awardG" .. touchIndex].gameObject, false)

	local tmp = self.items[touchIndex]
	self.items[touchIndex] = self.items[self.index]
	self.items[self.index] = tmp
	local icon = xyd.getItemIcon({
		hideText = true,
		itemID = self.items[touchIndex].item_id,
		num = tonumber(self.items[touchIndex].item_num),
		uiRoot = self["awardG" .. touchIndex].gameObject
	})

	self:flop(touchIndex, icon, true)
	self.mask_:SetActive(true)
	self:waitForTime(0.5, function ()
		for i = 1, 3 do
			local item = self.items[i]

			if i ~= touchIndex then
				local icon = xyd.getItemIcon({
					hideText = true,
					itemID = item.item_id,
					num = tonumber(item.item_num),
					uiRoot = self["awardG" .. i].gameObject
				})

				self:flop(i, icon)
			end
		end

		self.mask_:SetActive(false)

		self.isCardSelect_ = true
	end)
end

function ArenaBattleAwardWindow:registerEvent()
	UIEventListener.Get(self.bg.gameObject).onClick = function ()
		if self.isCardSelect_ then
			xyd.closeWindow(self.name_)
		end
	end

	for i = 1, 3 do
		UIEventListener.Get(self["awardG" .. tostring(i)].gameObject).onClick = function ()
			if not self.flag and self.isCanSelect_ then
				self:layoutItem(i)

				if self.delayedTop then
					self.delayedTop:setCanRefresh(true)
					self.delayedTop:refresResItems()
					self.delayedTop:setCanRefresh(false)
				end
			end

			xyd.SoundManager.get():playSound(xyd.SoundID.ARENA_AWARD)
		end
	end
end

function ArenaBattleAwardWindow:willClose()
	if self.isCheckShowType and xyd.BattleController.get():getIsNeedControllerOverCardArr()[self.isCheckShowType] and self.imgSelect.gameObject.activeSelf then
		xyd.db.misc:setValue({
			key = xyd.BattleController.get():getIsNeedControllerOverCardArr()[self.isCheckShowType],
			value = xyd.getServerTime()
		})
	end

	if self.delayedTop then
		self.delayedTop:setCanRefresh(true)
	end

	ArenaBattleAwardWindow.super.willClose(self)
end

return ArenaBattleAwardWindow
