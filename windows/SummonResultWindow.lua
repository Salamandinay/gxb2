local BaseWindow = import(".BaseWindow")
local SummonResultWindow = class("SummonResultWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")
local SummonButton = import("app.components.SummonButton")
local HeroAltarItem = class("HeroAltarItem", import("app.components.CopyComponent"))
local TypeEnum = {
	SUPER = 6,
	NEWBEE_SUMMON = 7,
	SENIOR = 2,
	SIMULATION_GACHA = 9,
	BAODI = 3,
	WISH = 5,
	LIMIT_TEN = 8,
	BASE = 1,
	FRIEND = 4
}

function SummonResultWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.isFiveStarSummon = false
	self.buttons = {}
	self.items = {}
	self.hasPipiluo = false
	self.showLimitTen = false
end

function SummonResultWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()

	local summonGiftData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_SUMMON_GIFTBAG)

	if summonGiftData and xyd.getServerTime() < summonGiftData:getEndTime() then
		self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.refreshSeniorSummonTimes))
		self:getSeniorSummonUIComponent()
	else
		self.bottomGroup:SetActive(false)
	end
end

function SummonResultWindow:getUIComponent()
	local go = self.window_
	self.topGroup = go:NodeByName("topGroup").gameObject
	self.bottomGroup = go:NodeByName("bottom_group").gameObject
	self.baodi_progress = go:ComponentByName("topGroup/baodi_progress", typeof(UIProgressBar))
	self.baodi_progress_thumb = go:ComponentByName("topGroup/baodi_progress/thumb", typeof(UISprite))
	self.fx_mask = go:ComponentByName("topGroup/baodi_progress/fx_mask", typeof(UITexture))
	self.baodi_progress_label = go:ComponentByName("topGroup/baodi_progress/labelDisplay", typeof(UILabel))
	self.baodi_tips = go:ComponentByName("topGroup/baodi_tips", typeof(UISprite))
	self.baodi_summon = go:NodeByName("topGroup/baodi_summon").gameObject
	self.groupPartners = go:NodeByName("groupPartners").gameObject
	self.content_ = go:NodeByName("groupPartners/content").gameObject
	self.gPartners = go:NodeByName("groupPartners/content/gPartners").gameObject
	self.gridOfItems_ = go:ComponentByName("groupPartners/content/gPartners", typeof(UIGrid))
	self.hero_altar_item = go:NodeByName("groupPartners/content/hero_altar_group").gameObject
	self.scrollView_ = self.content_:GetComponent(typeof(UIScrollView))
	self.bgPartners = go:ComponentByName("groupPartners/bgPartners", typeof(UISprite))
	self.energyEffect = go:ComponentByName("energyEffect", typeof(UIWidget))
	self.frameEffect = go:ComponentByName("frameEffect", typeof(UIWidget))
	local parent = go:NodeByName("buttons").gameObject
	self.buttonsGrid = parent:GetComponent(typeof(UIGrid))
	self.btnOk = SummonButton.new(parent:NodeByName("btn1").gameObject)
	self.btnSummonLeft = SummonButton.new(parent:NodeByName("btn2").gameObject)
	self.btnSummonRight = SummonButton.new(parent:NodeByName("btn3").gameObject)
end

function SummonResultWindow:initUIComponent()
	table.insert(self.buttons, self.btnOk:getGameObject():GetComponent(typeof(UISprite)))
	table.insert(self.buttons, self.btnSummonLeft:getGameObject():GetComponent(typeof(UISprite)))
	table.insert(self.buttons, self.btnSummonRight:getGameObject():GetComponent(typeof(UISprite)))

	local baodiCost = xyd.tables.summonTable:getCost(xyd.SummonType.BAODI)
	self.baodiCost = baodiCost[2]
	self.baodi_progress.value = self.params_.oldBaodiEnergy / self.baodiCost
	self.baodi_progress_label.text = self.params_.oldBaodiEnergy .. "/" .. self.baodiCost
	local needEffect = {
		"fx_ui_niudanshengji",
		"huakuang"
	}

	if xyd.models.backpack:getLev() > 1 or xyd.NOT_SHOW_GUIDE then
		needEffect = {
			"fx_ui_niudanshengji",
			"huakuang",
			"fx_ui_niudan",
			"fx_ui_niudanfaguang",
			"fx_dajiangchuchang",
			"fx_ui_beijingguang"
		}
	end

	self:initButton()
	xyd.Spine:downloadAssets(needEffect, xyd.scb(self.window_, function ()
		if not self.params_ then
			return
		end

		self:updateProgressBar()

		if self.params_.type == TypeEnum.SENIOR then
			-- Nothing
		elseif self.params_.type == TypeEnum.BAODI then
			self:setTimeout(function ()
				self.baodi_progress.value = self.params_.progressValue / self.baodiCost
				self.baodi_progress_label.text = self.params_.progressValue .. "/" .. self.baodiCost
			end, self, 1000)
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.SUMMON_BG_SHOW)
		self:playEffect()

		local function fiftyCallback()
			local summonId = self.params_.summonId
			local fiftySummonStatus = xyd.models.summon:getFiftySummonStatus()

			if fiftySummonStatus then
				if summonId == xyd.SummonType.SENIOR_CRYSTAL_TEN or summonId == xyd.SummonType.SENIOR_SCROLL_TEN then
					local costData = xyd.tables.summonTable:getCost(summonId)
					local itemNum = xyd.models.backpack:getItemNumByID(costData[1])
					local fiftySummonTimes = xyd.models.summon:getFiftySummonTimes()

					if fiftySummonTimes + 1 <= 5 and tonumber(costData[2]) <= itemNum then
						xyd.models.summon:summonPartner(summonId, nil, fiftySummonTimes + 1)
					else
						xyd.models.summon:setFiftySummonTimes(0)

						self.scrollView_.enabled = true

						xyd.MainController.get():addEscListener()

						self.isPlayAni = false
					end
				else
					self.isPlayAni = false
				end
			else
				self.isPlayAni = false
			end
		end

		local summonIndex = tonumber(self.params_.summonIndex) or 0

		if summonIndex == 1 then
			xyd.MainController.get():removeEscListener()
		end

		self.scrollView_.enabled = false
		self.isPlayAni = true

		self:playPartnerAction(false, nil, fiftyCallback)
	end))

	if self.params_.type == TypeEnum.SUPER or self.params_.type == TypeEnum.NEWBEE_SUMMON or self.params_.type == TypeEnum.SIMULATION_GACHA then
		self.topGroup:SetActive(false)
	end
