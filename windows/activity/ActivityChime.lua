local ActivityContent = import(".ActivityContent")
local ActivityChime = class("ActivityChime", ActivityContent)
local CountDown = import("app.components.CountDown")

function ActivityChime:ctor(parentGO, params, parent)
	for i = 1, 2 do
		self["itemShow" .. i] = xyd.tables.miscTable:split2num("activity_chime_cost" .. i, "value", "#")
	end

	self.baseHigtNum = xyd.tables.miscTable:getNumber("activity_chime_get", "value")

	ActivityChime.super.ctor(self, parentGO, params, parent)
end

function ActivityChime:getPrefabPath()
	return "Prefabs/Windows/activity/activity_chime"
end

function ActivityChime:initUI()
	self:getUIComponent()
	ActivityChime.super.initUI(self)
	self:initUIComponent()
end

function ActivityChime:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.imgBg = self.groupAction:ComponentByName("imgBg", typeof(UITexture))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.btn1 = self.downCon:NodeByName("btn1").gameObject
	self.btn1BoxCollider = self.downCon:ComponentByName("btn1", typeof(UnityEngine.BoxCollider))
	self.btnLabelNum = self.btn1:ComponentByName("btnLabelNum", typeof(UILabel))
	self.btnLabelName = self.btn1:ComponentByName("btnLabelName", typeof(UILabel))
	self.btn2 = self.downCon:NodeByName("btn2").gameObject
	self.btn2BoxCollider = self.downCon:ComponentByName("btn2", typeof(UnityEngine.BoxCollider))
	self.btnLabelNum2 = self.btn2:ComponentByName("btnLabelNum", typeof(UILabel))
	self.btnLabelName2 = self.btn2:ComponentByName("btnLabelName", typeof(UILabel))
	self.tipsCon = self.downCon:NodeByName("tipsCon").gameObject
	self.tipsConBg = self.tipsCon:ComponentByName("tipsConBg", typeof(UISprite))
	self.tipsConBgFlower1 = self.tipsConBg:ComponentByName("tipsConBgFlower1", typeof(UISprite))
	self.tipsConBgFlower2 = self.tipsConBg:ComponentByName("tipsConBgFlower2", typeof(UISprite))
	self.tipsText = self.tipsCon:ComponentByName("tipsText", typeof(UILabel))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.defenseBtn = self.centerCon:NodeByName("defenseBtn").gameObject
	self.defenseBtnRedPoint = self.defenseBtn:NodeByName("defenseBtnRedPoint").gameObject
	self.defenseBtnLabel = self.defenseBtn:ComponentByName("defenseBtnLabel", typeof(UILabel))
	self.defenseEffect = self.defenseBtn:ComponentByName("defenseEffect", typeof(UITexture))
	self.watarEffect = self.centerCon:ComponentByName("watarEffect", typeof(UITexture))
	self.taskBtn = self.centerCon:NodeByName("taskBtn").gameObject
	self.taskBtnLabel = self.taskBtn:ComponentByName("taskBtnLabel", typeof(UILabel))
	self.taskBtnRedPoint = self.taskBtn:NodeByName("taskBtnRedPoint").gameObject
	self.treeBtn = self.centerCon:NodeByName("treeBtn").gameObject
	self.treeBtnLabel = self.treeBtn:ComponentByName("treeBtnLabel", typeof(UILabel))
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.timeCon = self.upCon:NodeByName("timeCon").gameObject
	self.timeConUILayout = self.upCon:ComponentByName("timeCon", typeof(UILayout))
	self.timeText = self.timeCon:ComponentByName("timeText", typeof(UILabel))
	self.timeUpdateText = self.timeCon:ComponentByName("timeUpdateText", typeof(UILabel))
	self.helpBtn = self.upCon:NodeByName("helpBtn").gameObject
	self.checkBtn = self.upCon:NodeByName("checkBtn").gameObject
	self.awardBtn = self.upCon:NodeByName("awardBtn").gameObject
	self.warterBtn = self.centerCon:NodeByName("warterBtn").gameObject
	self.logoTextImg = self.upCon:ComponentByName("logoTextImg", typeof(UISprite))

	for i = 1, 2 do
		self["currencyCon" .. i] = self.upCon:NodeByName("currencyCon" .. i).gameObject
		self["currencyBg" .. i] = self["currencyCon" .. i]:ComponentByName("currencyBg", typeof(UISprite))
		self["currencyIcon" .. i] = self["currencyCon" .. i]:ComponentByName("currencyIcon", typeof(UISprite))
		self["currencyLabel" .. i] = self["currencyCon" .. i]:ComponentByName("currencyLabel", typeof(UILabel))
		self["currencyPlus" .. i] = self["currencyCon" .. i]:ComponentByName("currencyPlus", typeof(UISprite))
	end

	self.watarEffect = self.centerCon:ComponentByName("watarEffect", typeof(UITexture))
	self.timeOtherImg1 = self.upCon:ComponentByName("timeOtherImg1", typeof(UISprite))
	self.timeOtherImg2 = self.upCon:ComponentByName("timeOtherImg2", typeof(UISprite))

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.ACTIVITY_CHIME_TASK, self.taskBtnRedPoint)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.ACTIVITY_CHIME_DEFENSE, self.defenseBtnRedPoint)
end

