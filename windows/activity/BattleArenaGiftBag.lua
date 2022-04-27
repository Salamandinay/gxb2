local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local BattleArenaGiftBag = class("BattleArenaGiftBag", ActivityContent)
local BattleArenaGiftBagItem = class("BattleArenaGiftBagItem", import("app.components.CopyComponent"))
BattleArenaGiftBag.BattleArenaGiftBagItem = BattleArenaGiftBagItem

function BattleArenaGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.currentState = xyd.Global.lang
	self.data = {}

	self:getUIComponent()
	self:euiComplete()
	self:checkIfMove()
end

function BattleArenaGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/list_time_common_activity"
end

function BattleArenaGiftBag:getUIComponent()
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
	self.littleItem = go.transform:Find("level_fund_item")
end

function BattleArenaGiftBag:euiComplete()
	local res_prefix = "Textures/activity_text_web/"

	xyd.setUISpriteAsync(self.textImg, nil, "battle_arena_giftbag_text01_" .. xyd.Global.lang, nil, , true)

	res_prefix = "Textures/activity_web/battle_arena_giftbag/"

	xyd.setUISpriteAsync(self.bgImg, nil, "battle_arena_giftbag_bg01")
	self:setText()
	self:setItem()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end
end

function BattleArenaGiftBag:setText()
	self.endLabel.text = __("TEXT_END")
	self.textLabel01.text = __("BATTLE_ARENA_GIFTBAG_TEXT01")
end

function BattleArenaGiftBag:setItem()
	local ids = xyd.tables.activityArenaTable:getIDs()
	self.data = {}

	for i, v in pairs(ids) do
		local id = ids[i]
		local is_completed = false
		local type = xyd.tables.activityArenaTable:getType(id)

		if xyd.tables.activityArenaTable:getPoint(id) <= self:getPoint(type) then
			is_completed = true
		end

		local awards_info = xyd.tables.activityArenaTable:getAwards(id)
		local param = {
			id = id,
			isCompleted = is_completed,
			max_point = self:getMaxPoint(type, id),
			point = self:getPoint(type),
			type = type,
			awarded = awards_info,
			get_way = xyd.tables.activityArenaTable:getJumpWay(id)
		}

		table.insert(self.data, param)
	end

	table.sort(self.data, function (a, b)
		return tonumber(a.id) < tonumber(b.id)
	end)

	local tempArr = {}

	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(self.data) do
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.littleItem.gameObject)

		table.insert(tempArr, tmp)

		local item = BattleArenaGiftBagItem.new(tmp, self.data[i])
	end

	self.littleItem:SetActive(false)
end

function BattleArenaGiftBag:checkIfMove()
	if #self.data * self.groupItem_uigrid.cellHeight <= self.e_Scroller_uiPanel.height then
		self.e_Scroller.enabled = false
	end
end

function BattleArenaGiftBag:getPoint(type)
	if type == 1 then
		local point = 0

		for i, v in pairs(self.activityData.detail.awarded) do
			if self.activityData.detail.awarded[i] then
				point = point + 1
			end
		end

		return point
	elseif type == 2 then
		return self.activityData.detail.point_2
	elseif type == 3 then
		return self.activityData.detail.point_3
	end
end

function BattleArenaGiftBag:getMaxPoint(type, id)
	if type == 1 then
		return #xyd.tables.activityArenaTable:getIDs()
	else
		return xyd.tables.activityArenaTable:getPoint(id)
	end
end

function BattleArenaGiftBagItem:ctor(goItem, itemdata)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.getWayId_ = itemdata.get_way
	self.id_ = tonumber(itemdata.id)
	self.ifLock_ = itemdata.ifLock
	self.imgbg = transGo:ComponentByName("e:Image", typeof(UITexture))
	self.imgSprite = transGo:ComponentByName("e:Image", typeof(UISprite))
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem(itemdata)
	self:initBaseInfo(itemdata)
end

function BattleArenaGiftBagItem:initBaseInfo(itemdata)
	if itemdata.type == 1 then
		self.labelTitle_.text = __("COMPLETE_ALL_MISSIONS")

		xyd.setUITextureAsync(self.imgbg, "Textures/activity_web/miracle_giftbag/miracle_giftbag_special_item_bg")
	else
		xyd.setUITextureAsync(self.imgbg, "Textures/activity_web/weekly_monthly_giftbag/weekly_monthly_giftbag_bg01")

		if itemdata.type == 2 then
			self.labelTitle_.text = __("ARENA_GIFTBAG_TEXT02_WITH_POINT", itemdata.max_point)
		end

		if itemdata.type == 3 then
			self.labelTitle_.text = __("ARENA_GIFTBAG_TEXT03_WITH_POINT", itemdata.max_point)
		end
	end
end

function BattleArenaGiftBagItem:initItem(itemdata)
	local scaleNum = 0.8

	if itemdata.scale ~= nil then
		scaleNum = itemdata.scale
	end

	local level = xyd.tables.activityLevelUpTable:getLevel(self.id_)
	local gotten = false
	self.progressBar_.value = math.min(itemdata.point, itemdata.max_point) / itemdata.max_point
	self.progressDesc.text = math.min(itemdata.point, itemdata.max_point) .. "/" .. itemdata.max_point

	if self.progressBar_.value == 1 then
		gotten = true
	end

	for i, reward in pairs(itemdata.awarded) do
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			scale = Vector3(scaleNum, scaleNum, 1),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		icon:setChoose(gotten)
	end

	if self.getWayId_ and tonumber(self.getWayId_) > 0 then
		local function onClick()
			xyd.goWay(self.getWayId_, nil, , )
		end

		UIEventListener.Get(self.goItem_.gameObject).onClick = onClick
	end
end

return BattleArenaGiftBag
