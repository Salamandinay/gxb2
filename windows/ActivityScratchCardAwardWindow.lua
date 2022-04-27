local BaseWindow = import(".BaseWindow")
local ActivityScratchCardAwardWindow = class("ActivityScratchCardAwardWindow", BaseWindow)

function ActivityScratchCardAwardWindow:ctor(name, params)
	ActivityScratchCardAwardWindow.super.ctor(self, name, params)

	self.weigh_list_ = {}
	local weight = {
		1,
		3,
		4,
		5,
		2
	}

	for i = 1, 5 do
		local itemID = xyd.split(xyd.tables.miscTable:getVal("scratch_card_awards_identical_" .. i), "#", true)[1]
		self.weigh_list_[itemID] = weight[i]
	end

	self.awards = params.awards
	self.items = params.items
end

function ActivityScratchCardAwardWindow:initWindow()
	ActivityScratchCardAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initAwardGroup()
	self:initItemGroup()
	self:register()
end

function ActivityScratchCardAwardWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.contentGroup = groupAction:NodeByName("scroller/contentGroup").gameObject
	self.awardContentGroup = self.contentGroup:NodeByName("awardContentGroup").gameObject
	self.awardGroup = self.awardContentGroup:NodeByName("awardGroup").gameObject
	self.awardTitleLabel = self.awardContentGroup:ComponentByName("awardTitleLabel", typeof(UILabel))
	self.itemContentGroup = self.contentGroup:NodeByName("itemContentGroup").gameObject
	self.itemGroup = self.itemContentGroup:NodeByName("itemGroup").gameObject
	self.itemTitleLabel = self.itemContentGroup:ComponentByName("itemTitleLabel", typeof(UILabel))
	self.btnSure = groupAction:NodeByName("btnSure").gameObject
end

function ActivityScratchCardAwardWindow:initUIComponent()
	self.awardTitleLabel.text = __("ACTIVITY_SCRATCH_CARD_RES_TITLE1")
	self.itemTitleLabel.text = __("ACTIVITY_SCRATCH_CARD_RES_TITLE2")
	self.titleLabel.text = __("ACTIVITY_SCRATCH_CARD_RES_TITLE3")
	self.btnSure:ComponentByName("button_label", typeof(UILabel)).text = __("GET_PRIZE")
end

function ActivityScratchCardAwardWindow:initAwardGroup()
	if not self.awards or #self.awards == 0 then
		self.awardContentGroup:SetActive(false)
		self.itemContentGroup:Y(0)
	else
		local award_list = {}

		for i = 1, #self.awards do
			local list = self.awards[i]

			if list and #list > 0 then
				for j = 0, #list do
					table.insert(award_list, list[j])
				end
			end
		end

		if #award_list == 0 then
			self.awardContentGroup:SetActive(false)
			self.itemContentGroup:Y(0)
		else
			table.sort(award_list, function (a, b)
				local wei_a = self.weigh_list_[a.item_id] or 0
				local wei_b = self.weigh_list_[b.item_id] or 0

				return wei_a < wei_b
			end)

			for i = 1, #award_list do
				local data = award_list[i]

				xyd.getItemIcon({
					scale = 0.9,
					uiRoot = self.awardGroup,
					itemID = data.item_id,
					num = data.item_num,
					dragScrollView = self.scrollView
				})
			end

			self.awardGroup:GetComponent(typeof(UILayout)):Reposition()

			if #award_list <= 5 then
				self.itemContentGroup:Y(-170)
			else
				self.itemContentGroup:Y(-270)
			end
		end
	end
end

function ActivityScratchCardAwardWindow:initItemGroup()
	for i = 1, #self.items do
		local list = self.items[i]

		for j = 1, #list do
			local data = list[j]

			xyd.getItemIcon({
				scale = 0.9,
				uiRoot = self.itemGroup,
				itemID = data.item_id,
				num = data.item_num,
				dragScrollView = self.scrollView
			})
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityScratchCardAwardWindow:register()
	ActivityScratchCardAwardWindow.super.register(self)

	UIEventListener.Get(self.btnSure).onClick = function ()
		xyd.closeWindow(self.name_)
	end
end

return ActivityScratchCardAwardWindow
