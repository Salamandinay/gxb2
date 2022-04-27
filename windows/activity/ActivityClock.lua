local ActivityClock = class("ActivityClock", import(".ActivityContent"))
local ActivityClockItem = class("ActivityClockItem", import("app.components.CopyComponent"))
local SelectNum = import("app.components.SelectNum")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function ActivityClock:ctor(parentGO, params)
	ActivityClock.super.ctor(self, parentGO, params)
end

function ActivityClock:getPrefabPath()
	return "Prefabs/Windows/activity/activity_clock"
end

function ActivityClock:initUI()
	self:getUIComponent()
	ActivityClock.super.initUI(self)

	self.clockItems = {}
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CLOCK)

	self:initUIComponent()
	self:register()
end

function ActivityClock:resizeToParent()
	ActivityClock.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874

	self:resizePosY(self.titleImg_.gameObject, 275, 255)
	self:resizePosY(self.Bg_.gameObject, -140, -175)
	self:resizePosY(self.clockGroup.gameObject, -69, -104)
	self:resizePosY(self.btnAward.gameObject, -432, -470)
	self:resizePosY(self.progressAwardGroup.gameObject, -458, -483)
	self:resizePosY(self.numPos.gameObject, -479, -519)
	self:resizePosY(self.topGroup.gameObject, -18, 0)
end

function ActivityClock:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.titleImg_ = self.groupAction:ComponentByName("titleImg_", typeof(UITexture))
	self.Bg_ = self.groupAction:ComponentByName("Bg_", typeof(UITexture))
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.btnHelp = self.topGroup:NodeByName("btnHelp").gameObject
	self.btnAwardPreview = self.topGroup:NodeByName("btnAwardPreview").gameObject
	self.resourcesGroup = self.topGroup:NodeByName("resourcesGroup").gameObject
	self.resource1Group = self.resourcesGroup:NodeByName("resource1Group").gameObject
	self.imgResource1 = self.resource1Group:ComponentByName("img_", typeof(UISprite))
	self.labelResource1 = self.resource1Group:ComponentByName("label_", typeof(UILabel))
	self.addBtn = self.resource1Group:NodeByName("addBtn").gameObject
	self.clockGroup = self.groupAction:NodeByName("clockGroup").gameObject
	self.clock = self.clockGroup:NodeByName("clock").gameObject
	self.bg = self.clock:ComponentByName("bg", typeof(UISprite))
	self.bg2 = self.clock:ComponentByName("bg2", typeof(UISprite))
	self.pointer1 = self.clock:ComponentByName("pointer1", typeof(UISprite))
	self.clockItem = self.clock:NodeByName("clockItem").gameObject
	self.itemGroup = self.clock:NodeByName("itemGroup").gameObject
	self.effectGroup = self.groupAction:NodeByName("effectGroup").gameObject

	for i = 1, 3 do
		self["specialEffectPos" .. i] = self.effectGroup:NodeByName("specialEffectPos" .. i).gameObject
		self["normalEffectPos" .. i] = self.effectGroup:NodeByName("normalEffectPos" .. i).gameObject
	end

	self.refreshEffectPos = self.groupAction:NodeByName("refreshEffectPos").gameObject
	self.mask = self.groupAction:NodeByName("mask").gameObject
	self.clickmask = self.groupAction:NodeByName("clickmask").gameObject
	self.pointer2 = self.clock:ComponentByName("pointer2", typeof(UISprite))
	self.pointer3 = self.clock:ComponentByName("pointer3", typeof(UISprite))
	self.btnAward = self.groupAction:NodeByName("btnAward").gameObject
	self.labelAward = self.btnAward:ComponentByName("label", typeof(UILabel))
	self.redPoint = self.btnAward:ComponentByName("redPoint", typeof(UISprite))
	self.progressAwardGroup = self.groupAction:NodeByName("progressAwardGroup").gameObject
	self.btnProgressAward = self.progressAwardGroup:NodeByName("btnProgressAward").gameObject
	self.labelNextAward = self.progressAwardGroup:ComponentByName("labelNextAward", typeof(UILabel))
	self.icon1Pos = self.progressAwardGroup:NodeByName("icon1Pos").gameObject
	self.icon2Pos = self.progressAwardGroup:NodeByName("icon2Pos").gameObject
	self.progressAwardClickMask = self.progressAwardGroup:NodeByName("clickMask").gameObject
	self.numPos = self.groupAction:NodeByName("numPos").gameObject
	self.labelNumPos = self.numPos:ComponentByName("labelNumPos", typeof(UILabel))
