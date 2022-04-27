local BaseWindow = import(".BaseWindow")
local ChimeMainWindow = class("ChimeMainWindow", BaseWindow)
local AdvanceIcon = import("app.components.AdvanceIcon")
local WindowTop = import("app.components.WindowTop")
local ChimeMainLayerItem = class("ChimeMainLayerItem", import("app.common.ui.FixedWrapContentItem"))
local ChimeMainItem = class("ChimeMainItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local json = require("cjson")
local chimeTable = xyd.tables.chimeTable
local chimeDecomposeTable = xyd.tables.chimeDecomposeTable
local chimeModel = xyd.models.shrine
local itemLocalPosotionInLayer = {
	{
		Vector3(-227, 28, 0),
		Vector3(-12, 0, 0),
		Vector3(206, -9, 0)
	},
	{
		Vector3(-225, -8, 0),
		Vector3(0, 0, 0),
		Vector3(203, 22, 0)
	}
}
local effectTimes = {
	1.2,
	0.8,
	2.4,
	0.6,
	1.2,
	1.8,
	0.2,
	2.7,
	3.7,
	0.2
}
local NameColor = {
	Color.New2(4294967295.0),
	Color.New2(3889376511.0),
	Color.New2(4098292479.0),
	Color.New2(685729023),
	Color.New2(4128270335.0),
	Color.New2(4253160703.0)
}

function ChimeMainWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.expandBtnISOpen = false
end

function ChimeMainWindow:getUIComponent()
	self.trans = self.window_.transform
	self.content = self.trans:NodeByName("content").gameObject
	self.bg = self.content:ComponentByName("bg", typeof(UITexture))
	self.scroller = self.content:NodeByName("scroller").gameObject
	self.scrollView = self.content:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.chimeItem = self.scroller:NodeByName("chimeItem").gameObject
	self.layerItem = self.scroller:NodeByName("layerItem").gameObject
	self.btnGroup = self.content:NodeByName("btnGroup").gameObject
	self.btnHelp = self.btnGroup:NodeByName("btnHelp").gameObject
	self.expandBtnGroup = self.btnGroup:NodeByName("expandBtnGroupPos/expandBtnGroup").gameObject
	self.btnExpand = self.expandBtnGroup:NodeByName("btnExpand").gameObject
	self.btnExpand_img = self.expandBtnGroup:ComponentByName("btnExpand", typeof(UISprite))
	self.btnsGroup = self.expandBtnGroup:NodeByName("btnsGroup").gameObject
	self.btnPokedex = self.btnsGroup:NodeByName("btnPokedex").gameObject
	self.label_btnPokedex = self.btnPokedex:ComponentByName("label", typeof(UILabel))
	self.btnBackpack = self.btnsGroup:NodeByName("btnBackpack").gameObject
	self.label_btnBackpack = self.btnBackpack:ComponentByName("label", typeof(UILabel))
	self.drag = self.content:NodeByName("drag").gameObject
end

function ChimeMainWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	self.label_btnPokedex.text = __("CHIME_ATLAS")
	self.label_btnBackpack.text = __("CHIME_BAG")
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))

	if not self.wrapContent then
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.layerItem, ChimeMainLayerItem, self)
	end

	if xyd.Global.lang == "fr_fr" then
		self.label_btnPokedex.fontSize = 20
	end

	self:initResItem()
	self:updateExpandGroup(false)
	self:initChime()
end

function ChimeMainWindow:register()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		local items = {
			{
				id = xyd.ItemID.CRYSTAL
			},
			{
				id = xyd.ItemID.MANA
			}
		}

		self.windowTop:setItem(items)
	end)
	self.eventProxy_:addEventListener(xyd.event.ACTIVE_CHIME, function (event)
		local layerItems = self.wrapContent:getItems()

		for key, value in pairs(layerItems) do
			local items = value:getItems()

			for k, item in pairs(items) do
				dump(item)
				print(item:getTableID())
				print(event.data.chime_id)

				if tonumber(item:getTableID()) == tonumber(event.data.chime_id) then
					item:unlockChime()
				end
			end
		end
	end)

	UIEventListener.Get(self.btnExpand).onClick = function ()
		self:updateExpandGroup(not self.expandBtnISOpen)
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "CHIME_HELP"
		})
	end

	UIEventListener.Get(self.btnPokedex).onClick = function ()
		xyd.WindowManager:get():openWindow("chime_pokedex_window", {})
	end

	UIEventListener.Get(self.btnBackpack).onClick = function ()
		xyd.WindowManager:get():openWindow("chime_debris_backpack_window", {})
	end
