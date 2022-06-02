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
	self:resizePosY(self.awardBtn, -618, -774)
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
	self.probBtn = self.go:NodeByName("probBtn").gameObject
	self.resultBtn = self.go:NodeByName("resultBtn").gameObject
	self.helpBtn = self.go:NodeByName("helpBtn").gameObject
	self.awardBtn = self.go:NodeByName("awardBtn").gameObject
	self.awardBtnLabel = self.awardBtn:ComponentByName("label", typeof(UILabel))
	self.awardBtnRedMark = self.awardBtn:NodeByName("redMark").gameObject
	self.content = self.go:NodeByName("content").gameObject
	self.pointNum = self.content:ComponentByName("pointPanel/point/num", typeof(UILabel))
	self.pointLabel = self.content:ComponentByName("pointPanel/pointLabel", typeof(UILabel))
	self.gachaBtn = self.content:NodeByName("gachaBtn").gameObject
	self.gachaBtnLabel = self.gachaBtn:ComponentByName("label", typeof(UILabel))
	self.gachaBtnRedMark = self.gachaBtn:NodeByName("redMark").gameObject
	self.scroller = self.content:ComponentByName("scroller", typeof(UIScrollView))
	self.progressBg = self.scroller:ComponentByName("progressBg", typeof(UISprite))
	self.progressBar = self.scroller:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressBarSprite = self.scroller:ComponentByName("progressBar", typeof(UISprite))
	self.progressImg = self.progressBar:ComponentByName("progressImg", typeof(UISprite))
	self.groupItem = self.scroller:NodeByName("groupItem").gameObject
	self.itemCell = self.content:NodeByName("itemCell").gameObject
	self.emptyItem = self.content:NodeByName("emptyItem").gameObject
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

	self.pointLabel.text = __("ACTIVITY_DRAGONBOAT2022_TEXT01")
	self.awardBtnLabel.text = __("ACTIVITY_DRAGONBOAT2022_BUTTON02")
	self.gachaBtnLabel.text = __("ACTIVITY_DRAGONBOAT2022_BUTTON01")

	if xyd.Global.lang == "de_de" then
		self.pointLabel.overflowWidth = 78
	end

	local ids = xyd.tables.activityDragonboat2022Table:getIDs()
	self.progressBg.width = 2 + 154 * #ids + 13
	self.progressBarSprite.width = 2 + 154 * #ids + 13
	self.progressImg.width = 154 * #ids + 13

	self.progressBg:X(-(79 + 154 * #ids) / 2)
	self.progressBarSprite:X(-(79 + 154 * #ids) / 2)

	self.icons = {}

	NGUITools.AddChild(self.groupItem, self.emptyItem)

	for i, id in ipairs(ids) do
		self.icons[i] = {}
		local item = NGUITools.AddChild(self.groupItem, self.itemCell)
		local awardGroup = item:NodeByName("award").gameObject
		local labelPoint = item:ComponentByName("point", typeof(UILabel))
		local point = xyd.tables.activityDragonboat2022Table:getPoint(id)
		local awards = xyd.tables.activityDragonboat2022Table:getAwards(id)
		labelPoint.text = point

		for j, award in ipairs(awards) do
			self.icons[i][j] = xyd.getItemIcon({
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6018518518518519,
				uiRoot = awardGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.scroller,
				isNew = award[1] == 7271 and true or false
			})
		end
	end

	self.groupItem:GetComponent(typeof(UILayout)):Reposition()
	self.scroller:ResetPosition()

	self.maxPoint = xyd.tables.activityDragonboat2022Table:getPoint(ids[#ids]) + xyd.tables.activityDragonboat2022Table:getPoint(ids[#ids]) / #ids / 154 * 13
	self.partnerEffect = xyd.Spine.new(self.partner.gameObject)

	self.partnerEffect:setInfo("yuji_pifu02_lihui01", function ()
		self.partnerEffect:play("animation", 0)
	end)
	self:update()
end

function ActivityDragonboat2022:update()
	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.WORMWOOD_CAKE)
	self.pointNum.text = self.activityData.detail.point
	self.curIndex = 0
	local ids = xyd.tables.activityDragonboat2022Table:getIDs()

	for i, id in ipairs(ids) do
		local point = xyd.tables.activityDragonboat2022Table:getPoint(id)

		if point <= self.activityData.detail.point then
			self.curIndex = i

			for _, icon in ipairs(self.icons[i]) do
				icon:setChoose(true)
			end
		end
	end

	local curPoint = self.curIndex == 0 and 0 or xyd.tables.activityDragonboat2022Table:getPoint(self.curIndex)
	local nextPoint = self.curIndex < #ids and xyd.tables.activityDragonboat2022Table:getPoint(self.curIndex + 1) or self.maxPoint
	local correctedValue = (self.curIndex + (self.activityData.detail.point - curPoint) / (nextPoint - curPoint)) * self.maxPoint / #ids
	self.progressBar.value = math.max(0, correctedValue - 0.002 * self.maxPoint) / self.maxPoint
	local sp = self.scroller:GetComponent(typeof(SpringPanel))
	local dis = math.max(math.min(782 - (self.curIndex or 0) * 154 + 70, 782), -860)

	sp.Begin(sp.gameObject, Vector3(dis, 0, 0), 16)
	self.awardBtnRedMark:SetActive(false)
	self.gachaBtnRedMark:SetActive(false)

	for i = 1, 3 do
		local point = xyd.tables.activityDragonboat2022ChoseTable:getPoint(i)

		if point <= self.activityData.detail.point and (not self.activityData.detail.awarded_chosen or not self.activityData.detail.awarded_chosen[i] or self.activityData.detail.awarded_chosen[i] == 0) then
			self.awardBtnRedMark:SetActive(true)
		end
	end

	local cost = xyd.tables.miscTable:split2Cost("activity_dragonboat2022_cost", "value", "#")

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		self.gachaBtnRedMark:SetActive(true)
	end

	self.activityData:updateRedMark()
end

function ActivityDragonboat2022:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:update()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function ()
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

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_dragonboat2022_award_select_window")
	end

	UIEventListener.Get(self.gachaBtn).onClick = function ()
		local awardChosenNum = 0

		if self.activityData.detail.chosen_ids then
			for _, value in pairs(self.activityData.detail.chosen_ids) do
				if value and value ~= 0 then
					awardChosenNum = awardChosenNum + 1
				end
			end
		end

		if awardChosenNum < 3 then
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
