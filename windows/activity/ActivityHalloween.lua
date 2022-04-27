local effectGhostPositionParam = {
	{
		-88,
		-654
	},
	{
		72,
		-561
	},
	{
		-99,
		-430
	},
	{
		119,
		-393
	},
	{
		-30,
		-273
	},
	{
		165,
		-260
	}
}
local effectGhostScaleParam = {
	0.38,
	0.36,
	0.32,
	0.28,
	0.24,
	0.22
}
local windowType = {
	mainWindow = 1,
	trickWindow = 2
}
local ActivityHalloween = class("ActivityHalloween", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityHalloween:ctor(parentGO, params)
	ActivityHalloween.super.ctor(self, parentGO, params)
end

function ActivityHalloween:getPrefabPath()
	return "Prefabs/Windows/activity/activity_halloween"
end

function ActivityHalloween:resizeToParent()
	ActivityHalloween.super.resizeToParent(self)
	self:resizePosY(self.imgText, -381, -518)
	self:resizePosY(self.imgTime, -654, -791)
	self:resizePosY(self.timeGroup, -654, -791)
	self:resizePosY(self.goTrick, -755, -892)
	self:resizePosY(self.goMission, -754, -891)
	self:resizePosY(self.progressBar, -743, -920)
	self:resizePosY(self.btnTrick1, -817, -994)
	self:resizePosY(self.btnTrick10, -817, -994)
	self:resizePosY(self.btnBack, -775, -952)
	self:resizePosY(self.progressAward, -730, -907)
	self:resizePosY(self.resizeToParentGroup, 0, -88)
	self:resizePosY(self.trickBg, 88, 0)
	self:resizePosY(self.stagePlaces, 0, -88)
	self:resizePosY(self.awardPlaces, 0, -88)
end

function ActivityHalloween:getSequence(complete)
	local sequence = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		if complete then
			complete()
		end
	end)

	if not self.sequence_ then
		self.sequence_ = {}
	end

	table.insert(self.sequence_, sequence)

	return sequence
end

function ActivityHalloween:dispose()
	ActivityHalloween.super.dispose(self)

	if self.sequence_ then
		for i = 1, #self.sequence_ do
			if self.sequence_[i] then
				self.sequence_[i]:Kill(false)

				self.sequence_[i] = nil
			end
		end
	end
end

function ActivityHalloween:initUI()
	self.skipAni = xyd.db.misc:getValue("trickortreat_skipani")
	self.skipAni = self.skipAni and xyd.isToday(self.skipAni) or false

	self:getUIComponent()
	ActivityHalloween.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityHalloween:getUIComponent()
	local go = self.go
	self.resItem = go:ComponentByName("resItem", typeof(UISprite))
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.resPlus = self.resItem:NodeByName("plus").gameObject
	self.btnHelp = go:NodeByName("btnHelp").gameObject
	self.btnAward = go:NodeByName("btnAward").gameObject
	self.btnAwardRedPoint = self.btnAward:NodeByName("redPoint").gameObject
	self.mainWindow = go:NodeByName("mainWindow").gameObject
	self.imgText = self.mainWindow:ComponentByName("imgText", typeof(UISprite))
	self.imgTime = self.mainWindow:NodeByName("imgTime").gameObject
	self.timeGroup = self.mainWindow:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.goTrick = self.mainWindow:NodeByName("goTrick").gameObject
	self.goTrickRedPoint = self.goTrick:NodeByName("redPoint").gameObject
	self.labelTrick = self.goTrick:ComponentByName("labelTrick", typeof(UILabel))
	self.goMission = self.mainWindow:NodeByName("goMission").gameObject
	self.labelMission = self.goMission:ComponentByName("labelMission", typeof(UILabel))
	self.trickWindow = go:NodeByName("trickWindow").gameObject
	self.trickBg = self.trickWindow:NodeByName("trickBg").gameObject
	self.groupPreview = self.trickWindow:NodeByName("groupPreview").gameObject
	self.labelPreview = self.groupPreview:ComponentByName("labelPreview", typeof(UILabel))
	self.awardPreview = self.groupPreview:NodeByName("awardPreview").gameObject
	self.btnShop = self.trickWindow:NodeByName("btnShop").gameObject
	self.btnShopRedPoint = self.btnShop:NodeByName("redPoint").gameObject
	self.progressBar = self.trickWindow:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.progressAward = self.trickWindow:NodeByName("progressAward").gameObject
	self.btnTrick1 = self.trickWindow:NodeByName("btnTrick1").gameObject
	self.btnTrick1Label = self.btnTrick1:ComponentByName("label", typeof(UILabel))
	self.btnTrick1RedPoint = self.btnTrick1:NodeByName("redPoint").gameObject
	self.btnTrick10 = self.trickWindow:NodeByName("btnTrick10").gameObject
	self.btnTrick10Label = self.btnTrick10:ComponentByName("label", typeof(UILabel))
	self.btnTrick10RedPoint = self.btnTrick10:NodeByName("redPoint").gameObject
	self.btnBack = self.trickWindow:NodeByName("btnBack").gameObject
	self.stagePlaces = self.trickWindow:NodeByName("stagePlaces").gameObject

	for i = 1, 6 do
		self["stagePlace" .. i] = self.stagePlaces:NodeByName("stage" .. i).gameObject
	end

	self.awardPlaces = self.trickWindow:NodeByName("awardPlaces").gameObject

	for i = 1, 6 do
		self["awardPlace" .. i] = self.awardPlaces:ComponentByName("award" .. i, typeof(UIWidget))
		self["awardIconPlace" .. i] = self["awardPlace" .. i]:ComponentByName("icon", typeof(UISprite))
		self["awardNumPlace" .. i] = self["awardPlace" .. i]:ComponentByName("num", typeof(UILabel))
	end

	self.resizeToParentGroup = go:NodeByName("resizeToParentGroup").gameObject
	self.effect = self.resizeToParentGroup:NodeByName("effect").gameObject
	self.mask = go:NodeByName("mask").gameObject
