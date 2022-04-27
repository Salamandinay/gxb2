local BaseWindow = import(".BaseWindow")
local ChimeDetailWindow = class("ChimeDetailWindow", BaseWindow)
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")
local chimeTable = xyd.tables.chimeTable
local chimeDecomposeTable = xyd.tables.chimeDecomposeTable
local chimeExpTable = xyd.tables.chimeExpTable
local chimeModel = xyd.models.shrine
local NameColor = {
	Color.New2(4294967295.0),
	Color.New2(3889376511.0),
	Color.New2(4098292479.0),
	Color.New2(685729023),
	Color.New2(4128270335.0),
	Color.New2(4253160703.0)
}
local AttrToSpriteName = {
	spd = "attr_hp_icon",
	hp = "attr_hp_icon",
	atk = "attr_hp_icon"
}

function ChimeDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.pokedexMode = params.pokedexMode or false
	self.tableID = params.tableID

	chimeModel:reqChimeInfo()
end

function ChimeDetailWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.commonGroup = self.groupAction:NodeByName("commonGroup").gameObject
	self.labelName = self.commonGroup:ComponentByName("labelName", typeof(UILabel))
	self.labelProgressEnergy = self.commonGroup:ComponentByName("labelProgressEnergy", typeof(UILabel))
	self.labelProgressDebris = self.commonGroup:ComponentByName("labelProgressDebris", typeof(UILabel))
	self.labelBaseAttr = self.commonGroup:ComponentByName("labelBaseAttr", typeof(UILabel))
	self.AttrGroup = self.commonGroup:NodeByName("AttrGroup").gameObject

	for i = 1, 3 do
		self["Attr" .. i] = self.AttrGroup:NodeByName("Attr" .. i).gameObject
	end

	self.effectPos = self.commonGroup:ComponentByName("effectPos", typeof(UITexture))
	self.unlockEffectPos = self.commonGroup:ComponentByName("unlockEffectPos", typeof(UITexture))
	self.lockImg = self.commonGroup:ComponentByName("lockImg", typeof(UISprite))
	self.unlockMask = self.commonGroup:NodeByName("unlockMask").gameObject
	self.unlockableGroup = self.commonGroup:ComponentByName("unlockableGroup", typeof(UITexture))
	self.unlockableEffectPos = self.unlockableGroup:ComponentByName("effectPos", typeof(UITexture))
	self.unlockableLabel = self.unlockableGroup:ComponentByName("label", typeof(UILabel))
	self.detailGroup = self.groupAction:NodeByName("detailGroup").gameObject
	self.labelActivation = self.detailGroup:ComponentByName("labelActivation", typeof(UILabel))
	self.SuitAttrGroup = self.detailGroup:NodeByName("SuitAttrGroup").gameObject

	for i = 1, 3 do
		self["SuitAttr" .. i] = self.SuitAttrGroup:NodeByName("SuitAttr" .. i).gameObject
	end

	self.labelAwake = self.detailGroup:ComponentByName("labelAwake", typeof(UILabel))
	self.awakeAttrGroup = self.detailGroup:NodeByName("awakeAttrGroup").gameObject
	self.awakeAttr1 = self.awakeAttrGroup:NodeByName("awakeAttr1").gameObject
	self.activeEffectPos = self.detailGroup:ComponentByName("effectPos", typeof(UITexture))
	self.imgLine = self.detailGroup:ComponentByName("imgLine", typeof(UISprite))
	self.levelUpGroup = self.groupAction:NodeByName("levelUpGroup").gameObject
	self.AtrrDetailGroup = self.levelUpGroup:NodeByName("scrollerLevelUp/AtrrDetailGroup").gameObject
	self.EnergyDetail = self.AtrrDetailGroup:NodeByName("EnergyDetail").gameObject

	for i = 1, 3 do
		self["atrrDetail" .. i] = self.AtrrDetailGroup:NodeByName("atrrDetail" .. i).gameObject
	end

	self.costGroup_levelup = self.levelUpGroup:NodeByName("costGroup").gameObject
	self.costGroup_levelup_layout = self.levelUpGroup:ComponentByName("costGroup", typeof(UILayout))

	for i = 1, 3 do
		self["cost_levelup" .. i] = self.costGroup_levelup:NodeByName("cost" .. i).gameObject
	end

	self.btnComfirmLevelUp = self.levelUpGroup:NodeByName("btnLevelUp").gameObject
	self.levelUpEffectPos = self.levelUpGroup:NodeByName("levelUpEffectPos").gameObject
	self.awakeGroup = self.groupAction:NodeByName("awakeGroup").gameObject
	self.labelNeedEnergy = self.awakeGroup:ComponentByName("scrollerAwake/labelNeedEnergy", typeof(UILabel))
	self.awakeAttr = self.awakeGroup:NodeByName("scrollerAwake/SuitAttr").gameObject
	self.costGroup_awake = self.awakeGroup:NodeByName("costGroup").gameObject
	self.costGroup_awake_layout = self.awakeGroup:ComponentByName("costGroup", typeof(UILayout))

	for i = 1, 3 do
		self["cost_awake" .. i] = self.costGroup_awake:NodeByName("cost" .. i).gameObject
	end

	self.labelNeedDebris = self.awakeGroup:ComponentByName("labelNeedDebris", typeof(UILabel))
	self.btnConfirmAwake = self.awakeGroup:NodeByName("btnAwake").gameObject
	self.btnGroup = self.groupAction:NodeByName("btnGroup").gameObject
	self.btnDetail = self.btnGroup:NodeByName("btnDetail").gameObject
	self.btnLevelUp = self.btnGroup:NodeByName("btnLevelUp").gameObject
	self.btnActive = self.btnGroup:NodeByName("btnActive").gameObject
	self.btnAwake = self.btnGroup:NodeByName("btnAwake").gameObject
