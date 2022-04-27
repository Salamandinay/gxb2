local BaseWindow = import(".BaseWindow")
local AlertHerosWindow = class("AlertHerosWindow", BaseWindow)

function AlertHerosWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.datas = params.data
	self.callback = params.callback
	self.itemTable = xyd.tables.itemTable
end

function AlertHerosWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initData()
	self:layout()
	self:registerEvent()
end

function AlertHerosWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.btnSure_ = groupAction:NodeByName("btnSure_").gameObject
	self.scrollView = groupAction:ComponentByName("scrollview", typeof(UIScrollView))
	self.grid = self.scrollView:ComponentByName("grid", typeof(UIGrid))
	self.item1 = groupAction:NodeByName("item1").gameObject
end

function AlertHerosWindow:initData()
	local tmpData = {}

	for i = 1, #self.datas do
		local item = self.datas[i]
		local key = item.item_id .. "_" .. (item.star or 0)

		if not tmpData[key] then
			tmpData[key] = 0
		end

		if item.is_vowed == 1 then
			self.vowedPartnerID = item.item_id
		end

		tmpData[key] = tmpData[key] + item.item_num
	end

	self.datas = {}

	for key in pairs(tmpData) do
		local keyData = xyd.splitToNumber(key, "_", false)
		local id = keyData[1]
		local star = keyData[2]

		if star == 0 then
			star = nil
		end

		table.insert(self.datas, {
			item_id = tonumber(id),
			itemID = tonumber(id),
			item_num = tmpData[key],
			num = tmpData[key],
			star = star
		})
	end

	table.sort(self.datas, function (a, b)
		local id_a = a.item_id
		local id_b = b.item_id
		local showBagTypeA = self.itemTable:showInBagType(id_a)
		local showBagTypeB = self.itemTable:showInBagType(id_b)
		local typeA = self.itemTable:getType(id_a)
		local typeB = self.itemTable:getType(id_b)

		if showBagTypeA == showBagTypeB then
			if typeA == typeB then
				if typeA == xyd.ItemType.HERO then
					local groupA = xyd.tables.partnerTable:getGroup(id_a)
					local groupB = xyd.tables.partnerTable:getGroup(id_b)

					return groupA < groupB
				else
					return id_a < id_b
				end
			else
				return typeA < typeB
			end
		else
			return showBagTypeA < showBagTypeB
		end
	end)

	if self.vowedPartnerID then
		for i = 1, #self.datas do
			if self.datas[i].item_id == self.vowedPartnerID then
				if self.datas[i].item_num > 1 then
					self.datas[i].item_num = self.datas[i].item_num - 1
					self.datas[i].num = self.datas[i].num - 1

					table.insert(self.datas, {
						item_num = 1,
						num = 1,
						is_vowed = 1,
						item_id = self.datas[i].item_id,
						itemID = self.datas[i].item_id,
						star = self.datas[i].star
					})
				else
					datas[i].is_vowed = 1
				end
			end
		end
	end
end

function AlertHerosWindow:layout()
	for i = 1, #self.datas do
		local data = self.datas[i]
		local itemID = data.item_id
		local itemNum = data.item_num
		local type_ = self.itemTable:getType(itemID)
		local showBagType = self.itemTable:showInBagType(itemID)
		data.dragScrollView = self.scrollView
		local item = nil

		if showBagType == xyd.BackpackShowType.EQUIP or showBagType == xyd.BackpackShowType.ARTIFACT or type_ == xyd.ItemType.HERO or type_ == xyd.ItemType.DRESS or type_ == xyd.ItemType.DRESS_FRAGMENT then
			item = self:createNumItem(data)
		else
			item = self:createItem(data)
		end
	end

	self.labelTitle.text = __("ITEM_SUMMON")

	xyd.setBtnLabel(self.btnSure_, {
		text = __("SURE_2")
	})
end

function AlertHerosWindow:createItem(data)
	data.scale = 0.9
	data.uiRoot = self.grid.gameObject
	local itemIcon = xyd.getItemIcon(data)

	return itemIcon
end

function AlertHerosWindow:createNumItem(data)
	local item = NGUITools.AddChild(self.grid.gameObject, self.item1)
	item:ComponentByName("label", typeof(UILabel)).text = "x" .. tostring(data.item_num)

	xyd.getItemIcon({
		notShowGetWayBtn = true,
		noWays = true,
		itemID = data.item_id,
		star = data.star,
		uiRoot = item:NodeByName("icon").gameObject,
		dragScrollView = data.dragScrollView,
		is_vowed = data.is_vowed
	})

	return item
end

function AlertHerosWindow:registerEvent()
	UIEventListener.Get(self.btnSure_).onClick = handler(self, self.btnSureTouch)
end

function AlertHerosWindow:btnSureTouch()
	xyd.WindowManager:get():closeWindow(self.name_)
end

function AlertHerosWindow:excuteCallBack(isCloseAll)
	BaseWindow.excuteCallBack(self, isCloseAll)

	if isCloseAll then
		return
	end

	if self.callback then
		self:callback()
	end
end

return AlertHerosWindow
