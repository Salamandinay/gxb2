local cjson = require("cjson")
local BaseWindow = import(".BaseWindow")
local CountDown = import("app.components.CountDown")
local ActivityLimitCultivateWindow = class("ActivityLimitCultivateWindow", BaseWindow)
local activityID = xyd.ActivityID.ACTIVITY_LIMIT_CULTIVATE
local resItemID = xyd.ItemID.ACTIVITY_5WEEK_COST

function ActivityLimitCultivateWindow:ctor(name, params)
	self.awardItems_ = {}

	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(activityID)

	self.activityData:updateRedMark()
end

function ActivityLimitCultivateWindow:initWindow()
	self:getUIComponent()
	ActivityLimitCultivateWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityLimitCultivateWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.clickmask = groupAction:NodeByName("clickmask").gameObject
	self.normalEffectPos1 = groupAction:NodeByName("effectGroup/normalEffectPos1").gameObject
	self.imgText = groupAction:ComponentByName("imgText", typeof(UISprite))
	local groupTime = groupAction:NodeByName("groupTime").gameObject
	self.timeLayout = groupTime:NodeByName("layout").gameObject
	self.timeLabel = self.timeLayout:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeLayout:ComponentByName("endLabel", typeof(UILabel))
	local resItem = groupAction:NodeByName("resItem").gameObject
	self.resNum = resItem:ComponentByName("num", typeof(UILabel))
	self.resPlus = resItem:NodeByName("plus").gameObject
	local clock = groupAction:NodeByName("clockGroup/clock").gameObject
	local itemGroup = clock:NodeByName("itemGroup").gameObject
	self.pointer1 = clock:NodeByName("pointer1").gameObject

	for i = 1, 8 do
		self["award" .. i] = itemGroup:NodeByName("award" .. i).gameObject
		self["awardNum" .. i] = self["award" .. i]:ComponentByName("awardNum", typeof(UILabel))
	end

	self.btnDraw = clock:NodeByName("btnDraw").gameObject
	self.labelDraw = self.btnDraw:ComponentByName("labelDraw", typeof(UILabel))
	self.btnClose = groupAction:NodeByName("btnClose").gameObject
	self.btnHelp = groupAction:NodeByName("btnHelp").gameObject
	self.btnMission = groupAction:NodeByName("btnMission").gameObject
	self.bottomGroup = groupAction:NodeByName("bottomGroup").gameObject
	self.progressLabel = self.bottomGroup:ComponentByName("labelAll/progressLabel", typeof(UILabel))
	self.progressLabelUp = self.bottomGroup:ComponentByName("labelAll/progressLabelUp", typeof(UILabel))
	self.scrollViewProgress_ = self.bottomGroup:ComponentByName("scrollViewProgress", typeof(UIScrollView))
	self.gridProgress_ = self.bottomGroup:ComponentByName("scrollViewProgress/itemGrid", typeof(UIGrid))
	self.awardItem_ = self.bottomGroup:NodeByName("scrollViewProgress/awardItem").gameObject
	self.progressItem_ = self.bottomGroup:ComponentByName("scrollViewProgress/progressItem", typeof(UIProgressBar))
end

