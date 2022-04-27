local ActivityContent = import(".ActivityContent")
local ActivityBomb = class("ActivityBomb", ActivityContent)
local ActivityBombItem = class("ActivityBombItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")

function ActivityBomb:ctor(parentGO, params, parent)
	self.items = {}
	self.curGetId = 0

	ActivityBomb.super.ctor(self, parentGO, params, parent)
end

function ActivityBomb:getPrefabPath()
	return "Prefabs/Windows/activity/activity_bomb"
end

function ActivityBomb:initUI()
	self:getUIComponent()
	ActivityBomb.super.initUI(self)
	self:layout()
	self:initItems()
	self:registerEvent()
end

function ActivityBomb:getUIComponent()
	local goTrans = self.go.transform
	self.textImg = goTrans:ComponentByName("textImg", typeof(UISprite))
	self.timeGroup = self.textImg:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.bombBtn = goTrans:NodeByName("bombBtn").gameObject
	self.lvLabel = self.bombBtn:ComponentByName("lvLabel", typeof(UILabel))
	self.btnLabel = self.bombBtn:ComponentByName("descLabel", typeof(UILabel))
	self.redMark = self.bombBtn:ComponentByName("redMark", typeof(UISprite))
	self.itemGroup = goTrans:NodeByName("itemGroup").gameObject
	self.itemLabel1 = self.itemGroup:ComponentByName("groupItem1/label", typeof(UILabel))
	self.itemBtn1 = self.itemGroup:NodeByName("groupItem1/btn").gameObject
	self.itemLabel2 = self.itemGroup:ComponentByName("groupItem2/label", typeof(UILabel))
	self.itemBtn2 = self.itemGroup:NodeByName("groupItem2/btn").gameObject
	self.scrollView_ = self.itemGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.groupItem_ = self.itemGroup:ComponentByName("scrollView/groupItem", typeof(UIGrid))
	self.itemCell = goTrans:NodeByName("itemCell").gameObject
end

function ActivityBomb:layout()
	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	xyd.setUISpriteAsync(self.textImg, nil, "activity_bomb_logo_" .. xyd.Global.lang)

	self.endLabel.text = __("END_TEXT")

	if xyd.Global.lang == "de_de" then
		self.timeLabel.fontSize = 18
		self.endLabel.fontSize = 18
	end

	if xyd.Global.lang == "fr_fr" then
		self.lvLabel.text = "Niv." .. math.floor(self.activityData.detail.num / xyd.tables.miscTable:getNumber("activity_bomb_make_lv", "value"))
	else
		self.lvLabel.text = "Lv." .. math.floor(self.activityData.detail.num / xyd.tables.miscTable:getNumber("activity_bomb_make_lv", "value"))
	end

	self.itemLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FIREWORK_DUST)
	self.itemLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SP_BOMB)
	self.btnLabel.text = __("ACTIVITY_BOMB_MAKE")

	if xyd.Global.lang == "de_de" then
		self.btnLabel:Y(-42)
	end

	local cost = xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		self.redMark:SetActive(true)
	else
		self.redMark:SetActive(false)
	end
end

function ActivityBomb:initItems()
	local ids = xyd.tables.activityBombAwardTable:getIds()
	self.params = {}
	self.items = {}

	NGUITools.DestroyChildren(self.groupItem_.transform)

	for i = 1, #ids do
		local id = ids[i]

		table.insert(self.params, {
			id = id,
			award = xyd.tables.activityBombAwardTable:getAward(id),
			cost = xyd.tables.activityBombAwardTable:getCost(id),
			num = xyd.tables.activityBombAwardTable:getNum(id),
			limit = xyd.tables.activityBombAwardTable:getLimit(id),
			allNum = self.activityData.detail.num,
			buy_times = self.activityData.detail.buy_times[id]
		})
	end

	table.sort(self.params, function (a, b)
		local ACount = 0
		local BCount = 0

		if (a.buy_times < a.limit or a.limit < 0) and a.num <= a.allNum then
			ACount = ACount + 10000
		end

		if (b.buy_times < b.limit or b.limit < 0) and b.num <= b.allNum then
			BCount = BCount + 10000
		end

		if a.allNum < a.num then
			ACount = ACount + 1000
		end

		if b.allNum < b.num then
			BCount = BCount + 1000
		end

		ACount = ACount + a.id
		BCount = BCount + b.id

		return ACount > BCount
	end)

	for i = 1, #self.params do
		local tmp = NGUITools.AddChild(self.groupItem_.gameObject, self.itemCell.gameObject)
		local item = ActivityBombItem.new(tmp, self.params[i], self)

		table.insert(self.items, item)
	end

	self:waitForFrame(1, function ()
		self.groupItem_:Reposition()
		self.scrollView_:ResetPosition()
	end)
end

function ActivityBomb:updateItems()
	for i = 1, #self.params do
		self.params[i].allNum = self.activityData.detail.num
		self.params[i].buy_times = self.activityData.detail.buy_times[self.params[i].id]

		self.items[i]:setInfo(self.params[i])
	end