end

function SummonResultWindow:ResetScrollPos()
	self.scrollView_:ResetPosition()

	self.content_:GetComponent(typeof(UIPanel)).transform.localPosition = Vector3(0, 0, 0)
	self.content_:GetComponent(typeof(UIPanel)).clipOffset = Vector2(0, 0)
	self.gridOfItems_.transform.localPosition = Vector3(-265, 60, 0)
	self.gridOfItems_.pivot = UIWidget.Pivot.TopLeft
end

function SummonResultWindow:updateWindow(params)
	local summonIndex = tonumber(params.summonIndex) or 0
	self.params_ = params

	if summonIndex > 0 then
		self:playFiftySummon(params)
	else
		self:playNewSummon()
	end
end

function SummonResultWindow:playFiftySummon(params)
	local summonResData = xyd.models.summon:getFiftySummonData()
	local uiGrid = self.gridOfItems_

	local function playScroll(delta, endCallback)
		local pos = uiGrid.transform.localPosition
		local seq = self:getSequence()

		seq:Append(uiGrid.transform:DOLocalMove(Vector3(pos.x, pos.y + delta, pos.z), 0.6))
		seq:AppendCallback(function ()
			self:delSequene(seq)

			if endCallback then
				endCallback()
			end
		end)
	end

	local summonIndex = tonumber(params.summonIndex) or 0
	local summonId = tonumber(params.summonId) or 0

	local function callback()
		local fiftySummonStatus = xyd.models.summon:getFiftySummonStatus()

		if fiftySummonStatus and (summonId == xyd.SummonType.SENIOR_CRYSTAL_TEN or summonId == xyd.SummonType.SENIOR_SCROLL_TEN) then
			local costData = xyd.tables.summonTable:getCost(summonId)
			local itemNum = xyd.models.backpack:getItemNumByID(costData[1])
			local fiftySummonTimes = xyd.models.summon:getFiftySummonTimes()

			if fiftySummonTimes + 1 <= 5 and tonumber(costData[2]) <= itemNum then
				xyd.models.summon:summonPartner(summonId, nil, fiftySummonTimes + 1)
			else
				self.scrollView_.enabled = true

				xyd.MainController.get():addEscListener()
				xyd.models.summon:setFiftySummonTimes(0)

				self.isPlayAni = false
			end
		end
	end

	if summonIndex > 1 then
		playScroll(260, function ()
			self:playPartnerAction(true, params, callback)
		end)
	else
		self:ResetScrollPos()

		self.items = {}

		NGUITools.DestroyChildren(self.gPartners.transform)
		self:playPartnerAction(true, params, callback)
	end
end

function SummonResultWindow:playDisappear(onComplete, summonType, summonIndex)
	self.params_.type = summonType

	self:initButton(summonIndex)

	local sequence = self:getSequence()

	local function setter(value)
		self.groupPartners.gameObject:SetLocalScale(value, value, value)
		self.frameEffect.gameObject:SetLocalScale(value, value, value)
	end

	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 1.07, 0.1):SetEase(DG.Tweening.Ease.Linear))
	onComplete()
	sequence:InsertCallback(0.07, xyd.scb(self.window_, function ()
		self:playEffect()
	end))
end

function SummonResultWindow:playNewSummon()
	self:setTimeout(function ()
		self:playPartnerAction(true)
	end, self, 50)
	self:updateBaodi(self.params_)
end

function SummonResultWindow:updateBaodi(params)
	if params.type == TypeEnum.BAODI then
		self:setTimeout(function ()
			self.baodi_progress.value = params.progressValue / self.baodiCost
			self.baodi_progress_label.text = params.progressValue .. "/" .. self.baodiCost
		end, self, 1000)

		local vipNeed = xyd.tables.summonTable:getVipNeed(xyd.SummonType.BAODI)
		local vip = xyd.models.backpack:getVipLev()

		if params.progressValue < self.baodiCost or vip < vipNeed then
			self.baodi_tips:SetActive(true)
			self.baodi_summon:SetActive(false)

			if self.progressSpine then
				self.progressSpine:stop()
				self.progressSpine:SetActive(false)
			end

			if self.baodiSpine then
				self.baodiSpine:stop()
				self.baodiSpine:SetActive(false)
			end
		end
	else
		self:updateProgressBar()
	end
end

