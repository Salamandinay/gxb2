local ActivityDragonboat2022 = class("ActivityDragonboat2022", import(".ActivityContent"))
local ActivityDragonboat2022Item = class("ActivityDragonboat2022Item", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityDragonboat2022:ctor(parentGO, params)
	ActivityDragonboat2022.super.ctor(self, parentGO, params)
end

function ActivityDragonboat2022:getPrefabPath()
	return "Prefabs/Windows/activity/activity_dragonboat2022"
end

function ActivityDragonboat2022:resizeToParent()
	ActivityDragonboat2022.super.resizeToParent(self)
	self:resizePosY(self.resItem, -662, -818)
	self:resizePosY(self.content, -780, -936)
end

function ActivityDragonboat2022:initUI()
	self:getUIComponent()
	ActivityDragonboat2022.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityDragonboat2022:getUIComponent()
	self.partner = self.go:ComponentByName("partner", typeof(UITexture))
	self.logo = self.go:ComponentByName("logo", typeof(UISprite))
	self.timeGroup = self.go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.resItem = self.go:ComponentByName("resItem", typeof(UISprite))
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.resBtn = self.resItem:NodeByName("btn").gameObject
	self.resIcon = self.resItem:ComponentByName("icon", typeof(UISprite))
	self.probBtn = self.go:NodeByName("probBtn").gameObject
	self.resultBtn = self.go:NodeByName("resultBtn").gameObject
	self.helpBtn = self.go:NodeByName("helpBtn").gameObject
	self.content = self.go:NodeByName("content").gameObject
	self.btnAward = self.content:NodeByName("btnAward").gameObject
	self.labelAward = self.btnAward:ComponentByName("labelAward", typeof(UILabel))
	self.btnAwardRedMark = self.btnAward:NodeByName("redMark").gameObject
	self.labelTitle = self.content:ComponentByName("labelTitle", typeof(UILabel))
	self.labelDesc = self.content:ComponentByName("labelDesc", typeof(UILabel))
	self.btnSelectAward = self.content:NodeByName("btnSelectAward").gameObject
	self.btnSelectAwardRedMark = self.btnSelectAward:NodeByName("redMark").gameObject
	self.progressBar = self.content:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressBarSprite = self.content:ComponentByName("progressBar", typeof(UISprite))
	self.labelProgressNum1 = self.content:ComponentByName("labelProgressNum1", typeof(UILabel))
	self.labelProgressNum2 = self.content:ComponentByName("labelProgressNum2", typeof(UILabel))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
end

function ActivityDragonboat2022:initUIComponent()
	xyd.setUISpriteAsync(self.logo, nil, "activity_dragonboat2022_logo_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
	end

	self.labelAward.text = __("ACTIVITY_DRAGONBOAT2022_BUTTON01")
	local costItemID = xyd.tables.miscTable:getNumber("accumulated_consume_item01", "value")

	xyd.setUISpriteAsync(self.resIcon, nil, xyd.tables.itemTable:getIcon(costItemID), nil, )

	local ids = xyd.tables.activityDragonboat2022ChoseTable:getIDs()
	self.icons = {}

	self:update()

	local index = math.min(self.curIndex + 1, #ids)
	self.partnerEffect = xyd.Spine.new(self.partner.gameObject)

	self.partnerEffect:setInfo("activity_midautumn", function ()
		self.partnerEffect:SetLocalPosition(0, 277, 0)
		self.partnerEffect:play("idle" .. index, 0, 1, function ()
		end)
	end)
end

function ActivityDragonboat2022:update()
	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.WORMWOOD_CAKE)
	self.curIndex = 0
	local ids = xyd.tables.activityDragonboat2022ChoseTable:getIDs()

	for i, id in ipairs(ids) do
		local point = xyd.tables.activityDragonboat2022ChoseTable:getPoint(id)

		if point <= self.activityData.detail.point2 then
			self.curIndex = i
		end
	end

	local curPoint = self.curIndex == 0 and 0 or xyd.tables.activityDragonboat2022ChoseTable:getPoint(self.curIndex)
	local nextPoint = xyd.tables.activityDragonboat2022ChoseTable:getPoint(math.min(self.curIndex + 1, #ids))

	if nextPoint <= self.activityData.detail.point2 then
		self.progressBar.value = 1

		xyd.setUISpriteAsync(self.progressImg, nil, "activity_dragonboat2022_bg_jdt_m")

		self.labelProgressNum1.color = Color.New2(3947961599.0)
		self.labelProgressNum1.effectColor = Color.New2(4294967295.0)
		self.labelProgressNum1.fontSize = 26
		self.labelProgressNum1.text = self.activityData.detail.point2

		self.labelProgressNum1:X(-3)

		self.labelProgressNum2.color = Color.New2(1850553855)
		self.labelProgressNum2.effectColor = Color.New2(4294967295.0)
		self.labelProgressNum2.text = "/" .. nextPoint
	else
		self.progressBar.value = (self.activityData.detail.point2 - curPoint) / (nextPoint - curPoint)

		xyd.setUISpriteAsync(self.progressImg, nil, "activity_dragonboat2022_jdt2")

		self.labelProgressNum1.text = self.activityData.detail.point2 .. "/" .. nextPoint
	end

	self.btnAwardRedMark:SetActive(false)

	for i = 1, 4 do
		local point = xyd.tables.activityDragonboat2022ChoseTable:getPoint(i)

		if point <= self.activityData.detail.point2 and (not self.activityData.detail.awarded_chosen or not self.activityData.detail.awarded_chosen[i] or self.activityData.detail.awarded_chosen[i] == 0) then
			self.btnSelectAwardRedMark:SetActive(true)
		end
	end

	local cost = xyd.tables.miscTable:split2Cost("activity_dragonboat2022_cost", "value", "#")

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		self.btnAwardRedMark:SetActive(true)
	end

	local index = math.min(self.curIndex + 1, #ids)
	self.labelTitle.text = xyd.tables.activityDragonboat2022TextTable:getDesc(index)
	self.labelDesc.text = __("ACTIVITY_DRAGONBOAT2022_TEXT09")
	local awards = xyd.tables.activityDragonboat2022ChoseTable:getAwards(index)
	local awardChosen = nil

	if self.activityData.detail.chosen_ids and self.activityData.detail.chosen_ids[index] then
		awardChosen = awards[self.activityData.detail.chosen_ids[index]]
	end

	if awardChosen then
		local params = {
			notShowGetWayBtn = true,
			show_has_num = true,
			scale = 0.8703703703703703,
			isShowSelected = false,
			uiRoot = self.btnSelectAward.gameObject,
			itemID = awardChosen[1],
			num = awardChosen[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			callback = function ()
				if self.isReqing then
					return
				end

				xyd.WindowManager:get():openWindow("activity_dragonboat2022_award_select_window")
			end
		}

		if self.chooseAwardIcon then
			self.chooseAwardIcon:SetActive(true)
			self.chooseAwardIcon:setInfo(params)
		else
			self.chooseAwardIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		end

		if nextPoint <= self.activityData.detail.point2 then
			self.chooseAwardIcon:setChoose(true)
		end
	elseif self.chooseAwardIcon then
		self.chooseAwardIcon:SetActive(false)
	end

	self.activityData:updateRedMark()
end

function ActivityDragonboat2022:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:update()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id ~= xyd.ActivityID.ACTIVITY_DRAGONBOAT2022 then
			return
		end

		local detail = cjson.decode(data.detail)

		if detail.info then
			self.curIndex = 0
			local ids = xyd.tables.activityDragonboat2022ChoseTable:getIDs()

			for i, id in ipairs(ids) do
				local point = xyd.tables.activityDragonboat2022ChoseTable:getPoint(id)

				if point <= self.activityData.detail.point2 then
					self.curIndex = i
				end
			end

			local gachaTime = self.activityData.gachaTime

			if gachaTime then
				local realItems = {}
				local coolAward = xyd.tables.miscTable:split2Cost("activity_dragonboat2022_extra_awards", "value", "#")

				for i = 1, gachaTime do
					local awards = detail[tostring(i)]

					for _, award in pairs(awards) do
						table.insert(realItems, {
							item_id = award[1],
							item_num = award[2],
							cool = coolAward[1] == award[1] and 1 or 0
						})
					end
				end

				local index = math.min(self.curIndex + 1, #ids)

				self.partnerEffect:play("hit" .. index, 1, 1, function ()
					self.partnerEffect:play("idle" .. index, 0)

					self.btnAward:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
					self.resBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
					self.probBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
					self.resultBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
					self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
					self.btnSelectAward:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
					self.isReqing = false

					xyd.openWindow("gamble_rewards_window", {
						layoutCenter = true,
						wnd_type = 7,
						data = realItems
					})
					xyd.alertTips(__("ACTIVITY_DRAGONBOAT2022_TIPS02", self.activityData.tempAddPoint))
				end)
			end
		end

		self:update()
	end)

	UIEventListener.Get(self.resBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.WORMWOOD_CAKE
		})
	end

	UIEventListener.Get(self.probBtn).onClick = function ()
		local superAwards = xyd.tables.miscTable:split2Cost("activity_dragonboat2022_extra_awards", "value", "#")
		local superAwardProb = xyd.tables.miscTable:split2Cost("activity_dragonboat2022_extra_weight", "value", "|")
		local params = {
			windowTpye = 2,
			dropBox = xyd.tables.miscTable:getNumber("activity_dragonboat2022_dropbox", "value"),
			superAwardText = __("ACTIVITY_DRAGONBOAT2022_TEXT02"),
			commonAwardText = __("ACTIVITY_DRAGONBOAT2022_TEXT03"),
			superAwards = {
				superAwards
			},
			superAwardProb = {
				superAwardProb[1] / superAwardProb[2]
			}
		}

		xyd.WindowManager:get():openWindow("activity_halloween_trick_preview_window", params)
	end

	UIEventListener.Get(self.resultBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_space_explore_awarded_window", {
			data = self.activityData.detail.records,
			labelNone = __("ACTIVITY_DRAGONBOAT2022_TEXT08"),
			winTitle = __("ACTIVITY_CHRISTMAS_SIGN_UP_TEXT01")
		})
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_DRAGONBOAT2022_HELP"
		})
	end

	UIEventListener.Get(self.btnSelectAward).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_dragonboat2022_award_select_window")
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		local awardChosenNum = 0

		if self.activityData.detail.chosen_ids then
			for _, value in pairs(self.activityData.detail.chosen_ids) do
				if value and value ~= 0 then
					awardChosenNum = awardChosenNum + 1
				end
			end
		end

		if awardChosenNum < 4 then
			xyd.alertTips(__("ACTIVITY_DRAGONBOAT2022_TIPS01"))
			xyd.WindowManager:get():openWindow("activity_dragonboat2022_award_select_window")

			return
		end

		local cost = xyd.tables.miscTable:split2Cost("activity_dragonboat2022_cost", "value", "#")

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = math.min(math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]), 40),
			show_max_num = xyd.models.backpack:getItemNumByID(cost[1]),
			select_multiple = cost[2],
			icon_info = {
				height = 45,
				width = 45,
				name = "icon_" .. cost[1]
			},
			title_text = __("ACTIVITY_DRAGONBOAT2022_BUTTON01"),
			explain_text = __("ACTIVITY_DRAGONBOAT2022_TEXT07"),
			sure_callback = function (num)
				self.btnAward:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self.resBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self.probBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self.resultBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self.helpBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self.btnSelectAward:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self.isReqing = true

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_DRAGONBOAT2022, cjson.encode({
					award_type = 1,
					num = num
				}))

				self.activityData.gachaTime = num
				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	end
end

return ActivityDragonboat2022
