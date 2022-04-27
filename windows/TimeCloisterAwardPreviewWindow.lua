local TimeCloisterAwardPreviewWindow = class("TimeCloisterAwardPreviewWindow", import(".BaseWindow"))

function TimeCloisterAwardPreviewWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TimeCloisterAwardPreviewWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller_", typeof(UIScrollView))
	self.awardGroup1 = self.scrollView:NodeByName("awardGroup1").gameObject
	self.awardLabel1 = self.awardGroup1:ComponentByName("awardLabel", typeof(UILabel))
	self.itemRoot1 = self.awardGroup1:NodeByName("itemRoot").gameObject
	self.awardGroup2 = self.scrollView:NodeByName("awardGroup2").gameObject
	self.awardLabel2 = self.awardGroup2:ComponentByName("awardLabel", typeof(UILabel))
	self.itemRoot2 = self.awardGroup2:NodeByName("itemRoot").gameObject
end

function TimeCloisterAwardPreviewWindow:layout()
	self.titleLabel.text = __("TIME_CLOISTER_TEXT29")
	self.awardLabel1.text = __("TIME_CLOISTER_TEXT30")
	self.awardLabel2.text = __("TIME_CLOISTER_TEXT31")
	local items = self.params_.items or {}
	local list1 = {}
	local list2 = {}

	for type in pairs(items) do
		local awards = items[type]

		if tonumber(type) == xyd.TimeCloisterCardType.SUPPLY or tonumber(type) == xyd.TimeCloisterCardType.DRESS_SUCC then
			for item_id, item_num in pairs(awards) do
				list1[item_id] = list1[item_id] and list1[item_id] + item_num or item_num
			end
		elseif tonumber(type) == xyd.TimeCloisterCardType.BATTLE_WIN or tonumber(type) == xyd.TimeCloisterCardType.BATTLE_FAIL or tonumber(type) == xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_WIN or tonumber(type) == xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_FAIL then
			for item_id, item_num in pairs(awards) do
				list2[item_id] = list2[item_id] and list2[item_id] + item_num or item_num
			end
		end
	end

	local num1 = 0

	for item_id, item_num in pairs(list1) do
		num1 = num1 + 1

		xyd.getItemIcon({
			scale = 0.7962962962962963,
			uiRoot = self.itemRoot1,
			itemID = item_id,
			num = item_num,
			dragScrollView = self.scrollView
		})
	end

	if num1 > 6 then
		self.awardGroup2:Y(self.awardGroup2.transform.localPosition.y - math.floor(num1 / 6 - 0.1) * 98)
	end

	for item_id, item_num in pairs(list2) do
		xyd.getItemIcon({
			scale = 0.7962962962962963,
			uiRoot = self.itemRoot2,
			itemID = item_id,
			num = item_num,
			dragScrollView = self.scrollView
		})
	end

	self.scrollView:ResetPosition()
end

function TimeCloisterAwardPreviewWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = handler(self, function ()
		self:close()
	end)
end

return TimeCloisterAwardPreviewWindow