function SummonResultWindow:updateProgressBar()
	local vipNeed = xyd.tables.summonTable:getVipNeed(xyd.SummonType.BAODI)
	local vip = xyd.models.backpack:getVipLev()

	if self.params_.progressValue < self.baodiCost or vip < vipNeed then
		self.baodi_tips:SetActive(true)
		self.baodi_summon:SetActive(false)
	else
		self.baodi_tips:SetActive(false)
		self.baodi_summon:SetActive(true)

		if not self.progressSpine then
			self.progressSpine = xyd.Spine.new(self.fx_mask.gameObject)

			self.progressSpine:setInfo("fx_ui_niudanfaguang", function ()
				self.progressSpine:SetLocalScale(0.98, 0.98, 1)
				self.progressSpine:setRenderTarget(self.fx_mask, 1)
			end)
		end

		if not self.baodiSpine then
			self.baodiSpine = xyd.Spine.new(self.baodi_summon.gameObject)

			self.baodiSpine:setInfo("fx_ui_niudan", function ()
				self.baodiSpine:SetLocalScale(1, 1, 1)
				self.baodiSpine:setRenderTarget(self.baodi_summon:GetComponent(typeof(UISprite)), 2)
			end)
		end

		self.progressSpine:play("texiao01", 0, 1, nil)
		self.baodiSpine:play("texiao01", 0, 1, nil)
	end
end

function SummonResultWindow:playEffect()
	if not self.huakuangEffect then
		self.huakuangEffect = xyd.Spine.new(self.frameEffect.gameObject)

		self.huakuangEffect:setInfo("huakuang", function ()
			self.huakuangEffect:setRenderTarget(self.bgPartners, 1)
		end)
	end

	self.huakuangEffect:play("texiao01", 1, 1, function ()
		self.huakuangEffect:play("texiao02", 0)
	end, true)
end

function SummonResultWindow:playLastEffect()
	if tolua.isnull(self.window_) then
		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.SUMMON_END)
	self.huakuangEffect:play("texiao03", 1, 1, function ()
		self.huakuangEffect:SetActive(false)

		if self.params_ and self.params_.type and (self.params_.type == TypeEnum.SENIOR or self.params_.type == TypeEnum.WISH or self.params_.type == TypeEnum.LIMIT_TEN) then
			self:addEnergyEffect()
		end
	end, true)
end

function SummonResultWindow:playPartnerAction(isUpdate, params, aniCallback)
	local uiGrid = self.gridOfItems_
	params = params or self.params_
	local summonIndex = tonumber(params.summonIndex) or 0

	if #params.items == 1 then
		uiGrid.pivot = UIWidget.Pivot.Center

		uiGrid:SetLocalPosition(0, 0, 0)
	elseif summonIndex <= 1 then
		uiGrid.pivot = UIWidget.Pivot.TopLeft

		uiGrid:SetLocalPosition(-265, 60, 0)
	end

	uiGrid.cellWidth = 132
	uiGrid.cellHeight = 132
	uiGrid.maxPerLine = 5

	if summonIndex <= 1 then
		for i in pairs(self.items) do
			local heroIcon = self.items[i]:getHeroIcon()

			heroIcon:setStarsState(false)
		end

		self.items = {}

		NGUITools.DestroyChildren(self.gPartners.transform)
	end

	local partners = params.items

	if not isUpdate then
		self.groupPartners:SetActive(false)
	end

	self:setTimeout(function ()
		self.groupPartners:SetActive(true)

		for i = 1, #partners do
			if partners[i].item_id == tonumber(xyd.split(xyd.tables.miscTable:getVal("graduate_gift_partner"), "|")[1]) then
				self.hasPipiluo = true
			end

			local heroAltarItemObject = NGUITools.AddChild(self.gPartners, self.hero_altar_item)
			local hAltaritem = HeroAltarItem.new(heroAltarItemObject)

			hAltaritem:setInfo({
				itemID = partners[i].item_id,
				dragScrollView = self.scrollView_,
				parentWin = self,
				noWays = self.params_.type == TypeEnum.SIMULATION_GACHA and true or nil
			})
			table.insert(self.items, hAltaritem)

			local icon = heroAltarItemObject
			icon:GetComponent(typeof(UIWidget)).alpha = 0

			local function setter(val)
				icon:GetComponent(typeof(UIWidget)).alpha = val
			end

			local sequence = self:getSequence()
			local heroIcon = hAltaritem:getHeroIcon()

			if summonIndex == 0 then
				sequence:AppendInterval(0.1 * i)
				sequence:AppendCallback(xyd.scb(self.window_, function ()
					if icon and not tolua.isnull(icon) and not tolua.isnull(self.window_) then
						icon:SetLocalScale(0.36, 0.36, 1)
					end
				end))
				sequence:Append(icon.transform:DOScale(1.2, 0.13))
				sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.13))
				self:fiveStarEffect(partners[i].item_id, heroIcon, sequence, 0.1 * i)
				sequence:Append(icon.transform:DOScale(0.9, 0.16))
				sequence:Append(icon.transform:DOScale(1, 0.16))
				sequence:AppendCallback(xyd.scb(self.window_, function ()
					self:resizeBg(i, #partners, {
						self.groupPartners,
						self.frameEffect.gameObject
					})
				end))
				sequence:AppendInterval(0.1 * (#partners - i))
				sequence:Append(icon.transform:DOScale(0.95, 0.1))
				sequence:Append(icon.transform:DOScale(1.05, 0.13))
				sequence:Append(icon.transform:DOScale(1, 0.16))
			else
				local speedNum = 2

				sequence:AppendInterval(0.1 * i / speedNum)
				sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.13 / speedNum))
				self:fiveStarEffect(partners[i].item_id, heroIcon, sequence, 0.1 * i / speedNum)
				sequence:AppendInterval(0.1 * (#partners - i) / speedNum)

				if summonIndex == 5 then
					sequence:AppendCallback(xyd.scb(self.window_, function ()
						self:resizeBg(i, #partners, {
							self.groupPartners,
							self.frameEffect.gameObject
						})
					end))
				end
			end

			sequence:AppendCallback(function ()
				self:delSequene(sequence)
				self:freeBtn(i, #partners, aniCallback, summonIndex)
			end)
		end

		uiGrid:Reposition()
	end, self, 100)
end

function SummonResultWindow:fiveStarEffect(itemID, icon, sequence, t)
	local star = xyd.tables.partnerTable:getStar(itemID)

	if star >= 5 then
		local effect1 = icon:setBackEffect(true, "fx_ui_beijingguang", "texiao")
		local effect2 = icon:setEffect(true, "fx_dajiangchuchang", {
			playname = "texiao",
			playCount = 1
		})

		xyd.SoundManager.get():playSound(xyd.SoundID.GAMEBLE_VALUABLE)

		self.isFiveStarSummon = true

		local function setter(val)
			effect1:setAlpha(val)
			effect2:setAlpha(val)
		end

		sequence:Join(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 0.5, 0.13))
		sequence:AppendCallback(function ()
			effect1:SetActive(true)
			effect2:SetActive(true)
		end)

		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.GAMEBLE_NORMAL)