end

function ChimeDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()
	self:initData()

	self.btnDetail:ComponentByName("label", typeof(UILabel)).text = __("CHIME_TAB1")
	self.btnLevelUp:ComponentByName("label", typeof(UILabel)).text = __("CHIME_TAB2")
	self.btnActive:ComponentByName("label", typeof(UILabel)).text = __("CHIME_TAB3")
	self.btnAwake:ComponentByName("label", typeof(UILabel)).text = __("CHIME_TAB4")
	self.unlockableLabel.text = __("CHIME_TEXT14")
	self.labelBaseAttr.text = __("CHIME_TEXT02")
	self.labelActivation.text = __("CHIME_TEXT03")
	self.labelAwake.text = __("CHIME_TEXT04")
	self.btnComfirmLevelUp:ComponentByName("label", typeof(UILabel)).text = __("CHIME_BUTTON1")

	if self.pokedexMode then
		self.btnGroup:SetActive(false)
	end

	self:chooseTab(1)
end

function ChimeDetailWindow:register()
	self.eventProxy_:addEventListener(xyd.event.ACTIVE_CHIME, function (event)
		self:onGetMsgUnlock(event)
	end)
	self.eventProxy_:addEventListener(xyd.event.ACTIVE_CHIME_BUFF, function (event)
		local data = event.data

		if data.buffs[4] == 0 then
			self:onGetMsgActive(event)
		else
			self:onGetMsgAwake(event)
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.LEV_UP_CHIME, function (event)
		self:onGetMsgLevelUp(event)
	end)

	UIEventListener.Get(self.btnDetail).onClick = function ()
		if self.curTabIndex == 1 then
			return
		end

		if self.fakeLev > 0 and not self.hasSendLevleUpMsg then
			self:cleanFakeLev()

			self.hasSendLevleUpMsg = true
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
		self:chooseTab(1)
	end

	UIEventListener.Get(self.btnLevelUp).onClick = function ()
		if self.curTabIndex == 2 then
			return
		end

		if self.fakeLev > 0 and not self.hasSendLevleUpMsg then
			self:cleanFakeLev()

			self.hasSendLevleUpMsg = true
		end

		if self.lev == -1 then
			xyd.alertTips(__("CHIME_TEXT05"))

			return
		elseif self.maxLev <= self.lev then
			xyd.alertTips(__("CHIME_TEXT08"))

			return
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
		self:chooseTab(2)
	end

	UIEventListener.Get(self.btnActive).onClick = function ()
		if self.curTabIndex == 3 then
			return
		end

		if self.fakeLev > 0 and not self.hasSendLevleUpMsg then
			self:cleanFakeLev()

			self.hasSendLevleUpMsg = true
		end

		if self.lev == -1 then
			xyd.alertTips(__("CHIME_TEXT05"))

			return
		elseif self.activeTime >= #self.data.SuitAttr then
			xyd.alertTips(__("CHIME_TEXT09"))

			return
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
		self:chooseTab(3)
	end

	UIEventListener.Get(self.btnAwake).onClick = function ()
		if self.curTabIndex == 4 then
			return
		end

		if self.fakeLev > 0 and not self.hasSendLevleUpMsg then
			self:cleanFakeLev()

			self.hasSendLevleUpMsg = true
		end

		local limitNum = 0

		if self.data.AwakeAtrr and self.data.AwakeAtrr.limit then
			limitNum = self.data.AwakeAtrr.limit[2] + self.data.AwakeAtrr.limit[3] + self.data.AwakeAtrr.limit[4]
		end

		if self.lev == -1 then
			xyd.alertTips(__("CHIME_TEXT05"))

			return
		elseif self.activeTime < limitNum then
			xyd.alertTips(__("CHIME_TEXT07"))

			return
		elseif self.lev + self.fakeLev < self.data.AwakeAtrr.limit[1] then
			local str = self.data.AwakeAtrr.limit[1] .. "%"

			xyd.alertTips(__("CHIME_TEXT11", str))

			return
		elseif self.awakeTime > 0 then
			xyd.alertTips(__("CHIME_TEXT10"))

			return
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
		self:chooseTab(4)
	end

	UIEventListener.Get(self.btnComfirmLevelUp).onClick = function ()
		self:onClickBtnComfirmLevelUp()
	end

	UIEventListener.Get(self.btnConfirmAwake).onClick = function ()
		self:onClickBtnConfirmAwake()
	end

	UIEventListener.Get(self.unlockableGroup.gameObject).onClick = function ()
		self:onClickUnlockGroup()
	end

	UIEventListener.Get(self.lockImg.gameObject).onClick = function ()
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.debrisItemID)))
	end

	UIEventListener.Get(self.btnComfirmLevelUp).onPress = handler(self, self.onLongTouchBtnLevleUp)
end