end

function ActivityClock:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateResGroup()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id == xyd.ActivityID.ACTIVITY_CLOCK then
			self:onGetGambleMsg(event)
		end
	end)
	self:registerEvent(xyd.event.GET_CLOCK_AWARD, function (event)
		self:onGetTaskAward(event)
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_CLOCK_HELP"
		})
	end

	UIEventListener.Get(self.btnAwardPreview).onClick = function ()
		xyd.openWindow("activity_clock_award_preview_window")
		xyd.db.misc:setValue({
			key = "activity_clock_preview_time_stamp",
			value = xyd.getServerTime()
		})
		self:updateRedMark()
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		local data = self.activityData:getResource1()
		local params = {
			showGetWays = true,
			itemID = data[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.btnProgressAward).onClick = function ()
		local all_info = {}
		local ids = xyd.tables.activityClockAwardsTable:getIDs()

		for j in pairs(ids) do
			local data = {
				id = tonumber(j),
				max_value = xyd.tables.activityClockAwardsTable:getComplete(j)
			}
			data.name = __("ACTIVITY_CLOCK_AWARDS_TEXT01", math.floor(data.max_value))
			data.cur_value = tonumber(self.activityData:getCompleteTime())

			if data.max_value < data.cur_value then
				data.cur_value = data.max_value
			end

			data.items = xyd.tables.activityClockAwardsTable:getAwards(j)

			for i = 1, #data.items do
				if data.items[i][1] == 7255 or data.items[i][1] == 6755 then
					if not data.isNew then
						data.isNew = {}
					end

					data.isNew[i] = true
				end
			end

			if self.activityData:getAwardRecord(j) == 0 then
				if data.cur_value == data.max_value then
					data.state = 1
				else
					data.state = 2
				end
			else
				data.state = 3
			end

			table.insert(all_info, data)
		end

		xyd.WindowManager.get():openWindow("common_progress_award_window", {
			if_sort = true,
			all_info = all_info,
			title_text = __("ACTIVITY_CLOCK_TEXT02"),
			click_callBack = function (info)
				if self.activityData:getEndTime() <= xyd.getServerTime() then
					xyd.alertTips(__("ACTIVITY_END_YET"))

					return
				end

				self:GetTaskAward(info.id)
			end,
			wnd_type = xyd.CommonProgressAwardWindowType.ACTIVITY_CLOCK
		})
	end

	UIEventListener.Get(self.progressAwardClickMask).onClick = function ()
		local ids = xyd.tables.activityClockAwardsTable:getIDs()

		for j in pairs(ids) do
			local data = {
				id = tonumber(j),
				max_value = xyd.tables.activityClockAwardsTable:getComplete(j)
			}
			data.name = __("ACTIVITY_CLOCK_AWARDS_TEXT01", math.floor(data.max_value))
			data.cur_value = tonumber(self.activityData:getCompleteTime())

			if data.max_value < data.cur_value then
				data.cur_value = data.max_value
			end

			if self.activityData:getAwardRecord(j) == 0 and data.cur_value == data.max_value then
				data.state = 1

				self:GetTaskAward(data.id)

				return
			end
		end
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		for i = 1, 3 do
			if self.activityData:getChooseIndex(i) <= 0 and self.activityData:getRadio(i + (i - 1) * 2) > 0 then
				xyd.alertTips(__("ACTIVITY_CLOCK_CHOOSE_TIPS"))

				return
			end
		end

		local singleCost = self.activityData:getResource1()
		local resNum = xyd.models.backpack:getItemNumByID(singleCost[1])

		if resNum < singleCost[2] * self.pointerNum then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(singleCost[1])))

			return
		end

		local singleMaxTime = 80
		local canDrawTime = math.floor(resNum / (singleCost[2] * self.pointerNum))
		local select_max_num = math.min(canDrawTime, singleMaxTime)

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = select_max_num,
			show_max_num = xyd.models.backpack:getItemNumByID(singleCost[1]),
			select_multiple = singleCost[2] * self.pointerNum,
			icon_info = {
				height = 45,
				width = 45,
				name = xyd.tables.itemTable:getIcon(singleCost[1])
			},
			title_text = __("ACTIVITY_CLOCK_TEXT03"),
			explain_text = __("ACTIVITY_CLOCK_TEXT04"),
			sure_callback = function (num)
				self.activityData:reqGamble(num * self.pointerNum)

				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	end

	for i = 1, 3 do
		UIEventListener.Get(self["pointer" .. i].gameObject).onDrag = function (go, delta)
			local mouseLocalPos = xyd.mouseToLocalPos(self.clock.transform)
			local offY = mouseLocalPos.y
			local offX = mouseLocalPos.x

			if offY >= 0 then
				self["pointer" .. i].gameObject.transform.localEulerAngles = Vector3.New(0, 0, -math.deg(math.atan(offX / offY)))
			else
				self["pointer" .. i].gameObject.transform.localEulerAngles = Vector3.New(0, 0, -180 - math.deg(math.atan(offX / offY)))
			end
		end
	end
