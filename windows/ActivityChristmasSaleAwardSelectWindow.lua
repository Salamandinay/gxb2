local ActivityChristmasSaleAwardSelectWindow = class("ActivityChristmasSaleAwardSelectWindow", import(".BaseWindow"))
local ActivityChristmasSaleAwardsTable = xyd.tables.activityChristmasSaleAwardsTable
local ReplaceIcon = import("app.components.ReplaceIcon")

function ActivityChristmasSaleAwardSelectWindow:ctor(name, params)
	ActivityChristmasSaleAwardSelectWindow.super.ctor(self, name, params)

	self.item = params.item
	self.id = params.id
	self.leftTimes = params.leftTimes
	self.curIndex = params.index or 1
	self.opAwards = params.opAwards or {}
	self.opAwardIndexs = {}
end

function ActivityChristmasSaleAwardSelectWindow:initWindow()
	self:getUIComponent()
	self:setText()
	self:initReAward()
	self:updateCurIcon(self.curIndex)
	self:register()
end

function ActivityChristmasSaleAwardSelectWindow:getUIComponent()
	local main = self.window_:NodeByName("e:Group").gameObject
	local group1 = main:NodeByName("group1").gameObject
	self.closeBtn = group1:NodeByName("closeBtn").gameObject
	self.labelTitle_0 = group1:ComponentByName("labelTitle_0", typeof(UILabel))
	self.arrow = group1:NodeByName("arrow").gameObject
	self.groupContent = group1:NodeByName("groupContent").gameObject
	self.groupRewards = self.groupContent:NodeByName("groupRewards").gameObject
	self.line = self.groupContent:NodeByName("groupDesc/line").gameObject
	self.labelName = self.groupContent:ComponentByName("groupDesc/labelName", typeof(UILabel))
	self.labelDesc = self.groupContent:ComponentByName("groupDesc/scroller1/labelDesc", typeof(UILabel))
	self.btnCancel = self.groupContent:NodeByName("groupBtns/btnCancel").gameObject
	self.labelBtnCancel = self.btnCancel:ComponentByName("labelBtnCancel", typeof(UILabel))
	self.btnNext = self.groupContent:NodeByName("groupBtns/btnNext").gameObject
	self.labelBtnNext = self.btnNext:ComponentByName("labelBtnNext", typeof(UILabel))
	local group2 = main:NodeByName("group2").gameObject
	self.labelTitle_1 = group2:ComponentByName("labelTitle_1", typeof(UILabel))
	self.scrollerView = group2:ComponentByName("scroller", typeof(UIScrollView))
	self.groupPools = group2:NodeByName("scroller/groupPools").gameObject
	self.groupPoolsGrid = group2:ComponentByName("scroller/groupPools", typeof(UIGrid))
	self.icon_root = group2:NodeByName("icon_root").gameObject
end

function ActivityChristmasSaleAwardSelectWindow:setText()
	self.labelTitle_0.text = __("ACTIVITY_CHRISTMAS_SALE_TITLE")
	self.labelTitle_1.text = __("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW_SECOND_TITLE")
	self.labelBtnCancel.text = __("CANCEL")
end

function ActivityChristmasSaleAwardSelectWindow:updateNextBtn()
	local num = ActivityChristmasSaleAwardsTable:getOpAwardsNum(self.id)

	if self.curIndex < num then
		self.labelBtnNext.text = __("NEXT")
	else
		self.labelBtnNext.text = __("CONFIRM")
	end

	local flag = true

	for i = 1, num do
		if not self.opAwards[i] then
			flag = false

			break
		end
	end

	if num and flag or self.opAwards[self.curIndex] and self.curIndex < num then
		xyd.applyOrigin(self.btnNext:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnNext, true)
		self.labelBtnNext:ApplyOrigin()
	else
		xyd.applyGrey(self.btnNext:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnNext, false)
		self.labelBtnNext:ApplyGrey()
	end
end

function ActivityChristmasSaleAwardSelectWindow:initReAward()
	local num = ActivityChristmasSaleAwardsTable:getOpAwardsNum(self.id)

	NGUITools.DestroyChildren(self.groupRewards.transform)

	self.rewardsList = {}

	for i = 1, num do
		local icon = ReplaceIcon.new(self.groupRewards)
		local index = i

		if self.opAwards[i] then
			local data = self.opAwards[i]

			icon:setIcon(data[1], data[2], true)
		end

		table.insert(self.rewardsList, icon)

		UIEventListener.Get(icon:getGameObject()).onClick = function ()
			if self.curIndex == index then
				return
			end

			self.curIndex = index

			self:updateCurIcon(index)
		end
	end

	for i = 1, num do
		if self.opAwards[i] then
			local awards = ActivityChristmasSaleAwardsTable:getAwards(self.id, i)

			for j = 1, #awards do
				local data = awards[j]

				if tonumber(data[1][1]) == self.opAwards[i][1] then
					self.opAwardIndexs[i] = j
				end
			end
		end
	end
end