end

function ActivityHalloween:initUIComponent()
	self.mask:SetActive(false)

	self.windowType = windowType.mainWindow
	self.curStage = self.activityData.detail.stage
	self.progressBarMaxValue = xyd.tables.miscTable:getNumber("activity_trickortreat_point_full", "value")

	xyd.setUISpriteAsync(self.imgText, nil, "activity_halloween_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.GHOST_POTION)
	self.endLabel.text = __("END")
	self.labelTrick.text = __("ACTIVITY_TRICKORTREAT_BUTTON01")
	self.labelMission.text = __("ACTIVITY_TRICKORTREAT_BUTTON02")
	self.btnTrick1Label.text = __("ACTIVITY_TRICKORTREAT_BUTTON03")
	self.btnTrick10Label.text = __("ACTIVITY_TRICKORTREAT_BUTTON04")

	if xyd.Global.lang == "fr_fr" then
		self.labelPreview.height = 28

		self.awardPreview:Y(-20)
	end

	self:updateProgressBar()
	self:updateAwardPreview()
	self:updateRedPoint()
	self.trickWindow:SetActive(false)

	self.effectGhost = xyd.Spine.new(self.effect)

	self.effectGhost:setInfo("fx_trick_ghost", function ()
		self.effectGhost:play("idle", 0)
		self.effect:SetLocalScale(effectGhostScaleParam[self.curStage], effectGhostScaleParam[self.curStage], 1)
		self.effect:SetLocalPosition(effectGhostPositionParam[self.curStage][1], effectGhostPositionParam[self.curStage][2], 0)

		if self.windowType == windowType.mainWindow then
			self.effect:SetActive(false)
		end
	end)
end

function ActivityHalloween:updateRedPoint()
	self.activityData.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_HALLOWEEN, function ()
		self.activityData.holdRed = false
	end)

	local itemRed1 = false
	local itemRed10 = false
	local awardRed = false
	local shopRed = false

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.GHOST_POTION) >= 1 then
		itemRed1 = true
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.GHOST_POTION) >= 10 then
		itemRed10 = true
	end

	local awardIDs = xyd.tables.activityHalloweenTrickAwardTable:getIDs()

	for i = 1, #awardIDs do
		if xyd.tables.activityHalloweenTrickAwardTable:getComplete(i) <= self.activityData.detail.times and self.activityData.detail.awards[i] == 0 then
			awardRed = true
		end
	end

	local shopIDs = xyd.tables.activityHalloweenShopTable:getIDs()

	for i = 1, #shopIDs do
		local cost = xyd.tables.activityHalloweenShopTable:getCost(i)

		if self.activityData.detail.buy_times[i] < xyd.tables.activityHalloweenShopTable:getLimit(i) and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
			shopRed = true
		end
	end

	self.goTrickRedPoint:SetActive(itemRed1 or awardRed or shopRed)
	self.btnAwardRedPoint:SetActive(awardRed)
	self.btnShopRedPoint:SetActive(shopRed)
	self.btnTrick1RedPoint:SetActive(itemRed1)
	self.btnTrick10RedPoint:SetActive(itemRed10)