function ChimeDetailWindow:initData()
	local info = chimeModel:getChimeInfoByTableID(self.tableID)

	dump(info)
	dump(self.tableID)

	self.lev = info.lev
	self.maxLev = chimeTable:getMaxLev(self.tableID)
	self.unlockCost = chimeTable:getUnlock(self.tableID)
	self.debrisItemID = self.unlockCost[1]
	self.needDebrisNumCompose = self.unlockCost[2]
	self.activeTime = info.buffs[1] + info.buffs[2] + info.buffs[3]
	self.awakeTime = info.buffs[4]
	self.chimeEffectName = chimeTable:getEffectName(self.tableID)
	self.fakeUseRes = {
		[xyd.ItemID.MANA] = 0,
		[xyd.ItemID.CRYSTAL] = 0,
		[self.debrisItemID] = 0
	}
	self.fakeLev = 0
	self.data = {}
	local Atrr = {
		Num = 0
	}
	local Atrr = chimeTable:getBase(self.tableID)
	self.data.Atrr = Atrr
	local SuitAttr = {}
	local limit1 = chimeTable:getLimit1(self.tableID)

	if limit1 and limit1 > 0 then
		SuitAttr[1] = {
			buff = chimeTable:getBuff1(self.tableID),
			limit = chimeTable:getLimit1(self.tableID),
			cost = chimeTable:getCost1(self.tableID)
		}
	end

	local limit2 = chimeTable:getLimit1(self.tableID)

	if limit2 and limit2 > 0 then
		SuitAttr[2] = {
			buff = chimeTable:getBuff2(self.tableID),
			limit = chimeTable:getLimit2(self.tableID),
			cost = chimeTable:getCost2(self.tableID)
		}
	end

	local limit3 = chimeTable:getLimit3(self.tableID)

	if limit3 and limit3 > 0 then
		SuitAttr[3] = {
			buff = chimeTable:getBuff3(self.tableID),
			limit = chimeTable:getLimit3(self.tableID),
			cost = chimeTable:getCost3(self.tableID)
		}
	end

	self.data.SuitAttr = SuitAttr
	local limit4 = chimeTable:getLimit4(self.tableID)

	if limit4 and limit4[1] then
		self.data.AwakeAtrr = {
			buff = chimeTable:getBuff4(self.tableID),
			limit = chimeTable:getLimit4(self.tableID),
			cost = chimeTable:getCost4(self.tableID)
		}
	end

	if self.pokedexMode then
		self.activeTime = #SuitAttr
		self.awakeTime = 1
		self.lev = self.maxLev
	end
end

function ChimeDetailWindow:updateBtnGroup()
	local spriteName = ""
	local btns = {
		self.btnDetail,
		self.btnLevelUp,
		self.btnActive,
		self.btnAwake
	}

	for i = 1, 4 do
		if self.curTabIndex == i then
			xyd.setUISpriteAsync(btns[i]:ComponentByName("bg", typeof(UISprite)), nil, "chime_btn_yq_2", nil, , false)
			xyd.setUISpriteAsync(btns[i]:ComponentByName("bg/img", typeof(UISprite)), nil, "chime_btn_hw_1", nil, , false)
		else
			xyd.setUISpriteAsync(btns[i]:ComponentByName("bg", typeof(UISprite)), nil, "chime_btn_yq_1", nil, , false)
			xyd.setUISpriteAsync(btns[i]:ComponentByName("bg/img", typeof(UISprite)), nil, "chime_btn_hw_2", nil, , false)
		end
	end

	if self.lev + self.fakeLev == -1 or self.maxLev <= self.lev + self.fakeLev then
		xyd.applyChildrenGrey(self.btnLevelUp.gameObject)
	else
		xyd.applyChildrenOrigin(self.btnLevelUp.gameObject)
	end

	if self.lev + self.fakeLev == -1 or self.activeTime >= #self.data.SuitAttr then
		xyd.applyChildrenGrey(self.btnActive.gameObject)
	else
		xyd.applyChildrenOrigin(self.btnActive.gameObject)
	end

	local limitNum = 0

	if self.data.AwakeAtrr and self.data.AwakeAtrr.limit then
		limitNum = self.data.AwakeAtrr.limit[2] + self.data.AwakeAtrr.limit[3] + self.data.AwakeAtrr.limit[4]
	end

	if self.lev + self.fakeLev == -1 or not self.data.AwakeAtrr or self.activeTime < limitNum or self.lev + self.fakeLev < self.data.AwakeAtrr.limit[1] or self.awakeTime > 0 then
		xyd.applyChildrenGrey(self.btnAwake.gameObject)
	else
		xyd.applyChildrenOrigin(self.btnAwake.gameObject)
	end
end

function ChimeDetailWindow:chooseTab(tabIndex)
	self.commonGroup:SetActive(true)
	self.detailGroup:SetActive(false)
	self.levelUpGroup:SetActive(false)
	self.awakeGroup:SetActive(false)
	self:updateCommonGroup()

	self.curTabIndex = tabIndex

	if tabIndex == 1 then
		self.detailGroup:SetActive(true)
		self:updateDetailGroup()
	elseif tabIndex == 2 then
		self.levelUpGroup:SetActive(true)
		self:updateLevelUpGroup()
	elseif tabIndex == 3 then
		self.awakeGroup:SetActive(true)
		self:updateActiveGroup(false)
	elseif tabIndex == 4 then
		self.awakeGroup:SetActive(true)
		self:updateActiveGroup(true)
	end

	self:updateBtnGroup()
end