function ActivityChime:initUIComponent()
	self:loadRes()

	self.defenseBtnLabel.text = __("ACTIVITY_CHIME_TEXT02")
	self.taskBtnLabel.text = __("MISSION")

	if xyd.Global.lang == "fr_fr" then
		self.taskBtnLabel.fontSize = 24
	end

	self.btnLabelName.text = __("ACTIVITY_CHIME_TEXT13")
	self.btnLabelName2.text = __("ACTIVITY_CHIME_TEXT13")
	self.treeBtnLabel.text = __("SHRINE_TREE")

	self:initTime()
	self.activityData:checkRedPointOfTask()
	self.activityData:checkDayGiftBuyRed()
	xyd.setUISpriteAsync(self.logoTextImg, nil, "activity_chime_text_bg_yzqy_" .. xyd.Global.lang)

	for i = 1, 2 do
		xyd.setUISpriteAsync(self["currencyIcon" .. i], nil, xyd.tables.itemTable:getIcon(self["itemShow" .. i][1]), function ()
			self["currencyIcon" .. i]:SetLocalScale(0.5, 0.5, 1)
		end, nil, true)
		self["currencyIcon" .. i].gameObject:X(-50.5)
	end

	self:updateItemShow()
	self:updateTipsText()

	self.defenseSpine = xyd.Spine.new(self.defenseEffect.gameObject)

	self.defenseSpine:setInfo("activity_chime_gift", function ()
		self.defenseSpine:play("texiao01", 0, 1, nil)
	end)
end

function ActivityChime:resizeToParent()
	ActivityChime.super.resizeToParent(self)
	self:resizePosY(self.imgBg, 83, -5)
	self:resizePosY(self.treeBtn, 176.4, 190)
	self:resizePosY(self.defenseBtn, 224.7, 394)
	self:resizePosY(self.downCon, -293, -380)
end

function ActivityChime:onRegister()
	ActivityChime.super.onRegister(self)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemShow))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	for i = 1, 2 do
		self["goWayFun" .. i] = function ()
			if i == 1 then
				xyd.WindowManager.get():openWindow("shrine_hurdle_task_window", {})
			elseif i == 2 then
				xyd.WindowManager.get():openWindow("activity_chime_giftbag_window", {})
			end
		end

		UIEventListener.Get(self["currencyPlus" .. i].gameObject).onClick = handler(self, function ()
			self["goWayFun" .. i]()
		end)
		UIEventListener.Get(self["currencyBg" .. i].gameObject).onClick = handler(self, function ()
			self["goWayFun" .. i]()
		end)
	end

	UIEventListener.Get(self.defenseBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_chime_giftbag_window", {})
	end)
	UIEventListener.Get(self.taskBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("shrine_hurdle_task_window", {})
	end)
	UIEventListener.Get(self.treeBtn.gameObject).onClick = handler(self, function ()
		if not xyd.models.shrineHurdleModel:checkIsCanOpen() then
			return
		end

		xyd.WindowManager.get():openWindow("chime_main_window")
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_CHIME_HELP"
		})
	end)
	UIEventListener.Get(self.checkBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("activity_chime_preview_window", {})
	end)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		local items = xyd.cloneTable(self.activityData:getItems())

		xyd.WindowManager.get():openWindow("activity_space_explore_awarded_window", {
			data = items,
			winTitle = __("ACTIVITY_PARY_ALL_AWARDS")
		})
	end)
	UIEventListener.Get(self.btn1.gameObject).onClick = handler(self, function ()
		local cost = self.itemShow1

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = math.min(math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]), self.baseHigtNum),
			show_max_num = xyd.models.backpack:getItemNumByID(cost[1]),
			select_multiple = cost[2],
			icon_info = {
				height = 45,
				width = 45,
				name = xyd.tables.itemTable:getIcon(cost[1])
			},
			title_text = __("ACTIVITY_CHIME_TEXT10", xyd.tables.itemTable:getName(cost[1])),
			explain_text = __("ACTIVITY_CHIME_TEXT11"),
			sure_callback = function (num)
				if num > 0 then
					local function sendFun()
						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHIME, require("cjson").encode({
							type = xyd.ActivityChimeReqType.COMMON,
							num = num
						}))

						self.btn1BoxCollider.enabled = true
						self.btn2BoxCollider.enabled = true
					end

					self.btn1BoxCollider.enabled = false
					self.btn2BoxCollider.enabled = false

					self:playSendCallBack(xyd.ActivityChimeReqType.COMMON, sendFun)
				end

				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	end)
	UIEventListener.Get(self.btn2.gameObject).onClick = handler(self, function ()
		local cost = self.itemShow2

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = math.min(math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]), self.baseHigtNum),
			show_max_num = xyd.models.backpack:getItemNumByID(cost[1]),
			select_multiple = cost[2],
			icon_info = {
				height = 45,
				width = 45,
				name = xyd.tables.itemTable:getIcon(cost[1])
			},
			title_text = __("ACTIVITY_CHIME_TEXT10", xyd.tables.itemTable:getName(cost[1])),
			explain_text = __("ACTIVITY_CHIME_TEXT11"),
			sure_callback = function (num)
				if num > 0 then
					local function sendFun()
						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHIME, require("cjson").encode({
							type = xyd.ActivityChimeReqType.HIGH,
							num = num
						}))

						self.btn1BoxCollider.enabled = true
						self.btn2BoxCollider.enabled = true
					end

					self.btn1BoxCollider.enabled = false
					self.btn2BoxCollider.enabled = false

					self:playSendCallBack(xyd.ActivityChimeReqType.HIGH, sendFun)
				end

				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	end)