end

function ActivityClock:initUIComponent()
	self.labelAward.text = __("ACTIVITY_CLOCK_BUTTON01")
	self.labelNumPos.text = __("ACTIVITY_CLOCK_TEXT01")

	xyd.setUITextureByNameAsync(self.titleImg_, "activity_clock_logo_" .. xyd.Global.lang)

	if xyd.Global.lang == "fr_fr" then
		self.titleImg_.gameObject:SetLocalScale(0.93, 0.93, 1)
	end

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ja_jp" then
		self.titleImg_.gameObject:SetLocalScale(0.9, 0.9, 1)
	end

	local record = xyd.db.misc:getValue("activity_clock_pointer_num")
	self.pointerNum = tonumber(record) or 1

	self:changePointerNum()
	self:initEffect()
	self:updateResGroup()
	self:updateClockGroup()
	self:updateProgressAwardGroup()
	self:initNumPos()
	self:updateRedMark()
end

function ActivityClock:updateProgressAwardGroup()
	local ids = xyd.tables.activityClockAwardsTable:getIDs()
	local cur_value = tonumber(self.activityData:getCompleteTime())
	local nextID = nil
	local finish = false

	for id = 1, #ids do
		local needValue = xyd.tables.activityClockAwardsTable:getComplete(id)

		if self.activityData:getAwardRecord(id) == 0 then
			nextID = id

			if needValue <= cur_value then
				finish = true
			end

			break
		end
	end

	if nextID then
		local awards = xyd.tables.activityClockAwardsTable:getAwards(nextID)

		for i = 1, 2 do
			if i <= #awards then
				local params = {
					notShowGetWayBtn = true,
					scale = 0.6018518518518519,
					uiRoot = self["icon" .. i .. "Pos"],
					itemID = awards[i][1],
					num = awards[i][2],
					wndType = xyd.ItemTipsWndType.ACTIVITY
				}

				if self["progressAwardIcon" .. i] then
					self["progressAwardIcon" .. i]:SetActive(true)
					self["progressAwardIcon" .. i]:setInfo(params)
				else
					self["progressAwardIcon" .. i] = AdvanceIcon.new(params)
				end

				if finish then
					self["progressAwardIcon" .. i]:setEffect(true, "fx_ui_bp_available")
				else
					self["progressAwardIcon" .. i]:setEffect(false)
				end
			elseif self["progressAwardIcon" .. i] then
				self["progressAwardIcon" .. i]:SetActive(false)
			end
		end

		local leftTime = xyd.tables.activityClockAwardsTable:getComplete(nextID) - cur_value

		if finish then
			self.labelNextAward.text = __("ACTIVITY_CLOCK_AWARDS_TEXT03")
		else
			self.labelNextAward.text = __("ACTIVITY_CLOCK_AWARDS_TEXT02", leftTime)
		end

		self.progressAwardClickMask:SetActive(finish)
	else
		for i = 1, 2 do
			if self["progressAwardIcon" .. i] then
				self["progressAwardIcon" .. i]:SetActive(false)
			end
		end

		self.labelNextAward:SetActive(false)
		self.progressAwardGroup:ComponentByName("bg", typeof(UISprite)):SetActive(false)
		self.progressAwardClickMask:SetActive(false)
	end