function ChimeDetailWindow:updateCommonGroup(donotUpdate)
	self.labelName.text = xyd.tables.chimeTextTable:getName(self.tableID)
	local qlt = chimeTable:getQlt(self.tableID)
	self.labelName.color = NameColor[qlt]

	self.labelProgressEnergy:SetActive(self.lev + self.fakeLev > -1)
	self.labelProgressDebris:SetActive(self.lev + self.fakeLev < 0)

	if self.lev + self.fakeLev > -1 then
		self.labelProgressEnergy.text = __("CHIME_TEXT01") .. " " .. self.lev + self.fakeLev .. "%"

		self.lockImg:SetActive(false)
		self.unlockableGroup:SetActive(false)
	else
		if self.needDebrisNumCompose <= xyd.models.backpack:getItemNumByID(self.debrisItemID) then
			self.labelProgressDebris.text = "[c][394046]" .. __("CHIME_TEXT16") .. " " .. "[-][/c]" .. "[c][394046]" .. "(" .. xyd.models.backpack:getItemNumByID(self.debrisItemID) .. "/" .. self.needDebrisNumCompose .. ")" .. "[-][/c]"
		else
			self.labelProgressDebris.text = "[c][394046]" .. __("CHIME_TEXT16") .. " " .. "[-][/c]" .. "[c][cc0011]" .. "(" .. xyd.models.backpack:getItemNumByID(self.debrisItemID) .. "/" .. self.needDebrisNumCompose .. ")" .. "[-][/c]"
		end

		self.lockImg:SetActive(true)

		if self.needDebrisNumCompose <= xyd.models.backpack:getItemNumByID(self.debrisItemID) then
			self.unlockableGroup:SetActive(true)

			if not self.unlockableEffect then
				self.unlockableEffect = xyd.Spine.new(self.unlockableEffectPos.gameObject)

				self.unlockableEffect:setInfo("fx_ui_dianji", function ()
					self.unlockableEffect:play("texiao01", 0, 1, function ()
					end, true)
				end)
			end
		else
			self.unlockableGroup:SetActive(false)
		end
	end

	if not self.chimeEffect then
		self.chimeEffect = xyd.Spine.new(self.effectPos.gameObject)

		self.chimeEffect:setInfo(self.chimeEffectName, function ()
			self.chimeEffect:setRenderTarget(self.effectPos.gameObject:GetComponent(typeof(UITexture)), 1)

			if self.lev + self.fakeLev < 0 then
				self.chimeEffect:play("texiao01", 1, 10, function ()
				end, true)
				self.chimeEffect:setGrey()
				self.chimeEffect:stop()
			else
				self.chimeEffect:play("texiao01", 0, 1, function ()
				end, true)
			end
		end)
	elseif not donotUpdate then
		if self.lev + self.fakeLev < 0 then
			self.chimeEffect:setGrey()
			self.chimeEffect:stop()
		else
			self.chimeEffect:play("texiao01", 0, 1, function ()
			end, true)
		end
	end

	local AttrNum = #self.data.Atrr

	for i = 1, 3 do
		if AttrNum < i then
			self["Attr" .. i]:SetActive(false)
		else
			self["Attr" .. i]:SetActive(true)
			xyd.setUISpriteAsync(self["Attr" .. i]:ComponentByName("icon", typeof(UISprite)), nil, "attr_" .. self.data.Atrr[i][1] .. "_icon")

			local attrValue = self:calculateBaseAttr(self.data.Atrr[i][1], self.lev + self.fakeLev, self.data.Atrr[i][2], self.data.Atrr[i][3])
			self["Attr" .. i]:ComponentByName("label", typeof(UILabel)).text = xyd.tables.dBuffTable:getDesc(self.data.Atrr[i][1]) .. "+" .. attrValue
		end
	end

	self:waitForFrame(1, function ()
		self.AttrGroup:ComponentByName("", typeof(UILayout)):Reposition()
	end)

	self.bg.height = 901
end

function ChimeDetailWindow:updateDetailGroup()
	self.detailGroupHeight = 0
	local gap_LabelActivationToTop = 20
	local gap_SuitAttrToLabelActivation = 10
	local gap_SuitAttr = 10
	local gap_lineToSuitAttr = 16
	local gap_labelAwakeToLine = 10
	local gap_AwakeAttrToLabelAwake = 10
	local gap_AwakeAttrToBottom = 26
	local SuitAttrHeight = 0
	local AttrNum = #self.data.SuitAttr

	for i = 1, 3 do
		if AttrNum < i then
			self["SuitAttr" .. i]:SetActive(false)
		else
			self["SuitAttr" .. i]:SetActive(true)

			local iconSprite = self["SuitAttr" .. i]:ComponentByName("icon", typeof(UISprite))
			local descLabel = self["SuitAttr" .. i]:ComponentByName("label", typeof(UILabel))
			descLabel.text = chimeTable:getBuffDesc(self.tableID, i)
			SuitAttrHeight = SuitAttrHeight + descLabel.height
			self["SuitAttr" .. i]:ComponentByName("", typeof(UIWidget)).height = descLabel.height

			if i <= self.activeTime then
				xyd.applyOrigin(iconSprite)

				descLabel.color = Color.New2(960513791)
			else
				xyd.applyGrey(iconSprite)

				descLabel.color = Color.New2(2155905279.0)
			end
		end
	end

	if self.data.AwakeAtrr then
		local iconSprite = self.awakeAttr1:ComponentByName("icon", typeof(UISprite))
		local descLabel = self.awakeAttr1:ComponentByName("label", typeof(UILabel))
		descLabel.text = chimeTable:getBuffDesc(self.tableID, 4)

		if self.awakeTime > 0 then
			xyd.applyOrigin(iconSprite)

			descLabel.color = Color.New2(960513791)
		else
			xyd.applyGrey(iconSprite)

			descLabel.color = Color.New2(2155905279.0)
		end
	end

	if AttrNum <= 0 then
		self.btnActive:SetActive(false)
		self.labelActivation:SetActive(false)
		self.imgLine:SetActive(false)

		self.labelAwake.gameObject.transform.localPosition = self.labelActivation.gameObject.transform.localPosition

		if not self.data.AwakeAtrr then
			self.btnAwake:SetActive(false)
			self.labelAwake:SetActive(false)
			self.awakeAttr1:SetActive(false)
			self.detailGroup:NodeByName("bg").gameObject:SetActive(false)

			self.bg.height = 545
		else
			local labelAwakeAttr1 = self.awakeAttr1:ComponentByName("label", typeof(UILabel))
			local detailHeight = gap_LabelActivationToTop + self.labelAwake.heght + gap_AwakeAttrToLabelAwake + labelAwakeAttr1.height + gap_AwakeAttrToBottom
			self.detailGroup:ComponentByName("bg", typeof(UISprite)).height = detailHeight
			self.bg.height = 545 + detailHeight + 15
		end
	else
		self.labelActivation:SetActive(true)
		self.imgLine:SetActive(true)

		SuitAttrHeight = SuitAttrHeight + (AttrNum - 1) * gap_SuitAttr
		local activePartHeight = SuitAttrHeight + gap_SuitAttrToLabelActivation + self.labelActivation.height + gap_LabelActivationToTop

		self.imgLine:Y(-activePartHeight - gap_lineToSuitAttr - self.imgLine.height / 2)
		self.labelAwake:Y(-activePartHeight - gap_lineToSuitAttr - self.imgLine.height - gap_labelAwakeToLine - self.labelAwake.height / 2)

		local labelAwakeAttr1 = self.awakeAttr1:ComponentByName("label", typeof(UILabel))

		print(-self.labelAwake.gameObject.transform.localPosition.y)
		print(self.labelAwake.height / 2)
		print(gap_AwakeAttrToLabelAwake)
		print(gap_AwakeAttrToBottom)
		print(labelAwakeAttr1.height)

		local detailHeight = -self.labelAwake.gameObject.transform.localPosition.y + self.labelAwake.height / 2 + gap_AwakeAttrToLabelAwake + labelAwakeAttr1.height + gap_AwakeAttrToBottom
		self.detailGroup:ComponentByName("bg", typeof(UISprite)).height = detailHeight
		self.bg.height = 545 + detailHeight + 15
		local layout = self.SuitAttrGroup:ComponentByName("", typeof(UILayout))

		layout:Reposition()
	end
