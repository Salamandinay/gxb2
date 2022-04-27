local ActivityContent = import(".ActivityContent")
local ActivityTreasure = class("ActivityTreasure", ActivityContent)
local LongItem = class("LongItem", import("app.components.CopyComponent"))
local SmallItem = class("SmallItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityTreasure:ctor(parentGO, params, parent)
	ActivityTreasure.super.ctor(self, parentGO, params, parent)
end

function ActivityTreasure:getPrefabPath()
	return "Prefabs/Windows/activity/activity_treasure"
end

function ActivityTreasure:initUI()
	self:getUIComponent()
	ActivityTreasure.super.initUI(self)
	self:initUIComponent()
end

function ActivityTreasure:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.bgImg = self.groupAction:ComponentByName("bgImg", typeof(UITexture))
	self.btnGroup = self.groupAction:NodeByName("btnGroup").gameObject
	self.helpBtn = self.btnGroup:NodeByName("helpBtn").gameObject
	self.resCon = self.groupAction:NodeByName("resCon").gameObject
	self.resGroup = self.resCon:NodeByName("resGroup").gameObject
	self.icon = self.resGroup:ComponentByName("icon", typeof(UISprite))
	self.label = self.resGroup:ComponentByName("label", typeof(UILabel))
	self.btn = self.resGroup:NodeByName("btn").gameObject
	self.logoImg = self.groupAction:ComponentByName("logoImg", typeof(UISprite))
	self.allCon = self.groupAction:ComponentByName("allCon", typeof(UISprite))
	self.showItem = self.allCon:NodeByName("showItem").gameObject
	self.upCon = self.allCon:NodeByName("upCon").gameObject
	self.upLeftBtn = self.upCon:NodeByName("upLeftBtn").gameObject
	self.upLeftBtn_button_label = self.upLeftBtn:ComponentByName("button_label", typeof(UILabel))
	self.upLeftBtn_labelItemCost = self.upLeftBtn:ComponentByName("itemIcon/labelItemCost", typeof(UILabel))
	self.upRightBtn = self.upCon:NodeByName("upRightBtn").gameObject
	self.upRightBtn_button_label = self.upRightBtn:ComponentByName("button_label", typeof(UILabel))
	self.upRightBtn_labelItemCost = self.upRightBtn:ComponentByName("itemIcon/labelItemCost", typeof(UILabel))
	self.upShowBtn = self.upCon:NodeByName("upShowBtn").gameObject
	self.upScrollView = self.upCon:NodeByName("upScrollView").gameObject
	self.upScrollView_UIScrollView = self.upCon:ComponentByName("upScrollView", typeof(UIScrollView))
	self.upScrollCon = self.upScrollView:NodeByName("upScrollCon").gameObject
	self.upScrollCon_UILayout = self.upScrollView:ComponentByName("upScrollCon", typeof(UILayout))
	self.downCon = self.allCon:NodeByName("downCon").gameObject
	self.downLeftBtn = self.downCon:NodeByName("downLeftBtn").gameObject
	self.downLeftBtn_button_label = self.downLeftBtn:ComponentByName("button_label", typeof(UILabel))
	self.downLeftBtn_labelItemCost = self.downLeftBtn:ComponentByName("itemIcon/labelItemCost", typeof(UILabel))
	self.downRightBtn = self.downCon:NodeByName("downRightBtn").gameObject
	self.downRightBtn_button_label = self.downRightBtn:ComponentByName("button_label", typeof(UILabel))
	self.downRightBtn_labelItemCost = self.downRightBtn:ComponentByName("itemIcon/labelItemCost", typeof(UILabel))
	self.downShowBtn = self.downCon:NodeByName("downShowBtn").gameObject
	self.downScrollView = self.downCon:NodeByName("downScrollView").gameObject
	self.downScrollView_UIScrollView = self.downCon:ComponentByName("downScrollView", typeof(UIScrollView))
	self.downScrollCon = self.downScrollView:NodeByName("downScrollCon").gameObject
	self.downScrollCon_UILayout = self.downScrollView:ComponentByName("downScrollCon", typeof(UILayout))
end

function ActivityTreasure:initUIComponent()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_treasure_" .. xyd.Global.lang, nil, , )

	self.upCostOne = xyd.tables.miscTable:split2num("activity_3birthday_gamble1", "value", "#")
	self.downCostOne = xyd.tables.miscTable:split2num("activity_3birthday_gamble2", "value", "#")
	self.upLeftBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", 1)
	self.upLeftBtn_labelItemCost.text = self.upCostOne[2]
	self.downLeftBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", 1)
	self.downLeftBtn_labelItemCost.text = self.downCostOne[2]
	self.downRightBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", 10)
	self.downRightBtn_labelItemCost.text = 10 * self.downCostOne[2]
	self.label.text = self:getRoseNum()
	local nums = self.activityData.detail.nums
	local up_all_ids = xyd.tables.activity3BirthdayGambleTable:getByType(1)

	table.sort(up_all_ids, function (a, b)
		if xyd.tables.activity3BirthdayGambleTable:getNum(a) <= nums[a] and xyd.tables.activity3BirthdayGambleTable:getNum(b) <= nums[b] then
			return a < b
		else
			if xyd.tables.activity3BirthdayGambleTable:getNum(a) <= nums[a] then
				return false
			end

			if xyd.tables.activity3BirthdayGambleTable:getNum(b) <= nums[b] then
				return true
			else
				return a < b
			end
		end
	end)

	local up_info_arr = {}

	for i = 1, math.ceil(#up_all_ids / 5) do
		local for_left = (i - 1) * 5 + 1
		local for_right = i * 5

		if i > math.floor(#up_all_ids / 5) then
			for_right = #up_all_ids
		end

		local data = {}

		for j = for_left, for_right do
			local small_data = {
				id = up_all_ids[j],
				items = xyd.tables.activity3BirthdayGambleTable:getAwards(up_all_ids[j]),
				num = xyd.tables.activity3BirthdayGambleTable:getNum(up_all_ids[j])
			}
			small_data.cur_num = small_data.num - self.activityData.detail.nums[up_all_ids[j]]

			if small_data.cur_num < 0 then
				small_data.cur_num = 0
			end

			table.insert(data, small_data)
		end

		table.insert(up_info_arr, data)
	end

	self.up_long_items = {}

	for i in pairs(up_info_arr) do
		local itemRootNew = NGUITools.AddChild(self.upScrollCon.gameObject, self.showItem)
		local upItemLongNew = LongItem.new(itemRootNew, self, up_info_arr[i], 1)

		table.insert(self.up_long_items, upItemLongNew)
	end

	self.upScrollCon_UILayout:Reposition()
	self.upScrollView_UIScrollView:ResetPosition()

	local down_all_ids = xyd.tables.activity3BirthdayGambleTable:getByType(2)

	table.sort(down_all_ids, function (a, b)
		if xyd.tables.activity3BirthdayGambleTable:getNum(a) <= nums[a] and xyd.tables.activity3BirthdayGambleTable:getNum(b) <= nums[b] then
			return a < b
		else
			if xyd.tables.activity3BirthdayGambleTable:getNum(a) <= nums[a] then
				return false
			end

			if xyd.tables.activity3BirthdayGambleTable:getNum(b) <= nums[b] then
				return true
			else
				return a < b
			end
		end
	end)

	local down_info_arr = {}

	for i = 1, math.ceil(#down_all_ids / 5) do
		local for_left = (i - 1) * 5 + 1
		local for_right = i * 5

		if i > math.floor(#down_all_ids / 5) then
			for_right = #down_all_ids
		end

		local data = {}

		for j = for_left, for_right do
			local small_data = {
				id = down_all_ids[j],
				items = xyd.tables.activity3BirthdayGambleTable:getAwards(down_all_ids[j]),
				num = xyd.tables.activity3BirthdayGambleTable:getNum(down_all_ids[j])
			}
			small_data.cur_num = small_data.num - self.activityData.detail.nums[down_all_ids[j]]

			if small_data.cur_num < 0 then
				small_data.cur_num = 0
			end

			table.insert(data, small_data)
		end

		table.insert(down_info_arr, data)
	end

	self.down_long_items = {}

	for i in pairs(down_info_arr) do
		local itemRootNew = NGUITools.AddChild(self.downScrollCon.gameObject, self.showItem)
		local upItemLongNew = LongItem.new(itemRootNew, self, down_info_arr[i], 2)

		table.insert(self.down_long_items, upItemLongNew)
	end

	self.downScrollCon_UILayout:Reposition()
	self.downScrollView_UIScrollView:ResetPosition()
	self:updateBtnShow()
end

function ActivityTreasure:resizeToParent()
	ActivityTreasure.super.resizeToParent(self)
	self:resizePosY(self.logoImg.gameObject, -63, -102)
	self:resizePosY(self.resCon.gameObject, -103, -236)
	self:resizePosY(self.allCon.gameObject, -504, -641)

	if self.scale_num_contrary > 0.674 then
		self.resCon.gameObject:X(0)
	end
end

function ActivityTreasure:onRegister()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_3BIRTHDAY_GAMBLE_HELP"
		})
	end)
	UIEventListener.Get(self.upLeftBtn.gameObject).onClick = handler(self, function ()
		if self:getRoseNum() < self.upCostOne[2] then
			xyd.alertTips(__("SPIRIT_NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ROSE_BROOCH)))

			return
		end

		self:sendMessage(1, 1)
	end)
	UIEventListener.Get(self.upRightBtn.gameObject).onClick = handler(self, function ()
		if self:getRoseNum() < self.upShowTimes * self.upCostOne[2] then
			xyd.alertTips(__("SPIRIT_NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ROSE_BROOCH)))

			return
		end

		self:sendMessage(1, self.upShowTimes)
	end)
	UIEventListener.Get(self.downLeftBtn.gameObject).onClick = handler(self, function ()
		if self:getRoseNum() < self.downCostOne[2] then
			xyd.alertTips(__("SPIRIT_NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ROSE_BROOCH)))

			return
		end

		self:sendMessage(2, 1)
	end)
	UIEventListener.Get(self.downRightBtn.gameObject).onClick = handler(self, function ()
		if self:getRoseNum() < 10 * self.downCostOne[2] then
			xyd.alertTips(__("SPIRIT_NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ROSE_BROOCH)))

			return
		end

		self:sendMessage(2, 10)
	end)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, function (_, event)
		dump(xyd.decodeProtoBuf(event.data), "回來。。。。。。。。。。。。。。")

		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_TREASURE then
			return
		end

		self.label.text = self:getRoseNum()

		self:updateBtnShow()

		local detail = json.decode(event.data.detail)

		self:updateItemsNum(detail.type)
	end))

	UIEventListener.Get(self.btn.gameObject).onClick = handler(self, self.goWay)
	UIEventListener.Get(self.upShowBtn.gameObject).onClick = handler(self, function ()
		self:openShowAllWindow(1)
	end)
	UIEventListener.Get(self.downShowBtn.gameObject).onClick = handler(self, function ()
		self:openShowAllWindow(2)
	end)
end

function ActivityTreasure:updateBtnShow()
	self.activityData = xyd.models.activity:getActivity(self.id)
	self.upShowTimes = math.floor(self:getRoseNum() / self.upCostOne[2])

	if self.upShowTimes < 10 then
		self.upShowTimes = 10
	elseif self.upShowTimes > 50 then
		self.upShowTimes = 50
	end

	self.upRightBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", self.upShowTimes)
	self.upRightBtn_labelItemCost.text = self.upShowTimes * self.upCostOne[2]
	local up_all_ids = xyd.tables.activity3BirthdayGambleTable:getByType(1)
	local up_all_times = 0
	local up_yet_times = 0

	for i in pairs(up_all_ids) do
		up_yet_times = up_yet_times + self.activityData.detail.nums[up_all_ids[i]]
		up_all_times = up_all_times + xyd.tables.activity3BirthdayGambleTable:getNum(up_all_ids[i])
	end

	if up_all_times - up_yet_times < self.upShowTimes and up_all_times - up_yet_times >= 10 then
		self.upShowTimes = up_all_times - up_yet_times
		self.upRightBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", self.upShowTimes)
		self.upRightBtn_labelItemCost.text = self.upShowTimes * self.upCostOne[2]
	end

	if up_all_times <= up_yet_times then
		self:changeBtnState(self.upLeftBtn, false)
		self:changeBtnState(self.upRightBtn, false)
	elseif up_all_times - up_yet_times < 10 then
		self:changeBtnState(self.upLeftBtn, true)
		self:changeBtnState(self.upRightBtn, false)

		self.upShowTimes = 10
		self.upRightBtn_button_label.text = __("ACTIVITY_3BIRTHDAY_TEXT12", 10)
		self.upRightBtn_labelItemCost.text = 10 * self.upCostOne[2]
	else
		self:changeBtnState(self.upLeftBtn, true)
		self:changeBtnState(self.upRightBtn, true)
	end

	local down_all_ids = xyd.tables.activity3BirthdayGambleTable:getByType(2)
	local down_all_times = 0
	local down_yet_times = 0

	for i in pairs(down_all_ids) do
		down_yet_times = down_yet_times + self.activityData.detail.nums[down_all_ids[i]]
		down_all_times = down_all_times + xyd.tables.activity3BirthdayGambleTable:getNum(down_all_ids[i])
	end

	if down_all_times <= down_yet_times then
		self:changeBtnState(self.downLeftBtn, false)
		self:changeBtnState(self.downRightBtn, false)
	elseif down_all_times - down_yet_times < 10 then
		self:changeBtnState(self.downLeftBtn, true)
		self:changeBtnState(self.downRightBtn, false)
	else
		self:changeBtnState(self.downLeftBtn, true)
		self:changeBtnState(self.downRightBtn, true)
	end
end

function ActivityTreasure:getRoseNum()
	return xyd.models.backpack:getItemNumByID(xyd.ItemID.ROSE_BROOCH)
end

function ActivityTreasure:changeBtnState(obj, state)
	if state then
		xyd.applyChildrenOrigin(obj)
	else
		xyd.applyChildrenGrey(obj)
	end

	obj:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = state
end

function ActivityTreasure:sendMessage(type, num)
	if self.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	xyd.models.activity:reqAwardWithParams(self.id, json.encode({
		type = type,
		num = num
	}))
end

function ActivityTreasure:updateItemsNum(type)
	self.activityData = xyd.models.activity:getActivity(self.id)

	if type == 1 then
		for i in pairs(self.up_long_items) do
			self.up_long_items[i]:updateNum()
		end
	elseif type == 2 then
		for i in pairs(self.down_long_items) do
			self.down_long_items[i]:updateNum()
		end
	end
end

function ActivityTreasure:goWay()
	local win = xyd.WindowManager.get():getWindow("activity_window")
	local newParams = xyd.tables.activityTable:getWindowParams(self.id)
	local params = {}

	if newParams ~= nil then
		params.onlyShowList = newParams.activity_ids
		params.activity_type = newParams.activity_type
		params.select = xyd.ActivityID.ACTIVITY_WINE
	end

	if win then
		xyd.WindowManager.get():closeWindow("activity_window", function ()
			xyd.WindowManager.get():openWindow("activity_window", params)
		end)
	else
		xyd.WindowManager.get():openWindow("activity_window", params)
	end
end

function ActivityTreasure:openShowAllWindow(type)
	local nums = self.activityData.detail.nums
	local all_ids = xyd.tables.activity3BirthdayGambleTable:getByType(type)

	table.sort(all_ids, function (a, b)
		if xyd.tables.activity3BirthdayGambleTable:getNum(a) <= nums[a] and xyd.tables.activity3BirthdayGambleTable:getNum(b) <= nums[b] then
			return a < b
		else
			if xyd.tables.activity3BirthdayGambleTable:getNum(a) <= nums[a] then
				return false
			end

			if xyd.tables.activity3BirthdayGambleTable:getNum(b) <= nums[b] then
				return true
			else
				return a < b
			end
		end
	end)

	local data = {}

	for j = 1, #all_ids do
		local small_data = {
			items = xyd.tables.activity3BirthdayGambleTable:getAwards(all_ids[j]),
			num = xyd.tables.activity3BirthdayGambleTable:getNum(all_ids[j])
		}
		small_data.cur_num = small_data.num - self.activityData.detail.nums[all_ids[j]]

		if small_data.cur_num < 0 then
			small_data.cur_num = 0
		end

		table.insert(data, small_data)
	end

	xyd.WindowManager.get():openWindow("activity_wine_award_preview_window", data)
end

function LongItem:ctor(go, parent, info, type)
	self.parent = parent
	self.info = info
	self.type = type

	LongItem.super.ctor(self, go)
end

function LongItem:initUI()
	self.go_UIWidget = self.go:GetComponent(typeof(UIWidget))
	self.imgBg = self.go:ComponentByName("imgBg", typeof(UISprite))
	self.itemAllCon = self.go:NodeByName("itemAllCon").gameObject
	self.itemAllCon_UILayout = self.go:ComponentByName("itemAllCon", typeof(UILayout))
	self.itemEgCon = self.go:NodeByName("itemEgCon").gameObject

	if self.type == 1 then
		self.imgBg.width = 596
		self.go_UIWidget.width = 596
	elseif self.type == 2 then
		self.imgBg.width = 644
		self.go_UIWidget.width = 644

		xyd.setUISpriteAsync(self.imgBg, nil, "activity_treasure_bg3", nil, , )
	end

	self:initInfo()
end

function LongItem:initInfo()
	self.all_items = {}

	for i in pairs(self.info) do
		local itemRootNew = NGUITools.AddChild(self.itemAllCon.gameObject, self.itemEgCon)
		local upItemLongNew = SmallItem.new(itemRootNew, self, self.info[i])

		table.insert(self.all_items, upItemLongNew)
	end

	self.itemAllCon_UILayout:Reposition()
end

function LongItem:updateNum()
	for i in pairs(self.all_items) do
		self.all_items[i]:updateNum()
	end
end

function SmallItem:ctor(go, parent, info)
	self.parent = parent
	self.info = info

	LongItem.super.ctor(self, go)
end

function SmallItem:initUI()
	self.itemCon = self.go:NodeByName("itemCon").gameObject
	self.hasNumLabel = self.go:ComponentByName("hasNumLabel", typeof(UILabel))

	self:initInfo()
end

function SmallItem:initInfo()
	self.icon = xyd.getItemIcon({
		show_has_num = true,
		noClickSelected = true,
		uiRoot = self.itemCon,
		itemID = self.info.items[1],
		num = self.info.items[2]
	})

	self.icon:setScale(0.7407407407407407)
	self.icon:AddUIDragScrollView()

	self.id = self.info.id
	self.hasNumLabel.text = self.info.cur_num .. "/" .. tostring(self.info.num)

	if self.info.cur_num == 0 then
		self.hasNumLabel.color = Color.New2(3422556671.0)
	end
end

function SmallItem:updateNum()
	local num = self.parent.parent.activityData.detail.nums[self.info.id]
	num = self.info.num - num

	if num < 0 then
		num = 0
	end

	if num ~= self.info.cur_num then
		if self.info.num < num then
			num = self.info.num
		end

		self.info.cur_num = num
		self.hasNumLabel.text = self.info.cur_num .. "/" .. tostring(self.info.num)
	end

	if self.info.cur_num == 0 then
		self.hasNumLabel.color = Color.New2(3422556671.0)
	end
end

return ActivityTreasure