end

function ChimeMainWindow:initResItem()
	local winTop = WindowTop.new(self.window_, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	winTop:setItem(items)

	self.windowTop = winTop
end

function ChimeMainWindow:updateExpandGroup(isExpanded)
	if self.expandBtnISOpen == isExpanded then
		return
	else
		self.expandBtnISOpen = isExpanded

		if self.moveSequence then
			self.moveSequence:Kill(false)

			self.moveSequence = nil
		end

		self.moveSequence = self:getSequence()

		if isExpanded == false then
			self.btnExpand.transform.localRotation = Vector3(0, 0, 180)
			self.btnExpand:ComponentByName("", typeof(UnityEngine.BoxCollider)).enabled = false

			self.moveSequence:Insert(0, self.expandBtnGroup.transform:DOLocalMove(Vector3(-18, 0, 0), 0.3, false))
			self.moveSequence:AppendCallback(function ()
				self.btnExpand:ComponentByName("", typeof(UnityEngine.BoxCollider)).enabled = true
			end)
		else
			self.btnExpand.transform.localRotation = Vector3(0, 0, 0)
			self.btnExpand:ComponentByName("", typeof(UnityEngine.BoxCollider)).enabled = false

			self.moveSequence:Insert(0, self.expandBtnGroup.transform:DOLocalMove(Vector3(-109, 0, 0), 0.3, false))
			self.moveSequence:AppendCallback(function ()
				self.btnExpand:ComponentByName("", typeof(UnityEngine.BoxCollider)).enabled = true
			end)
		end
	end
end

function ChimeMainWindow:initChime()
	local datas = {}
	local infos = {}
	local ids = chimeTable:getIDs()

	dump(chimeModel:getChimeInfo())

	for i = 1, #ids do
		local id = ids[i]

		print(id)

		local info = chimeModel:getChimeInfoByTableID(id)
		infos[i] = {
			tableID = id,
			lev = info.lev,
			effectOrder = chimeTable:getSort(id)
		}
	end

	local function sort_func(a, b)
		return a.effectOrder < b.effectOrder
	end

	table.sort(infos, sort_func)

	local layerNum = math.ceil(#infos / 3)

	for i = 1, layerNum do
		datas[i] = {
			infos[3 * (i - 1) + 1],
			infos[3 * (i - 1) + 2],
			infos[3 * (i - 1) + 3],
			type = i % 2 + 1
		}
	end

	dump(datas)
	self.wrapContent:setInfos(datas, {})
end

function ChimeMainWindow:fixTop(fakeUseRes)
	local itemList = self.windowTop:getResItemList()

	for i = 1, #itemList do
		local item = itemList[i]
		local itemID = item:getItemID()
		local num = xyd.models.backpack:getItemNumByID(itemID)

		item:setItemNum(num - fakeUseRes[itemID])
	end
end

function ChimeMainLayerItem:ctor(go, parent)
	ChimeMainLayerItem.super.ctor(self, go, parent)

	self.parent = parent
	self.items = {}
end

function ChimeMainLayerItem:initUI()
	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UITexture))
end

function ChimeMainLayerItem:updateInfo()
	for i = 1, #self.data do
		if not self.items[i] then
			local item_object = NGUITools.AddChild(self.go, self.parent.chimeItem)
			local item = ChimeMainItem.new(item_object)

			item:setInfo(self.data[i])

			self.items[i] = item
		else
			self.items[i]:setInfo(self.data[i])
		end

		self.items[i]:setRootLocalPosition(itemLocalPosotionInLayer[self.data.type][i])
	end

	print(self.data.type)

	if self.data.type == 1 then
		self.bg.gameObject.transform.localRotation = Vector3(0, 0, 0)
	else
		self.bg.gameObject.transform.localRotation = Vector3(0, 180, 0)
	end
end

function ChimeMainLayerItem:getItems()
	return self.items
end

function ChimeMainItem:ctor(go, parent)
	ChimeMainItem.super.ctor(self, go)

	self.parent = parent
	self.effects = {}
end

