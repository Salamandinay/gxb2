local BaseWindow = import(".BaseWindow")
local ChimePokedexWindow = class("ChimePokedexWindow", BaseWindow)
local ChimePokedexLayerItem = class("ChimePokedexItem", import("app.common.ui.FixedWrapContentItem"))
local ChimePokedexItem = class("ChimePokedexItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local json = require("cjson")
local chimeTable = xyd.tables.chimeTable
local chimeDecomposeTable = xyd.tables.chimeDecomposeTable
local NameColor = {
	Color.New2(4294967295.0),
	Color.New2(3889376511.0),
	Color.New2(4098292479.0),
	Color.New2(685729023),
	Color.New2(4128270335.0),
	Color.New2(4253160703.0)
}
local chimeSize = {
	[20001] = {
		97,
		266
	},
	[30001] = {
		99,
		269
	},
	[40001] = {
		116,
		288
	},
	[40002] = {
		126,
		271
	},
	[40003] = {
		99,
		288
	},
	[40004] = {
		107,
		268
	},
	[50001] = {
		107,
		282
	},
	[50002] = {
		102,
		289
	}
}

function ChimePokedexWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ChimePokedexWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.btnClose = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.scrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.item = self.groupAction:NodeByName("item").gameObject
	self.layerItem = self.groupAction:NodeByName("layerItem").gameObject
	self.img = self.item:NodeByName("img").gameObject
	self.labelName = self.item:ComponentByName("labelName", typeof(UILabel))
	self.maxGroup = self.item:ComponentByName("maxGroup", typeof(UISprite))
	self.label = self.maxGroup:ComponentByName("label", typeof(UILabel))
	self.drag = self.groupAction:NodeByName("drag").gameObject
end

function ChimePokedexWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	self.labelTitle.text = __("CHIME_ATLAS")
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))

	if not self.wrapContent then
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.layerItem, ChimePokedexLayerItem, self)
	end

	self:initPokedex()
end

function ChimePokedexWindow:register()
	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ChimePokedexWindow:initPokedex()
	local data = {}
	local datas = chimeTable:getIDs()

	local function sort_func(a, b)
		local qlt_A = chimeTable:getQlt(a)
		local qlt_B = chimeTable:getQlt(b)

		if qlt_A ~= qlt_B then
			return qlt_B < qlt_A
		else
			return a < b
		end
	end

	table.sort(datas, sort_func)

	for i = 1, #datas do
		if not data[math.ceil(i / 3)] then
			data[math.ceil(i / 3)] = {}
		end

		table.insert(data[math.ceil(i / 3)], datas[i])
	end

	self.wrapContent:setInfos(data, {})
end

function ChimePokedexLayerItem:ctor(go, parent)
	ChimePokedexLayerItem.super.ctor(self, go, parent)

	self.parent = parent
	self.items = {}
end

function ChimePokedexLayerItem:initUI()
	local go = self.go
	self.fgx1 = go:ComponentByName("fgx1", typeof(UISprite))
	self.fgx2 = go:ComponentByName("fgx2", typeof(UISprite))
	self.content = go:NodeByName("content").gameObject
	self.contentGrid = go:ComponentByName("content", typeof(UIGrid))
end

function ChimePokedexLayerItem:updateInfo()
	for i = 1, #self.data do
		if not self.items[i] then
			local item_object = NGUITools.AddChild(self.content, self.parent.item)
			local item = ChimePokedexItem.new(item_object)

			item:setInfo(self.data[i])

			self.items[i] = item
		else
			self.items[i]:setInfo(self.data[i])
		end
	end

	self.contentGrid:Reposition()
end

function ChimePokedexLayerItem:getItems()
	return self.items
end

function ChimePokedexItem:ctor(go, parent)
	ChimePokedexItem.super.ctor(self, go)

	self.parent = parent
end

function ChimePokedexItem:initUI()
	self:getUIComponent()

	UIEventListener.Get(self.go).onClick = function ()
		xyd.openWindow("chime_detail_window", {
			pokedexMode = true,
			tableID = self.tableID
		})
	end
end

function ChimePokedexItem:getUIComponent()
	local go = self.go
	self.img = self.go:ComponentByName("img", typeof(UISprite))
	self.labelName = self.go:ComponentByName("labelName", typeof(UILabel))
	self.maxGroup = self.go:ComponentByName("maxGroup", typeof(UISprite))
	self.label = self.maxGroup:ComponentByName("label", typeof(UILabel))
end

function ChimePokedexItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.tableID = params
	local ID = self.tableID
	local spriteName = chimeTable:getIcon(ID)
	local qlt = chimeTable:getQlt(ID)
	self.img.width = chimeSize[tonumber(self.tableID)][1]
	self.img.height = chimeSize[tonumber(self.tableID)][2]

	xyd.setUISpriteAsync(self.img, nil, spriteName)

	self.labelName.text = xyd.tables.chimeTextTable:getName(ID)
	self.labelName.color = NameColor[qlt]
	self.label.text = "MAX"
end

return ChimePokedexWindow
