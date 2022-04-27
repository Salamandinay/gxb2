local CountDown = import("app.components.CountDown")
local BattleArenaGiftBag = import("app.windows.activity.BattleArenaGiftBag")
local ActivityRecharge = class("BattleArenaGiftBag", BattleArenaGiftBag)
local ActivityRechargeItem = class("ValueGiftBagItem", BattleArenaGiftBag.BattleArenaGiftBagItem)

function ActivityRecharge:ctor(parentGO, params)
	BattleArenaGiftBag.ctor(self, parentGO, params)

	if not xyd.db.misc:getValue("activity_recharge_first") then
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_recharge_first"
		})
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_RECHARGE, function ()
		end)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_RECHARGE)
end

function ActivityRecharge:getPrefabPath()
	return "Prefabs/Windows/activity/activity_recharge"
end

function BattleArenaGiftBag:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("activityGroup").gameObject
	self.bgImg = self.activityGroup:ComponentByName("bgImg", typeof(UISprite))
	self.textImg = self.activityGroup:ComponentByName("textImg", typeof(UISprite))
	self.textLabel01 = self.activityGroup:ComponentByName("textLabel01", typeof(UILabel))
	self.timeLabel = self.activityGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.activityGroup:ComponentByName("endLabel", typeof(UILabel))
	self.scrollerBg = self.activityGroup:ComponentByName("scrollerBg", typeof(UISprite))
	self.e_Scroller = self.activityGroup:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.e_Scroller_uiPanel = self.activityGroup:ComponentByName("e:Scroller", typeof(UIPanel))
	self.e_Scroller_uiPanel.depth = self.e_Scroller_uiPanel.depth + 1
	self.groupItem = self.e_Scroller_uiPanel:NodeByName("groupItem")
	self.groupItem_uigrid = self.groupItem:GetComponent(typeof(UIGrid))
	self.littleItem = go.transform:Find("level_fund_item")
end

function ActivityRecharge:euiComplete()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_recharge_" .. xyd.Global.lang)
	self:setText()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end
end

function ActivityRecharge:setText()
	self.endLabel.text = __("TEXT_END")
	self.textLabel01.text = __("ACTIVITY_RECHARGE_TEXT")

	if xyd.Global.lang == "fr_fr" then
		self.textLabel01:Y(-165)
	end
end

function ActivityRecharge:onActivityByID()
	self:setItem()
	self.groupItem_uigrid:Reposition()

	self.e_Scroller.enabled = true
end

function ActivityRecharge:setItem()
	local ids = xyd.tables.activityRechargeTable:getIDs()
	self.data = {}

	for i, v in pairs(ids) do
		local id = tonumber(ids[i])
		local is_completed = false

		if xyd.tables.activityRechargeTable:getPoint(id) <= self.activityData.detail.point then
			is_completed = true
		end

		local awards_info = xyd.tables.activityRechargeTable:getAwards(id)
		local param = {
			scale = 0.7,
			id = id,
			isCompleted = is_completed,
			max_point = xyd.tables.activityRechargeTable:getPoint(id),
			point = self.activityData.detail.point,
			awarded = awards_info,
			is_new = xyd.tables.activityRechargeTable:getIsNew(id)
		}

		table.insert(self.data, param)
	end

	table.sort(self.data, function (a, b)
		if a.isCompleted == b.isCompleted then
			return tonumber(a.id) < tonumber(b.id)
		else
			return not a.isCompleted
		end
	end)

	local tempArr = {}

	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(self.data) do
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.littleItem.gameObject)

		table.insert(tempArr, tmp)

		local item = ActivityRechargeItem.new(tmp, self.data[i])
	end

	self.littleItem:SetActive(false)
end

function ActivityRechargeItem:ctor(goItem, itemdata)
	ActivityRechargeItem.super.ctor(self, goItem, itemdata)
	self.itemsGroup_:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityRechargeItem:initBaseInfo(itemdata)
	self.imgNew = self.goItem_.transform:ComponentByName("imgNew", typeof(UISprite))

	xyd.setUITextureAsync(self.imgbg, "Textures/activity_web/weekly_monthly_giftbag/weekly_monthly_giftbag_bg01")

	self.labelTitle_.text = __("ACTIVITY_RECHARGE_POINT", itemdata.max_point)

	if itemdata.is_new and itemdata.is_new == 1 then
		self.imgNew:SetActive(true)
	else
		self.imgNew:SetActive(false)
	end
end

return ActivityRecharge