end

function ChimeDetailWindow:updateLevelUpGroup()
	local labelOld = self.EnergyDetail:ComponentByName("labelOld", typeof(UILabel))
	local labelNew = self.EnergyDetail:ComponentByName("labelNew", typeof(UILabel))
	labelOld.text = __("CHIME_TEXT01") .. " " .. self.lev + self.fakeLev .. "%"
	labelNew.text = self.lev + self.fakeLev + 1 .. "%"
	local AttrNum = #self.data.Atrr

	for i = 1, 3 do
		if AttrNum < i then
			self["atrrDetail" .. i]:SetActive(false)
		else
			labelOld = self["atrrDetail" .. i]:ComponentByName("labelOld", typeof(UILabel))
			labelNew = self["atrrDetail" .. i]:ComponentByName("labelNew", typeof(UILabel))

			self["atrrDetail" .. i]:SetActive(true)
			xyd.setUISpriteAsync(self["atrrDetail" .. i]:ComponentByName("icon", typeof(UISprite)), nil, "attr_" .. self.data.Atrr[i][1] .. "_icon")

			local attrValue = self:calculateBaseAttr(self.data.Atrr[i][1], self.lev + self.fakeLev, self.data.Atrr[i][2], self.data.Atrr[i][3])
			labelOld.text = xyd.tables.dBuffTable:getDesc(self.data.Atrr[i][1]) .. "+" .. attrValue
			labelNew.text = self:calculateBaseAttr(self.data.Atrr[i][1], self.lev + self.fakeLev + 1, self.data.Atrr[i][2], self.data.Atrr[i][3])
		end
	end

	local qlt = chimeTable:getQlt(self.tableID)

	print(qlt)
	print(self.lev + self.fakeLev)

	local cost = chimeExpTable:getCost(self.lev + self.fakeLev, qlt)
	local debrisCostNum = chimeExpTable:getDebrisCost(self.lev + self.fakeLev, qlt)
	local debrisID = self.debrisItemID
	local costNum = #cost

	for i = 1, 3 do
		local iconPos = self["cost_levelup" .. i]:NodeByName("iconPos").gameObject
		local needLabel = self["cost_levelup" .. i]:ComponentByName("label", typeof(UILabel))

		if i <= costNum then
			self["cost_levelup" .. i]:SetActive(true)

			local params = {
				scale = 0.6481481481481481,
				show_has_num = false,
				uiRoot = iconPos,
				itemID = cost[i][1]
			}

			if not self["cost_levelup_icon" .. i] then
				self["cost_levelup_icon" .. i] = AdvanceIcon.new(params)
			else
				self["cost_levelup_icon" .. i]:setInfo(params)
			end

			needLabel.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1])) .. "/" .. xyd.getRoughDisplayNumber(cost[i][2])

			if cost[i][2] <= xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1]) then
				needLabel.color = Color.New2(960513791)
			else
				needLabel.color = Color.New2(3422556671.0)
			end
		else
			self["cost_levelup" .. i]:SetActive(false)
		end
	end

	local labelNeedDebris = self.levelUpGroup:ComponentByName("labelNeedDebris", typeof(UILabel))

	if debrisCostNum and debrisCostNum > 0 then
		labelNeedDebris:SetActive(true)

		local hasNum = xyd.models.backpack:getItemNumByID(debrisID) - self:getFakeUseRes(self.debrisItemID)

		if debrisCostNum <= hasNum then
			labelNeedDebris.text = "[c][394046]" .. xyd.tables.itemTextTable:getName(debrisID) .. "×" .. debrisCostNum .. "[-][/c]" .. "[c][3838C1]" .. "(" .. hasNum .. "/" .. debrisCostNum .. ")" .. "[-][/c]"
		else
			labelNeedDebris.text = "[c][394046]" .. xyd.tables.itemTextTable:getName(debrisID) .. "×" .. debrisCostNum .. "[-][/c]" .. "[c][cc0011]" .. "(" .. hasNum .. "/" .. debrisCostNum .. ")" .. "[-][/c]"
		end
	else
		labelNeedDebris:SetActive(false)
	end
end