end

function SummonResultWindow:freeBtn(index, length, aniCallback, summonIndex)
	if index == length then
		if summonIndex == 0 or summonIndex == 5 then
			if self.params_.type == TypeEnum.SENIOR then
				xyd.models.selfPlayer:openNewPlayerTipsWindow(xyd.NewPlayerTipsId.SUMMON_SENIOR)
			end

			self.btnOk:SetEnabled(true)
			self.btnSummonLeft:SetEnabled(true)
			self.btnSummonRight:SetEnabled(true)
			self.baodi_summon:GetComponent(typeof(UIButton)):SetEnabled(true)
			xyd.models.floatMessage2:pushSummonList()
			self:autoAltar()
		end

		if aniCallback then
			aniCallback()
		end
	end
end

function SummonResultWindow:autoAltar()
	local autoAltarStatus = xyd.models.summon:getAutoAltarStatus()

	if not autoAltarStatus then
		return
	end

	local summonId = self.params_.summonId

	if summonId ~= xyd.SummonType.SENIOR_CRYSTAL_TEN and summonId ~= xyd.SummonType.SENIOR_SCROLL_TEN and summonId ~= xyd.SummonType.SENIOR_SCROLL and summonId ~= xyd.SummonType.SENIOR_CRYSTAL and summonId ~= xyd.SummonType.SENIOR_FREE and summonId ~= xyd.SummonType.ACT_LIMIT_TEN then
		return
	end

	local summonIndex = self.params_.summonIndex
	local altarList = {}

	if summonIndex > 0 then
		local summonData = xyd.models.summon:getFiftySummonData()

		if summonData and next(summonData) then
			for _, sData in ipairs(summonData) do
				local items = sData.items

				if items and next(items) then
					for _, itemData in ipairs(items) do
						local tableId = itemData.item_id
						local partnerId = itemData.partnerId
						local star = xyd.tables.partnerTable:getStar(tableId)

						if star == 3 then
							table.insert(altarList, partnerId)
						end
					end
				end
			end
		end
	else
		local items = self.params_.items

		if items and next(items) then
			for _, itemData in ipairs(items) do
				local tableId = itemData.item_id
				local partnerId = itemData.partnerId
				local star = xyd.tables.partnerTable:getStar(tableId)

				if star == 3 then
					table.insert(altarList, partnerId)
				end
			end
		end
	end

	if altarList and next(altarList) then
		local msg = messages_pb.decompose_partners_req()

		for i = 1, #altarList do
			local partnerID = altarList[i]

			table.insert(msg.partner_ids, partnerID)
		end

		xyd.Backend.get():request(xyd.mid.DECOMPOSE_PARTNERS, msg)
	end
end

function SummonResultWindow:resizeBg(index, length, objs)
	if index == length then
		for i, obj in pairs(objs) do
			obj.transform:DOScale(1, 0.1)
		end

		self:playLastEffect()
	end
end

function SummonResultWindow:addEnergyEffect()
	if not self.energySpine then
		self.energySpine = xyd.Spine.new(self.energyEffect.gameObject)

		self.energySpine:setInfo("fx_ui_niudanshengji", function ()
			self.energySpine:SetLocalScale(1, 1, 1)
			self.energySpine:setPlayNeedStop(true)
			self.energySpine:setRenderTarget(self.energyEffect:GetComponent(typeof(UITexture)), 10)
		end)
	end

	if #self.params_.items > 1 then
		self.energySpine:SetLocalPosition(25, -10, 0)
		self.energySpine:play("texiao02", 1, 1.2, nil, true)
	else
		self.energySpine:SetLocalPosition(20, -10, 0)
		self.energySpine:play("texiao01", 1, 1, nil, true)
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.SUMMON_ENERGY)
	self:setTimeout(function ()
		self.baodi_progress.value = self.params_.progressValue / self.baodiCost
		self.baodi_progress_label.text = self.params_.progressValue .. "/" .. self.baodiCost
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)

		if self.hasPipiluo and activityData and xyd.getServerTime() < activityData.start_time + tonumber(xyd.tables.miscTable:getVal("graduate_gift_open_limit")) and activityData.detail.active_time == 0 then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)
			xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_GRADUATE_TIP"), function (yes)
				if yes then
					self:close()
					xyd.WindowManager.get():openWindow("activity_window", {
						activity_type = xyd.EventType.LIMIT,
						select = xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG
					})
				end
			end)
		end
	end, self, 1000)