end

function ActivityClock:updateClockGroup()
	local datas = {}
	local first = true
	local beforeRadio = -0.3333333333333333
	local normalCount = 1
	local specialCount = 1
	local round = self.activityData:getRound()
	local ids = self.activityData.detail.ids

	for i = 1, 9 do
		local radio = self.activityData:getRadio(i)

		if radio and radio > 0 and first then
			first = false
			beforeRadio = beforeRadio - radio / 2
		end

		local data = {
			index = i,
			isSpecial = i % 3 == 1,
			beforeRadio = beforeRadio,
			radio = radio
		}

		if data.isSpecial then
			data.id = ids[specialCount + 6]
			data.count = specialCount
			specialCount = specialCount + 1
		else
			data.id = ids[normalCount]
			data.count = normalCount
			normalCount = normalCount + 1
		end

		beforeRadio = beforeRadio + radio

		if not self.clockItems[i] then
			local itemObject = NGUITools.AddChild(self.itemGroup.gameObject, self.clockItem)
			local item = ActivityClockItem.new(itemObject, self)
			self.clockItems[i] = item
		end

		self.clockItems[i]:setInfo(data)
	end
end

function ActivityClock:updateResGroup()
	local res1Data = self.activityData:getResource1()

	xyd.setUISpriteAsync(self.imgResource1, nil, xyd.tables.itemTable:getIcon(res1Data[1]))

	self.labelResource1.text = xyd.models.backpack:getItemNumByID(res1Data[1])
end

function ActivityClock:initNumPos()
	local maxNum = 3
	local curNum = self.pointerNum
	self.pointerSelectNum = SelectNum.new(self.numPos, "default", {})

	self.pointerSelectNum:setInfo({
		noKeyBord = true,
		minNum = 1,
		notCallback = true,
		maxNum = maxNum,
		curNum = curNum,
		callback = function (num)
			self.pointerNum = num

			self:changePointerNum()
		end
	})
	self.pointerSelectNum:setFontSize(24, 24)
	self.pointerSelectNum:setKeyboardPos(0, 180)
	self.pointerSelectNum:setSelectBGSize(140, 40)
	self.pointerSelectNum:setBtnPos(120)
	self.pointerSelectNum:setSelectBGSprite("activity_clock_bg_srk")
end

function ActivityClock:changePointerNum()
	for i = 1, 3 do
		self["pointer" .. i]:SetActive(i <= self.pointerNum)

		local r = xyd.random(1, 36, {
			int = true
		}) * 10
	end

	xyd.db.misc:setValue({
		key = "activity_clock_pointer_num",
		value = self.pointerNum
	})
end

