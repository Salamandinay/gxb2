local RollbackAwardWindow = class("RollbackAwardWindow", import(".BaseWindow"))

function RollbackAwardWindow:ctor(name, params)
	RollbackAwardWindow.super.ctor(self, name, params)

	self.datas = params.data
	self.callback = params.callback
	self.itemTable = xyd.tables.itemTable
	self.title_key_ = params.title_key or "ITEM_SUMMON"
end

function RollbackAwardWindow:initWindow()
	RollbackAwardWindow.super.initWindow(self)
	self:getComponent()
	self:initData()
	self:layout()
	self:registerEvent()
end

function RollbackAwardWindow:getComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.btnSure_ = groupAction:NodeByName("btnSure_").gameObject
	self.scrollView = groupAction:ComponentByName("scrollview", typeof(UIScrollView))
	self.grid = self.scrollView:ComponentByName("grid", typeof(UIGrid))
	self.item1 = groupAction:NodeByName("item1").gameObject
end

function RollbackAwardWindow:initData()
	local tmpData = {}
	local starData = {}

	for i = 1, #self.datas do
		local item = self.datas[i]

		if not tmpData[item.item_id] then
			tmpData[item.item_id] = item.item_num
		else
			tmpData[item.item_id] = tmpData[item.item_id] + item.item_num
		end

		starData[item.item_id] = item.star
	end

	self.datas = {}

	for id, _ in pairs(tmpData) do
		table.insert(self.datas, {
			item_id = tonumber(id),
			itemID = tonumber(id),
			item_num = tmpData[id],
			num = tmpData[id]
		})
	end
end

function RollbackAwardWindow:layout()
	for i = 1, #self.datas do
		local data = self.datas[i]
		local itemID = data.item_id
		local itemNum = data.item_num
		local type_ = self.itemTable:getType(itemID)
		local showBagType = self.itemTable:showInBagType(itemID)
		local item = nil

		if showBagType == xyd.BackpackShowType.EQUIP or showBagType == xyd.BackpackShowType.ARTIFACT or type_ == xyd.ItemType.HERO then
			item = self:createNumItem(data)
		else
			item = self:createItem(data)
		end
	end

	self.labelTitle.text = __(self.title_key_)

	xyd.setBtnLabel(self.btnSure_, {
		text = __("SURE_2")
	})
end

return RollbackAwardWindow
