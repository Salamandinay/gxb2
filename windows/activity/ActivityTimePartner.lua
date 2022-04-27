local ActivityTimePartner = class("ActivityTimePartner", import(".ActivityContent"))
local AwardItem = class("AwardItem")
local myTable = xyd.tables.activityTimePartnerTable
local cjson = require("cjson")

function ActivityTimePartner:ctor(parentGo, params, parent)
	ActivityTimePartner.super.ctor(self, parentGo, params, parent)
end

function ActivityTimePartner:getPrefabPath()
	return "Prefabs/Windows/activity/activity_time_partner"
end

function ActivityTimePartner:resizeToParent()
	ActivityTimePartner.super.resizeToParent(self)
	self.textLogo:Y(-153 + -7 * self.scale_num_contrary)
	self.groupMain:Y(-594 + -160 * self.scale_num_contrary)
end

function ActivityTimePartner:initUI()
	self:getUIComponent()
	ActivityTimePartner.super.initUI(self)
	self:layout()
	self:register()
end

function ActivityTimePartner:getUIComponent()
	local go = self.go
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.labelTime = self.textLogo:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.labelEnd = self.textLogo:ComponentByName("timeGroup/labelEnd", typeof(UILabel))
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.scroller = self.groupMain:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject
	self.itemRoot = self.groupMain:NodeByName("itemRoot").gameObject
	self.btnPlay = self.groupMain:NodeByName("btnPlay").gameObject
	self.btnCheck = self.groupMain:NodeByName("groupCheck/btnCheck").gameObject
	self.labelName = self.groupMain:ComponentByName("groupCheck/labelName", typeof(UILabel))
end

function ActivityTimePartner:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_time_partner_" .. xyd.Global.lang)

	local id = xyd.tables.miscTable:getVal("activity_time_partner_id")
	self.labelName.text = xyd.tables.partnerTable:getName(id)
	self.labelEnd.text = __("END")
	local duration = self.activityData:getEndTime() - xyd.getServerTime()

	if duration < 0 then
		self.labelTime:SetActive(false)
		self.labelEnd:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end,
			duration = duration
		})
	end

	local ids = myTable:getIds()
	local pr = self.activityData.detail_.pr
	local pr_awards = self.activityData.detail_.pr_awards
	local list = {}

	for i = 1, #ids do
		local item = {
			id = ids[i],
			needPoint = myTable:getPoint(ids[i]),
			pr = pr,
			isAwarded = pr_awards[ids[i]],
			dragScrollView = self.scroller
		}

		table.insert(list, item)
	end

	table.sort(list, function (a, b)
		if a.isAwarded == b.isAwarded then
			return a.id < b.id
		else
			return a.isAwarded == 0
		end
	end)

	self.itemList = {}

	for _, data in ipairs(list) do
		local tmp = NGUITools.AddChild(self.groupContent, self.itemRoot)
		local item = AwardItem.new(tmp, data)
		self.itemList[data.id] = item
	end

	self:waitForFrame(1, function ()
		self.scroller:ResetPosition()
	end)
end

function ActivityTimePartner:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.btnPlay).onClick = function ()
		self:playBattle()
	end

	UIEventListener.Get(self.btnCheck).onClick = function ()
		local id = xyd.tables.miscTable:getVal("activity_time_partner_id")

		xyd.WindowManager.get():openWindow("guide_detail_window", {
			partners = {
				{
					table_id = id
				}
			},
			table_id = id
		})
	end
end

function ActivityTimePartner:playBattle()
	local battleId1 = xyd.tables.miscTable:getVal("activity_time_monster_id")
	local battleId2 = xyd.tables.miscTable:getVal("activity_time_battle_id")

	xyd.BattleController.get():frontBattleBy2BattleId(battleId1, battleId2, xyd.BattleType.SKIN_PLAY, 1)
end

function ActivityTimePartner:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_TIME_PARTNER then
		return
	end

	local tableId = cjson.decode(event.data.detail).table_id
	local awards = myTable:getAwards(tableId)
	local items = {}

	for _, item in pairs(awards) do
		table.insert(items, {
			item_id = item[1],
			item_num = item[2]
		})
	end

	xyd.models.itemFloatModel:pushNewItems(items)
	self.itemList[tableId]:onAward()
end

function AwardItem:ctor(go, params)
	self.icon_ = {}
	self.go = go
	self.params = params
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.tipsLabel = go:ComponentByName("tipsLabel", typeof(UILabel))
	self.valueLabel = go:ComponentByName("valueLabel", typeof(UILabel))
	self.awardBtn = go:NodeByName("awardBtn").gameObject
	self.awardBtnLabel = self.awardBtn:ComponentByName("label", typeof(UILabel))
	self.awardImg = go:ComponentByName("awardImg", typeof(UISprite))
	self.awardBtnGrey = go:NodeByName("awardBtnGrey").gameObject
	self.awardBtnGreyLabel = self.awardBtnGrey:ComponentByName("label", typeof(UILabel))

	self:layout()
end

function AwardItem:layout()
	self.tipsLabel.text = __("ACTIVITY_TIME_PARTNER_NUM", self.params.needPoint)
	local showValue = xyd.checkCondition(self.params.needPoint <= self.params.pr, self.params.needPoint, self.params.pr)
	self.valueLabel.text = "(" .. showValue .. "/" .. self.params.needPoint .. ")"
	self.awardBtnLabel.text = __("MIDAS_TEXT04")
	self.awardBtnGreyLabel.text = __("MIDAS_TEXT04")
	local isAwarded = false

	xyd.setUISpriteAsync(self.awardImg, nil, "mission_awarded_" .. xyd.Global.lang)

	if self.params.isAwarded == 1 then
		self.awardImg:SetActive(true)
		self.awardBtn:SetActive(false)
		self.awardBtnGrey:SetActive(false)

		isAwarded = true
	elseif self.params.needPoint <= self.params.pr then
		self.awardImg:SetActive(false)
		self.awardBtn:SetActive(true)
		self.awardBtnGrey:SetActive(false)
		xyd.setDragScrollView(self.awardBtn, self.params.dragScrollView)

		UIEventListener.Get(self.awardBtn).onClick = function ()
			local params = cjson.encode({
				table_id = tonumber(self.params.id)
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_TIME_PARTNER, params)
		end
	else
		self.awardImg:SetActive(false)
		self.awardBtn:SetActive(false)
		self.awardBtnGrey:SetActive(true)
	end

	local awards = myTable:getAwards(self.params.id)

	for _, item in pairs(awards) do
		local icon = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7962962962962963,
			itemID = item[1],
			num = item[2],
			uiRoot = self.awardGroup,
			dragScrollView = self.params.dragScrollView
		})

		icon:setChoose(isAwarded)
		table.insert(self.icon_, icon)
	end
end

function AwardItem:onAward()
	self.awardImg:SetActive(true)
	self.awardBtn:SetActive(false)

	for _, icon in ipairs(self.icon_) do
		icon:setChoose(true)
	end
end

return ActivityTimePartner