function ActivityClock:playGambleAniamtion(indexs)
	self.clickmask:SetActive(true)

	if self.pointerAnimation then
		self.pointerAnimation:Kill(true)

		self.pointerAnimation = nil
	end

	if not self.pointerAnimation then
		self.pointerAnimation = self:getSequence()
	end

	if self.pointerNum >= 1 then
		local radiao = self.clockItems[indexs[1]]:getCenterRadio()

		self.pointerAnimation:Insert(0, self.pointer1.gameObject.transform:DOLocalRotate(Vector3(0, 0, radiao - 1080), 1, DG.Tweening.RotateMode.FastBeyond360))
	end

	if self.pointerNum >= 2 then
		local radiao = self.clockItems[indexs[2]]:getCenterRadio()

		self.pointerAnimation:Insert(0.1, self.pointer2.gameObject.transform:DOLocalRotate(Vector3(0, 0, radiao - 1080), 1.1, DG.Tweening.RotateMode.FastBeyond360))
	end

	if self.pointerNum >= 3 then
		local radiao = self.clockItems[indexs[3]]:getCenterRadio()

		self.pointerAnimation:Insert(0.2, self.pointer3.gameObject.transform:DOLocalRotate(Vector3(0, 0, radiao - 1080), 1.2, DG.Tweening.RotateMode.FastBeyond360))
	end

	self.pointerAnimation:AppendCallback(function ()
		for i = 1, self.pointerNum do
			if self.clockItems[indexs[i]]:IsSpecial() then
				self["specialEffectPos" .. i]:SetActive(true)

				self["specialEffectPos" .. i].gameObject.transform.position = self.clockItems[indexs[i]]:getIconPosition()
				self["specialEffectPos" .. i].gameObject.transform.eulerAngles = self.clockItems[indexs[i]]:getIconEulerAngle()

				self["specialEffect" .. i]:play("good", 1, 1, function ()
					if i == self.pointerNum then
						for j = 1, 3 do
							self["specialEffectPos" .. j]:SetActive(false)
							self["normalEffectPos" .. j]:SetActive(false)
						end

						self.clickmask:SetActive(false)
						self:showAward()
					end
				end)
			else
				self["normalEffectPos" .. i]:SetActive(true)

				self["normalEffectPos" .. i].gameObject.transform.position = self.clockItems[indexs[i]]:getIconPosition()
				self["normalEffectPos" .. i].gameObject.transform.eulerAngles = self.clockItems[indexs[i]]:getIconEulerAngle()

				self["normalEffect" .. i]:play("normal", 1, 1, function ()
					if i == self.pointerNum then
						for j = 1, 3 do
							self["specialEffectPos" .. j]:SetActive(false)
							self["normalEffectPos" .. j]:SetActive(false)
						end

						self.clickmask:SetActive(false)
						self:showAward()
					end
				end)
			end
		end
	end)
end

function ActivityClock:initEffect()
	self.refreshEffectPos:SetActive(false)

	if not self.refreshEffect then
		self.refreshEffect = xyd.Spine.new(self.refreshEffectPos.gameObject)

		self.refreshEffect:setInfo("clock_refresh", function ()
			self.refreshEffect:play("refresh", 1)
		end)
	end

	for i = 1, 3 do
		if not self["specialEffect" .. i] then
			self["specialEffect" .. i] = xyd.Spine.new(self["specialEffectPos" .. i].gameObject)

			self["specialEffect" .. i]:setInfo("clock_awards", function ()
				self["specialEffectPos" .. i]:SetActive(false)
				self["specialEffect" .. i]:play("good", 1)
			end)
		end

		if not self["normalEffect" .. i] then
			self["normalEffect" .. i] = xyd.Spine.new(self["normalEffectPos" .. i].gameObject)

			self["normalEffect" .. i]:setInfo("clock_awards", function ()
				self["normalEffectPos" .. i]:SetActive(false)
				self["normalEffect" .. i]:play("normal", 1)
			end)
		end
	end
end

