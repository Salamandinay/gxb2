local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestCrystalWindow = class("ActivityEntranceTestCrystalWindow", BaseWindow)
local EntranceTestCrystalItemRenderer = class("EntranceTestCrystalItemRenderer", import("app.components.CopyComponent"))

function ActivityEntranceTestCrystalWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.partner = params.partner
	self.itemsArr = {}
end

function ActivityEntranceTestCrystalWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:layout()
end

function ActivityEntranceTestCrystalWindow:getUIComponent()
	local trans = self.window_.transform
	local allGroup = trans:NodeByName("groupAction").gameObject
	self.labelWinTitle = allGroup:ComponentByName("e:Group/labelWinTitle", typeof(UILabel))
	self.closeBtn = allGroup:NodeByName("e:Group/closeBtn").gameObject
	self.activity_Entrance_Test_Crystal_Item = allGroup:NodeByName("activity_Entrance_Test_Crystal_Item").gameObject
	self.containerNode = allGroup:NodeByName("containerNode").gameObject
	self.scroller = self.containerNode:NodeByName("scroller").gameObject
	self.scroller_scrollerView = self.scroller:GetComponent(typeof(UIScrollView))
	self.scroller_uiPanel = self.scroller:GetComponent(typeof(UIPanel))
	self.listContainer = self.scroller:NodeByName("listContainer").gameObject
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivityEntranceTestCrystalWindow:layout()
	self:updateListShow()
end

function ActivityEntranceTestCrystalWindow:freshCrystal()
	for i in pairs(self.itemsArr) do
		self.itemsArr[i]:updateItem()
	end

	local win = xyd.WindowManager.get():getWindow("activity_entrance_test_partner_window")

	win:updateData()
end

function ActivityEntranceTestCrystalWindow:updateListShow()
	local list = {}

	for key, id in pairs(xyd.tables.activityWarmupArenaEquipTable:getIdsByType(xyd.WarmupItemType.CRYSTAL)) do
		local params = {
			id = id,
			partner = self.partner
		}

		table.insert(list, params)
	end

	NGUITools.DestroyChildren(self.listContainer.transform)

	for i in ipairs(list) do
		local tmp = NGUITools.AddChild(self.listContainer.gameObject, self.activity_Entrance_Test_Crystal_Item.gameObject)
		local item = EntranceTestCrystalItemRenderer.new(tmp, list[i])

		table.insert(self.itemsArr, item)
	end

	self.activity_Entrance_Test_Crystal_Item:SetActive(false)
end

function EntranceTestCrystalItemRenderer:ctor(goItem, itemdata)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.data = itemdata
	self.allbg = transGo:NodeByName("allbg").gameObject
	self.icon = transGo:NodeByName("icon").gameObject
	self.name_text = transGo:ComponentByName("name_text", typeof(UILabel))
	self.des_text = transGo:ComponentByName("des_text", typeof(UILabel))
	self.shaddow_node = transGo:NodeByName("shaddow_node").gameObject

	self:createChildren()
	self:updateItem()
end

function EntranceTestCrystalItemRenderer:createChildren()
	UIEventListener.Get(self.allbg.gameObject).onClick = handler(self, function ()
		if not self.shaddow_node.activeSelf then
			local equipId = xyd.tables.activityWarmupArenaEquipTable:getEquipId(self.data.id)
			self.data.partner.equipments[5] = equipId
			self.data.partner.time = xyd.getServerTime()
			local win = xyd.WindowManager.get():getWindow("activity_entrance_test_crystal_window")

			win:freshCrystal()

			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

			activityData:setPartnerTime(self.data.partner)

			activityData.dataHasChange = true
		end
	end)
	local equipId = xyd.tables.activityWarmupArenaEquipTable:getEquipId(self.data.id)
	local item = {
		itemID = equipId,
		uiRoot = self.icon.gameObject
	}
	local icon = xyd.getItemIcon(item)
end

function EntranceTestCrystalItemRenderer:updateItem()
	local equipId = xyd.tables.activityWarmupArenaEquipTable:getEquipId(self.data.id)
	self.name_text.text = xyd.tables.itemTable:getName(equipId)
	self.des_text.text = xyd.tables.equipTable:getDesc(equipId)

	self.shaddow_node:SetActive(equipId == self.data.partner.equipments[5])

	self.name = "item_" .. tostring(self.itemIndex)
end

return ActivityEntranceTestCrystalWindow
