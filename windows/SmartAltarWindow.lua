local BaseWindow = import(".BaseWindow")
local SmartAltarWindow = class("SmartAltarWindow", BaseWindow)
local slotModel = xyd.models.slot
local SelectNum = import("app.components.SelectNum")
local HeroIcon = import("app.components.HeroIcon")

function SmartAltarWindow:ctor(name, params)
	SmartAltarWindow.super.ctor(self, name, params)

	self.threeStarPartners = {}
	self.oneTwoStarPartners = {}
	self.remainNum = {
		20,
		20,
		20,
		20,
		4,
		4
	}
	self.restDecompose = {}
	self.curDecomposeNum = 1
	self.maxDecomposeNum = 50
	self.allAwards = {}
	self.timer = nil
	self.time = 1
end

function SmartAltarWindow:initWindow()
	SmartAltarWindow.super.initWindow(self)
	self:getUIComponents()
	self:initData()
	self:initLayout()
	self:registerEvent()
	self:solveMultiLang()
end

function SmartAltarWindow:solveMultiLang()
	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.labelText.spacingY = 3
	end
end

function SmartAltarWindow:getUIComponents()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelText = groupAction:ComponentByName("labelText", typeof(UILabel))
	self.btnDetail = groupAction:NodeByName("btnDetail").gameObject
	self.btnDecompose = groupAction:NodeByName("btnDecompose").gameObject
	self.labelDecompose = self.btnDecompose:ComponentByName("labelDecompose", typeof(UILabel))
	self.loadingComponent = groupAction:NodeByName("loadingComponent").gameObject
	self.loadingEffect = self.loadingComponent:NodeByName("loadingEffect").gameObject
	self.loadingText = self.loadingComponent:ComponentByName("loadingText", typeof(UILabel))
	self.keyboardMask = groupAction:NodeByName("keyboardMask").gameObject

	for i = 1, 6 do
		self["item" .. i] = groupAction:NodeByName("grid/item" .. i).gameObject
		local selectNumPos = self["item" .. i]:NodeByName("selectNum" .. i).gameObject
		self["selectNum" .. i] = SelectNum.new(selectNumPos, "default")
		self["itemIcon" .. i] = self["item" .. i]:NodeByName("itemIcon" .. i).gameObject
	end

	for i = 1, 2 do
		self["chooseGroup" .. i] = groupAction:NodeByName("chooseGroup" .. i).gameObject
		self["chooseBtn" .. i] = self["chooseGroup" .. i]:ComponentByName("chooseBtn" .. i, typeof(UISprite))
		self["chooseLabel" .. i] = self["chooseGroup" .. i]:ComponentByName("chooseLabel" .. i, typeof(UILabel))
	end
end

function SmartAltarWindow:initData()
	local partners = slotModel:getPartnersByStar()

	for i = 1, 6 do
		local partners = partners["3_" .. tostring(i)]
		local res = {}

		for j = 1, #partners do
			local partner = slotModel:getPartner(partners[j])

			if not self:isPartnerLock(partner) then
				table.insert(res, partners[j])
			end
		end

		self.threeStarPartners[i] = res
	end

	self.oneTwoStarPartners[1] = {}
	self.oneTwoStarPartners[2] = {}

	for i = 1, 2 do
		local partners = partners[i .. "_0"]

		for j = 1, #partners do
			local partner = slotModel:getPartner(partners[j])

			if not self:isPartnerLock(partner) then
				table.insert(self.oneTwoStarPartners[i], partners[j])
			end
		end
	end
end

function SmartAltarWindow:isPartnerLock(partner)
	local lockFlags = partner:getLockFlags()

	for _, lock in pairs(lockFlags) do
		if lock ~= 0 then
			return true
		end
	end

	return false
end

