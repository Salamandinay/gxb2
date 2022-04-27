local CountDown = import("app.components.CountDown")
local BattleArenaGiftBag = import("app.windows.activity.BattleArenaGiftBag")
local WishingPoolGiftBag = class("BattleArenaGiftBag", BattleArenaGiftBag)
local WishingPoolGiftbagItem = class("ValueGiftBagItem", BattleArenaGiftBag.BattleArenaGiftBagItem)

function WishingPoolGiftBag:ctor(parentGO, params)
	BattleArenaGiftBag.ctor(self, parentGO, params)

	self.items = {}
	self.e_Scroller.enabled = true
end

function WishingPoolGiftBag:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("activityGroup").gameObject
	self.bgImg = self.activityGroup:ComponentByName("bgImg", typeof(UISprite))
	self.bgImg2 = self.activityGroup:ComponentByName("bgImg2", typeof(UISprite))
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
	self.imgBg1 = self.activityGroup:ComponentByName("imgBg1", typeof(UISprite))
	self.roundLabel = self.activityGroup:ComponentByName("imgBg1/roundLabel", typeof(UILabel))
	self.btn = self.activityGroup:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("label", typeof(UILabel))
	self.littleItem = go.transform:Find("level_fund_item")
end

function WishingPoolGiftBag:eventRegister()
	UIEventListener.Get(self.btn).onClick = function ()
		xyd.goWay(xyd.GoWayId.gamble, nil, function ()
			xyd.closeWindow("activity_window")
		end)
	end

	self.eventProxyInner_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, self.onWindowClose, self)
	self.eventProxyInner_:addEventListener(xyd.event.GAMBLE_GET_AWARD, self.onGetAward, self)
end

function WishingPoolGiftBag:euiComplete()
	self.btn:SetActive(true)
	self.timeLabel:X(8.5)
	self.endLabel:X(40)
	xyd.setUISpriteAsync(self.textImg, nil, "wishing_pool_giftbag_text01_" .. tostring(xyd.Global.lang), function ()
		self.textImg:SetLocalPosition(130, -86, 0)

		if xyd.Global.lang == "ko_kr" then
			self.textImg:SetLocalScale(0.8, 0.8, 0.8)
		elseif xyd.Global.lang == "fr_fr" then
			self.textImg:SetLocalPosition(130, -83, 0)
		end
	end, nil, true)

	self.bgImg.enabled = false

	xyd.setUISpriteAsync(self.bgImg2, nil, "wishing_pool_giftbag_bg01")

	self.bgImg2.enabled = true

	xyd.setUISpriteAsync(self.imgBg1, nil, "wishing_pool_giftbag_bg02")
	self.imgBg1:SetActive(true)
	self:setText()
	self:setItem()
	self:eventRegister()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" then
		self.timeLabel:X(-10)
		self.endLabel:X(-5)

		self.timeLabel.fontSize = 20
		self.endLabel.fontSize = 20
	end

	if xyd.Global.lang == "fr_fr" then
		self.timeLabel:X(15)
		self.endLabel:X(30)

		self.timeLabel.fontSize = 20
		self.endLabel.fontSize = 20
	end
end

function WishingPoolGiftBag:onWindowClose(event)
	if event.params.windowName == "gamble_window" then
		self:setText()
		self:setItem()
		self.groupItem_uigrid:Reposition()
	end
end

function WishingPoolGiftBag:onGetAward(event)
	local awards = event.data.awards
	local type_ = event.data.gamble_type

	if type_ == 1 then
		self.activityData.detail.point = self.activityData.detail.point + #awards

		if xyd.tables.activityGambleTable:getLastPoint() <= self.activityData.detail.point and self.activityData.detail.circle_times < xyd.tables.activityTable:getRound(xyd.ActivityID.WISHING_POOL_GIFTBAG)[1] then
			self.activityData.detail.point = self.activityData.detail.point - xyd.tables.activityGambleTable:getLastPoint()
			self.activityData.detail.circle_times = self.activityData.detail.circle_times + 1
		end
	end