function ChimeDetailWindow:updateActiveGroup(isAwake)
	local cost = nil
	local costNum = 0
	local bg = self.awakeGroup:ComponentByName("bg", typeof(UISprite))

	if isAwake == true then
		self.btnConfirmAwake:ComponentByName("label", typeof(UILabel)).text = __("CHIME_BUTTON3")
		cost = self.data.AwakeAtrr.cost

		self.labelNeedEnergy:SetActive(false)

		self.awakeAttr:ComponentByName("label", typeof(UILabel)).text = chimeTable:getBuffDesc(self.tableID, 4)
		costNum = #cost - 1
		local Suitwidget = self.awakeGroup:ComponentByName("scrollerAwake/SuitAttr", typeof(UIWidget))
		Suitwidget.height = Suitwidget:ComponentByName("label", typeof(UILabel)).height

		if Suitwidget.height >= 70 then
			self.awakeAttr:Y(10)
		else
			self.awakeAttr:Y(-10)
		end

		self.labelNeedDebris:SetActive(true)
		xyd.setUISpriteAsync(self.awakeAttr:ComponentByName("icon", typeof(UISprite)), nil, "chime_bg_ysm_tc_hx")

		local debrisItemID = self.debrisItemID
		local hasNum = xyd.models.backpack:getItemNumByID(debrisItemID) - self:getFakeUseRes(debrisItemID)

		if cost[#cost][2] <= hasNum then
			self.labelNeedDebris.text = "[c][394046]" .. xyd.tables.itemTextTable:getName(debrisItemID) .. "×" .. cost[#cost][2] .. "[-][/c]" .. "[c][3838C1]" .. "(" .. hasNum .. "/" .. cost[#cost][2] .. ")" .. "[-][/c]"
		else
			self.labelNeedDebris.text = "[c][394046]" .. xyd.tables.itemTextTable:getName(debrisItemID) .. "×" .. cost[#cost][2] .. "[-][/c]" .. "[c][cc0011]" .. "(" .. hasNum .. "/" .. cost[#cost][2] .. ")" .. "[-][/c]"
		end
	else
		self.btnConfirmAwake:ComponentByName("label", typeof(UILabel)).text = __("CHIME_BUTTON2")
		cost = self.data.SuitAttr[self.activeTime + 1].cost

		self.labelNeedDebris:SetActive(false)

		local needEnergyValue = self.data.SuitAttr[self.activeTime + 1].limit
		self.awakeAttr:ComponentByName("label", typeof(UILabel)).text = chimeTable:getBuffDesc(self.tableID, self.activeTime + 1)
		costNum = #cost

		if needEnergyValue > self.lev + self.fakeLev then
			self.labelNeedEnergy:SetActive(true)

			self.labelNeedEnergy.text = __("CHIME_TEXT11", needEnergyValue .. "%")

			self.awakeAttr:Y(-10)
		else
			self.labelNeedEnergy:SetActive(false)
			self:waitForFrame(1, function ()
				if self.awakeAttr:ComponentByName("label", typeof(UILabel)).height >= 70 then
					self.awakeAttr:Y(10)
				else
					self.awakeAttr:Y(-10)
				end
			end)
		end

		print(cost[costNum])
		print(self.debrisItemID)

		if cost[costNum] and cost[costNum][1] and tonumber(cost[costNum][1]) == tonumber(self.debrisItemID) then
			self.labelNeedDebris:SetActive(true)

			local debrisItemID = self.debrisItemID
			local hasNum = xyd.models.backpack:getItemNumByID(debrisItemID) - self:getFakeUseRes(debrisItemID)

			if cost[#cost][2] <= hasNum then
				self.labelNeedDebris.text = "[c][394046]" .. xyd.tables.itemTextTable:getName(debrisItemID) .. "×" .. cost[#cost][2] .. "[-][/c]" .. "[c][3838C1]" .. "(" .. hasNum .. "/" .. cost[#cost][2] .. ")" .. "[-][/c]"
			else
				self.labelNeedDebris.text = "[c][394046]" .. xyd.tables.itemTextTable:getName(debrisItemID) .. "×" .. cost[#cost][2] .. "[-][/c]" .. "[c][cc0011]" .. "(" .. hasNum .. "/" .. cost[#cost][2] .. ")" .. "[-][/c]"
			end

			costNum = costNum - 1
		else
			self.labelNeedDebris:SetActive(false)
		end

		xyd.setUISpriteAsync(self.awakeAttr:ComponentByName("icon", typeof(UISprite)), nil, "chime_bg_ysm_tc_jh_gl")
	end

	for i = 1, 3 do
		local iconPos = self["cost_awake" .. i]:NodeByName("iconPos").gameObject
		local needLabel = self["cost_awake" .. i]:ComponentByName("label", typeof(UILabel))

		if i <= costNum then
			self["cost_awake" .. i]:SetActive(true)

			local params = {
				scale = 0.6481481481481481,
				show_has_num = false,
				uiRoot = iconPos,
				itemID = cost[i][1]
			}

			if not self["cost_awake_icon" .. i] then
				self["cost_awake_icon" .. i] = AdvanceIcon.new(params)
			else
				self["cost_awake_icon" .. i]:setInfo(params)
			end

			needLabel.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1])) .. "/" .. xyd.getRoughDisplayNumber(cost[i][2])

			if cost[i][2] <= xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1]) then
				needLabel.color = Color.New2(960513791)
			else
				needLabel.color = Color.New2(3422556671.0)
			end
		else
			self["cost_awake" .. i]:SetActive(false)
		end
	end
end

function ChimeDetailWindow:onClickBtnComfirmLevelUp()
	if self.maxLev <= self.lev + self.fakeLev then
		xyd.alertTips(__("CHIME_TEXT08"))

		return
	end

	local qlt = chimeTable:getQlt(self.tableID)
	local cost = chimeExpTable:getCost(self.lev + self.fakeLev, qlt)
	local costNum = #cost
	local debrisCostNum = chimeExpTable:getDebrisCost(self.lev + self.fakeLev, qlt)

	for i = 1, costNum do
		if xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1]) < cost[i][2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[i][1])))

			return
		end

		if debrisCostNum > 0 and debrisCostNum > xyd.models.backpack:getItemNumByID(self.debrisItemID) - self:getFakeUseRes(self.debrisItemID) then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.debrisItemID)))

			return
		end
	end

	print(self.isPlayingLevelUpEffect)

	if not self.isPlayingLevelUpEffect then
		print(self.levelUpEffect)

		if not self.levelUpEffect then
			print("1111111111")
			self.levelUpEffectPos:SetActive(true)

			self.levelUpEffect = xyd.Spine.new(self.levelUpEffectPos.gameObject)

			self.levelUpEffect:setInfo("chime_levelup", function ()
				self.isPlayingLevelUpEffect = true

				self.levelUpEffect:play("texiao01", 1, 1.25, function ()
					self.isPlayingLevelUpEffect = false

					self.levelUpEffectPos:SetActive(false)
				end, true)
			end)
		else
			print("222222222222")
			self.levelUpEffectPos:SetActive(true)

			self.isPlayingLevelUpEffect = true

			self.levelUpEffect:play("texiao01", 1, 1.25, function ()
				self.isPlayingLevelUpEffect = false

				self.levelUpEffectPos:SetActive(false)
			end, true)
		end
	end

	for i = 1, costNum do
		self.fakeUseRes[cost[i][1]] = self.fakeUseRes[cost[i][1]] + cost[i][2]
	end

	if debrisCostNum > 0 then
		self.fakeUseRes[self.debrisItemID] = self.fakeUseRes[self.debrisItemID] + debrisCostNum
	end

	self.fakeLev = self.fakeLev + 1
	local wnd = xyd.getWindow("chime_main_window")

	if wnd then
		wnd:fixTop(self.fakeUseRes)
	end

	if self.lev + self.fakeLev == self.maxLev then
		self:cleanFakeLev()
		self:chooseTab(1)

		return
	end

	self:updateCommonGroup(true)
	self:updateLevelUpGroup()
	self:updateBtnGroup()