function SmartAltarWindow:initLayout()
	for i = 1, 6 do
		local needDecomposeNum = math.max(0, #self.threeStarPartners[i] - self.remainNum[i])
		local selectNum = self["selectNum" .. i]
		local params = {
			minNum = 0,
			delForceZero = true,
			maxNum = #self.threeStarPartners[i],
			curNum = needDecomposeNum,
			callback = function (num)
				selectNum:setCurNum(num)
			end,
			touchCallback = function ()
				self.keyboardMask:SetActive(true)
			end,
			sureCallback = function ()
				self.keyboardMask:SetActive(false)
			end
		}

		selectNum:setSelectBGSize(108.6, 32.9)
		selectNum:setFontSize(30, 30)
		selectNum:setInfo(params)
		selectNum:SetLocalScale(0.71, 0.71, 1)
		selectNum.numberKeyBoard:SetLocalScale(0.82, 0.81, 1)
		selectNum:setBtnPos(100)

		if i == 1 or i == 4 then
			selectNum:setKeyboardPos(15, -165, 0)
		elseif i == 2 or i == 5 then
			selectNum:setKeyboardPos(0, -165, 0)
		else
			selectNum:setKeyboardPos(-15, -165, 0)
		end

		local params = {
			noClick = true,
			needStarBg = true,
			star = 3,
			group = i,
			heroIcon = xyd.tables.partnerIDRuleTable:getIcon("3" .. tostring(i) .. "999"),
			num = #self.threeStarPartners[i]
		}
		local icon = HeroIcon.new(self["itemIcon" .. tostring(i)])

		icon:setInfo(params)
	end

	local effect = xyd.Spine.new(self.loadingEffect)

	effect:setInfo("loading", function ()
		effect:SetLocalScale(0.95, 0.95, 0.95)
		effect:play("idle", 0, 1)
	end)

	self.effect = effect
	self.labelTitle.text = __("ALTAR_AUTO_TEXT")
	self.labelText.text = __("ALTAR_AUTO_TEXT02")
	self.labelDecompose.text = __("ALTAR_AUTO_TEXT03")
	self.loadingText.text = __("ALTAR_AUTO_TEXT05")
	self.chooseLabel1.text = __("ALTAR_AUTO_TEXT07")
	self.chooseLabel2.text = __("ALTAR_AUTO_TEXT08")
	self.flag1 = false
	local oneTwoMark = xyd.db.misc:getValue("smart_altar_one_two_mark")

	if oneTwoMark and oneTwoMark == "1" then
		self:onClickChoose(1)
	end

	self.flag2 = false
	local allThreeMark = xyd.db.misc:getValue("smart_altar_all_three_mark")

	if allThreeMark and allThreeMark == "1" then
		self:onClickChoose(2)
	end
end

function SmartAltarWindow:registerEvent()
	SmartAltarWindow.super.register(self)

	UIEventListener.Get(self.keyboardMask).onClick = handler(self, self.onClickMask)
	UIEventListener.Get(self.btnDetail).onClick = handler(self, self.onClickBtnDetail)
	UIEventListener.Get(self.btnDecompose).onClick = handler(self, self.onClickDecompose)

	UIEventListener.Get(self.chooseBtn1.gameObject).onClick = function ()
		self:onClickChoose(1)
	end

	UIEventListener.Get(self.chooseBtn2.gameObject).onClick = function ()
		self:onClickChoose(2)
	end

	self.eventProxy_:addEventListener(xyd.event.DECOMPOSE_PARTNERS, handler(self, self.decomposeCallback))
end

function SmartAltarWindow:onClickMask()
	self.keyboardMask:SetActive(false)

	for i = 1, 6 do
		local selectNum = self["selectNum" .. i]

		selectNum.numberKeyBoard:SetActive(false)
	end
end

function SmartAltarWindow:onClickBtnDetail()
	local curIds = self:getCurIds()
	local decomposeItems = {}
	local baseItems = {}
	local treasureItems = {}

	for _, partnerID in ipairs(curIds) do
		local partner = slotModel:getPartner(partnerID)
		local res = partner:getDecompose()
		local equipItems = res[3]

		for _, v in ipairs(equipItems) do
			table.insert(decomposeItems, v)
		end

		for _, v in ipairs(res[2]) do
			table.insert(treasureItems, v)
		end

		baseItems[xyd.ItemID.PARTNER_EXP] = (baseItems[xyd.ItemID.PARTNER_EXP] or 0) + (res[1][xyd.ItemID.PARTNER_EXP] or 0)
		baseItems[xyd.ItemID.GRADE_STONE] = (baseItems[xyd.ItemID.GRADE_STONE] or 0) + (res[1][xyd.ItemID.GRADE_STONE] or 0)
		baseItems[xyd.ItemID.SOUL_STONE] = (baseItems[xyd.ItemID.SOUL_STONE] or 0) + (res[1][xyd.ItemID.SOUL_STONE] or 0)
		baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] = (baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] or 0) + (res[1][xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] or 0)
		baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE] = (baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE] or 0) + (res[1][xyd.ItemID.SKILL_RESONATE_DARK_STONE] or 0)
	end

	for _, v in ipairs(treasureItems) do
		table.insert(decomposeItems, v)
	end

	if baseItems[xyd.ItemID.PARTNER_EXP] and baseItems[xyd.ItemID.PARTNER_EXP] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.PARTNER_EXP,
			item_num = baseItems[xyd.ItemID.PARTNER_EXP]
		})
	end

	if baseItems[xyd.ItemID.GRADE_STONE] and baseItems[xyd.ItemID.GRADE_STONE] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.GRADE_STONE,
			item_num = baseItems[xyd.ItemID.GRADE_STONE]
		})
	end

	if baseItems[xyd.ItemID.GRADE_STONE] and baseItems[xyd.ItemID.SOUL_STONE] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.SOUL_STONE,
			item_num = baseItems[xyd.ItemID.SOUL_STONE]
		})
	end

	if baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] and baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.SKILL_RESONATE_LIGHT_STONE,
			item_num = baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE]
		})
	end

	if baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE] and baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.SKILL_RESONATE_DARK_STONE,
			item_num = baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE]
		})
	end

	xyd.alertItems(decomposeItems, nil, __("ALTAR_PREVIEW_TEXT"))