end

function SummonResultWindow:showSeniorButtons()
	local summonConf = xyd.tables.summonTable
	local summonType = xyd.SummonType
	local fiftySummonStatus = xyd.models.summon:getFiftySummonStatus()
	local val = 1

	if fiftySummonStatus then
		val = 5
	end

	if xyd.Global.lang == "ja_jp" then
		self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 1))
		self.btnSummonLeft:setCostIcon({
			xyd.ItemID.SENIOR_SUMMON_SCROLL,
			1
		})
		self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 10 * val))
		self.btnSummonRight:setCostIcon({
			xyd.ItemID.SENIOR_SUMMON_SCROLL,
			10 * val
		})
	elseif #self.params_.items <= 1 then
		self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 1))
		self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 1))
		self.btnSummonLeft:setCostIcon({
			xyd.ItemID.SENIOR_SUMMON_SCROLL,
			1
		})

		local cost = summonConf:getCost(summonType.SENIOR_CRYSTAL)

		self.btnSummonRight:setCostIcon({
			cost[1],
			cost[2]
		})
	else
		self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 10 * val))
		self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 10 * val))
		self.btnSummonLeft:setCostIcon({
			xyd.ItemID.SENIOR_SUMMON_SCROLL,
			10 * val
		})

		local cost = summonConf:getCost(summonType.SENIOR_CRYSTAL_TEN)

		self.btnSummonRight:setCostIcon({
			cost[1],
			cost[2] * val
		})
	end
end

function SummonResultWindow:initButton(summonIndex)
	summonIndex = tonumber(summonIndex) or 0
	local summonConf = xyd.tables.summonTable
	local summonType = xyd.SummonType

	self.btnOk:setLabel(__("SURE_2"))
	self.btnOk:setCostIcon()
	self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 10))

	if self.params_.type == TypeEnum.BASE then
		if self.params_.free then
			self.btnSummonLeft:setLabel(__("FREE3"))
			self.btnSummonLeft:setCostIcon()
		else
			self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 1))
			self.btnSummonLeft:setCostIcon({
				xyd.ItemID.BASE_SUMMON_SCROLL,
				1
			})
		end

		self.btnSummonRight:setCostIcon({
			xyd.ItemID.BASE_SUMMON_SCROLL,
			10
		})
	elseif self.params_.type == TypeEnum.SENIOR then
		self:showSeniorButtons()
	elseif self.params_.type == TypeEnum.SIMULATION_GACHA then
		if self.params_.showSummonBtn then
			if self.params_.btnSummonLeftText then
				self.btnSummonLeft.label.text = self.params_.btnSummonLeftText

				self.btnSummonLeft.label:X(0)
				self.btnSummonLeft.itemIcon:SetActive(false)

				self.btnSummonLeft.label.width = 160
				self.btnSummonLeft.label.height = 40
			end

			if self.params_.btnSummonRightText then
				self.btnSummonRight.label.text = self.params_.btnSummonRightText

				self.btnSummonRight.label:X(0)
				self.btnSummonRight.itemIcon:SetActive(false)

				self.btnSummonRight.label.width = 160
				self.btnSummonRight.label.height = 40
			end

			if self.params_.btnOKText then
				self.btnOk.label.text = self.params_.btnOKText
				self.btnOk.label.width = 160
				self.btnOk.label.height = 40
			end

			if self.params_.btnSummonRightSprite then
				xyd.setUISprite(self.btnSummonRight.go:GetComponent(typeof(UISprite)), nil, self.params_.btnSummonRightSprite)
			end

			if self.params_.btnSummonRightLabelColor then
				self.btnSummonRight.label.color = self.params_.btnSummonRightLabelColor
			end

			if self.params_.btnSummonRightLabelEffectColor then
				self.btnSummonRight.label.effectColor = self.params_.btnSummonRightLabelEffectColor
			end
		else
			self.btnSummonLeft:SetActive(false)
			self.btnSummonRight:SetActive(false)
			self.btnOk.go:X(0)
		end
	elseif self.params_.type == TypeEnum.LIMIT_TEN then
		local limitTenScrollNum = xyd.models.summon:getLimitTenScrollNum()

		if limitTenScrollNum <= 0 then
			self:showSeniorButtons()

			self.showLimitTen = false
		else
			self.showLimitTen = true

			self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 1))

			local costData = xyd.tables.summonTable:getCost(xyd.SummonType.ACT_LIMIT_TEN)

			self.btnSummonLeft:setCostIcon({
				costData[1],
				1
			})
			self.btnSummonRight:SetActive(false)

			self.buttonsGrid.cellWidth = 270

			self.buttonsGrid:Reposition()
		end
	elseif self.params_.type == TypeEnum.BAODI or self.params_.type == TypeEnum.SUPER then
		self.btnSummonLeft:SetActive(false)
		self.btnSummonRight:SetActive(false)
		self.buttonsGrid:Reposition()
	elseif self.params_.type == TypeEnum.NEWBEE_SUMMON then
		self.btnSummonLeft:SetActive(false)
		self.buttonsGrid:Reposition()

		if #self.params_.items <= 1 then
			self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 1))
			self.btnSummonRight:setCostIcon({
				xyd.ItemID.NEWBEE_SUMMON_SCROLL,
				1
			})
		else
			self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 10))
			self.btnSummonRight:setCostIcon({
				xyd.ItemID.NEWBEE_SUMMON_SCROLL,
				10
			})
		end
	elseif self.params_.type == TypeEnum.FRIEND then
		local friendCost1 = summonConf:getCost(summonType.FRIEND)
		local friendCost10 = summonConf:getCost(summonType.FRIEND_TEN)

		self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 1))
		self.btnSummonLeft:setCostIcon({
			friendCost1[1],
			friendCost1[2]
		})
		self.btnSummonRight:setCostIcon({
			friendCost10[1],
			friendCost10[2]
		})
	elseif self.params_.type == TypeEnum.WISH then
		if xyd.Global.lang == "ja_jp" then
			self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 1))
			self.btnSummonLeft:setCostIcon({
				xyd.ItemID.SENIOR_SUMMON_SCROLL,
				1
			})
			self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 10))
			self.btnSummonRight:setCostIcon({
				xyd.ItemID.SENIOR_SUMMON_SCROLL,
				10
			})
		elseif #self.params_.items <= 1 then
			self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 1))
			self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 1))
			self.btnSummonLeft:setCostIcon({
				xyd.ItemID.SENIOR_SUMMON_SCROLL,
				1
			})

			local cost = summonConf:getCost(summonType.WISH_CRYSTAL)

			self.btnSummonRight:setCostIcon({
				cost[1],
				cost[2]
			})
		else
			self.btnSummonLeft:setLabel(__("SUMMON_X_TIME", 10))
			self.btnSummonRight:setLabel(__("SUMMON_X_TIME", 10))
			self.btnSummonLeft:setCostIcon({
				xyd.ItemID.SENIOR_SUMMON_SCROLL,
				10
			})

			local cost = summonConf:getCost(summonType.WISH_CRYSTAL_TEN)

			self.btnSummonRight:setCostIcon({
				cost[1],
				cost[2]
			})
		end
	end

	if summonIndex == 0 then
		for i = 1, #self.buttons do
			local btn = self.buttons[i]
			btn.alpha = 0
			local sequence = self:getSequence()

			sequence:AppendInterval(0.2)

			local function setter1(val)
				btn.alpha = val
			end

			sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.2))
			sequence:Join(btn.transform:DOScale(1.2, 0.2))
			sequence:Append(btn.transform:DOScale(0.95, 0.2))
			sequence:Append(btn.transform:DOScale(1, 0.2))
			sequence:AppendCallback(function ()
				self:delSequene(sequence)
			end)
		end
	end

	self.btnOk:SetEnabled(false)
	self.btnSummonLeft:SetEnabled(false)
	self.btnSummonRight:SetEnabled(false)
	self.baodi_summon:GetComponent(typeof(UIButton)):SetEnabled(false)