end

function WishingPoolGiftBag:setText()
	self.endLabel.text = __("TEXT_END")

	self.endLabel:SetLocalPosition(68, -300, 0)
	self.timeLabel:SetLocalPosition(60, -300, 0)

	self.textLabel01.text = __("WISHING_POOL_GIFTBAG_TEXT01")

	self.textLabel01:SetLocalPosition(-49, -147, 0)

	self.textLabel01.fontSize = 23
	self.btnLabel.text = __("GO_TO_WISHING_POOL")
	self.roundLabel.text = __("WISHING_POOL_GIFTBAG_TEXT02", self.activityData.detail.circle_times, xyd.tables.activityTable:getRound(self.id)[2])
end

function WishingPoolGiftBag:setItem()
	local table_instance = xyd.tables.activityGambleTable
	local already_item = {}
	local ids = table_instance:getIDs()
	local not_completed_item = {}

	for i in ipairs(ids) do
		local id = ids[i]
		local is_completed = false
		local point = self.activityData.detail.point
		local up = xyd.tables.activityTable:getRound(xyd.ActivityID.WISHING_POOL_GIFTBAG)[1]

		if table_instance:getPoint(id) <= point then
			is_completed = true
		end

		local awards_info = xyd.tables.activityGambleTable:getAwards(id)
		local scaleNew = 0.7
		local cur_item = {
			id = id,
			isCompleted = is_completed,
			max_point = xyd.tables.activityGambleTable:getPoint(id),
			point = point,
			awarded = awards_info,
			scale = scaleNew
		}

		if is_completed then
			table.insert(already_item, cur_item)
		else
			table.insert(not_completed_item, cur_item)
		end
	end

	for i in ipairs(already_item) do
		table.insert(not_completed_item, already_item[i])
	end

	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(not_completed_item) do
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.littleItem.gameObject)
		local item = WishingPoolGiftbagItem.new(tmp, not_completed_item[i])

		xyd.setDragScrollView(item.goItem_, self.e_Scroller)
	end

	self.littleItem:SetActive(false)
end

function WishingPoolGiftbagItem:ctor(goItem, itemdata)
	WishingPoolGiftbagItem.super.ctor(self, goItem, itemdata)
	self.progressBar_:SetLocalScale(0.7, 0.87, 0.87)
	self.progressDesc:SetLocalScale(1.2428571428571429, 1, 1)
end

function WishingPoolGiftbagItem:initBaseInfo(itemdata)
	self.itemsGroup_:GetComponent(typeof(UILayout)).verticalAlign = UILayout.VerticalAlign.Bottom

	self.itemsGroup_:SetLocalPosition(315, -38, 0)
	xyd.setUITextureAsync(self.imgbg, "Textures/activity_web/weekly_monthly_giftbag/weekly_monthly_giftbag_bg01")

	self.labelTitle_.text = __("SUMMON_GIFTBAG_TEXT01", xyd.tables.activityGambleTable:getPoint(itemdata.id))

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.labelTitle_.width = 225
	end
end

function WishingPoolGiftbagItem:initItem(itemdata)
	local scaleNum = 0.8

	if itemdata.scale ~= nil then
		scaleNum = itemdata.scale
	end

	local level = xyd.tables.activityLevelUpTable:getLevel(self.id_)
	self.progressBar_.value = math.min(itemdata.point, itemdata.max_point) / itemdata.max_point
	self.progressDesc.text = math.min(itemdata.point, itemdata.max_point) .. "/" .. itemdata.max_point
	local isComplete = itemdata.max_point <= itemdata.point

	for i, reward in pairs(itemdata.awarded) do
		if #itemdata.awarded >= 5 then
			if i == 1 or i == 2 then
				scaleNum = 0.6
			else
				scaleNum = 0.7
			end
		end

		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			scale = Vector3(scaleNum, scaleNum, 1)
		})

		if isComplete then
			icon:setChoose(true)
		else
			icon:setChoose(false)
		end
	end
end

return WishingPoolGiftBag
