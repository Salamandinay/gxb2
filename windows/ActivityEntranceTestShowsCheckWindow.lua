local ActivityEntranceTestShowsCheckWindow = class("ActivityEntranceTestShowsCheckWindow", import(".BaseWindow"))

function ActivityEntranceTestShowsCheckWindow:ctor(name, params)
	ActivityEntranceTestShowsCheckWindow.super.ctor(self, name, params)

	self.monster = params.monster
	self.color = params.color
	self.dayIndex = params.dayIndex
	self.needItemsNum = {}
	self.currentSelect = 0
	local costArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_guess_cost", "value", "|#")
	self.needItem = costArr[1][1]

	for _, item in ipairs(costArr) do
		table.insert(self.needItemsNum, item[2])
	end
end

function ActivityEntranceTestShowsCheckWindow:initWindow()
	ActivityEntranceTestShowsCheckWindow.super.initWindow(self)
	self:getComponent()
	self:registerEvent()
	self:layout()
end

function ActivityEntranceTestShowsCheckWindow:getComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.winTitle = self.groupAction:ComponentByName("winTitle", typeof(UILabel))
	self.tipWords = self.groupAction:ComponentByName("tipWords", typeof(UILabel))
	self.frontAvatars = self.groupAction:ComponentByName("frontAvatars", typeof(UIGrid))
	self.backAvatars = self.groupAction:ComponentByName("backAvatars", typeof(UIGrid))
	self.btnOk_ = self.groupAction:NodeByName("btnOk").gameObject
	self.btnOKlabel_ = self.groupAction:ComponentByName("btnOk/label", typeof(UILabel))
	self.costNodeGroup = self.groupAction:NodeByName("costNodeGroup").gameObject

	for i = 1, 3 do
		self["costNode" .. i] = self.costNodeGroup:NodeByName("costNode" .. i).gameObject
		self["selectImg" .. i] = self["costNode" .. i]:NodeByName("selectImg").gameObject
		self["costLabel" .. i] = self["costNode" .. i]:ComponentByName("label", typeof(UILabel))
	end
end

function ActivityEntranceTestShowsCheckWindow:registerEvent()
	ActivityEntranceTestShowsCheckWindow.super.register(self)

	local awardArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_guess_cost", "value", "|#")

	UIEventListener.Get(self.btnOk_).onClick = function ()
		if self.currentSelect == 0 then
			xyd.alertTips(__("ACTIVITY_SPORTS_SELECT_GUESS_TIP"))

			return
		end

		local theColor = 0

		if self.color == 1 then
			theColor = 1
		end

		local msg = messages_pb.warmup_bet_req()
		msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
		msg.index = self.dayIndex
		msg.is_win = theColor
		msg.bet_num_id = self.currentSelect

		xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	for i = 1, 3 do
		UIEventListener.Get(self["costNode" .. i]).onClick = function ()
			if xyd.models.backpack:getItemNumByID(self.needItem) < self.needItemsNum[i] then
				return
			end

			if self.currentSelect > 0 then
				self["selectImg" .. self.currentSelect]:SetActive(false)
			end

			self.currentSelect = i

			self["selectImg" .. self.currentSelect]:SetActive(true)
		end
	end
end

function ActivityEntranceTestShowsCheckWindow:layout()
	local str = xyd.checkCondition(self.color == 1, __("ACTIVITY_SPORTS_SELECT_GUESS_TIP_1"), __("ACTIVITY_SPORTS_SELECT_GUESS_TIP_2"))
	self.tipWords.text = str
	self.btnOKlabel_.text = __("SURE")

	for i = 1, 6 do
		if self.monster[i] then
			local tableID = self.monster[i]
			local partnerInfo = xyd.tables.activityEntranceTestMonsterTable:getPartnerData(tableID)
			local parent_ = self.backAvatars

			if i <= 2 then
				parent_ = self.frontAvatars
			end

			partnerInfo.uiRoot = parent_.gameObject
			partnerInfo.noClick = true
			partnerInfo.scale = 1

			xyd.getHeroIcon(partnerInfo)
		end
	end

	self.backAvatars:Reposition()
	self.frontAvatars:Reposition()

	for i = 1, 3 do
		self["selectImg" .. i]:SetActive(false)

		self["costLabel" .. i].text = xyd.getRoughDisplayNumber(self.needItemsNum[i])

		if xyd.models.backpack:getItemNumByID(self.needItem) < self.needItemsNum[i] then
			xyd.applyChildrenGrey(self["costNode" .. i])
		end
	end
end

return ActivityEntranceTestShowsCheckWindow