end

function SmartAltarWindow:getCurIds()
	local ids = {}

	for i = 1, 6 do
		local curNum = self["selectNum" .. i].curNum_

		for j = 1, curNum do
			table.insert(ids, self.threeStarPartners[i][j])
		end
	end

	if self.flag1 then
		xyd.tableConcat(ids, self.oneTwoStarPartners[1])
		xyd.tableConcat(ids, self.oneTwoStarPartners[2])
	end

	return ids
end

function SmartAltarWindow:onClickDecompose()
	local curIds = self:getCurIds()

	if #curIds <= 0 then
		xyd.showToast(__("ALTAR_AUTO_TEXT01"))

		return
	end

	local allPartners = slotModel:getPartnersByStar()["0_0"]

	if #allPartners - #curIds < 1 then
		xyd.alertTips(__("ALTAR_DECOMPOSE_TIP2"))

		return
	end

	local timeStamp = xyd.db.misc:getValue("altar_auto_time_stamp")

	if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
		local params = {
			type = "altar_auto"
		}

		if self.flag1 then
			local oneStarNum = #self.oneTwoStarPartners[1]
			local twoStarNum = #self.oneTwoStarPartners[2]
			local threeStarNum = #curIds - oneStarNum - twoStarNum

			if oneStarNum > 0 or twoStarNum > 0 then
				params.text = __("ALTAR_AUTO_TEXT06", oneStarNum, twoStarNum, threeStarNum)
			else
				params.text = __("ALTAR_AUTO_TEXT04", #curIds)
			end
		else
			params.text = __("ALTAR_AUTO_TEXT04", #curIds)
		end

		function params.callback()
			self.loadingComponent:SetActive(true)

			self.timer = self:getTimer(function ()
				self.time = self.time + 1
			end, 1, 0)
			self.restDecompose = curIds
			local msg = messages_pb.decompose_partners_req()
			local len = math.min(self.maxDecomposeNum, #curIds)

			for i = 1, len do
				local partnerID = curIds[i]

				table.insert(msg.partner_ids, partnerID)
			end

			xyd.Backend.get():request(xyd.mid.DECOMPOSE_PARTNERS, msg)
		end

		xyd.openWindow("gamble_tips_window", params)
	else
		self.loadingComponent:SetActive(true)

		self.timer = self:getTimer(function ()
			self.time = self.time + 1
		end, 1, 0)
		self.restDecompose = curIds
		local msg = messages_pb.decompose_partners_req()
		local len = math.min(self.maxDecomposeNum, #curIds)

		for i = 1, len do
			local partnerID = curIds[i]

			table.insert(msg.partner_ids, partnerID)
		end

		xyd.Backend.get():request(xyd.mid.DECOMPOSE_PARTNERS, msg)
	end
end

function SmartAltarWindow:decomposeCallback(event)
	self.curDecomposeNum = self.curDecomposeNum + #event.data.partner_ids

	for _, data in ipairs(event.data.items) do
		if not self.allAwards[data.item_id] then
			self.allAwards[data.item_id] = 0
		end

		self.allAwards[data.item_id] = self.allAwards[data.item_id] + data.item_num
	end

	local allPartners = slotModel:getPartnersByStar()["0_0"]

	if self.curDecomposeNum > #self.restDecompose or #allPartners <= 1 then
		if self.time <= 1 then
			self:waitForTime(1, function ()
				self:hideEffect(function ()
					xyd.closeWindow("smart_altar_window")
				end)
			end)
		else
			self:hideEffect(function ()
				xyd.closeWindow("smart_altar_window")
			end)
		end
	else
		local curIds = xyd.slice(self.restDecompose, self.curDecomposeNum, #self.restDecompose)
		local msg = messages_pb.decompose_partners_req()
		local len = math.min(self.maxDecomposeNum, #curIds)

		for i = 1, len do
			local partnerID = curIds[i]

			table.insert(msg.partner_ids, partnerID)
		end

		xyd.Backend.get():request(xyd.mid.DECOMPOSE_PARTNERS, msg)
	end
end

function SmartAltarWindow:onClickChoose(index)
	self["flag" .. index] = not self["flag" .. index]

	if self["flag" .. index] then
		xyd.setUISpriteAsync(self["chooseBtn" .. index], nil, "setting_up_pick")
	else
		xyd.setUISpriteAsync(self["chooseBtn" .. index], nil, "setting_up_unpick")
	end

	if index == 2 then
		xyd.db.misc:setValue({
			key = "smart_altar_all_three_mark",
			value = self.flag2
		})

		if self.flag2 then
			for i = 1, 6 do
				self["selectNum" .. i]:setCurNum(#self.threeStarPartners[i])
			end
		else
			for i = 1, 6 do
				local needDecomposeNum = math.max(0, #self.threeStarPartners[i] - self.remainNum[i])

				self["selectNum" .. i]:setCurNum(needDecomposeNum)
			end
		end
	elseif index == 1 then
		xyd.db.misc:setValue({
			key = "smart_altar_one_two_mark",
			value = self.flag1
		})
	end
end

function SmartAltarWindow:hideEffect(callback)
	local action = self:getSequence()

	local function setter(value)
		self.loadingComponent:GetComponent(typeof(UIWidget)).alpha = value

		if self.effect and self.effect.spAnim then
			self.effect.spAnim:setAlpha(value)
		end
	end

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 1))
	action:AppendCallback(callback)
end

function SmartAltarWindow:showAwards()
	local items = {}

	for itemId, itemNum in pairs(self.allAwards) do
		table.insert(items, {
			item_id = itemId,
			item_num = itemNum
		})
	end

	if #items > 0 then
		xyd.alertItems(items)
	end
end

function SmartAltarWindow:didClose()
	if self and self.showAwards then
		self:showAwards()
	end
end

return SmartAltarWindow