end

function SummonResultWindow:registerEvent()
	self.btnOk:touchCallback(function ()
		if self.params_ and self.params_.type == TypeEnum.SIMULATION_GACHA then
			if self.params_.btnOkCallBack then
				self.params_.btnOkCallBack()
			end

			return
		end

		xyd.WindowManager.get():closeWindow(self.name_, function ()
		end)

		if self.params_ and (self.params_.type == TypeEnum.SUPER or self.params_.type == TypeEnum.NEWBEE_SUMMON) then
			return
		end

		local pushParams = xyd.models.activity:getLimitGiftParams()
		local myparam = nil

		for i = 1, #pushParams do
			if pushParams[i].activity_id ~= nil and pushParams[i].activity_id == xyd.ActivityID.SUMMON_WELFARE then
				myparam = pushParams[i]

				xyd.models.activity:removeLimitGiftParams(pushParams[i].giftbag_id)

				break
			end
		end

		if myparam ~= nil and myparam.activity_id ~= nil and myparam.activity_id == xyd.ActivityID.SUMMON_WELFARE then
			xyd.WindowManager.get():openWindow("summon_welfare_window", myparam)
		end
	end, self)
	self.btnSummonLeft:touchCallback(function ()
		if self.params_.type == TypeEnum.SIMULATION_GACHA then
			if self.params_.btnSummonLeftCallBack then
				self.params_.btnSummonLeftCallBack()
			end

			return
		end

		local win = xyd.WindowManager.get():getWindow("summon_window")

		if not win then
			self:close()

			return
		end

		local flag = nil

		if self.params_.type == TypeEnum.BASE then
			flag = win:onBaseSummon(1)
		elseif self.params_.type == TypeEnum.FRIEND then
			flag = win:onFriendSummon(1)
		elseif self.params_.type == TypeEnum.SENIOR then
			if #self.params_.items <= 1 then
				flag = win:onSeniorSummon(1, xyd.SummonType.SENIOR_SCROLL)
			elseif #self.params_.items == 10 then
				if xyd.Global.lang ~= "ja_jp" then
					flag = win:onSeniorSummon(10, xyd.SummonType.SENIOR_SCROLL_TEN)
				else
					flag = win:onSeniorSummon(1, xyd.SummonType.SENIOR_SCROLL)
				end
			end
		elseif self.params_.type == TypeEnum.WISH then
			if #self.params_.items <= 1 then
				flag = win:onWishSummon(1, xyd.SummonType.WISH_SCROLL)
			elseif #self.params_.items == 10 then
				if xyd.Global.lang ~= "ja_jp" then
					flag = win:onWishSummon(10, xyd.SummonType.WISH_SCROLL_TEN)
				else
					flag = win:onWishSummon(1, xyd.SummonType.WISH_SCROLL)
				end
			end
		elseif self.params_.type == TypeEnum.LIMIT_TEN then
			if self.showLimitTen then
				flag = win:onLimitSummonTen()
			elseif #self.params_.items <= 1 then
				flag = win:onSeniorSummon(1, xyd.SummonType.SENIOR_SCROLL)
			elseif #self.params_.items == 10 then
				if xyd.Global.lang ~= "ja_jp" then
					flag = win:onSeniorSummon(10, xyd.SummonType.SENIOR_SCROLL_TEN)
				else
					flag = win:onSeniorSummon(1, xyd.SummonType.SENIOR_SCROLL)
				end
			end
		end

		if flag and not xyd.models.summon:getSkipAnimation() then
			self:close()
		end
	end, self)
	self.btnSummonRight:touchCallback(function ()
		if self.params_.type == TypeEnum.NEWBEE_SUMMON then
			local num = xyd.checkCondition(#self.params_.items == 10, 10, 1)

			if self.params_.btnSummonRightCallBack then
				self.params_.btnSummonRightCallBack(num)

				return
			end
		end

		if self.params_.type == TypeEnum.SIMULATION_GACHA then
			if self.params_.btnSummonRightCallBack then
				self.params_.btnSummonRightCallBack()
			end

			return
		end

		local win = xyd.WindowManager.get():getWindow("summon_window")

		if not win then
			self:close()

			return
		end

		local flag = nil

		if self.params_.type == TypeEnum.BASE then
			flag = win:onBaseSummon(10)
		elseif self.params_.type == TypeEnum.FRIEND then
			flag = win:onFriendSummon(10)
		elseif self.params_.type == TypeEnum.SENIOR then
			if #self.params_.items <= 1 then
				if xyd.Global.lang ~= "ja_jp" then
					flag = win:onSeniorSummon(1, xyd.SummonType.SENIOR_CRYSTAL)
				else
					flag = win:onSeniorSummon(10, xyd.SummonType.SENIOR_SCROLL_TEN)
				end
			elseif #self.params_.items == 10 then
				if xyd.Global.lang ~= "ja_jp" then
					flag = win:onSeniorSummon(10, xyd.SummonType.SENIOR_CRYSTAL_TEN)
				else
					flag = win:onSeniorSummon(10, xyd.SummonType.SENIOR_SCROLL_TEN)
				end
			end
		elseif self.params_.type == TypeEnum.WISH then
			if #self.params_.items <= 1 then
				if xyd.Global.lang ~= "ja_jp" then
					flag = win:onWishSummon(1, xyd.SummonType.WISH_CRYSTAL)
				else
					flag = win:onWishSummon(10, xyd.SummonType.WISH_SCROLL_TEN)
				end
			elseif #self.params_.items == 10 then
				if xyd.Global.lang ~= "ja_jp" then
					flag = win:onWishSummon(10, xyd.SummonType.WISH_CRYSTAL_TEN)
				else
					flag = win:onWishSummon(10, xyd.SummonType.WISH_SCROLL_TEN)
				end
			end
		elseif self.params_.type == TypeEnum.LIMIT_TEN then
			if self.showLimitTen then
				flag = win:onLimitSummonTen()
			elseif xyd.Global.lang ~= "ja_jp" then
				flag = win:onSeniorSummon(10, xyd.SummonType.SENIOR_CRYSTAL_TEN)
			else
				flag = win:onSeniorSummon(10, xyd.SummonType.SENIOR_SCROLL_TEN)
			end
		end

		if flag and not xyd.models.summon:getSkipAnimation() then
			self:close()
		end
	end, self)
	xyd.setDarkenBtnBehavior(self.baodi_summon, self, self.onBaodiSummon)
	xyd.setDarkenBtnBehavior(self.baodi_tips.gameObject, self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SUMMON_HELP_3"
		})
	end)
	self.eventProxy_:addEventListener(xyd.event.DECOMPOSE_PARTNERS, handler(self, self.onDecomposePartner))