function ActivityClock:showAward()
	xyd.MainController.get():removeEscListener()

	local function callback()
		if self.multyFlag and #self.tempAlertInfos > 0 then
			xyd.models.itemFloatModel:pushNewItems(self.tempAlertInfos)
		end

		if self.multyFlag and #self.tempInfos <= 0 then
			self.activityData:updateGambleData()
			self:updateClockGroup()
			self:updateProgressAwardGroup()
			self:updateRedMark()
			xyd.MainController.get():addEscListener()
		else
			xyd.openWindow("gamble_rewards_window", {
				wnd_type = 4,
				isNeedCostBtn = false,
				data = self.tempInfos,
				btnLabelText = __("SURE"),
				sureCallback = function ()
					if self.isNextRound then
						local function callback2()
							xyd.models.itemFloatModel:pushNewItems(self.tempNormalInfos)
							self:waitForTime(0.5, function ()
								self.mask:SetActive(true)
								self.refreshEffectPos:SetActive(true)
								self.activityData:updateGambleData()
								self:updateClockGroup()
								self:updateProgressAwardGroup()
								self:updateRedMark()
								xyd.MainController.get():addEscListener()
								self.refreshEffect:play("refresh", 1, 1, function ()
									self.mask:SetActive(false)
									self.refreshEffectPos:SetActive(false)
								end)
							end)
						end

						xyd.alert(xyd.AlertType.CONFIRM, __("ACTIVITY_CLOCK_AWARD_GET"), callback2, __("SURE"), nil, , , , callback2)

						local wnd = xyd.getWindow("alert_window")

						if wnd then
							wnd:setDescWidth(550)
						end
					else
						self.activityData:updateGambleData()
						self:updateClockGroup()
						self:updateProgressAwardGroup()
						self:updateRedMark()
						xyd.MainController.get():addEscListener()
					end

					xyd.closeWindow("gamble_rewards_window")
				end
			})
		end
	end

	local skins = {}

	for i = 1, #self.tempInfos do
		local item = self.tempInfos[i]
		local type = xyd.tables.itemTable:getType(item.item_id)

		if type == xyd.ItemType.SKIN then
			table.insert(skins, item.item_id)
		end
	end

	if #skins > 0 then
		xyd.onGetNewPartnersOrSkins({
			destory_res = false,
			skins = skins,
			callback = callback
		})
	else
		callback()
	end
end

function ActivityClock:updateRedMark()
	if self.activityData:getRedMarkState() then
		self.btnProgressAward:NodeByName("redPoint"):SetActive(self.activityData:checkRedMarkOfProgressAward())
		self.btnAwardPreview:NodeByName("redPoint"):SetActive(self.activityData:checkRedMarkOfAwardPreview())
		self.btnAward:NodeByName("redPoint"):SetActive(self.activityData:checkRedMarkOfGamble())
	end
end

function ActivityClock:GetTaskAward(id)
	self.AwardedTaskID = id
	local msg = messages_pb.get_clock_award_req()
	msg.id = id
	msg.activity_id = xyd.ActivityID.ACTIVITY_CLOCK

	xyd.Backend.get():request(xyd.mid.GET_CLOCK_AWARD, msg)
end

function ActivityClock:onGetTaskAward(event)
	local data = event.data
	local items = xyd.tables.activityClockAwardsTable:getAwards(self.AwardedTaskID)
	local haveSkin = nil
	local infos = {}

	for key, value in pairs(items) do
		local item = {
			item_id = value[1],
			item_num = value[2]
		}

		table.insert(infos, item)

		if value[1] == 7255 then
			haveSkin = value[1]
		end
	end

	if haveSkin then
		xyd.WindowManager.get():openWindow("summon_effect_res_window", {
			skins = {
				haveSkin
			},
			callback = function ()
				xyd.models.itemFloatModel:pushNewItems(infos)

				local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

				if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_CLOCK then
					common_progress_award_window_wn:updateItemState(tonumber(self.AwardedTaskID), 3)
				end

				self:updateProgressAwardGroup()
				self:updateRedMark()
			end
		})
	else
		xyd.models.itemFloatModel:pushNewItems(infos)

		local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

		if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_CLOCK then
			common_progress_award_window_wn:updateItemState(tonumber(self.AwardedTaskID), 3)
		end

		self:updateProgressAwardGroup()
		self:updateRedMark()
	end
end

