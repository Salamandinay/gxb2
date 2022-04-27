local CountDown = import("app.components.CountDown")
local BattleArenaGiftBag = import("app.windows.activity.BattleArenaGiftBag")
local PubMissionGiftBag = class("BattleArenaGiftBag", BattleArenaGiftBag)
local PubMissionGiftBagItem = class("ValueGiftBagItem", BattleArenaGiftBag.BattleArenaGiftBagItem)

function PubMissionGiftBag:ctor(parentGO, params)
	BattleArenaGiftBag.ctor(self, parentGO, params)
end

function PubMissionGiftBag:euiComplete()
	xyd.setUISpriteAsync(self.textImg, nil, "pub_mission_giftbag_text01_" .. xyd.Global.lang, function ()
		if xyd.Global.lang == "ko_kr" then
			self.textImg:Y(-85)
			self.textLabel01:Y(-165)
			self.timeLabel:Y(-290)
			self.endLabel:Y(-290)
		end
	end, nil, true)
	xyd.setUISpriteAsync(self.bgImg, nil, "pub_mission_giftbag_bg01")
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

function PubMissionGiftBag:setText()
	self.endLabel.text = __("TEXT_END")
	self.textLabel01.text = __("PUB_MISSION_GIFTBAG_TEXT01")
end

function PubMissionGiftBag:setItem()
	local ids = xyd.tables.activityPubMissionTable:getIDs()
	self.data = {}

	for i, v in pairs(ids) do
		local id = tonumber(ids[i])
		local is_completed = false

		if xyd.tables.activityPubMissionTable:getCompleteValue(id) <= self:getPoint(id) then
			is_completed = true
		end

		local awards_info = xyd.tables.activityPubMissionTable:getAwards(id)
		local param = {
			id = id,
			isCompleted = is_completed,
			max_point = xyd.tables.activityPubMissionTable:getCompleteValue(id),
			point = self:getPoint(id),
			awarded = awards_info,
			get_way = xyd.tables.activityPubMissionTable:getJumpWay(id)
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

		local item = PubMissionGiftBagItem.new(tmp, self.data[i])
	end

	self.littleItem:SetActive(false)
end

function PubMissionGiftBag:getPoint(id)
	return self.activityData.detail.values[id]
end

function PubMissionGiftBagItem:ctor(goItem, itemdata)
	PubMissionGiftBagItem.super.ctor(self, goItem, itemdata)
end

function PubMissionGiftBagItem:initBaseInfo(itemdata)
	xyd.setUITextureAsync(self.imgbg, "Textures/activity_web/weekly_monthly_giftbag/weekly_monthly_giftbag_bg01")

	self.labelTitle_.text = __("PUB_MISSION_WITH_STAR", xyd.tables.activityPubMissionTable:getStar(itemdata.id))
end

return PubMissionGiftBag
