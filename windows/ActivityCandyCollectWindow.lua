local BaseWindow = import("app.windows.BaseWindow")
local ActivityCandyCollectWindow = class("ActivityCandyCollectWindow", BaseWindow)
local ActivityCandyCollectItem = class("ActivityCandyCollectItem", import("app.components.BaseComponent"))

function ActivityCandyCollectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.id = params.id
	self.items = {}
end

function ActivityCandyCollectWindow:initWindow()
	ActivityCandyCollectWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.tipsLabel = self.groupAction:ComponentByName("tipsLabel", typeof(UILabel))
	self.iconGroup = self.groupAction:NodeByName("iconGroup").gameObject
	self.iconLabel = self.iconGroup:ComponentByName("label", typeof(UILabel))
	self.iconBtn = self.iconGroup:NodeByName("btn").gameObject
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject

	self:layout()
	self:RegisterEvent()
end

function ActivityCandyCollectWindow:layout()
	self.iconLabel.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2))
	self.tipsLabel.text = __("CANDY_COLLECT_TEXT_1")
	self.title.text = __("EXCHANGE")

	for i = 1, 4 do
		local award = xyd.tables.activityCandyCollectTable:getAwards(self.id, i)

		if award ~= nil then
			local item = ActivityCandyCollectItem.new(self.itemGroup, {
				id = self.id,
				index = i
			})

			table.insert(self.items, item)
		end
	end

	XYDCo.WaitForFrame(1, function ()
		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	end, nil)
end

function ActivityCandyCollectWindow:RegisterEvent()
	UIEventListener.Get(self.iconBtn).onClick = handler(self, function ()
		local params = {
			showGetWays = true,
			itemID = xyd.ItemID.LOVE_LETTER2,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
	UIEventListener.Get(self.closeBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.window_.name)
	end)

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, function (self, event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.CANDY_COLLECT then
			self.iconLabel.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.LOVE_LETTER2))
			local detail = require("cjson").decode(data.detail)

			dump(detail.awards)
			xyd.itemFloat({
				{
					item_id = detail.awards[1],
					item_num = detail.awards[2]
				}
			}, nil, self.window_)

			for i = 1, #self.items do
				self.items[i]:checkBtn()
			end
		end
	end))
end

function ActivityCandyCollectItem:ctor(parentGo, params)
	self.id = params.id
	self.index = params.index

	ActivityCandyCollectItem.super.ctor(self, parentGo)
end

function ActivityCandyCollectItem:getPrefabPath()
	return "Prefabs/Components/activity_candy_collect_item"
end

function ActivityCandyCollectItem:initUI()
	ActivityCandyCollectItem.super.initUI(self)

	self.icon = self.go:NodeByName("icon").gameObject
	self.btn = self.go:NodeByName("btn").gameObject
	self.label = self.btn:ComponentByName("label", typeof(UILabel))
	self.label.text = xyd.tables.activityCandyCollectTable:getCost(self.id, self.index)[2]
	local params = {
		itemID = xyd.tables.activityCandyCollectTable:getAwards(self.id, self.index)[1],
		num = xyd.tables.activityCandyCollectTable:getAwards(self.id, self.index)[2],
		uiRoot = self.icon
	}
	local icon = xyd.getItemIcon(params)

	self:checkBtn()
	self:registerEvent()
end

function ActivityCandyCollectItem:checkBtn()
	local awarded = xyd.models.activity:getActivity(xyd.ActivityID.CANDY_COLLECT).detail.awarded

	dump(awarded)

	local curAwardIndex = awarded[self.id]
	local splitIndex = xyd.split(tostring(curAwardIndex), "#")

	dump(splitIndex)

	for i = 0, #splitIndex do
		if tonumber(splitIndex[i]) ~= nil and tonumber(splitIndex[i]) == self.index then
			xyd.applyChildrenGrey(self.btn)

			self.btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		end
	end
end

function ActivityCandyCollectItem:canBuy()
	local awarded = xyd.models.activity:getActivity(xyd.ActivityID.CANDY_COLLECT).detail.awarded
	local curAwardIndex = awarded[self.id]
	local splitIndex = xyd.split(tostring(curAwardIndex), "#")
	local listLength = {}

	for i = 1, #awarded do
		local splitStr = xyd.split(tostring(awarded[i]), "#")

		if #splitStr == 1 then
			if tonumber(splitStr[1]) == 0 then
				listLength[i] = 0
			else
				listLength[i] = #splitStr
			end
		else
			listLength[i] = #splitStr
		end
	end

	local max = nil
	max = listLength[1]

	for i = 2, #listLength do
		if max < listLength[i] then
			max = listLength[i]
		end
	end

	local flag = false

	if #splitIndex == 1 then
		if tonumber(splitIndex[1]) == 0 then
			flag = true
		elseif max > #splitIndex then
			flag = true
		end
	elseif max > #splitIndex then
		flag = true
	end

	local isAllEquil = true

	for i = 1, #listLength - 1 do
		if listLength[i] ~= listLength[i + 1] then
			isAllEquil = false
		end
	end

	if isAllEquil then
		flag = true
	end

	return flag
end

function ActivityCandyCollectItem:registerEvent()
	UIEventListener.Get(self.btn).onClick = handler(self, function ()
		if not self:canBuy() then
			xyd.alertTips(__("CANDY_COLLECT_TEXT_3"))

			return
		end

		if xyd.isItemAbsence(xyd.ItemID.LOVE_LETTER2, xyd.tables.activityCandyCollectTable:getCost(self.id, self.index)[2]) then
			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("CANDY_COLLECT_TEXT_2"), function (yes_no)
			if yes_no then
				local data = require("cjson").encode({
					award_id = self.id,
					sub_award_id = self.index
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.CANDY_COLLECT
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			end
		end)
	end)
end

return ActivityCandyCollectWindow