function ChimeMainItem:initUI()
	self:getUIComponent()
	self.eventProxyInner_:addEventListener(xyd.event.LEV_UP_CHIME, function (event)
		local data = event.data

		if self.tableID and tonumber(self.tableID) == tonumber(data.chime_id) then
			self.lev = data.lev

			self:setInfo({
				tableID = self.tableID,
				lev = self.lev,
				effectOrder = self.effectOrder
			})
		end
	end)

	UIEventListener.Get(self.clickMask).onClick = function ()
		self:onClickChime()
	end
end

function ChimeMainItem:getUIComponent()
	self.effectPos = self.go:ComponentByName("effectPos", typeof(UITexture))
	self.lockGroup = self.go:NodeByName("lockGroup").gameObject
	self.lockImg = self.lockGroup:ComponentByName("img", typeof(UISprite))
	self.redPoint = self.go:ComponentByName("redPoint", typeof(UISprite))
	self.progressGroup = self.go:ComponentByName("progressGroup", typeof(UISprite))
	self.labelLev = self.progressGroup:ComponentByName("label", typeof(UILabel))
	self.labelName = self.go:ComponentByName("labelName", typeof(UILabel))
	self.clickMask = self.go:NodeByName("clickMask").gameObject
end

function ChimeMainItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.tableID = params.tableID
	self.lev = params.lev
	self.effectOrder = params.effectOrder

	if chimeModel:getChimeInfoByTableID(self.tableID).lev == -1 then
		self.lock = true
	else
		self.lock = false
	end

	self.unlockCost = chimeTable:getUnlock(self.tableID)
	self.debrisItemID = self.unlockCost[1]
	self.needDebrisNumCompose = self.unlockCost[2]
	self.debrisNum = xyd.models.backpack:getItemNumByID(self.debrisItemID)

	if self.needDebrisNumCompose <= self.debrisNum and self.lock then
		self.canUnlock = true
	else
		self.canUnlock = false
	end

	if self.effect then
		self.effect:SetActive(false)
	end

	self.effect = self.effects[self.tableID]

	if not self.effect then
		self.effects[self.tableID] = xyd.Spine.new(self.effectPos.gameObject)
		self.effect = self.effects[self.tableID]

		self.effect:setInfo(chimeTable:getEffectName(self.tableID), function ()
			self.effect:setRenderTarget(self.effectPos.gameObject:GetComponent(typeof(UITexture)), self.effectOrder)
			self.effect:play("texiao01", 0, 1, function ()
			end, true)

			if self.lock then
				self.effect:setGrey()
				self:waitForFrame(3, function ()
					self.effect:pause()
				end)
			else
				self.effect:setOrigin()

				local index = self.effectOrder % #effectTimes + 1

				self.effect:playAtTime("texiao01", 0, effectTimes[index])
			end
		end)
	else
		self.effect:SetActive(true)
	end

	self.lockImg.depth = 1000 + self.effectOrder * 2 - 1
	self.redPoint.depth = 1000 + self.effectOrder * 2 - 1

	self.progressGroup:SetActive(self.lock == false)
	self.redPoint:SetActive(self.canUnlock == true)
	self.lockImg:SetActive(self.lock == true)

	self.labelName.text = xyd.tables.chimeTextTable:getName(self.tableID)
	local ids = chimeTable:getIDs()

	if self.lev == 100 then
		self.labelLev.text = "MAX"
	else
		self.labelLev.text = self.lev .. "%"
	end

	local qlt = chimeTable:getQlt(self.tableID)
	self.labelName.color = NameColor[qlt]
end

function ChimeMainItem:setRootLocalPosition(position)
	self.go.gameObject.transform.localPosition = position
end

function ChimeMainItem:onClickChime()
	xyd.openWindow("chime_detail_window", {
		tableID = self.tableID
	})
end

function ChimeMainItem:getTableID()
	return self.tableID
end

function ChimeMainItem:unlockChime()
	self.lock = false
	self.unlock = false
	self.lev = 0

	self.progressGroup:SetActive(true)
	self.redPoint:SetActive(false)
	self.lockImg:SetActive(false)

	local qlt = chimeTable:getQlt(self.tableID)
	self.labelName.color = NameColor[qlt]
	self.labelLev.text = self.lev .. "%"

	self.effect:setOrigin()
	self.effect:play("texiao01", 0, 1, function ()
	end, true)
end

function ChimeMainWindow:willClose()
	ChimeMainWindow.super.willClose(self)
	xyd.models.slot:updateAllPartnersAttrs()
end

return ChimeMainWindow