end

function ChimeDetailWindow:onClickBtnConfirmAwake()
	if self.curTabIndex == 3 then
		local needEnergyValue = self.data.SuitAttr[self.activeTime + 1].limit

		if self.lev < needEnergyValue then
			xyd.alertTips(__("CHIME_TEXT11", needEnergyValue .. "%"))

			return
		end

		local cost = self.data.SuitAttr[self.activeTime + 1].cost
		local costNum = #cost

		for i = 1, costNum do
			if xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1]) < cost[i][2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[i][1])))

				return
			end
		end
	elseif self.curTabIndex == 4 then
		local cost = self.data.AwakeAtrr.cost
		local costNum = #cost

		for i = 1, costNum do
			if xyd.models.backpack:getItemNumByID(cost[i][1]) - self:getFakeUseRes(cost[i][1]) < cost[i][2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[i][1])))

				return
			end
		end
	end

	local function callback(flag)
		if flag == true then
			local msg = messages_pb:active_chime_buff_req()
			msg.chime_id = tonumber(self.tableID)

			if self.curTabIndex == 4 then
				msg.index = 4
			else
				msg.index = self.activeTime + 1
			end

			xyd.Backend.get():request(xyd.mid.ACTIVE_CHIME_BUFF, msg)
		end
	end

	local message_text = ""

	if self.curTabIndex == 4 then
		message_text = __("CHIME_TEXT13")
	else
		message_text = __("CHIME_TEXT12")
	end

	xyd.alertYesNo(message_text, callback, __("YES"), false, nil, , , , , )
end

function ChimeDetailWindow:onLongTouchBtnLevleUp(go, isPressed)
	local longTouchFunc = nil

	function longTouchFunc()
		if self.maxLev <= self.lev + self.fakeLev then
			self.levUpLongTouchFlag = false

			return
		end

		self:onClickBtnComfirmLevelUp()

		if self.levUpLongTouchFlag == true then
			XYDCo.WaitForTime(0.05, function ()
				if not self or not go or go.activeSelf == false then
					return
				end

				longTouchFunc()
			end, "chimeLevUpLongTouchClick")
		end
	end

	XYDCo.StopWait("chimeLevUpLongTouchClick")

	if isPressed then
		self.levUpLongTouchFlag = true

		XYDCo.WaitForTime(0.5, function ()
			if not self then
				return
			end

			if self.levUpLongTouchFlag then
				longTouchFunc()
			end
		end, "chimeLevUpLongTouchClick")
	else
		self.levUpLongTouchFlag = false
	end
end

function ChimeDetailWindow:onClickUnlockGroup()
	local msg = messages_pb:active_chime_req()
	msg.chime_id = tonumber(self.tableID)

	xyd.Backend.get():request(xyd.mid.ACTIVE_CHIME, msg)
end

function ChimeDetailWindow:onGetMsgUnlock(event)
	self.lev = 0

	self.unlockEffectPos:SetActive(true)
	self.unlockableEffectPos:SetActive(false)
	self.unlockableGroup:SetActive(false)
	self.unlockMask:SetActive(true)
	self.lockImg:SetActive(false)
	self.labelProgressDebris:SetActive(false)
	self.labelProgressEnergy:SetActive(true)

	self.labelProgressEnergy.text = __("CHIME_TEXT01") .. " " .. self.lev + self.fakeLev .. "%"

	local function callback()
		self.unlockEffectPos:SetActive(false)
		self.unlockMask:SetActive(false)
		self.chimeEffect:setOrigin()
		self:updateBtnGroup()
		self.chimeEffect:play("texiao01", 0, 1, function ()
		end, true)
	end

	if not self.unlockEffect then
		self.unlockEffect = xyd.Spine.new(self.unlockEffectPos.gameObject)

		self.unlockEffect:setInfo("chime_unlock", function ()
			self.unlockEffect:play("texiao01", 1, 1, callback, true)
		end)
	else
		self.unlockEffect:play("texiao01", 1, 1, callback, true)
	end

	chimeModel:updateChimeRedPoint()
