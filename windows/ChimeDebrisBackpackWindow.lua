local BaseWindow = import(".BaseWindow")
local ChimeDebrisBackpackWindow = class("ChimeDebrisBackpackWindow", BaseWindow)
local ChimeDebrisItem = class("ChimeDebrisItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local json = require("cjson")
local chimeTable = xyd.tables.chimeTable
local chimeDecomposeTable = xyd.tables.chimeDecomposeTable
local chimeModel = xyd.models.shrine

function ChimeDebrisBackpackWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ChimeDebrisBackpackWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UITexture))
	self.btnClose = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.scrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.item = self.scroller:NodeByName("item").gameObject
	self.img = self.item:NodeByName("img").gameObject
	self.label = self.item:ComponentByName("label", typeof(UILabel))
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.btnDecompose = self.groupAction:NodeByName("btnDecompose").gameObject
	self.button_label = self.btnDecompose:ComponentByName("button_label", typeof(UILabel))
	self.decomposeGroup = self.groupAction:NodeByName("decomposeGroup").gameObject
	self.btnCancel = self.decomposeGroup:NodeByName("btnCancel").gameObject
	self.btnSure = self.decomposeGroup:NodeByName("btnSure").gameObject
	self.resGroup = self.decomposeGroup:NodeByName("resGroup").gameObject
	self.iconRes = self.resGroup:ComponentByName("icon", typeof(UISprite))
	self.labelResNum = self.resGroup:ComponentByName("label", typeof(UILabel))
	self.inputPos = self.decomposeGroup:NodeByName("inputPos").gameObject
	self.groupNone = self.groupAction:NodeByName("groupNone_").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNoneTips_", typeof(UILabel))
end

function ChimeDebrisBackpackWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	self.labelTitle.text = __("CHIME_BAG")
	self.button_label.text = __("CHIME_TEXT17")
	self.labelNone.text = __("NO_ITEM")
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))

	if not self.wrapContent then
		self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.item, ChimeDebrisItem, self)
	end

	local function callback(num)
		self.curNum_ = num

		if self.chooseID then
			local award = chimeDecomposeTable:getAwards(self.chooseID)

			xyd.setUISpriteAsync(self.iconRes, nil, xyd.tables.itemTable:getIcon(award[1]))

			self.labelResNum.text = xyd.getRoughDisplayNumber(award[2] * self.curNum_)
		end
	end

	local SelectNum = import("app.components.SelectNum")
	self.selectNum_ = SelectNum.new(self.inputPos, "default")

	self.selectNum_:setInfo({
		curNum = 1,
		maxNum = 1000,
		callback = callback
	})
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -180)
	self.selectNum_:setMaxNum(1000)
	self.selectNum_:setCurNum(1)
	self.selectNum_:changeCurNum()
	self.selectNum_:setSelectBGSize(140, 40)
	self:initBackpack()
end

function ChimeDebrisBackpackWindow:register()
	self.eventProxy_:addEventListener(xyd.event.EXCHANGE_CHIME_PIECE, function (event)
		local allItem = {}
		local awards = chimeDecomposeTable:getAwards(self.chooseID)
		local award = awards
		local item = {
			item_id = award[1],
			item_num = award[2] * self.curNum_
		}

		table.insert(allItem, item)
		xyd.itemFloat(allItem)

		self.chooseID = nil

		self.chooseItem:choose(false)
		self.chooseItem:updateInfo()

		self.chooseItem = nil

		self.selectNum_:setCurNum(1)
		self.selectNum_:changeCurNum()
	end)

	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnDecompose).onClick = function ()
		self:onClickBtnDecompose()
		self.selectNum_:setBtnPos(109)
	end

	UIEventListener.Get(self.btnCancel).onClick = function ()
		self:onClickBtnCancel()
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		self:onClickBtnSure()
	end
end

function ChimeDebrisBackpackWindow:initBackpack()
	local datas = {}
	local ids = chimeDecomposeTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])
		local hasNum = xyd.models.backpack:getItemNumByID(id)

		if hasNum > 0 then
			table.insert(datas, id)
		end
	end

	if #datas > 0 then
		self.groupNone:SetActive(false)
		self.bg2:SetActive(true)
		self.scroller:SetActive(true)
		self.btnDecompose:SetActive(true)
		self.wrapContent:setInfos(datas, {})
	else
		self.groupNone:SetActive(true)
		self.bg2:SetActive(false)
		self.scroller:SetActive(false)
		self.btnDecompose:SetActive(false)

		return
	end
end

function ChimeDebrisBackpackWindow:onClickBtnDecompose()
	self.isDecomposeMode = true

	self.decomposeGroup:SetActive(true)
	self.btnDecompose:SetActive(false)

	self.chooseID = nil
	self.chooseItem = nil
	self.labelResNum.text = 0
	local wrapcontentItems = self.wrapContent:getItems()

	for key, value in pairs(wrapcontentItems) do
		if value.data then
			value:updateDecomposeState()
		end
	end
end

function ChimeDebrisBackpackWindow:onClickBtnCancel()
	self.isDecomposeMode = false

	self.decomposeGroup:SetActive(false)
	self.btnDecompose:SetActive(true)

	if self.chooseItem then
		self.chooseItem:choose(false)

		self.chooseItem = nil
		self.chooseID = nil

		self:updateDecomposeGroup()
	end

	local wrapcontentItems = self.wrapContent:getItems()

	for key, value in pairs(wrapcontentItems) do
		if value.data then
			value:updateDecomposeState()
		end
	end
end