end

function ActivityChime:initTime()
	self.timeUpdateText.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.timeUpdateText.transform:SetSiblingIndex(0)
		self.timeText.transform:SetSiblingIndex(1)
	end

	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.timeText, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime(),
			callback = handler(self, self.timeOver)
		})

		self.timeConUILayout:Reposition()
		self:updateTimeLinePos()
	else
		self:timeOver()
		self:updateTimeLinePos()
	end
end

function ActivityChime:timeOver()
	self.timeText.text = "00:00:00"

	self.timeConUILayout:Reposition()
end

function ActivityChime:updateTimeLinePos()
	local allTimeTextWidth = self.timeUpdateText.width + self.timeText.width + self.timeConUILayout.gap.x
	local halfWidth = allTimeTextWidth / 2

	self.timeOtherImg1.gameObject:X(-halfWidth - 7)
	self.timeOtherImg2.gameObject:X(halfWidth + 7)
end

function ActivityChime:updateItemShow()
	for i = 1, 2 do
		self["currencyLabel" .. i].text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(self["itemShow" .. i][1]))
	end
end

function ActivityChime:updateTipsText()
	local num = self.baseHigtNum - self.activityData:getTimes()

	if num < 1 then
		num = 1
	end

	self.tipsText.text = __("ACTIVITY_CHIME_TEXT03", num)
end

function ActivityChime:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_CHIME then
		return
	end

	local data = xyd.decodeProtoBuf(data)
	local info = require("cjson").decode(data.detail)
	local type = info.type

	if type == xyd.ActivityChimeReqType.HIGH then
		self:updateTipsText()
	elseif type == xyd.ActivityChimeReqType.TASK then
		-- Nothing
	end
end

function ActivityChime:playSendCallBack(type, callBack)
	if not self.watar then
		self.watar = xyd.Spine.new(self.watarEffect.gameObject)

		self.watar:SetLocalPosition(-50, 110, 0)
		self.watar:SetLocalScale(0.97, 0.97, 0)
		self.watar:setInfo("activity_chime", function ()
			self.watar:playWithEvent("texiao0" .. type, 1, 1, {
				award = function ()
					callBack()
				end
			})
		end)
	else
		self.watar:playWithEvent("texiao0" .. type, 1, 1, {
			award = function ()
				callBack()
			end
		})
	end
end

function ActivityChime:loadRes()
	local res = xyd.getEffectFilesByNames({
		"activity_chime"
	})
	local allHasRes = xyd.isAllPathLoad(res)

	if allHasRes then
		return
	else
		ResCache.DownloadAssets("activity_chime", res, function (success)
			xyd.WindowManager.get():closeWindow("res_loading_window")

			if tolua.isnull(self.go) then
				return
			end
		end, function (progress)
			local loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			if progress >= 1 and not loading_win then
				return
			end

			if not loading_win then
				xyd.WindowManager.get():openWindow("res_loading_window", {})
			end

			loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			loading_win:setLoadWndName("activity_chime_load_wd")
			loading_win:setLoadProgress("activity_chime_load_wd", progress)
		end, 1)
	end
end

return ActivityChime
