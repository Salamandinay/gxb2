local ActivitySpaceExploreTeamWindow = class("ActivitySpaceExploreTeamWindow", import(".BaseWindow"))
local ItemIcon = import("app.components.ItemIcon")

function ActivitySpaceExploreTeamWindow:ctor(name, params)
	ActivitySpaceExploreTeamWindow.super.ctor(self, name, params)
end

function ActivitySpaceExploreTeamWindow:initWindow()
	ActivitySpaceExploreTeamWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:updateContent(true)
	self:register()
end

function ActivitySpaceExploreTeamWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.setBtn_ = winTrans:NodeByName("setBtn_").gameObject
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.scroller_ = winTrans:ComponentByName("scroller_", typeof(UIScrollView))
	self.layout = winTrans:ComponentByName("scroller_/layout", typeof(UILayout))
	local ssrGroup = winTrans:NodeByName("scroller_/layout/ssrGroup")
	self.numLabel_1 = ssrGroup:ComponentByName("numLabel_", typeof(UILabel))
	self.itemGroup1 = ssrGroup:NodeByName("itemGroup").gameObject
	local srGroup = winTrans:NodeByName("scroller_/layout/srGroup")
	self.numLabel_2 = srGroup:ComponentByName("numLabel_", typeof(UILabel))
	self.itemGroup2 = srGroup:NodeByName("itemGroup").gameObject
	local rGroup = winTrans:NodeByName("scroller_/layout/rGroup")
	self.numLabel_3 = rGroup:ComponentByName("numLabel_", typeof(UILabel))
	self.itemGroup3 = rGroup:NodeByName("itemGroup").gameObject
end

function ActivitySpaceExploreTeamWindow:initUIComponent()
	self.titleLabel_.text = __("SPACE_EXPLORE_TEXT_18")
end

