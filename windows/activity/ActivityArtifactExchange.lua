local ActivityArtifactExchange = class("ActivityArtifactExchange", import(".ActivityContent"))
local ActivityArtifactExchangeItem = class("ActivityArtifactExchangeItem")
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityArtifactExchange:ctor(parentGO, params)
	ActivityArtifactExchange.super.ctor(self, parentGO, params)
end

function ActivityArtifactExchange:getPrefabPath()
	return "Prefabs/Windows/activity/activity_artifact_exchange"
end

function ActivityArtifactExchange:initUI()
	self:getUIComponent()
	ActivityArtifactExchange.super.initUI(self)
	self:initData()
	self:initUIComponent()
	self:register()
	self:arrowMove()
end

function ActivityArtifactExchange:getUIComponent()
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.imgText = self.groupAction:ComponentByName("imgText", typeof(UISprite))
	self.timeGroup = self.groupAction:NodeByName("timeGroup").gameObject
	self.timeGroupUILayout = self.groupAction:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
	self.contentGroup = self.groupAction:NodeByName("contentGroup").gameObject
	self.resItem1 = self.contentGroup:NodeByName("resGroup/resItem1").gameObject
	self.resItem2 = self.contentGroup:NodeByName("resGroup/resItem2").gameObject
	self.resNum1 = self.resItem1:ComponentByName("num", typeof(UILabel))
	self.resNum2 = self.resItem2:ComponentByName("num", typeof(UILabel))
	self.groupNav = self.contentGroup:NodeByName("groupNav").gameObject
	self.nav_item = self.groupNav:NodeByName("nav_item").gameObject
	self.navGrid = self.groupNav:NodeByName("navGrid").gameObject
	self.groupArrow = self.contentGroup:NodeByName("groupArrow").gameObject
	self.arrowLeft = self.groupArrow:NodeByName("arrowLeft").gameObject
	self.arrowRight = self.groupArrow:NodeByName("arrowRight").gameObject
	self.groupItem = self.contentGroup:NodeByName("groupItem").gameObject
	self.exchange_item = self.go:NodeByName("exchange_item").gameObject
end

function ActivityArtifactExchange:initData()
	self.data = {}
	local ids = xyd.tables.activityArtifactExchangeTable:getIDs()

	for i = 1, #ids do
		table.insert(self.data, {
			id = ids[i],
			buy_times = self.activityData.detail.buy_times[ids[i]],
			limit_times = xyd.tables.activityArtifactExchangeTable:getLimit(ids[i])
		})
	end

	table.sort(self.data, function (a, b)
		if a.buy_times < a.limit_times ~= (b.buy_times < b.limit_times) then
			return a.buy_times - a.limit_times < b.buy_times - b.limit_times
		else
			return a.id < b.id
		end
	end)
end

function ActivityArtifactExchange:initUIComponent()
	xyd.setUISpriteAsync(self.imgText, nil, "activity_artifact_exchange_text_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")
	self.resNum1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DREAM_SLATE)
	self.resNum2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DIVINATION_CRYSTAL)

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
		self.timeLabel.transform:SetSiblingIndex(1)
	end

	self.timeGroupUILayout:Reposition()
	self:updateContent()
end