end

function ActivityHalloween:updateProgressBar()
	self.progressBar.value = self.activityData.detail.point / self.progressBarMaxValue
	self.progressLabel.text = self.activityData.detail.point .. "/" .. self.progressBarMaxValue

	if self.progressAwardSeq1 then
		self.progressAwardSeq1 = nil
	end

	if self.progressAwardSeq2 then
		self.progressAwardSeq2 = nil
	end

	if self.sequence1 then
		self.sequence1:Kill()

		self.sequence1 = nil
	end

	if self.sequence2 then
		self.sequence2:Kill()

		self.sequence2 = nil
	end

	local sequence = self:getSequence()

	sequence:Insert(0, self.progressAward.transform:DORotate(Vector3(0, 0, 0), 0.1))
	NGUITools.DestroyChildren(self.progressAward.transform)

	local award = xyd.tables.miscTable:split2Cost("activity_trickortreat_point_award", "value", "|#")[1]
	local itemIcon = xyd.getItemIcon({
		noClick = true,
		scale = 0.6296296296296297,
		uiRoot = self.progressAward.gameObject,
		itemID = award[1],
		num = award[2]
	})

	if self.progressBarMaxValue <= self.activityData.detail.point then
		itemIcon:setEffect(true, "fx_ui_bp_available")

		function self.progressAwardSeq1()
			self.sequence1 = self:getSequence()

			self.sequence1:Insert(0, self.progressAward.transform:DORotate(Vector3(0, 0, 4), 1))
			self.sequence1:AppendCallback(function ()
				if self.progressAwardSeq2 then
					self.progressAwardSeq2()
				end
			end)
		end

		function self.progressAwardSeq2()
			self.sequence2 = self:getSequence()

			self.sequence2:Insert(0, self.progressAward.transform:DORotate(Vector3(0, 0, -4), 1))
			self.sequence2:AppendCallback(function ()
				if self.progressAwardSeq1 then
					self.progressAwardSeq1()
				end
			end)
		end

		self.progressAwardSeq1()
	end
end

function ActivityHalloween:updateAwardPreview()
	self.checkAward = false
	self.previewShowID = 0
	local ids = xyd.tables.activityHalloweenTrickAwardTable:getIDs()

	for i = 1, #ids do
		if self.activityData.detail.awards[i] == 0 then
			if xyd.tables.activityHalloweenTrickAwardTable:getComplete(i) <= self.activityData.detail.times then
				self.checkAward = true
			end

			self.previewShowID = i

			break
		end
	end

	if self.previewShowID == 0 then
		self.groupPreview:SetActive(false)
	else
		if self.checkAward == true then
			self.labelPreview.text = __("ACTIVITY_TRICKORTREAT_TEXT02")
		else
			self.labelPreview.text = __("ACTIVITY_TRICKORTREAT_TEXT01", xyd.tables.activityHalloweenTrickAwardTable:getComplete(self.previewShowID) - self.activityData.detail.times)
		end

		NGUITools.DestroyChildren(self.awardPreview.transform)

		local awards = xyd.tables.activityHalloweenTrickAwardTable:getAwards(self.previewShowID)

		for i = 1, #awards do
			local award = awards[i]
			local itemIcon = xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				scale = 0.6018518518518519,
				uiRoot = self.awardPreview.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				noClick = self.checkAward
			})

			if self.checkAward == true then
				itemIcon:setEffect(true, "fx_ui_bp_available")
			end
		end

		self.awardPreview:GetComponent(typeof(UILayout)):Reposition()
	end
end

