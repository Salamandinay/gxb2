local BaseWindow = import(".BaseWindow")
local SoulEquipChooseSuitWindow = class("SoulEquipChooseSuitWindow", BaseWindow)
local slot = xyd.models.slot
local CommonTabBar = import("app.common.ui.CommonTabBar")
local SoulEquipChooseSuitSimpleItem = class("SoulEquipChooseSuitSimpleItem", import("app.common.ui.FixedMultiWrapContentItem"))
local SoulEquipChooseSuitCompleteItem = class("SoulEquipChooseSuitCompleteItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function SoulEquipChooseSuitWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curSelectSuitID = params.curSelectSuitID
	self.chooseCompleteMode = true
end

function SoulEquipChooseSuitWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulEquipChooseSuitWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.topGoup = self.groupAction:NodeByName("topGoup").gameObject
	self.btnCompleteMode = self.topGoup:NodeByName("btnCompleteMode").gameObject
	self.imgSelect = self.btnCompleteMode:ComponentByName("imgSelect", typeof(UISprite))
	self.labelComplete = self.btnCompleteMode:ComponentByName("labelComplete", typeof(UILabel))
	self.btnfilter = self.topGoup:NodeByName("btnfilter").gameObject
	self.labelFilter = self.btnfilter:ComponentByName("label", typeof(UILabel))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.content1 = self.bottomGroup:NodeByName("content1").gameObject
	self.simpleItem = self.content1:NodeByName("simpleItem").gameObject
	self.simpleScroller = self.content1:NodeByName("simpleScroller").gameObject
	self.simpleScrollView = self.content1:ComponentByName("simpleScroller", typeof(UIScrollView))
	self.itemGroupSimple = self.simpleScroller:NodeByName("itemGroup").gameObject
	self.content2 = self.bottomGroup:NodeByName("content2").gameObject
	self.completeItem = self.content2:NodeByName("completeItem").gameObject
	self.completeScroller = self.content2:NodeByName("completeScroller").gameObject
	self.completeScrollView = self.content2:ComponentByName("completeScroller", typeof(UIScrollView))
	self.itemGroupComplete = self.completeScroller:NodeByName("itemGroup").gameObject
	local wrapContent = self.completeScroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.wrapContentComplete = FixedWrapContent.new(self.completeScrollView, wrapContent, self.completeItem.gameObject, SoulEquipChooseSuitCompleteItem, self)
	local wrapContent = self.simpleScroller:ComponentByName("itemGroup", typeof(MultiRowWrapContent))
	self.multiWrapSimple = require("app.common.ui.FixedMultiWrapContent").new(self.simpleScrollView, wrapContent, self.simpleItem, SoulEquipChooseSuitSimpleItem, self)
end

function SoulEquipChooseSuitWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnfilter).onClick = function ()
		self.curSelectSuitID = 0

		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnCompleteMode).onClick = function ()
		self.chooseCompleteMode = not self.chooseCompleteMode

		self:update()
	end
end

function SoulEquipChooseSuitWindow:layout()
	self.labelWindowTitle.text = __("SOUL_EQUIP_TEXT09")
	self.labelComplete.text = __("SOUL_EQUIP_TEXT21")
	self.labelFilter.text = __("SOUL_EQUIP_TEXT20")

	self:update()
end

function SoulEquipChooseSuitWindow:update()
	if self.chooseCompleteMode then
		self.content2:SetActive(true)
		self.content1:SetActive(false)
		self.imgSelect:SetActive(true)
		self:updateCompleteGroup()
	else
		self.content2:SetActive(false)
		self.content1:SetActive(true)
		self.imgSelect:SetActive(false)
		self:updateSimpleGroup()
	end
end

function SoulEquipChooseSuitWindow:updateCompleteGroup()
	if not self.sortedBySuit then
		self.sortedBySuit = {}
		local list = xyd.models.slot:getSoulEquip2s()

		for id, equip in pairs(list) do
			local suitID = xyd.tables.soulEquip2Table:getGroup(equip:getTableID())

			if not self.sortedBySuit[suitID] then
				self.sortedBySuit[suitID] = {}
			end

			table.insert(self.sortedBySuit[suitID], equip)
		end
	end

	local data = {}
	local suitIDs = xyd.tables.soulEquip2GroupTable:getIDs()

	for i = 1, #suitIDs do
		local suitID = tonumber(suitIDs[i])
		local hasNum = 0

		if self.sortedBySuit[suitID] then
			hasNum = #self.sortedBySuit[suitID]
		end

		table.insert(data, {
			suitID = suitID,
			hasNum = hasNum,
			skillID = xyd.tables.soulEquip2GroupTable:getSuitSkill(suitID)
		})
	end

	self.wrapContentComplete:setInfos(data, {})
	self.completeScrollView:ResetPosition()
end