function ActivityArtifactExchange:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id == xyd.ActivityID.ACTIVITY_ARTIFACT_EXCHANGE and self.activityData.awardID then
			local awards = xyd.tables.activityArtifactExchangeTable:getAwards(self.activityData.awardID)
			local awardItem = {}

			for i = 1, #awards do
				local award = awards[i]

				table.insert(awardItem, {
					item_id = award[1],
					item_num = award[2]
				})
			end

			xyd.models.itemFloatModel:pushNewItems(awardItem)

			for i = 1, #self.data do
				self.data[i].buy_times = self.activityData.detail.buy_times[self.data[i].id]
			end

			self:updateContent()
		end
	end)
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resNum1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DREAM_SLATE)
		self.resNum2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DIVINATION_CRYSTAL)
	end)

	UIEventListener.Get(self.arrowLeft).onClick = function ()
		self.curNav = self.curNav - 1

		self:updateContent()
	end

	UIEventListener.Get(self.arrowRight).onClick = function ()
		self.curNav = self.curNav + 1

		self:updateContent()
	end

	for i = 1, self.navNum do
		UIEventListener.Get(self.navItems[i].gameObject).onClick = function ()
			if self.curNav ~= i then
				self.curNav = i

				self:updateContent()
			end
		end
	end

	UIEventListener.Get(self.resItem1).onClick = function ()
		local params = {
			itemID = xyd.ItemID.DREAM_SLATE,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.DREAM_SLATE),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.resItem2).onClick = function ()
		local params = {
			itemID = xyd.ItemID.DIVINATION_CRYSTAL,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.DIVINATION_CRYSTAL),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityArtifactExchange:updateContent()
	if not self.curNav then
		self.curNav = 1
	end

	if not self.navNum then
		self.navNum = math.floor((#self.data + 5) / 6)
	end

	if not self.navItems then
		self.navItems = {}
	end

	for i = 1, self.navNum do
		if not self.navItems[i] then
			local tmp = NGUITools.AddChild(self.navGrid, self.nav_item)
			local navSprite = tmp:GetComponent(typeof(UISprite))

			table.insert(self.navItems, navSprite)
		end

		if i == self.curNav then
			xyd.setUISpriteAsync(self.navItems[i], nil, "market_dot_bg2", nil, , true)

			self.navItems[i].width = 20
			self.navItems[i].height = 20
		else
			xyd.setUISpriteAsync(self.navItems[i], nil, "emotbtn1", nil, , true)

			self.navItems[i].width = 16
			self.navItems[i].height = 16
		end
	end

	self.navGrid:GetComponent(typeof(UIGrid)):Reposition()

	if self.navNum == 1 then
		self.navGrid:SetActive(false)
	end

	if self.curNav == 1 then
		self.arrowLeft:SetActive(false)
	else
		self.arrowLeft:SetActive(true)
	end

	if self.curNav == self.navNum then
		self.arrowRight:SetActive(false)
	else
		self.arrowRight:SetActive(true)
	end

	if not self.items then
		self.items = {}
	end

	for i = 1, 6 do
		if not self.items[i] then
			local tmp = NGUITools.AddChild(self.groupItem, self.exchange_item)
			local item = ActivityArtifactExchangeItem.new(tmp, self)

			table.insert(self.items, item)
		end

		if self.data[i + (self.curNav - 1) * 6] then
			self.items[i]:SetActive(true)
			self.items[i]:setInfo(self.data[i + (self.curNav - 1) * 6])
		else
			self.items[i]:SetActive(false)
		end
	end
end

function ActivityArtifactExchange:resizeToParent()
	ActivityArtifactExchange.super.resizeToParent(self)
	self:resizePosY(self.contentGroup, -601, -778)
end

function ActivityArtifactExchange:arrowMove()
	local positionLeft = self.arrowLeft.transform.localPosition
	local positionRight = self.arrowRight.transform.localPosition

	function self.playAni1()
		self.sequence1 = DG.Tweening.DOTween.Sequence()

		self.sequence1:Insert(0, self.arrowLeft.transform:DOLocalMove(Vector3(positionLeft.x - 5, positionRight.y, 0), 1, false))
		self.sequence1:Insert(1, self.arrowLeft.transform:DOLocalMove(Vector3(positionLeft.x + 5, positionRight.y, 0), 1, false))
		self.sequence1:Insert(0, self.arrowRight.transform:DOLocalMove(Vector3(positionRight.x + 5, positionRight.y, 0), 1, false))
		self.sequence1:Insert(1, self.arrowRight.transform:DOLocalMove(Vector3(positionRight.x - 5, positionRight.y, 0), 1, false))
		self.sequence1:AppendCallback(function ()
			self.playAni2()
		end)
	end

	function self.playAni2()
		self.sequence2 = DG.Tweening.DOTween.Sequence()

		self.sequence2:Insert(0, self.arrowLeft.transform:DOLocalMove(Vector3(positionLeft.x - 5, positionRight.y, 0), 1, false))
		self.sequence2:Insert(1, self.arrowLeft.transform:DOLocalMove(Vector3(positionLeft.x + 5, positionRight.y, 0), 1, false))
		self.sequence2:Insert(0, self.arrowRight.transform:DOLocalMove(Vector3(positionRight.x + 5, positionRight.y, 0), 1, false))
		self.sequence2:Insert(1, self.arrowRight.transform:DOLocalMove(Vector3(positionRight.x - 5, positionRight.y, 0), 1, false))
		self.sequence2:AppendCallback(function ()
			self.playAni1()
		end)
	end

	self.playAni1()
end

function ActivityArtifactExchange:dispose()
	ActivityArtifactExchange.super.dispose(self)

	if self.sequence1 then
		self.sequence1:Kill(false)

		self.sequence1 = nil
	end

	if self.sequence2 then
		self.sequence2:Kill(false)

		self.sequence2 = nil
	end
end

function ActivityArtifactExchangeItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
	self:registerEvent()
end

function ActivityArtifactExchangeItem:getUIComponent()
	self.icon = self.go:NodeByName("icon").gameObject
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.btnExchange = self.go:NodeByName("btnExchange").gameObject
	self.btnExchangeBox = self.btnExchange:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnGrid = self.btnExchange:NodeByName("btnGrid").gameObject
	self.cost_item = self.btnExchange:NodeByName("cost_item").gameObject
end

function ActivityArtifactExchangeItem:setInfo(data)
	self.data = data
	local awards = xyd.tables.activityArtifactExchangeTable:getAwards(self.data.id)

	NGUITools.DestroyChildren(self.icon.transform)

	for i = 1, #awards do
		local award = awards[i]

		xyd.getItemIcon({
			show_has_num = true,
			scale = 0.9074074074074074,
			uiRoot = self.icon,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	local costs = xyd.tables.activityArtifactExchangeTable:getCost(self.data.id)

	NGUITools.DestroyChildren(self.btnGrid.transform)

	for i = 1, #costs do
		local cost = costs[i]
		local tmp = NGUITools.AddChild(self.btnGrid, self.cost_item)
		local costIcon = tmp:ComponentByName("icon", typeof(UISprite))
		local costNum = tmp:ComponentByName("num", typeof(UILabel))

		xyd.setUISpriteAsync(costIcon, nil, "icon_" .. cost[1])

		costNum.text = tostring(cost[2])
	end

	self.btnGrid:GetComponent(typeof(UIGrid)):Reposition()

	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", self.data.limit_times - self.data.buy_times)

	if self.data.limit_times <= self.data.buy_times then
		xyd.applyChildrenGrey(self.btnExchange)
		xyd.applyChildrenGrey(self.icon)

		self.btnExchangeBox.enabled = false
	else
		xyd.applyChildrenOrigin(self.btnExchange)
		xyd.applyChildrenOrigin(self.icon)

		self.btnExchangeBox.enabled = true
	end
end

function ActivityArtifactExchangeItem:registerEvent()
	UIEventListener.Get(self.btnExchange).onClick = function ()
		local costs = xyd.tables.activityArtifactExchangeTable:getCost(self.data.id)

		for i = 1, #costs do
			local cost = costs[i]

			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

				return
			end
		end

		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
			if yes then
				local data = cjson.encode({
					award_id = self.data.id
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_ARTIFACT_EXCHANGE
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				self.parent.activityData:setAwardID(self.data.id)
			end
		end)
	end
end

function ActivityArtifactExchangeItem:SetActive(flag)
	self.go:SetActive(flag)
end

return ActivityArtifactExchange