function ActivityHalloween:playTrick(event, i)
	self.mask:SetActive(true)

	local seq = self:getSequence(function ()
		self["awardPlace" .. self.curStage]:SetActive(false)

		if self.curStage == event.data.stages[i] then
			if #event.data.stages == 1 and self.curStage ~= 1 then
				xyd.alertTips(__("ACTIVITY_TRICKORTREAT_TIPS"))
			end

			if i == #event.data.stages then
				xyd.openWindow("gamble_rewards_window", {
					isNeedOptionalBox = true,
					wnd_type = 4,
					data = self.trickAwards,
					cost = {
						xyd.ItemID.GHOST_POTION,
						#event.data.indexes
					},
					btnLabelText = #event.data.indexes == 1 and "ACTIVITY_TRICKORTREAT_BUTTON03" or "ACTIVITY_TRICKORTREAT_BUTTON04",
					buyCallback = function ()
						local cost = xyd.tables.miscTable:split2Cost("activity_trickortreat_cost", "value", "|#")[1]

						if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] * #event.data.indexes then
							xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

							return
						end

						local msg = messages_pb:trickortreat_get_rand_award_req()
						msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN
						msg.num = #event.data.indexes

						xyd.Backend.get():request(xyd.mid.TRICKORTREAT_GET_RAND_AWARD, msg)
					end,
					optionalBoxTextSize = xyd.Global.lang == "fr_fr" and 19 or nil,
					optionalBoxText = __("ACTIVITY_TRICKORTREAT_AWARDS_JUMP"),
					optionalBoxCallBack = function (value)
						if value then
							xyd.db.misc:setValue({
								key = "trickortreat_skipani",
								value = xyd.getServerTime()
							})

							self.skipAni = true
						end
					end
				})
				self.mask:SetActive(false)
			else
				self:playTrick(event, i + 1)
			end
		else
			self.effectGhost:play("walk", 0)

			local seq1 = self:getSequence(function ()
				self.effectGhost:play("idle", 0)

				self.curStage = event.data.stages[i]

				if i == #event.data.stages then
					slot2.btnLabelText = #event.data.indexes == 1 and "ACTIVITY_TRICKORTREAT_BUTTON03" or "ACTIVITY_TRICKORTREAT_BUTTON04"

					function slot2.buyCallback()
						local cost = xyd.tables.miscTable:split2Cost("activity_trickortreat_cost", "value", "|#")[1]

						if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] * #event.data.indexes then
							xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

							return
						end

						local msg = messages_pb:trickortreat_get_rand_award_req()
						msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN
						msg.num = #event.data.indexes

						xyd.Backend.get():request(xyd.mid.TRICKORTREAT_GET_RAND_AWARD, msg)
					end

					slot2.optionalBoxTextSize = xyd.Global.lang == "fr_fr" and 19 or nil
					slot2.optionalBoxText = __("ACTIVITY_TRICKORTREAT_AWARDS_JUMP")

					function slot2.optionalBoxCallBack(value)
						if value then
							xyd.db.misc:setValue({
								key = "trickortreat_skipani",
								value = xyd.getServerTime()
							})

							self.skipAni = true
						end
					end

					xyd.openWindow("gamble_rewards_window", {
						isNeedOptionalBox = true,
						wnd_type = 4,
						data = self.trickAwards,
						cost = {
							xyd.ItemID.GHOST_POTION,
							#event.data.indexes
						}
					})
					self.mask:SetActive(false)
				else
					self:playTrick(event, i + 1)
				end
			end)

			seq1:Insert(0, self.effect.transform:DOLocalMove(Vector3(effectGhostPositionParam[event.data.stages[i]][1], effectGhostPositionParam[event.data.stages[i]][2], 0), 1))
			seq1:Insert(0, self.effect.transform:DOScale(Vector3(effectGhostScaleParam[event.data.stages[i]], effectGhostScaleParam[event.data.stages[i]], 0), 1))
		end
	end)

	self["awardPlace" .. self.curStage]:SetActive(true)

	local award = xyd.tables.activityTrickortreatTable:getAwards(self.curStage)[event.data.indexes[i]]

	table.insert(self.trickAwards, {
		item_id = award[1],
		item_num = award[2]
	})

	if event.data.indexes[i] == 1 then
		self.trickAwards[i].cool = 1
	end

	xyd.setUISpriteAsync(self["awardIconPlace" .. self.curStage], nil, xyd.tables.itemTable:getIcon(award[1]))

	self["awardNumPlace" .. self.curStage].text = "x" .. tostring(award[2])

	local function setter(value)
		self["awardPlace" .. self.curStage].alpha = value
	end

	self["awardPlace" .. self.curStage].alpha = 0

	seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.5))
	seq:Insert(0.5, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.5))
end