end

function SummonResultWindow:onBaodiSummon()
	local win = xyd.WindowManager.get():getWindow("summon_window")
	local flag = win:onBaodiSummon()

	if flag and not xyd.models.summon:getSkipAnimation() then
		self:close()
	end
end

function SummonResultWindow:willClose()
	BaseWindow.willClose(self)

	if self.params_.type == TypeEnum.SUPER or self.params_.type == TypeEnum.NEWBEE_SUMMON then
		return
	end

	if self.isFiveStarSummon then
		local eventObj = {
			name = xyd.event.HIGH_PRAISE,
			params = {}
		}

		xyd.EventDispatcher:inner():dispatchEvent(eventObj)
	end
end

function SummonResultWindow:iosTestChangeUI()
	xyd.setUISprite(self.baodi_tips, nil, "baodi_tips_icon_ios_test")
	xyd.setUISprite(self.baodi_summon:GetComponent(typeof(UISprite)), nil, "baodi_tips_icon_ios_test")
	xyd.setUISprite(self.baodi_progress:ComponentByName("bg", typeof(UISprite)), nil, "summon_progressbar_bg_ios_test")
	xyd.setUISprite(self.baodi_progress_thumb, nil, "summon_prgressbar_thumb_ios_test")
	xyd.setUISprite(self.bgPartners, nil, "summon_res_ios_test")
	xyd.setUISprite(self.window_:ComponentByName("mask_", typeof(UISprite)), nil, "guide_mask_ios_test")
	xyd.setUISprite(self.btnOk.go:GetComponent(typeof(UISprite)), nil, "white_btn70_70_ios_test")
	xyd.setUISprite(self.btnSummonLeft.go:GetComponent(typeof(UISprite)), nil, "white_btn70_70_ios_test")
	xyd.setUISprite(self.btnSummonRight.go:GetComponent(typeof(UISprite)), nil, "white_btn70_70_ios_test")