function ActivityClock:onGetGambleMsg(event)
	local details = require("cjson").decode(event.data.detail)
	local award_ids = details.award_ids
	local indexs = {}

	if #award_ids <= 3 then
		for i = 1, #award_ids do
			for j = 1, 9 do
				if award_ids[i] == self.activityData.detail.ids[j] then
					local realIndex = 0

					if j <= 6 then
						realIndex = j + math.ceil(j / 2)
					else
						realIndex = (j - 7) * 2 + j - 6
					end

					table.insert(indexs, realIndex)
				end
			end
		end

		self.tempInfos = self.activityData:getGambleAward()
		self.isNextRound = details.next_flag

		if self.isNextRound then
			self.tempNormalInfos = self.activityData:getRoundAward()
		end

		self.multyFlag = false
	else
		for i = 1, #award_ids do
			for j = 7, 9 do
				if award_ids[i] == self.activityData.detail.ids[j] then
					local realIndex = 0
					realIndex = (j - 7) * 2 + j - 6

					table.insert(indexs, realIndex)
				end
			end
		end

		if self.pointerNum > #indexs then
			for i = 1, #award_ids do
				for j = 1, 6 do
					if award_ids[i] == self.activityData.detail.ids[j] then
						local realIndex = 0
						realIndex = j + math.ceil(j / 2)

						table.insert(indexs, realIndex)
					end

					if self.pointerNum <= #indexs then
						break
					end
				end

				if self.pointerNum <= #indexs then
					break
				end
			end
		end

		local gambleAwards = self.activityData:getGambleAward()
		self.tempInfos = {}
		self.tempAlertInfos = {}

		for i = 1, #gambleAwards do
			if gambleAwards[i].cool then
				table.insert(self.tempInfos, gambleAwards[i])
			else
				table.insert(self.tempAlertInfos, gambleAwards[i])
			end
		end

		self.isNextRound = details.next_flag

		if self.isNextRound then
			self.tempNormalInfos = self.activityData:getRoundAward()
		end

		self.multyFlag = true
	end

	if self.pointerNum > #indexs then
		self.pointerNum = #indexs

		self.pointerSelectNum:setCurNum(self.pointerNum)
		self:changePointerNum()
	end

	self:playGambleAniamtion(indexs)
	self:updateRedMark()
end

function ActivityClock:dispose()
	ActivityClock.super.dispose(self)
	self.activityData:updateGambleData()
	self:updateRedMark()
end

function ActivityClockItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	ActivityClockItem.super.ctor(self, go)
	self:initUI()
end

function ActivityClockItem:initUI()
	self:getUIComponent()
end

function ActivityClockItem:getUIComponent()
	self.specialGroup = self.go:NodeByName("specialGroup").gameObject
	self.specialIconPos = self.specialGroup:NodeByName("iconPos").gameObject
	self.btnChoose = self.specialGroup:NodeByName("btnChoose").gameObject
	self.btnExchange = self.specialGroup:NodeByName("btnExchange").gameObject
	self.img = self.go:ComponentByName("img", typeof(UISprite))
	self.line = self.go:ComponentByName("line", typeof(UISprite))
	self.normalIconPos = self.go:NodeByName("iconPos").gameObject
	self.leftTimeGroup = self.go:NodeByName("leftTimeGroup").gameObject
	self.label = self.leftTimeGroup:ComponentByName("label", typeof(UILabel))
end