function ActivityChristmasSaleAwardSelectWindow:updateCurIcon(index)
	for i = 1, #self.rewardsList do
		local icon = self.rewardsList[i]
		local flag = i == index

		icon:selected(flag)

		if flag then
			self:waitForFrame(5, function ()
				local x = icon:getGameObject().transform.localPosition.x

				self.arrow:X(x)
			end)
		end
	end

	self:initDesc()
	self:updateAwardPool(index)
	self:updateNextBtn()
end

function ActivityChristmasSaleAwardSelectWindow:initDesc()
	self.line:SetActive(false)

	self.labelName.text = ""
	self.labelDesc.text = __("ACTIVITY_DUANWU_SHUOMING")
end

function ActivityChristmasSaleAwardSelectWindow:updateAwardPool(index)
	local awards = ActivityChristmasSaleAwardsTable:getAwards(self.id, index)
	local limits = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE).detail.limits[self.id]["limit" .. index]
	local list = {}

	for i = 1, #awards do
		local data = awards[i]
		local item = {
			tonumber(data[1][1]),
			tonumber(data[1][2]),
			leftTimes = tonumber(data[2][1]) - limits[i],
			limitTimes = tonumber(data[2][1]),
			index = i
		}

		table.insert(list, item)
	end

	table.sort(list, function (a, b)
		if a.leftTimes == 0 and b.leftTimes ~= 0 then
			return false
		elseif a.leftTimes ~= 0 and b.leftTimes == 0 then
			return true
		else
			return a.index < b.index
		end
	end)
	NGUITools.DestroyChildren(self.groupPools.transform)

	self.selectedIcon = nil

	for i = 1, #list do
		local data = list[i]
		local icon = nil
		local tmp = NGUITools.AddChild(self.groupPools, self.icon_root)
		local labelNum = tmp:ComponentByName("labelNum", typeof(UILabel))
		labelNum.text = data.leftTimes .. "/" .. data.limitTimes

		if data.leftTimes == 0 then
			labelNum.color = Color.New2(3422556671.0)
		end

		icon = xyd.getItemIcon({
			noClickSelected = true,
			uiRoot = tmp,
			itemID = tonumber(data[1]),
			num = tonumber(data[2]),
			callback = function ()
				if self.leftTimes == 0 or data.leftTimes == 0 then
					return
				end

				self.opAwards[index] = data
				self.opAwardIndexs[index] = data.index

				if self.selectedIcon then
					self.selectedIcon:setChoose(false)
				end

				self.selectedIcon = icon

				self.selectedIcon:setChoose(true)
				self:setCurIconInfo(data)
			end
		})

		icon:setDragScrollView(self.scrollerView)

		if self.opAwards[index] and self.opAwards[index][1] == data[1] then
			self.opAwardIndexs[index] = data.index
			self.selectedIcon = icon

			self.selectedIcon:setChoose(true)
			self:setCurIconInfo(data)
		end
	end

	self.groupPoolsGrid:Reposition()
end

function ActivityChristmasSaleAwardSelectWindow:setCurIconInfo(data)
	local curIcon = self.rewardsList[self.curIndex]

	curIcon:setIcon(data[1], data[2], true)

	self.labelName.text = xyd.tables.itemTextTable:getName(data[1])
	local type_ = xyd.tables.itemTable:getType(data[1])

	if type_ == xyd.ItemType.ARTIFACT then
		self.labelDesc.text = xyd.tables.equipTable:getDesc(data[1])
	else
		self.labelDesc.text = xyd.tables.itemTextTable:getDesc(data[1])
	end

	self.line:SetActive(true)
	self:updateNextBtn()
end

function ActivityChristmasSaleAwardSelectWindow:register()
	ActivityChristmasSaleAwardSelectWindow.super.register(self)

	UIEventListener.Get(self.btnCancel).onClick = function ()
		self:onClickCloseButton()
	end

	local num = ActivityChristmasSaleAwardsTable:getOpAwardsNum(self.id)

	UIEventListener.Get(self.btnNext).onClick = function ()
		self.curIndex = self.curIndex + 1

		if self.curIndex <= num then
			self:updateCurIcon(self.curIndex)
		else
			if self.leftTimes ~= 0 then
				self.item:setOpAward(self.opAwards)
				self.item:setIcon()
				self:recordSelect()
			end

			self:onClickCloseButton()
		end
	end
end

function ActivityChristmasSaleAwardSelectWindow:recordSelect()
	local msg = messages_pb:christmas_self_select_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE
	msg.table_id = self.id

	for i in pairs(self.opAwardIndexs) do
		table.insert(msg.indexs, self.opAwardIndexs[i])
	end

	xyd.Backend.get():request(xyd.mid.CHRISTMAS_SELF_SELECT, msg)

	local data = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE)
	local rs = ""
	local t = {}

	for i = 1, #self.opAwardIndexs do
		table.insert(t, tostring(self.opAwardIndexs[i]))
	end

	rs = rs .. table.concat(t, "|")
	data.detail[tostring(self.id)] = rs
end

return ActivityChristmasSaleAwardSelectWindow
