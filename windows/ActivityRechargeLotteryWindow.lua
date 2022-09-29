local cjson = require("cjson")
local BaseWindow = import(".BaseWindow")
local CountDown = import("app.components.CountDown")
local ActivityRechargeLotteryWindow = class("ActivityRechargeLotteryWindow", BaseWindow)
local activityID = xyd.ActivityID.ACTIVITY_RECHARGE_LOTTERY
local resItemID = xyd.ItemID.RECHARGE_LOTTERY_TICKET

function ActivityRechargeLotteryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(activityID)
	self.isSkipAni = tonumber(xyd.db.misc:getValue("activity_recharge_lottery_skip") or 0)

	xyd.db.misc:setValue({
		value = "1",
		key = "ActivityFirstRedMark_" .. xyd.ActivityID.ACTIVITY_RECHARGE_LOTTERY .. "_" .. self.activityData.end_time
	})

	local lastViewTime = xyd.db.misc:getValue("activity_recharge_lottery_view_time")

	if not lastViewTime or not xyd.isSameDay(tonumber(lastViewTime), xyd.getServerTime()) then
		local msg = messages_pb.record_activity_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_RECHARGE_LOTTERY

		xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
	end

	xyd.db.misc:setValue({
		key = "activity_recharge_lottery_view_time",
		value = xyd.getServerTime()
	})
	self.activityData:updateRedMark()

	self.isFirst = true
	self.isFinish = true

	for _, v in pairs(self.activityData.detail.awards) do
		if v ~= 0 then
			self.isFirst = false
		end

		if v ~= 1 then
			self.isFinish = false
		end
	end

	self.icons = {}
	self.curID = 1
	self.stopAniFlag = 0
end

function ActivityRechargeLotteryWindow:initWindow()
	self:getUIComponent()
	ActivityRechargeLotteryWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityRechargeLotteryWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.imgText = groupAction:ComponentByName("imgText", typeof(UISprite))
	local groupTime = groupAction:NodeByName("groupTime").gameObject
	self.timeLayout = groupTime:NodeByName("layout").gameObject
	self.timeLabel = self.timeLayout:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeLayout:ComponentByName("endLabel", typeof(UILabel))
	local groupDesc = groupAction:NodeByName("groupDesc").gameObject
	self.labelDesc = groupDesc:ComponentByName("labelDesc", typeof(UILabel))
	local resItem = groupAction:NodeByName("resItem").gameObject
	self.resNum = resItem:ComponentByName("num", typeof(UILabel))
	self.resPlus = resItem:NodeByName("plus").gameObject
	local groupContent = groupAction:NodeByName("groupContent").gameObject
	local groupTip = groupContent:NodeByName("groupTip").gameObject
	self.labelTip = groupTip:ComponentByName("labelTip", typeof(UILabel))
	self.groupSkip = groupContent:NodeByName("groupSkip").gameObject
	self.btnSkip = self.groupSkip:NodeByName("btnSkip").gameObject
	self.skipChoose = self.btnSkip:ComponentByName("imgChoose", typeof(UISprite))
	self.labelSkip = self.groupSkip:ComponentByName("labelSkip", typeof(UILabel))
	self.btnDraw = groupContent:NodeByName("btnDraw").gameObject
	self.labelDraw = self.btnDraw:ComponentByName("labelDraw", typeof(UILabel))
	self.labelCostNum = self.btnDraw:ComponentByName("num", typeof(UILabel))
	local groupAward = groupContent:NodeByName("groupAward").gameObject

	for i = 1, 12 do
		self["award" .. i] = groupAward:NodeByName("award" .. i).gameObject
		self["awardChoose" .. i] = self["award" .. i]:NodeByName("imgChoose").gameObject
		self["awardIcon" .. i] = self["award" .. i]:NodeByName("icon").gameObject
	end

	self.btnClose = groupAction:NodeByName("btnClose").gameObject
	self.btnHelp = groupAction:NodeByName("btnHelp").gameObject
	self.btnMission = groupAction:NodeByName("btnMission").gameObject