function ActivityClockItem:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.params = params
	self.index = params.index
	self.id = params.id
	self.count = params.count
	self.radio = params.radio
	self.beforeRadio = params.beforeRadio
	self.isSpecial = params.isSpecial

	if self.isSpecial then
		self.chooseIndex = self.parent.activityData:getChooseIndex(self.count)

		if self.chooseIndex and self.chooseIndex > #xyd.tables.activityClockGambleTable:getAwards(self.id) then
			self.parent.activityData:selectSpecialAward(self.count, 0)

			self.chooseIndex = 0
		end

		if (not self.chooseIndex or self.chooseIndex <= 0) and #xyd.tables.activityClockGambleTable:getAwards(self.id) == 1 then
			self.parent.activityData:selectSpecialAward(self.count, 1)

			self.chooseIndex = self.parent.activityData:getChooseIndex(self.count)
		end
	end

	if not self.radio or self.radio <= 0 then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if not self.initDepth then
		self.img.depth = self.img.depth - self.index
	end

	self.specialGroup:SetActive(self.isSpecial)

	if self.isSpecial then
		if self.chooseIndex and self.chooseIndex > 0 then
			self.award = xyd.tables.activityClockGambleTable:getAwards(self.id)[self.chooseIndex]

			self.specialIconPos:SetActive(true)
			self.btnExchange:SetActive(#xyd.tables.activityClockGambleTable:getAwards(self.id) > 1)
		else
			self.award = nil

			self.specialIconPos:SetActive(false)
			self.btnExchange:SetActive(false)
		end

		self.leftTimeGroup:SetActive(false)
		xyd.setUISpriteAsync(self.img, nil, "activity_clock_bg_zp_ts")

		if not self.initBtnChoose then
			self.initBtnChoose = true

			UIEventListener.Get(self.btnChoose).onClick = function ()
				local awards = xyd.tables.activityClockGambleTable:getAwards(self.id)

				xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
					items = awards,
					sureCallback = function (index)
						self.parent.activityData:selectSpecialAward(self.count, index)
						self:setInfo(self.params)
					end,
					buttomTitleText = __("ACTIVITY_CLOCK_CHOOSE"),
					titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
					sureBtnText = __("SURE"),
					cancelBtnText = __("CANCEL"),
					tipsText = __(""),
					selectedIndex = self.parent.activityData:getChooseIndex(self.count)
				})
			end

			UIEventListener.Get(self.btnExchange).onClick = function ()
				local awards = xyd.tables.activityClockGambleTable:getAwards(self.id)

				xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
					items = awards,
					sureCallback = function (index)
						self.parent.activityData:selectSpecialAward(self.count, index)
						self:setInfo(self.params)
					end,
					buttomTitleText = __("ACTIVITY_CLOCK_CHOOSE"),
					titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
					sureBtnText = __("SURE"),
					cancelBtnText = __("CANCEL"),
					tipsText = __(""),
					selectedIndex = self.parent.activityData:getChooseIndex(self.count)
				})
			end
		end
	else
		self.award = xyd.tables.activityClockGambleTable:getAwards(self.id)[1]

		self.leftTimeGroup:SetActive(true)

		self.label.text = self.parent.activityData:getLeftTime(self.count)

		if not self.parent.imgIndex then
			self.parent.imgIndex = 1
		end

		xyd.setUISpriteAsync(self.img, nil, "activity_clock_bg_zp_ts" .. self.parent.imgIndex)

		self.parent.imgIndex = (self.parent.imgIndex + 2) % 2 + 1
	end

	if self.award then
		local params1 = {
			notShowGetWayBtn = true,
			scale = 0.8518518518518519,
			uiRoot = self.normalIconPos,
			itemID = self.award[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			num = self.award[2]
		}

		if self.isSpecial then
			params1.uiRoot = self.specialIconPos
		end

		if self.awardIcon then
			self.awardIcon:SetActive(true)
			self.awardIcon:setInfo(params1)
		else
			self.awardIcon = AdvanceIcon.new(params1)
		end
	end

	self.img.fillAmount = self.radio
	self.line.gameObject.transform.localEulerAngles = Vector3.New(0, 0, -self.radio * 360 / 2)
	self.img.gameObject.transform.localEulerAngles = Vector3.New(0, 0, self.radio * 360 / 2)
	self.go.gameObject.transform.localEulerAngles = Vector3.New(0, 0, -self.beforeRadio * 360 - self.radio * 360 / 2)
	self.normalIconPos.gameObject.transform.localEulerAngles = Vector3.New(0, 0, self.beforeRadio * 360 + self.radio * 360 / 2)
end

function ActivityClockItem:getCenterRadio()
	return -self.beforeRadio * 360 - self.radio * 360 / 2 - xyd.random(-self.radio * 360 / 4, self.radio * 360 / 4)
end

function ActivityClockItem:getUIRoot()
	return self.go
end

function ActivityClockItem:IsSpecial()
	return self.isSpecial
end

function ActivityClockItem:getIconPosition()
	if self:IsSpecial() then
		return self.specialIconPos.gameObject.transform.position
	else
		return self.normalIconPos.gameObject.transform.position
	end
end

function ActivityClockItem:getIconEulerAngle()
	if self:IsSpecial() then
		return self.specialIconPos.gameObject.transform.eulerAngles
	else
		return self.normalIconPos.gameObject.transform.eulerAngles
	end
end

return ActivityClock