function ActivitySpaceExploreTeamWindow:updateContent(fix)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
	local collection = {
		{},
		{},
		{}
	}
	self.arr_r = {}
	self.arr_sr = {}
	self.arr_ssr = {}
	self.arr_all = {}
	local partner_ids = xyd.tables.activitySpaceExplorePartnerTable:getIDs()

	for i, partner_id in pairs(partner_ids) do
		if self.activityData.detail.partners[i] > 0 then
			local level_state = xyd.tables.activitySpaceExplorePartnerTable:getGrade(partner_id)

			if level_state == 1 then
				table.insert(collection[3], {
					id = partner_id,
					index = i
				})
			elseif level_state == 2 then
				table.insert(collection[2], {
					id = partner_id,
					index = i
				})
			elseif level_state == 3 then
				table.insert(collection[1], {
					id = partner_id,
					index = i
				})
			end
		end
	end

	for i, partner_id in pairs(partner_ids) do
		if self.activityData.detail.partners[i] == 0 then
			local level_state = xyd.tables.activitySpaceExplorePartnerTable:getGrade(partner_id)

			if level_state == 1 then
				table.insert(collection[3], {
					id = partner_id,
					index = i
				})
			elseif level_state == 2 then
				table.insert(collection[2], {
					id = partner_id,
					index = i
				})
			elseif level_state == 3 then
				table.insert(collection[1], {
					id = partner_id,
					index = i
				})
			end
		end
	end

	for i = 1, 3 do
		local datas = collection[i]
		local has_num = 0

		for k in pairs(datas) do
			if self.activityData.detail.partners[datas[k].index] > 0 then
				has_num = has_num + 1
			end
		end

		self["numLabel_" .. i].text = has_num .. "/" .. #datas
		local itemGroup = self["itemGroup" .. i]

		if fix then
			local widget = itemGroup:GetComponent(typeof(UIWidget))

			if #datas > 5 then
				widget.height = 108 + 128 * math.ceil((#datas - 5) / 5)
			end
		end

		for j = 1, #datas do
			local level = self.activityData.detail.partners[datas[j].index]
			local params = {
				grey = false,
				num = 1,
				showLev = true,
				itemID = datas[j].id,
				dragScrollView = self.scroller_,
				uiRoot = itemGroup,
				lev = level,
				callback = function ()
					local isShort = false

					if level == 0 then
						isShort = true
					end

					self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
					local level_new = self.activityData.detail.partners[datas[j].index]

					xyd.WindowManager.get():openWindow("activity_space_explore_partner_up_window", {
						id = datas[j].id,
						level = level_new,
						is_short = isShort,
						closeCallBack = function ()
							self:checkIfCanUp()
						end
					})
				end
			}

			if params.lev <= 0 then
				params.showLev = false
				params.grey = true
			end

			local item = xyd.getItemIcon(params, xyd.ItemIconType.ACTIVITY_SPACE_EXPLORE_ICON)

			item:setLabelNumVisble(false)

			if i == 1 then
				table.insert(self.arr_ssr, {
					item = item,
					data = datas[j]
				})
				table.insert(self.arr_all, {
					item = item,
					data = datas[j]
				})
			elseif i == 2 then
				table.insert(self.arr_sr, {
					item = item,
					data = datas[j]
				})
				table.insert(self.arr_all, {
					item = item,
					data = datas[j]
				})
			elseif i == 3 then
				table.insert(self.arr_r, {
					item = item,
					data = datas[j]
				})
				table.insert(self.arr_all, {
					item = item,
					data = datas[j]
				})
			end
		end

		itemGroup:GetComponent(typeof(UILayout)):Reposition()
	end

	self:waitForFrame(1, function ()
		self.layout:Reposition()
	end)
	self:checkIfCanUp()
	self:checkIfHideNoPartner()
end

function ActivitySpaceExploreTeamWindow:checkIfCanUp()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
	local isHideUp = xyd.db.misc:getValue("activity_space_explore_team_window_flag" .. 1)

	if not isHideUp or tonumber(isHideUp) == 0 then
		local has_cost = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPACE_EXPLORE_UP_PARTNER)

		for i in pairs(self.arr_all) do
			local partner_id = self.arr_all[i].data.id

			if self.activityData.detail.partners[self.arr_all[i].data.index] > 0 then
				local partner_level = self.activityData.detail.partners[self.arr_all[i].data.index]
				local need_cost = xyd.tables.activitySpaceExplorePartnerTable:getLvCost1(partner_id)[2] + (partner_level - 1) * xyd.tables.activitySpaceExplorePartnerTable:getLvCost2(partner_id)[2]
				local max_lev = xyd.tables.activitySpaceExplorePartnerTable:getMaxLv(partner_id)

				if need_cost <= has_cost and partner_level < max_lev then
					self.arr_all[i].item:setUpTips(true)
				else
					self.arr_all[i].item:setUpTips(false)
				end
			else
				self.arr_all[i].item:setUpTips(false)
			end
		end
	else
		for i in pairs(self.arr_all) do
			self.arr_all[i].item:setUpTips(false)
		end
	end
end

function ActivitySpaceExploreTeamWindow:checkIfHideNoPartner()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)
	local isHideUp = xyd.db.misc:getValue("activity_space_explore_team_window_flag" .. 2)

	if not isHideUp or tonumber(isHideUp) == 0 then
		for i in pairs(self.arr_ssr) do
			self.arr_ssr[i].item:SetActive(true)
		end

		self:changeItemGroupHeight(self["itemGroup" .. 1]:GetComponent(typeof(UIWidget)), #self.arr_ssr)
		self["itemGroup" .. 1]:GetComponent(typeof(UILayout)):Reposition()

		for i in pairs(self.arr_sr) do
			self.arr_sr[i].item:SetActive(true)
		end

		self:changeItemGroupHeight(self["itemGroup" .. 2]:GetComponent(typeof(UIWidget)), #self.arr_sr)
		self["itemGroup" .. 2]:GetComponent(typeof(UILayout)):Reposition()

		for i in pairs(self.arr_r) do
			self.arr_r[i].item:SetActive(true)
		end

		self:changeItemGroupHeight(self["itemGroup" .. 3]:GetComponent(typeof(UIWidget)), #self.arr_r)
		self["itemGroup" .. 3]:GetComponent(typeof(UILayout)):Reposition()
		self:waitForFrame(1, function ()
			self.layout:Reposition()
			self.scroller_:ResetPosition()
		end)
	else
		local len_ssr = 0

		for i in pairs(self.arr_ssr) do
			if self.activityData.detail.partners[self.arr_ssr[i].data.index] > 0 then
				len_ssr = len_ssr + 1

				self.arr_ssr[i].item:SetActive(true)
			else
				self.arr_ssr[i].item:SetActive(false)
			end
		end

		self:changeItemGroupHeight(self["itemGroup" .. 1]:GetComponent(typeof(UIWidget)), len_ssr)
		self["itemGroup" .. 1]:GetComponent(typeof(UILayout)):Reposition()

		local len_sr = 0

		for i in pairs(self.arr_sr) do
			if self.activityData.detail.partners[self.arr_sr[i].data.index] > 0 then
				len_sr = len_sr + 1

				self.arr_sr[i].item:SetActive(true)
			else
				self.arr_sr[i].item:SetActive(false)
			end
		end

		self:changeItemGroupHeight(self["itemGroup" .. 2]:GetComponent(typeof(UIWidget)), len_sr)
		self["itemGroup" .. 2]:GetComponent(typeof(UILayout)):Reposition()

		local len_r = 0

		for i in pairs(self.arr_r) do
			if self.activityData.detail.partners[self.arr_r[i].data.index] > 0 then
				len_r = len_r + 1

				self.arr_r[i].item:SetActive(true)
			else
				self.arr_r[i].item:SetActive(false)
			end
		end

		self:changeItemGroupHeight(self["itemGroup" .. 3]:GetComponent(typeof(UIWidget)), len_r)
		self["itemGroup" .. 3]:GetComponent(typeof(UILayout)):Reposition()
		self:waitForFrame(1, function ()
			self.layout:Reposition()
			self.scroller_:ResetPosition()
		end)
	end
end

function ActivitySpaceExploreTeamWindow:changeItemGroupHeight(ui_widget, len)
	if len > 5 then
		ui_widget.height = 108 + 128 * math.ceil((len - 5) / 5)
	elseif len > 0 then
		ui_widget.height = 108
	else
		ui_widget.height = 40
	end
end

function ActivitySpaceExploreTeamWindow:register()
	ActivitySpaceExploreTeamWindow.super.register(self)

	UIEventListener.Get(self.setBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_space_explore_team_setting_window", {
			closeCallBack = function (is_change_one, is_change_two)
				if is_change_one == 1 then
					self:checkIfCanUp()
				end

				if is_change_two == 1 then
					self:checkIfHideNoPartner()
				end
			end
		})
	end)
end

function ActivitySpaceExploreTeamWindow:updateOneLevel(partner_id, level)
	for i in pairs(self.arr_all) do
		if self.arr_all[i].data.id == partner_id then
			if self.activityData.detail.partners[self.arr_all[i].data.index] > 0 then
				self.arr_all[i].item:setLevLabel(level)
			end

			local max_lev = xyd.tables.activitySpaceExplorePartnerTable:getMaxLv(partner_id)

			if max_lev <= level then
				self.arr_all[i].item:setUpTips(false)
			end

			break
		end
	end
end

function ActivitySpaceExploreTeamWindow:willClose()
	local mapWn = xyd.WindowManager.get():getWindow("activity_space_explore_map_window")

	if mapWn then
		mapWn:updateTeamInfoShow()
	end

	ActivitySpaceExploreTeamWindow.super.willClose(self)
end

return ActivitySpaceExploreTeamWindow