end

function ActivityRechargeLotteryWindow:initUIComponent()
	xyd.setUISpriteAsync(self.imgText, nil, "activity_recharge_lottery_logo_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
	end

	self.labelDesc.text = __("ACTIVITY_LOTTERY_TEXT08")
	self.resNum.text = xyd.models.backpack:getItemNumByID(resItemID)
	self.labelTip.text = __("ACTIVITY_LOTTERY_TEXT01")
	self.labelSkip.text = __("ACTIVITY_LOTTERY_TEXT03")
	self.labelDraw.text = self.isFirst and __("ACTIVITY_LOTTERY_TEXT04") or __("ACTIVITY_LOTTERY_TEXT07")
	self.labelCostNum.text = self.isFirst and "x0" or "x1"

	for i = 1, 12 do
		if i % 3 ~= 1 then
			local pos = i
			local id = xyd.tables.activityLotteryTable:getIdByPos(pos)
			local award = xyd.tables.activityLotteryTable:getAwards(id)[1]
			self.icons[i] = xyd.getItemIcon({
				showGetWays = false,
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.7037037037037037,
				isShowSelected = false,
				itemID = award[1],
				num = award[2],
				uiRoot = self["awardIcon" .. i],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			if self.activityData.detail.awards[id] == 1 then
				self.icons[i]:setChoose(true)
			end
		else
			local pos = i
			local id = xyd.tables.activityLotteryTable:getIdByPos(pos)

			if self.activityData.detail.awards[id] == 1 then
				self["award" .. i]:NodeByName("mask").gameObject:SetActive(true)
				self["award" .. i]:NodeByName("imgSelect").gameObject:SetActive(true)
			end
		end

		self["awardChoose" .. i]:SetActive(false)
	end

	if self.isSkipAni == 1 then
		self.skipChoose:SetActive(true)
	else
		self.skipChoose:SetActive(false)
	end

	if self.isFinish then
		xyd.setEnabled(self.btnDraw.gameObject, false)
	end

	self:playAni()
end

function ActivityRechargeLotteryWindow:playAni()
	local aniFunction = nil

	function aniFunction()
		self["awardChoose" .. self.curID]:SetActive(false)

		self.curID = self.curID % 12 + 1

		self["awardChoose" .. self.curID]:SetActive(true)
		self:waitForTime(1, function ()
			if self.stopAniFlag == 0 then
				aniFunction()
			else
				self.stopAniFlag = self.stopAniFlag - 1
			end
		end)
	end

	aniFunction()
end

function ActivityRechargeLotteryWindow:register()
	ActivityRechargeLotteryWindow.super.register(self)

	UIEventListener.Get(self.btnClose).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_LOTTERY_HELP"
		})
	end

	UIEventListener.Get(self.btnMission).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_recharge_lottery_mission_window", {
			vipExp = self.activityData.detail.point
		})
	end

	UIEventListener.Get(self.resPlus).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_recharge_lottery_mission_window", {
			vipExp = self.activityData.detail.point
		})
	end

	UIEventListener.Get(self.btnSkip).onClick = function ()
		if self.isSkipAni == 1 then
			self.isSkipAni = 0

			self.skipChoose:SetActive(false)
		else
			self.isSkipAni = 1

			self.skipChoose:SetActive(true)
		end

		xyd.db.misc:setValue({
			key = "activity_recharge_lottery_skip",
			value = self.isSkipAni
		})
	end

	UIEventListener.Get(self.groupSkip.gameObject).onClick = function ()
		if self.isSkipAni == 1 then
			self.isSkipAni = 0

			self.skipChoose:SetActive(false)
		else
			self.isSkipAni = 1

			self.skipChoose:SetActive(true)
		end

		xyd.db.misc:setValue({
			key = "activity_recharge_lottery_skip",
			value = self.isSkipAni
		})
	end

	UIEventListener.Get(self.btnDraw).onClick = function ()
		if xyd.models.backpack:getItemNumByID(resItemID) < 1 and not self.isFirst then
			xyd.alertTips(__("ACTIVITY_LOTTERY_TEXT06"))

			return
		end

		xyd.models.activity:reqAwardWithParams(activityID, cjson.encode({
			num = 1
		}))
		xyd.setEnabled(self.btnDraw.gameObject, false)
	end

	for i = 1, 12 do
		UIEventListener.Get(self["award" .. i]).onClick = function ()
			local id = xyd.tables.activityLotteryTable:getIdByPos(i)

			xyd.WindowManager:get():openWindow("activity_recharge_lottery_box_detail_window", {
				type = xyd.tables.activityLotteryTable:getType2(id),
				boxID = id
			})
		end
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(resItemID)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= activityID then
			return
		end

		xyd.SoundManager.get():stopSound(xyd.SoundID.GAMBLE_1)
		xyd.SoundManager.get():stopSound(xyd.SoundID.GAMEBLE_NORMAL)

		self.stopAniFlag = self.stopAniFlag + 1
		local awardID = self.activityData.awardID

		print("awardID   ", awardID)

		local pos = xyd.tables.activityLotteryTable:getPos(awardID)

		print("pos    ", pos)

		local function updateState()
			self.isFinish = true

			for _, v in pairs(self.activityData.detail.awards) do
				if v ~= 0 then
					self.isFirst = false
				end

				if v ~= 1 then
					self.isFinish = false
				end
			end

			self.labelDraw.text = __("ACTIVITY_LOTTERY_TEXT07")
			self.labelCostNum.text = "x1"

			if not self.isFinish then
				xyd.setEnabled(self.btnDraw.gameObject, true)
			end

			if pos % 3 ~= 1 then
				self.icons[pos]:setChoose(true)
			else
				self["award" .. pos]:NodeByName("mask").gameObject:SetActive(true)
				self["award" .. pos]:NodeByName("imgSelect").gameObject:SetActive(true)
			end
		end

		local function pushNewItems()
			local awards = xyd.tables.activityLotteryTable:getAwards(awardID)
			local info = {}

			for i = 1, #awards do
				local award = awards[i]

				table.insert(info, {
					item_id = award[1],
					item_num = award[2]
				})
			end

			xyd.models.itemFloatModel:pushNewItems(info)
		end

		if self.isSkipAni == 1 then
			xyd.SoundManager.get():playSound(xyd.SoundID.GAMEBLE_NORMAL)
			updateState()
			pushNewItems()
			self["awardChoose" .. self.curID]:SetActive(false)

			self.curID = pos

			self["awardChoose" .. self.curID]:SetActive(true)

			self.curID = self.curID - 1

			if self.curID == 0 then
				self.curID = 12
			end

			self:playAni()
		else
			xyd.SoundManager.get():playSound(xyd.SoundID.GAMBLE_1)

			local fastAniRound = 3
			local fastAniFunction, slowAniFunction = nil

			function fastAniFunction()
				self["awardChoose" .. self.curID]:SetActive(false)

				self.curID = self.curID % 12 + 1

				self["awardChoose" .. self.curID]:SetActive(true)
				self:waitForTime(0.06, function ()
					if self.curID == pos then
						fastAniRound = fastAniRound - 1
					end

					if fastAniRound > 0 then
						fastAniFunction()
					else
						slowAniFunction()
					end
				end)
			end

			function slowAniFunction()
				self["awardChoose" .. self.curID]:SetActive(false)

				self.curID = self.curID % 12 + 1

				self["awardChoose" .. self.curID]:SetActive(true)
				self:waitForTime(0.2, function ()
					if self.curID ~= pos then
						slowAniFunction()
					else
						updateState()
						pushNewItems()

						self.curID = self.curID - 1

						if self.curID == 0 then
							self.curID = 12
						end

						self:playAni()
					end
				end)
			end

			fastAniFunction()
		end
	end)
end

return ActivityRechargeLotteryWindow
