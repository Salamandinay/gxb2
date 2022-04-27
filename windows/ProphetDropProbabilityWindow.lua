local BaseWindow = import(".BaseWindow")
local ProphetDropProbabilityWindow = class("ProphetDropProbabilityWindow", BaseWindow)
local ProbabilityRender = class("ProbabilityRender", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local DropboxShowTable = xyd.tables.dropboxShowTable

function ProphetDropProbabilityWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.allWeight = 0
	self.allWightWithGroup = {
		0,
		0,
		0,
		0,
		0
	}
	self.ids = {}
	self.idWithGroup = {}
	self.selectIndex = 0
end

function ProphetDropProbabilityWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle = winTrans:ComponentByName("groupAction/labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.dropItem = winTrans:NodeByName("dropItem").gameObject
	self.scroller = winTrans:ComponentByName("groupAction/scroller", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("groupAction/scroller/itemGroup").gameObject

	for i = 1, 5 do
		self["group" .. i] = winTrans:NodeByName("groupAction/btns/group" .. i).gameObject
		self["group" .. i .. "_chosen"] = self["group" .. i]:NodeByName("group" .. i .. "_chosen").gameObject
	end

	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, self.dropItem, ProbabilityRender, self)
end

function ProphetDropProbabilityWindow:initWindow()
	ProphetDropProbabilityWindow.super.initWindow(self)
	self:getUIComponent()
	self:initData()
	self:initLayOut()
	self:registerEvent()
end

function ProphetDropProbabilityWindow:registerEvent()
	self:register()

	for i = 1, 5 do
		UIEventListener.Get(self["group" .. i]).onClick = function ()
			self:changeGroup(i)
		end
	end
end

function ProphetDropProbabilityWindow:changeGroup(index)
	if self.selectIndex == index then
		self.selectIndex = 0
	else
		self.selectIndex = index
	end

	for i = 1, 5 do
		if self.selectIndex == i then
			self["group" .. tostring(i) .. "_chosen"]:SetActive(true)
		else
			self["group" .. tostring(i) .. "_chosen"]:SetActive(false)
		end
	end

	self:updateLayout(self.selectIndex)
end

function ProphetDropProbabilityWindow:initData()
	local ids = DropboxShowTable:getIds()

	for _, id in ipairs(ids) do
		local summonId = DropboxShowTable:getDropboxId(id)

		if summonId >= 20001 and summonId <= 20005 then
			table.insert(self.ids, id)

			local weight = DropboxShowTable:getWeight(id)
			local type = summonId % 20000

			if not self.idWithGroup[type] then
				self.idWithGroup[type] = {}
			end

			table.insert(self.idWithGroup[type], id)

			self.allWightWithGroup[type] = self.allWightWithGroup[type] + weight
		end
	end
end

function ProphetDropProbabilityWindow:initLayOut()
	self.labelTitle.text = __("DROP_PROBABILITY_WINDOW_TITLE")

	self:changeGroup(self.selectIndex)
end

function ProphetDropProbabilityWindow:updateLayout(type)
	local list = self.ids

	if type > 0 then
		list = self.idWithGroup[type]
	end

	local collect = {}

	for i = 1, #list do
		local table_id = list[i]
		local weight = DropboxShowTable:getWeight(table_id)
		local type = DropboxShowTable:getDropboxId(table_id) % 20000

		if weight then
			table.insert(collect, {
				table_id = table_id,
				all_proba = self.allWightWithGroup[type]
			})
		end
	end

	self.collect_ = collect

	self.wrapContent:setInfos(self.collect_, {})
end

function ProbabilityRender:ctor(go, parent)
	ProbabilityRender.super.ctor(self, go, parent)
end

function ProbabilityRender:initUI()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.label = go:ComponentByName("label", typeof(UILabel))
	local HeroIcon = import("app.components.HeroIcon")
	local icon = HeroIcon.new(self.groupIcon)

	icon:setDragScrollView(self.scroller)

	self.icon_ = icon
end

function ProbabilityRender:updateInfo()
	self.table_id_ = self.data.table_id
	self.all_proba_ = self.data.all_proba
	local data = DropboxShowTable:getItem(self.table_id_)
	self.itemID = data[1]
	self.num = data[2]
	local proba = DropboxShowTable:getWeight(self.table_id_)
	local show_proba = math.ceil(proba * 1000000 / self.all_proba_)
	show_proba = show_proba / 10000
	self.label.text = tostring(show_proba) .. "%"

	self.icon_:setInfo({
		scale = 1.1,
		not_show_ways = true,
		uiRoot = self.groupIcon,
		itemID = self.itemID,
		num = self.num
	})
end

return ProphetDropProbabilityWindow