end

function ChimeDetailWindow:onGetMsgLevelUp(event)
	self.lev = self.lev + self.fakeLev
	self.fakeLev = 0
	self.hasSendLevleUpMsg = false
	self.fakeUseRes = {
		[xyd.ItemID.CRYSTAL] = 0,
		[xyd.ItemID.MANA] = 0,
		[self.debrisItemID] = 0
	}
end

function ChimeDetailWindow:onGetMsgActive(event)
	local activeTime = self.activeTime + 1
	self.activeTime = self.activeTime + 1

	self:chooseTab(1)

	local iconSprite = self["SuitAttr" .. self.activeTime]:ComponentByName("icon", typeof(UISprite))
	local descLabel = self["SuitAttr" .. self.activeTime]:ComponentByName("label", typeof(UILabel))

	xyd.applyGrey(iconSprite)

	descLabel.color = Color.New2(2155905279.0)

	self.activeEffectPos:SetActive(true)

	self.activeEffectPos.gameObject.transform.position = descLabel.gameObject.transform.position

	self.activeEffectPos:X(-12)

	if not self.activeEffect then
		self.activeEffect = xyd.Spine.new(self.activeEffectPos.gameObject)

		self.activeEffect:setInfo("chime_skill", function ()
			self.activeEffect:play("texiao01", 1, 1, function ()
				xyd.applyOrigin(iconSprite)

				descLabel.color = Color.New2(960513791)

				self.activeEffectPos:SetActive(false)
			end, true)
		end)
	else
		self.activeEffect:play("texiao01", 1, 1, function ()
			xyd.applyOrigin(iconSprite)

			descLabel.color = Color.New2(960513791)

			self.activeEffectPos:SetActive(false)
		end, true)
	end
end

function ChimeDetailWindow:onGetMsgAwake(event)
	local awakeTime = self.awakeTime + 1
	self.awakeTime = self.awakeTime + 1

	self:chooseTab(1)

	local iconSprite = self.awakeAttr1:ComponentByName("icon", typeof(UISprite))
	local descLabel = self.awakeAttr1:ComponentByName("label", typeof(UILabel))

	xyd.applyGrey(iconSprite)

	descLabel.color = Color.New2(2155905279.0)

	self.activeEffectPos:SetActive(true)

	self.activeEffectPos.gameObject.transform.position = descLabel.gameObject.transform.position

	self.activeEffectPos:X(-12)

	if not self.activeEffect then
		self.activeEffect = xyd.Spine.new(self.activeEffectPos.gameObject)

		self.activeEffect:setInfo("chime_skill", function ()
			self.activeEffect:play("texiao02", 1, 1, function ()
				xyd.applyOrigin(iconSprite)

				descLabel.color = Color.New2(960513791)

				self.activeEffectPos:SetActive(false)
			end, true)
		end)
	else
		self.activeEffect:play("texiao02", 1, 1, function ()
			xyd.applyOrigin(iconSprite)

			descLabel.color = Color.New2(960513791)

			self.activeEffectPos:SetActive(false)
		end, true)
	end
end

function ChimeDetailWindow:getFakeUseRes(itemID)
	if not self.fakeUseRes[itemID] then
		self.fakeUseRes[itemID] = 0
	end

	return self.fakeUseRes[itemID]
end

function ChimeDetailWindow:cleanFakeLev()
	if self.fakeLev <= 0 then
		return
	end

	local msg = messages_pb:lev_up_chime_req()
	msg.chime_id = tonumber(self.tableID)
	msg.num = self.fakeLev

	xyd.Backend.get():request(xyd.mid.LEV_UP_CHIME, msg)
end

function ChimeDetailWindow:dispose()
	ChimeDetailWindow.super.dispose(self)

	if self.fakeLev > 0 and not self.hasSendLevleUpMsg then
		self:cleanFakeLev()

		self.hasSendLevleUpMsg = true
	end
end

function ChimeDetailWindow:calculateBaseAttr(attr, lev, baseValue, effectValue)
	lev = math.max(lev, 0)
	local pValue = 1

	for i = 1, 3 do
		if self.data.SuitAttr[i] then
			for j = 1, #self.data.SuitAttr[i].buff do
				if i <= self.activeTime then
					local activeAtrr = self.data.SuitAttr[i].buff[j][1]

					if activeAtrr == attr .. "P" then
						pValue = pValue + self.data.SuitAttr[i].buff[j][2]
					end
				end
			end
		end
	end

	if self.awakeTime > 0 and self.data.AwakeAtrr then
		for j = 1, #self.data.AwakeAtrr.buff do
			local awakeAtrr = self.data.AwakeAtrr.buff[j][1]

			print(awakeAtrr)
			print(attr .. "P")
			print(awakeAtrr == attr .. "P")

			if awakeAtrr == attr .. "P" then
				pValue = pValue + self.data.AwakeAtrr.buff[j][2]
			end
		end
	end

	print(baseValue)
	print(lev + 1)
	print(effectValue)
	print(lev)
	print((lev + 1) / 2)
	print(pValue)
	dump(self.data)

	local result = math.floor((baseValue * (lev + 1) + effectValue * lev * (lev + 1) / 2 + baseValue * math.floor(lev / 10)) * pValue)

	return result
end

return ChimeDetailWindow