function ActivityHalloween:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.GHOST_POTION)
	end)
	self:registerEvent(xyd.event.BOSS_BUY, function (event)
		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = xyd.ItemID.GHOST_POTION,
				item_num = event.data.buy_times
			}
		})

		self.activityData.detail.limit = self.activityData.detail.limit + event.data.buy_times

		self:updateRedPoint()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function ()
		self:updateRedPoint()
	end)
	self:registerEvent(xyd.event.TRICKORTREAT_GET_AWARDS, function ()
		self:updateAwardPreview()
		self:updateRedPoint()
	end)
	self:registerEvent(xyd.event.TRICKORTREAT_GET_POINT_AWARD, function (event)
		local awardNum = math.floor(self.activityData.detail.point / self.progressBarMaxValue)
		self.activityData.detail.point = event.data.point

		self:updateProgressBar()

		local award = xyd.tables.miscTable:split2Cost("activity_trickortreat_point_award", "value", "|#")[1]

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = award[1],
				item_num = award[2] * awardNum
			}
		})
	end)
	self:registerEvent(xyd.event.TRICKORTREAT_GET_RAND_AWARD, function (event)
		self.activityData.detail.stage = event.data.stages[#event.data.stages]
		self.activityData.detail.point = event.data.point
		self.activityData.detail.times = self.activityData.detail.times + #event.data.stages

		self:updateRedPoint()
		self:updateAwardPreview()
		self:updateProgressBar()

		self.trickAwards = {}

		if self.skipAni == true then
			if #event.data.indexes == 1 and self.curStage ~= 1 and self.curStage == event.data.stages[#event.data.indexes] then
				xyd.alertTips(__("ACTIVITY_TRICKORTREAT_TIPS"))
			end

			for i in ipairs(event.data.indexes) do
				local award = xyd.tables.activityTrickortreatTable:getAwards(self.curStage)[event.data.indexes[i]]

				table.insert(self.trickAwards, {
					item_id = award[1],
					item_num = award[2]
				})

				if event.data.indexes[i] == 1 then
					self.trickAwards[i].cool = 1
				end

				self.curStage = event.data.stages[i]
			end

			xyd.openWindow("gamble_rewards_window", {
				wnd_type = 4,
				data = self.trickAwards,
				cost = {
					xyd.ItemID.GHOST_POTION,
					#event.data.indexes
				},
				btnLabelText = #event.data.indexes == 1 and "ACTIVITY_TRICKORTREAT_BUTTON03" or "ACTIVITY_TRICKORTREAT_BUTTON04",
				buyCallback = function ()
					local cost = xyd.tables.miscTable:split2Cost("activity_trickortreat_cost", "value", "|#")[1]

					if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] * #event.data.indexes then
						xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

						return
					end

					local msg = messages_pb:trickortreat_get_rand_award_req()
					msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN
					msg.num = #event.data.indexes

					xyd.Backend.get():request(xyd.mid.TRICKORTREAT_GET_RAND_AWARD, msg)
				end
			})

			self.effect.transform.localPosition = Vector3(effectGhostPositionParam[self.curStage][1], effectGhostPositionParam[self.curStage][2], 0)
			self.effect.transform.localScale = Vector3(effectGhostScaleParam[self.curStage], effectGhostScaleParam[self.curStage], 0)
		else
			self:playTrick(event, 1)
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function ()
		self:updateRedPoint()
	end)

	UIEventListener.Get(self.resPlus).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			activityData = self.activityData.detail,
			itemID = xyd.ItemID.GHOST_POTION,
			activityID = xyd.ActivityID.ACTIVITY_HALLOWEEN,
			openItemBuyWnd = function ()
				local limit = xyd.tables.miscTable:getNumber("activity_trickortreat_buy_limit", "value")

				if limit <= self.activityData.detail.limit then
					xyd.alertTips(__("FULL_BUY_SLOT_TIME"))

					return
				end

				xyd.WindowManager.get():openWindow("item_buy_window", {
					hide_min_max = false,
					item_no_click = false,
					cost = xyd.tables.miscTable:split2Cost("activity_trickortreat_buy", "value", "|#")[1],
					max_num = limit - self.activityData.detail.limit,
					itemParams = {
						num = 1,
						itemID = xyd.ItemID.GHOST_POTION
					},
					buyCallback = function (num)
						local msg = messages_pb.boss_buy_req()
						msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN
						msg.num = num

						xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
					end,
					limitText = __("BUY_GIFTBAG_LIMIT", self.activityData.detail.limit .. "/" .. limit)
				})
			end
		})
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_TRICKORTREAT_HELP"
		})
	end

	UIEventListener.Get(self.goTrick).onClick = function ()
		self.mainWindow:SetActive(false)
		self.trickWindow:SetActive(true)
		self.effect:SetActive(true)

		self.windowType = windowType.trickWindow

		xyd.setUISpriteAsync(self.btnTrick1:ComponentByName("icon", typeof(UISprite)), nil, "icon_294")
		xyd.setUISpriteAsync(self.btnTrick10:ComponentByName("icon", typeof(UISprite)), nil, "icon_294")
	end

	UIEventListener.Get(self.goMission).onClick = function ()
		xyd.closeWindow("activity_window")
		xyd.openWindow("activity_window", {
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_HALLOWEEN_MISSION),
			select = xyd.ActivityID.ACTIVITY_HALLOWEEN_MISSION
		})
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		local all_info = {}
		local ids = xyd.tables.activityHalloweenTrickAwardTable:getIDs()

		for i = 1, #ids do
			local info = {
				id = ids[i],
				max_value = xyd.tables.activityHalloweenTrickAwardTable:getComplete(ids[i])
			}
			info.cur_value = math.min(tonumber(self.activityData.detail.times), info.max_value)
			info.name = __("ACTIVITY_TRICKORTREAT_AWARDS", math.floor(info.max_value))
			info.items = xyd.tables.activityHalloweenTrickAwardTable:getAwards(ids[i])

			if self.activityData.detail.awards[i] == 0 then
				if info.cur_value == info.max_value then
					info.state = 1
				else
					info.state = 2
				end
			else
				info.state = 3
			end

			table.insert(all_info, info)
		end

		dump(self.activityData.detail.awards)
		xyd.WindowManager.get():openWindow("common_progress_award_window", {
			if_sort = true,
			all_info = all_info,
			title_text = __("ACTIVITY_TRICKORTREAT_AWARDS_TITLE"),
			click_callBack = function (info)
				local msg = messages_pb:trickortreat_get_awards_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN
				msg.table_id = info.id

				xyd.Backend.get():request(xyd.mid.TRICKORTREAT_GET_AWARDS, msg)
			end,
			wnd_type = xyd.CommonProgressAwardWindowType.ACTIVITY_HALLOWEEN
		})
	end

	UIEventListener.Get(self.btnShop).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_halloween_shop_window")
	end

	UIEventListener.Get(self.btnTrick1).onClick = function ()
		local cost = xyd.tables.miscTable:split2Cost("activity_trickortreat_cost", "value", "|#")[1]

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		local msg = messages_pb:trickortreat_get_rand_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN
		msg.num = 1

		xyd.Backend.get():request(xyd.mid.TRICKORTREAT_GET_RAND_AWARD, msg)
	end

	UIEventListener.Get(self.btnTrick10).onClick = function ()
		local cost = xyd.tables.miscTable:split2Cost("activity_trickortreat_cost", "value", "|#")[1]

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] * 10 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		local msg = messages_pb:trickortreat_get_rand_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN
		msg.num = 10

		xyd.Backend.get():request(xyd.mid.TRICKORTREAT_GET_RAND_AWARD, msg)
	end

	UIEventListener.Get(self.btnBack).onClick = function ()
		self.trickWindow:SetActive(false)
		self.effect:SetActive(false)
		self.mainWindow:SetActive(true)

		self.windowType = windowType.mainWindow
	end

	for i = 1, 6 do
		UIEventListener.Get(self["stagePlace" .. i]).onClick = function ()
			xyd.WindowManager:get():openWindow("activity_halloween_trick_preview_window", {
				boxID = i
			})
		end
	end

	UIEventListener.Get(self.groupPreview).onClick = function ()
		if self.checkAward == true then
			local msg = messages_pb:trickortreat_get_awards_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN
			msg.table_id = self.previewShowID

			xyd.Backend.get():request(xyd.mid.TRICKORTREAT_GET_AWARDS, msg)
		end
	end

	UIEventListener.Get(self.progressAward).onClick = function ()
		if self.progressBarMaxValue <= self.activityData.detail.point then
			local msg = messages_pb:trickortreat_get_point_award_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_HALLOWEEN

			xyd.Backend.get():request(xyd.mid.TRICKORTREAT_GET_POINT_AWARD, msg)
		end
	end
end

return ActivityHalloween