function ChimeDebrisBackpackWindow:onClickBtnSure()
	if not self.chooseID then
		xyd.alertTips(__("CHIME_TEXT15"))

		return
	else
		local msg = messages_pb:exchange_chime_piece_req()
		msg.item_id = self.chooseID
		msg.item_num = self.curNum_

		xyd.Backend.get():request(xyd.mid.EXCHANGE_CHIME_PIECE, msg)
	end
end

function ChimeDebrisBackpackWindow:updateDecomposeGroup()
	if self.chooseID then
		self.iconRes:SetActive(true)
		self.labelResNum:SetActive(true)

		local award = chimeDecomposeTable:getAwards(self.chooseID)

		xyd.setUISpriteAsync(self.iconRes, nil, xyd.tables.itemTable:getIcon(award[1]))

		self.labelResNum.text = award[2] * self.curNum_
		local maxNum = self:getMaxCanDecomposeNum(self.chooseID)

		self.selectNum_:setMaxNum(maxNum)
	else
		self.iconRes:SetActive(true)

		self.labelResNum.text = 0
		local maxNum = 1000

		self.selectNum_:setMaxNum(maxNum)
	end

	self.selectNum_:setCurNum(1)
	self.selectNum_:changeCurNum()
end

function ChimeDebrisBackpackWindow:getMaxCanDecomposeNum(ItemID)
	local hasNum = xyd.models.backpack:getItemNumByID(ItemID)
	local stillNeed = 0
	local chimeID = chimeDecomposeTable:getChimeID(ItemID)
	local chimeInfo = chimeModel:getChimeInfoByTableID(chimeID)
	local activeTime = chimeInfo.buffs[1] + chimeInfo.buffs[2] + chimeInfo.buffs[3]
	local awakeTime = chimeInfo.buffs[4]
	local lev = chimeInfo.lev
	local maxLevel = chimeTable:getMaxLev(chimeID)
	local qlt = chimeTable:getQlt(chimeID)
	local cost = nil

	for i = lev, maxLevel - 1 do
		local costDebrisNum = xyd.tables.chimeExpTable:getDebrisCost(i, qlt)

		if costDebrisNum and costDebrisNum > 0 then
			stillNeed = stillNeed + costDebrisNum
		end
	end

	if awakeTime < 1 then
		cost = chimeTable:getCost4(chimeID)

		if cost then
			for i = 1, #cost do
				if cost[i][1] == ItemID then
					stillNeed = stillNeed + cost[i][2]
				end
			end
		end
	end

	if activeTime < 3 then
		cost = chimeTable:getCost3(chimeID)

		if cost then
			for i = 1, #cost do
				if cost[i][1] == ItemID then
					stillNeed = stillNeed + cost[i][2]
				end
			end
		end
	end

	if activeTime < 2 then
		cost = chimeTable:getCost2(chimeID)

		if cost then
			for i = 1, #cost do
				if cost[i][1] == ItemID then
					stillNeed = stillNeed + cost[i][2]
				end
			end
		end
	end

	if activeTime < 1 then
		cost = chimeTable:getCost1(chimeID)

		if cost then
			for i = 1, #cost do
				if cost[i][1] == ItemID then
					stillNeed = stillNeed + cost[i][2]
				end
			end
		end
	end

	print(ItemID)
	print(hasNum)
	print(stillNeed)

	local maxNum = math.max(0, hasNum - stillNeed)

	return maxNum
end

function ChimeDebrisItem:ctor(go, parent)
	ChimeDebrisItem.super.ctor(self, go, parent)

	self.parent = parent
end

function ChimeDebrisItem:initUI()
	local go = self.go
	self.img = self.go:ComponentByName("img", typeof(UISprite))
	self.label = self.go:ComponentByName("label", typeof(UILabel))
	self.selectGroup = self.go:NodeByName("selectGroup")
	self.greyGroup = self.go:NodeByName("greyGroup")

	UIEventListener.Get(self.go).onClick = function ()
		if not self.parent.isDecomposeMode then
			xyd.WindowManager.get():openWindow("item_tips_window", {
				show_has_num = true,
				itemID = self.itemID
			})

			return
		end

		if self.parent:getMaxCanDecomposeNum(self.itemID) <= 0 then
			xyd.alertTips(__("CHIME_TEXT18"))

			return
		end

		if self.parent.chooseItem then
			if self.parent.chooseItem ~= self then
				self.parent.chooseItem:choose(false)

				self.parent.chooseItem = self
				self.parent.chooseID = self.data

				self:choose(true)
			else
				self.parent.chooseItem:choose(false)

				self.parent.chooseItem = nil
				self.parent.chooseID = nil
			end
		else
			self.parent.chooseItem = self
			self.parent.chooseID = self.data

			self:choose(true)
		end

		self.parent.chooseNum = 1

		self.parent:updateDecomposeGroup()
	end
end

function ChimeDebrisItem:updateInfo()
	self.itemID = self.data
	local spriteName = xyd.tables.itemTable:getIcon(self.itemID)

	xyd.setUISpriteAsync(self.img, nil, spriteName)

	self.label.text = "×" .. xyd.models.backpack:getItemNumByID(self.itemID)

	self:updateDecomposeState()
end

function ChimeDebrisItem:choose(flag)
	self.selectGroup:SetActive(flag)
end

function ChimeDebrisItem:updateDecomposeState()
	if self.parent.isDecomposeMode then
		self.maxCanDecomposeNum = self.parent:getMaxCanDecomposeNum(self.itemID)

		if self.maxCanDecomposeNum <= 0 then
			self.greyGroup:SetActive(true)
		else
			self.greyGroup:SetActive(false)
		end
	else
		self.greyGroup:SetActive(false)
	end
end

return ChimeDebrisBackpackWindow