end

function SummonResultWindow:getSeniorSummonUIComponent()
	self.partnerUpGroup = self.bottomGroup:NodeByName("partner_up_group").gameObject
	self.wishTextGroup = self.bottomGroup:NodeByName("describe_group/wish_text_group").gameObject
	self.probIcon = self.wishTextGroup:ComponentByName("prob_icon", typeof(UISprite))
	self.probIcon2 = self.wishTextGroup:ComponentByName("prob_icon2", typeof(UISprite))
	self.probNumIcon = self.wishTextGroup:ComponentByName("prob_num_icon", typeof(UISprite))
	self.probLabel = self.wishTextGroup:ComponentByName("prob_label", typeof(UILabel))
	self.probNumLabel = self.wishTextGroup:ComponentByName("prob_num_label", typeof(UILabel))
end

function SummonResultWindow:refreshSeniorSummonTimes(event)
	if event.data.activity_id ~= xyd.ActivityID.NEW_SUMMON_GIFTBAG then
		return
	end

	if self.params_.type ~= TypeEnum.SENIOR and self.params_.type ~= TypeEnum.LIMIT_TEN then
		return
	end

	self.bottomGroup:SetActive(true)

	local summonGiftData = require("cjson").decode(event.data.act_info.detail)
	self.times = tonumber(summonGiftData.times) or 0
	local numSuffix = tostring(math.floor(self.times / 100) + 1)

	xyd.setUISprite(self.probIcon2, nil, "summon_up_" .. xyd.Global.lang)
	xyd.setUISprite(self.probNumIcon, nil, "bg_gc_up" .. numSuffix)

	self.probNumLabel.text = self.times .. "/" .. __("WISH_GACHA_NUM" .. math.floor(self.times / 100) + 1)
	local temp_text = nil

	if self.times < 400 then
		temp_text = __("WISH_GACHA_TEXT4")
	else
		temp_text = __("WISH_GACHA_TEXT5")
	end

	self.probLabel.text = temp_text
	local upTableId = xyd.tables.miscTable:getVal("activity_gacha_partners")
	local heroIcon = HeroIcon.new(self.partnerUpGroup)

	heroIcon:setInfo({
		itemID = upTableId,
		callback = function ()
			heroIcon.selected = false

			if self.isPlayAni == true then
				return
			end

			local params = {
				lev = 1,
				table_id = upTableId
			}

			xyd.WindowManager.get():openWindow("partner_info", params)
		end
	})
end

function SummonResultWindow:onDecomposePartner(event)
	local floatDatas = {}

	for _, data in ipairs(event.data.items) do
		table.insert(floatDatas, {
			item_id = data.item_id,
			item_num = data.item_num
		})
	end

	xyd.models.itemFloatModel:pushNewItems(floatDatas)

	if self.items then
		for _, item in ipairs(self.items) do
			item:startAltarAnimation()
		end
	end
end

function HeroAltarItem:ctor(go)
	HeroAltarItem.super.ctor(self, go)
	self:getUIComponent()
end

function HeroAltarItem:getUIComponent()
	self.heroIconGroup = self.go:NodeByName("hero_icon_group").gameObject
	self.itemGroup = self.go:NodeByName("item_group").gameObject

	self.itemGroup:SetActive(false)

	self.commonedIcon = self.go:NodeByName("commoned_icon").gameObject

	self.commonedIcon:SetActive(false)
end

function HeroAltarItem:setInfo(params)
	self.partnerParams = params
	self.parentWin = params.parentWin
	self.heroIcon = HeroIcon.new(self.heroIconGroup)

	function params.callback()
		self.heroIcon.selected = false

		if self.parentWin.isPlayAni == true then
			return
		end

		local cParams = {
			lev = 1,
			table_id = params.itemID,
			noWays = params.noWays
		}

		if self.parentWin.params_.type == TypeEnum.SIMULATION_GACHA and xyd.tables.partnerRecommendSimulationTable:checkIsRecommend(params.itemID) then
			cParams.showRecommoned = true
			cParams.recommonedText = __("PARTNER_RECOMMEND_TIPS")
		end

		xyd.WindowManager.get():openWindow("partner_info", cParams)
	end

	if self.parentWin.params_.type == TypeEnum.SIMULATION_GACHA and xyd.tables.partnerRecommendSimulationTable:checkIsRecommend(params.itemID) then
		self.commonedIcon:SetActive(true)
	end

	self.heroIcon:setInfo(params)

	self.itemIcon_ = xyd.getItemIcon({
		itemID = xyd.ItemID.SOUL_STONE,
		dragScrollView = params.dragScrollView,
		uiRoot = self.itemGroup
	})
end

function HeroAltarItem:getHeroIcon()
	return self.heroIcon
end

function HeroAltarItem:startAltarAnimation()
	local tableId = self.partnerParams.itemID
	local star = xyd.tables.partnerTable:getStar(tableId)

	if star ~= 3 then
		return
	end

	self.itemGroup:SetActive(true)

	self.seq = self:getSequence()

	self.seq:SetLoops(-1)

	self.heroIconGroup:GetComponent(typeof(UIWidget)).alpha = 0

	local function setter(val)
		self.heroIconGroup:GetComponent(typeof(UIWidget)).alpha = val
	end

	self.seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 1.5))
	self.seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 1.5))
end

return SummonResultWindow