end

function ActivityBomb:registerEvent()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_BOMB_HELP"
		})
	end

	UIEventListener.Get(self.bombBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_bomb_gacha_window", {
			num = self.activityData.detail.num
		})
	end

	UIEventListener.Get(self.itemBtn1).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.FIREWORK_DUST,
			activityID = xyd.ActivityID.ACTIVITY_BOMB
		})
	end

	UIEventListener.Get(self.itemBtn2).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_bomb_gacha_window", {
			num = self.activityData.detail.num
		})
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxyInner_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, handler(self, self.onWindowWillClose))
end

function ActivityBomb:getAwardReq(id)
	self.curGetId = id
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_BOMB
	msg.params = require("cjson").encode({
		num = 1,
		award_id = id
	})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityBomb:onAward(event)
	local award = xyd.tables.activityBombAwardTable:getAward(self.curGetId)

	xyd.models.itemFloatModel:pushNewItems({
		{
			item_id = award[1],
			item_num = award[2]
		}
	})

	self.activityData.detail.buy_times[self.curGetId] = self.activityData.detail.buy_times[self.curGetId] + 1
	self.curGetId = 0

	self:updateItems()
end

function ActivityBomb:onItemChange()
	self.itemLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FIREWORK_DUST)
	self.itemLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SP_BOMB)
	local cost = xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		self.redMark:SetActive(true)
	else
		self.redMark:SetActive(false)
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_BOMB, function ()
	end)
end

function ActivityBomb:onWindowWillClose(event)
	if event.params.windowName ~= "activity_bomb_gacha_window" then
		return
	end

	self:initItems()

	if xyd.Global.lang == "fr_fr" then
		self.lvLabel.text = "Niv." .. math.floor(self.activityData.detail.num / xyd.tables.miscTable:getNumber("activity_bomb_make_lv", "value"))
	else
		self.lvLabel.text = "Lv." .. math.floor(self.activityData.detail.num / xyd.tables.miscTable:getNumber("activity_bomb_make_lv", "value"))
	end
end

function ActivityBombItem:ctor(goItem, params, parent)
	ActivityBombItem.super.ctor(self, goItem)

	self.go = goItem
	self.params = params
	self.parent = parent

	self:getComponent()
	self:layout()
	self:register()
end

function ActivityBombItem:getComponent()
	local goTrans = self.go.transform
	self.bg2 = goTrans:NodeByName("bg2").gameObject
	self.textLabel = goTrans:ComponentByName("bg2/label", typeof(UILabel))
	self.itemGroup = goTrans:NodeByName("itemGroup").gameObject
	self.limitLabel = goTrans:ComponentByName("limitLabel", typeof(UILabel))
	self.btn = goTrans:NodeByName("confirmBtn").gameObject
	self.btnLabel = goTrans:ComponentByName("confirmBtn/label", typeof(UILabel))
	self.btnIcon = goTrans:ComponentByName("confirmBtn/costImg", typeof(UISprite))
end

function ActivityBombItem:setInfo(params)
	self.params = params

	self:layout()
end

function ActivityBombItem:layout()
	NGUITools.DestroyChildren(self.itemGroup.transform)

	local icon = xyd.getItemIcon({
		show_has_num = true,
		notShowGetWayBtn = true,
		itemID = self.params.award[1],
		num = self.params.award[2],
		uiRoot = self.itemGroup,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		scale = Vector3(0.9074074074074074, 0.9074074074074074, 1),
		dragScrollView = self.parent.scrollView_
	})

	if self.params.limit > 0 then
		self.limitLabel:SetActive(true)

		self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.params.limit - self.params.buy_times)
	else
		self.limitLabel:SetActive(false)
	end

	xyd.setUISpriteAsync(self.btnIcon, nil, "icon_" .. self.params.cost[1])

	self.btnLabel.text = self.params.cost[2]

	if self.params.num <= self.params.allNum then
		self.bg2:SetActive(false)

		if self.params.limit - self.params.buy_times <= 0 and self.params.limit > 0 then
			icon:setChoose(true)

			self.btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btn)
		else
			icon:setChoose(false)

			self.btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.applyChildrenOrigin(self.btn)
		end
	else
		self.bg2:SetActive(true)

		self.textLabel.text = __("ACTIVITY_BOMB_UNLOCK", self.params.num / xyd.tables.miscTable:getNumber("activity_bomb_make_lv", "value"))
		self.btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.btn)
	end
end

function ActivityBombItem:register()
	UIEventListener.Get(self.btn).onClick = handler(self, function ()
		if self.params.cost[2] <= xyd.models.backpack:getItemNumByID(self.params.cost[1]) then
			xyd.alert(xyd.AlertType.YES_NO, __("FIT_UP_DORM_TIPS3"), function (yes)
				if yes then
					self.parent:getAwardReq(self.params.id)
				end
			end)
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.params.cost[1])))
		end
	end)
end

return ActivityBomb