function ActivityLimitCultivateWindow:initUIComponent()
	xyd.setUISpriteAsync(self.imgText, nil, "logo_zp_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData.detail.start_time + 604800 - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
	end

	self.resNum.text = xyd.models.backpack:getItemNumByID(resItemID)
	self.labelDraw.text = __("ACTIVITY_5WEEK_TEXT01")
	local ids = xyd.tables.activityLimitCultivateTable:getIDs()
	self.icons = {}
	local awardAngel = 67.5

	for i = 1, 8 do
		self["award" .. i]:X(math.cos(awardAngel * 3.14 / 180) * 190)
		self["award" .. i]:Y(math.sin(awardAngel * 3.14 / 180) * 190 - 25)

		awardAngel = awardAngel - 45
		self.icons[i] = xyd.getItemIcon({
			showGetWays = false,
			notShowGetWayBtn = true,
			show_has_num = true,
			scale = 0.7037037037037037,
			isShowSelected = false,
			itemID = xyd.tables.activityLimitCultivateTable:getAwards(ids[i])[1],
			num = xyd.tables.activityLimitCultivateTable:getAwards(ids[i])[2],
			uiRoot = self["award" .. i],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	local curNum = self.activityData.detail.lefts
	local curIds = self.activityData.detail.ids

	for i = 1, 8 do
		self.icons[i]:setChoose(true)
		self.icons[i]:setDepth(20)

		self["awardNum" .. i].text = " "

		for ii = 1, #curIds do
			if i == curIds[ii] then
				self.icons[i]:setChoose(false)

				self["awardNum" .. i].text = curNum[ii]
			end
		end
	end

	if not self.normalEffect1 then
		self.normalEffect1 = xyd.Spine.new(self.normalEffectPos1.gameObject)

		self.normalEffect1:setInfo("clock_awards", function ()
			self.normalEffectPos1:SetActive(false)
			self.normalEffect1:play("normal", 1)
		end)
	end

	local max_score = xyd.tables.activityLimitCultivateAwardTable:getMaxPoint() or 0
	local point = self.activityData.detail.times
	self.progressLabelUp.text = __("ACTIVITY_5WEEK_TEXT02")
	self.progressLabel.text = self.activityData.detail.times
	local awardIds = xyd.tables.activityLimitCultivateAwardTable:getIDs()

	for index, id in ipairs(awardIds) do
		local need_point = xyd.tables.activityLimitCultivateAwardTable:getPoint(id)
		local award = xyd.tables.activityLimitCultivateAwardTable:getAward(id)
		local newRoot = NGUITools.AddChild(self.gridProgress_.gameObject, self.awardItem_)
		self["awardItemNewRoot" .. index] = newRoot:NodeByName("awardbtn").gameObject

		newRoot:SetActive(true)

		local labelPoint = newRoot:ComponentByName("labelScore", typeof(UILabel))
		labelPoint.text = need_point
		self.awardItems_[index] = xyd.getItemIcon({
			showGetWays = false,
			notShowGetWayBtn = true,
			show_has_num = true,
			scale = 0.6018518518518519,
			isShowSelected = false,
			uiRoot = newRoot,
			itemID = award[1],
			num = award[2],
			dragScrollView = self.scrollViewProgress_,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		self.awardItems_[index]:setDepth(20)

		if self.activityData.detail.times_awarded[index] == 0 then
			self.awardItems_[index]:setChoose(false)

			if xyd.tables.activityLimitCultivateAwardTable:getPoint(index) <= self.activityData.detail.times then
				self.awardItems_[index]:setEffect(true, "fx_ui_bp_available")
				self["awardItemNewRoot" .. index]:SetActive(true)
			else
				self.awardItems_[index]:setEffect(false, "fx_ui_bp_available")
				self["awardItemNewRoot" .. index]:SetActive(false)
			end
		else
			self.awardItems_[index]:setChoose(true)
			self.awardItems_[index]:setEffect(false, "fx_ui_bp_available")
			self["awardItemNewRoot" .. index]:SetActive(false)
		end
	end

	local progressValue = 0

	for index = 1, #awardIds do
		if xyd.tables.activityLimitCultivateAwardTable:getPoint(index) <= self.activityData.detail.times then
			progressValue = progressValue + 1 / #awardIds
		else
			if index == 1 then
				progressValue = progressValue + self.activityData.detail.times / xyd.tables.activityLimitCultivateAwardTable:getPoint(index) * 1 / #awardIds * 0.76

				break
			end

			progressValue = progressValue + (self.activityData.detail.times - xyd.tables.activityLimitCultivateAwardTable:getPoint(index - 1)) / (xyd.tables.activityLimitCultivateAwardTable:getPoint(index) - xyd.tables.activityLimitCultivateAwardTable:getPoint(index - 1)) * 1 / #awardIds * 0.76

			break
		end
	end

	self.progressItem_.value = math.min(progressValue, 1)
end

function ActivityLimitCultivateWindow:playAni(details)
	local awardId = details.award_ids[1]

	if awardId > 8 then
		return
	end

	self.clickmask:SetActive(true)

	if self.pointerAnimation then
		self.pointerAnimation:Kill(true)

		self.pointerAnimation = nil
	end

	if not self.pointerAnimation then
		self.pointerAnimation = self:getSequence()
	end

	local radiao = -22.5 - (awardId - 1) * 45 + xyd.random(-15, 15)

	self.pointerAnimation:Insert(0, self.pointer1.gameObject.transform:DOLocalRotate(Vector3(0, 0, radiao - 1080), 1, DG.Tweening.RotateMode.FastBeyond360))
	self.pointerAnimation:AppendCallback(function ()
		self.normalEffectPos1:SetActive(true)

		self.normalEffectPos1.gameObject.transform.position = self["award" .. awardId].gameObject.transform.position

		self.normalEffect1:play("normal", 1, 1, function ()
			self.clickmask:SetActive(false)
			self.normalEffectPos1:SetActive(false)
			self:showAward(details)
		end)
	end)
end

function ActivityLimitCultivateWindow:showAward(details)
	local awardIds = details.award_ids
	local items = {}

	for i = 1, #awardIds do
		local item = {
			item_id = xyd.tables.activityLimitCultivateTable:getAwards(awardIds[i])[1],
			item_num = xyd.tables.activityLimitCultivateTable:getAwards(awardIds[i])[2]
		}

		table.insert(items, item)
	end

	xyd.openWindow("gamble_rewards_window", {
		wnd_type = 4,
		isNeedCostBtn = false,
		data = items,
		callback = function ()
			self:refresh()
		end
	})
end

function ActivityLimitCultivateWindow:refresh()
	local curNum = self.activityData.detail.lefts
	local curIds = self.activityData.detail.ids

	for i = 1, 8 do
		self.icons[i]:setChoose(true)

		self["awardNum" .. i].text = " "

		for ii = 1, #curIds do
			if i == curIds[ii] then
				self.icons[i]:setChoose(false)

				self["awardNum" .. i].text = curNum[ii]
			end
		end
	end

	self.resNum.text = xyd.models.backpack:getItemNumByID(resItemID)

	for index = 1, #self.awardItems_ do
		if self.activityData.detail.times_awarded[index] == 0 then
			self.awardItems_[index]:setChoose(false)

			if xyd.tables.activityLimitCultivateAwardTable:getPoint(index) <= self.activityData.detail.times then
				self.awardItems_[index]:setEffect(true, "fx_ui_bp_available")
				self["awardItemNewRoot" .. index]:SetActive(true)
			else
				self.awardItems_[index]:setEffect(false, "fx_ui_bp_available")
				self["awardItemNewRoot" .. index]:SetActive(false)
			end
		else
			self.awardItems_[index]:setChoose(true)
			self.awardItems_[index]:setEffect(false, "fx_ui_bp_available")
			self["awardItemNewRoot" .. index]:SetActive(false)
		end
	end

	local awardIds = xyd.tables.activityLimitCultivateAwardTable:getIDs()
	local progressValue = 0

	for index = 1, #awardIds do
		if xyd.tables.activityLimitCultivateAwardTable:getPoint(index) <= self.activityData.detail.times then
			progressValue = progressValue + 1 / #awardIds
		else
			if index == 1 then
				progressValue = progressValue + self.activityData.detail.times / xyd.tables.activityLimitCultivateAwardTable:getPoint(index) * 1 / #awardIds * 0.76

				break
			end

			progressValue = progressValue + (self.activityData.detail.times - xyd.tables.activityLimitCultivateAwardTable:getPoint(index - 1)) / (xyd.tables.activityLimitCultivateAwardTable:getPoint(index) - xyd.tables.activityLimitCultivateAwardTable:getPoint(index - 1)) * 1 / #awardIds * 0.76

			break
		end
	end

	self.progressItem_.value = math.min(progressValue, 1)
	self.progressLabel.text = self.activityData.detail.times
end

function ActivityLimitCultivateWindow:register()
	ActivityLimitCultivateWindow.super.register(self)

	UIEventListener.Get(self.btnClose).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_5WEEK_HELP"
		})
	end

	UIEventListener.Get(self.btnMission).onClick = function ()
		local curNum = self.activityData.detail.lefts
		local curIds = self.activityData.detail.ids
		local ids = xyd.tables.activityLimitCultivateTable:getIDs()
		local datas = {}

		for i = 1, #ids do
			local nowNum = 0

			for ii = 1, #curIds do
				if i == curIds[ii] then
					nowNum = curNum[ii]
				end
			end

			table.insert(datas, {
				items = xyd.tables.activityLimitCultivateTable:getAwards(ids[i]),
				num = xyd.tables.activityLimitCultivateTable:getNum(ids[i]),
				cur_num = nowNum
			})
		end

		xyd.WindowManager.get():openWindow("activity_wine_award_preview_window", datas)
	end

	UIEventListener.Get(self.resPlus).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW),
			select = xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW
		})
		self:close()
	end

	UIEventListener.Get(self.btnDraw).onClick = function ()
		local leftNum = 0
		local lefts = self.activityData.detail.lefts

		for i = 1, #lefts do
			leftNum = leftNum + lefts[i]
		end

		if leftNum <= 0 then
			xyd.alertTips(__("ACTIVITY_5WEEK_TEXT06"))

			return
		end

		local resNum = xyd.models.backpack:getItemNumByID(resItemID)

		if resNum <= 0 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(resItemID)))

			return
		end

		local chooseMin = math.min(resNum, leftNum)

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_multiple = 1,
			select_max_num = math.min(chooseMin, 20),
			show_max_num = resNum,
			icon_info = {
				height = 45,
				width = 45,
				name = xyd.tables.itemTable:getIcon(resItemID)
			},
			title_text = __("ACTIVITY_5WEEK_TEXT03"),
			explain_text = __("ACTIVITY_5WEEK_TEXT04"),
			sure_callback = function (useNum)
				local data = require("cjson").encode({
					type = 1,
					num = useNum
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = activityID
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(resItemID)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= activityID then
			return
		end

		local details = require("cjson").decode(event.data.detail)

		if details.type == 1 then
			self.activityData.detail.lefts = details.info.lefts
			self.activityData.detail.ids = details.info.ids
			self.activityData.detail.times = details.info.times
			self.activityData.detail.times_awarded = details.info.times_awarded

			self:playAni(details)
		else
			for i = 1, #self.activityData.detail.times_awarded do
				if self.activityData.detail.times_awarded[i] ~= details.times_awarded[i] then
					local info = {}
					local award = xyd.tables.activityLimitCultivateAwardTable:getAward(i)

					table.insert(info, {
						item_id = award[1],
						item_num = award[2]
					})
					xyd.models.itemFloatModel:pushNewItems(info)
				end
			end

			self.activityData.detail.times_awarded = details.times_awarded

			for index = 1, #self.awardItems_ do
				if self.activityData.detail.times_awarded[index] == 0 then
					self.awardItems_[index]:setChoose(false)

					if xyd.tables.activityLimitCultivateAwardTable:getPoint(index) <= self.activityData.detail.times then
						self.awardItems_[index]:setEffect(true, "fx_ui_bp_available")
						self["awardItemNewRoot" .. index]:SetActive(true)
					else
						self.awardItems_[index]:setEffect(false, "fx_ui_bp_available")
						self["awardItemNewRoot" .. index]:SetActive(false)
					end
				else
					self.awardItems_[index]:setChoose(true)
					self.awardItems_[index]:setEffect(false, "fx_ui_bp_available")
					self["awardItemNewRoot" .. index]:SetActive(false)
				end
			end
		end
	end)

	for i = 1, #self.awardItems_ do
		UIEventListener.Get(self["awardItemNewRoot" .. i]).onClick = function ()
			if xyd.tables.activityLimitCultivateAwardTable:getPoint(i) <= self.activityData.detail.times and self.activityData.detail.times_awarded[i] == 0 then
				local data = require("cjson").encode({
					type = 2,
					id = i
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = activityID
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			end
		end
	end
end

return ActivityLimitCultivateWindow