function SoulEquipChooseSuitWindow:updateSimpleGroup()
	if not self.sortedBySuit then
		self.sortedBySuit = {}
		local list = xyd.models.slot:getSoulEquip2s()

		for id, equip in pairs(list) do
			local suitID = xyd.tables.soulEquip2Table:getGroup(equip:getTableID())

			if not self.sortedBySuit[suitID] then
				self.sortedBySuit[suitID] = {}
			end

			table.insert(self.sortedBySuit[suitID], equip)
		end
	end

	local data = {}
	local suitIDs = xyd.tables.soulEquip2GroupTable:getIDs()

	for i = 1, #suitIDs do
		local suitID = tonumber(suitIDs[i])
		local hasNum = 0

		if self.sortedBySuit[suitID] then
			hasNum = #self.sortedBySuit[suitID]
		end

		table.insert(data, {
			suitID = suitID,
			hasNum = hasNum,
			skillID = xyd.tables.soulEquip2GroupTable:getSuitSkill(suitID)
		})
	end

	self.multiWrapSimple:setInfos(data, {})
	self.simpleScrollView:ResetPosition()
end

function SoulEquipChooseSuitWindow:willClose(params)
	BaseWindow.willClose(self, params)

	local wnd = xyd.WindowManager.get():getWindow("soul_equip2_strengthen_window")

	if wnd then
		wnd:changeFilterSuit(self.curSelectSuitID)
	else
		local wnd1 = xyd.WindowManager.get():getWindow("soul_equip_info_window")

		if wnd1 then
			wnd1:changeFilterSuit(self.curSelectSuitID)
		end
	end
end

function SoulEquipChooseSuitCompleteItem:ctor(go, parent)
	SoulEquipChooseSuitCompleteItem.super.ctor(self, go, parent)

	self.parent = parent
end

function SoulEquipChooseSuitCompleteItem:initUI()
	self.completeItem = self.go
	self.bg = self.completeItem:ComponentByName("bg", typeof(UISprite))
	self.icon = self.completeItem:ComponentByName("icon", typeof(UISprite))
	self.labelHaveNum = self.completeItem:ComponentByName("labelHaveNum", typeof(UILabel))
	self.labelName = self.completeItem:ComponentByName("labelName", typeof(UILabel))
	self.labelSkillDesc = self.completeItem:ComponentByName("labelSkillDesc", typeof(UILabel))
	self.imgSelect = self.completeItem:ComponentByName("imgSelect", typeof(UISprite))

	UIEventListener.Get(self.go.gameObject).onClick = function ()
		self.parent.curSelectSuitID = self.data.suitID

		if self.parent.curSelectCompleteItem then
			self.parent.curSelectCompleteItem:checkChoose()
		end

		self:checkChoose()
	end
end

function SoulEquipChooseSuitCompleteItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo(index)
end

function SoulEquipChooseSuitCompleteItem:updateInfo(index)
	local skillID = xyd.tables.soulEquip2GroupTable:getSuitSkill(self.data.suitID)
	self.labelName.text = xyd.tables.skillTextTable:getName(skillID)
	self.labelSkillDesc.text = xyd.tables.skillTextTable:getDesc(skillID)
	self.labelHaveNum.text = "x" .. self.data.hasNum

	xyd.setUISpriteAsync(self.icon, nil, xyd.tables.soulEquip2GroupTable:getIcon(self.data.suitID))

	if xyd.Global.lang == "fr_fr" then
		self.labelSkillDesc.fontSize = 18
	end

	self:checkChoose()
end

function SoulEquipChooseSuitCompleteItem:checkChoose()
	if self.parent.curSelectSuitID ~= self.data.suitID then
		self.imgSelect:SetActive(false)
	else
		self.parent.curSelectCompleteItem = self

		self.imgSelect:SetActive(true)
	end
end

function SoulEquipChooseSuitSimpleItem:ctor(go, parent)
	SoulEquipChooseSuitSimpleItem.super.ctor(self, go, parent)

	self.parent = parent
end

function SoulEquipChooseSuitSimpleItem:initUI()
	self.simpleItem = self.go
	self.bg = self.simpleItem:ComponentByName("bg", typeof(UISprite))
	self.icon = self.simpleItem:ComponentByName("icon", typeof(UISprite))
	self.labelHaveNum = self.simpleItem:ComponentByName("labelHaveNum", typeof(UILabel))
	self.labelName = self.simpleItem:ComponentByName("labelName", typeof(UILabel))
	self.imgSelect = self.simpleItem:ComponentByName("imgSelect", typeof(UISprite))

	UIEventListener.Get(self.go.gameObject).onClick = function ()
		self.parent.curSelectSuitID = self.data.suitID

		if self.parent.curSelectSimpleItem then
			self.parent.curSelectSimpleItem:checkChoose()
		end

		self:checkChoose()
	end
end

function SoulEquipChooseSuitSimpleItem:update(wrapIndex, index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:updateInfo(wrapIndex, index)
end

function SoulEquipChooseSuitSimpleItem:updateInfo(wrapIndex, index)
	local skillID = xyd.tables.soulEquip2GroupTable:getSuitSkill(self.data.suitID)
	self.labelName.text = xyd.tables.skillTextTable:getName(skillID)
	self.labelHaveNum.text = "x" .. self.data.hasNum

	xyd.setUISpriteAsync(self.icon, nil, xyd.tables.soulEquip2GroupTable:getIcon(self.data.suitID))
	self:checkChoose()
end

function SoulEquipChooseSuitSimpleItem:checkChoose()
	if self.parent.curSelectSuitID ~= self.data.suitID then
		self.imgSelect:SetActive(false)
	else
		self.parent.curSelectSimpleItem = self

		self.imgSelect:SetActive(true)
	end
end

return SoulEquipChooseSuitWindow
