local BaseWindow = import("app.windows.BaseWindow")
local ActivityEasterEggAwardWindow = class("ActivityEasterEggAwardWindow", BaseWindow)

function ActivityEasterEggAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.point = params.point
end

function ActivityEasterEggAwardWindow:initWindow()
	ActivityEasterEggAwardWindow.super:initWindow()

	local groupAction = self.window_.transform:NodeByName("groupAction").gameObject
	self.scroll = groupAction:ComponentByName("scroll", typeof(UIScrollView))
	self.scrollPanel = self.scroll:GetComponent(typeof(UIPanel))
	self.scrollGroup = self.scroll:NodeByName("group").gameObject
	self.specialAwardGroup = self.scrollGroup:NodeByName("specialAwardGroup").gameObject
	self.label1 = self.specialAwardGroup:ComponentByName("title/label", typeof(UILabel))
	self.group1 = self.specialAwardGroup:NodeByName("itemGroup").gameObject
	self.line1 = self.specialAwardGroup:ComponentByName("title/line", typeof(UISprite))
	self.normalAwardGroup = self.scrollGroup:NodeByName("normalAwardGroup").gameObject
	self.label2 = self.normalAwardGroup:ComponentByName("title/label", typeof(UILabel))
	self.group2 = self.normalAwardGroup:NodeByName("itemGroup").gameObject
	self.line2 = self.normalAwardGroup:ComponentByName("title/line", typeof(UISprite))
	self.pointAwardGroup = self.scrollGroup:NodeByName("pointAwardGroup").gameObject
	self.label3 = self.pointAwardGroup:ComponentByName("title/label", typeof(UILabel))
	self.group3 = self.pointAwardGroup:NodeByName("itemGroup").gameObject
	self.line3 = self.pointAwardGroup:ComponentByName("title/line", typeof(UISprite))
	self.itemCell1 = groupAction:NodeByName("activity_easter_egg_award_item1").gameObject
	self.itemCell2 = groupAction:NodeByName("activity_easter_egg_award_item2").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.title = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))

	self:layout()
	self:RegisterEvent()
end

function ActivityEasterEggAwardWindow:RegisterEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager:get():closeWindow(self.name_)
	end
end

function ActivityEasterEggAwardWindow:layout()
	self.title.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.label1.text = __("ACTIVITY_EASTER_EGG_AWARD_HIGH")
	self.label2.text = __("ACTIVITY_EASTER_EGG_AWARD")
	self.label3.text = __("ACTIVITY_EASTER_EGG_POINT")
	self.line1.width = 496 - self.label1.width
	self.line2.width = 496 - self.label2.width
	self.line3.width = 496 - self.label3.width
	local items1 = xyd.tables.miscTable:split2Cost("activity_easter_egg_show_bonus", "value", "|#")

	for id in ipairs(items1) do
		local data = items1[id]
		local item = NGUITools.AddChild(self.group1, self.itemCell1)
		local iconData = {
			show_has_num = true,
			itemID = data[1],
			num = data[2],
			uiRoot = item:NodeByName("icon").gameObject,
			scale = Vector3(0.8, 0.8, 1)
		}
		local icon = xyd.getItemIcon(iconData)
		item:ComponentByName("label", typeof(UILabel)).text = data[3] .. "%"
	end

	local items2 = xyd.tables.miscTable:split2Cost("activity_easter_egg_show", "value", "|#")

	for id in ipairs(items2) do
		local data = items2[id]
		local item = NGUITools.AddChild(self.group2, self.itemCell1)
		local iconData = {
			show_has_num = true,
			itemID = data[1],
			num = data[2],
			uiRoot = item:NodeByName("icon").gameObject,
			scale = Vector3(0.8, 0.8, 1)
		}
		local icon = xyd.getItemIcon(iconData)
		item:ComponentByName("label", typeof(UILabel)).text = data[3] .. "%"
	end

	local items3 = xyd.tables.activityEasterEggPointTable:getIDs()

	for id in ipairs(items3) do
		local point = xyd.tables.activityEasterEggPointTable:getPoint(id)
		local award = xyd.tables.activityEasterEggPointTable:getAwards(id)
		local item = NGUITools.AddChild(self.group3, self.itemCell2)
		local iconData = {
			show_has_num = true,
			itemID = award[1],
			num = award[2],
			uiRoot = item:NodeByName("icon").gameObject,
			scale = Vector3(0.8, 0.8, 1),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}
		local icon = xyd.getItemIcon(iconData)

		if point <= self.point then
			icon:setChoose(true)
		end

		local progressBar = item:ComponentByName("progressBar_", typeof(UIProgressBar))
		local progressDesc = progressBar:ComponentByName("progressLabel", typeof(UILabel))
		progressBar.value = math.min(self.point, point) / point
		progressDesc.text = math.min(self.point, point) .. "/" .. point
		item:ComponentByName("label", typeof(UILabel)).text = __("BALLOON_POINT", point)
	end

	self.specialAwardGroup:GetComponent(typeof(UIWidget)).height = 150 + 122 * math.floor((#items1 - 1) / 5)
	self.normalAwardGroup:GetComponent(typeof(UIWidget)).height = 150 + 122 * math.floor((#items2 - 1) / 5)
	self.pointAwardGroup:GetComponent(typeof(UIWidget)).height = 33 + 119 * #items3

	self.itemCell1:SetActive(false)
	self.itemCell2:SetActive(false)
	XYDCo.WaitForFrame(1, function ()
		self.group1:GetComponent(typeof(UILayout)):Reposition()
		self.group2:GetComponent(typeof(UILayout)):Reposition()
		self.scrollGroup:GetComponent(typeof(UILayout)):Reposition()
		self.scroll:ResetPosition()

		if not tonumber(xyd.db.misc:getValue("esater_egg_award_first_touch")) then
			xyd.db.misc:setValue({
				value = 1,
				key = "esater_egg_award_first_touch"
			})

			local pos = self.scrollPanel.transform.localPosition

			SpringPanel.Begin(self.scrollPanel.gameObject, Vector3(pos.x, self.specialAwardGroup:GetComponent(typeof(UIWidget)).height + self.normalAwardGroup:GetComponent(typeof(UIWidget)).height + self.pointAwardGroup:GetComponent(typeof(UIWidget)).height - 750, pos.z), 4)
		end
	end, nil)
end

return ActivityEasterEggAwardWindow
