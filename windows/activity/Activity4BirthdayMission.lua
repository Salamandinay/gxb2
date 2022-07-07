local Activity4BirthdayMission = class("Activity4BirthdayMission", import(".ActivityContent"))
local MissionItem = class("MissionItem", import("app.components.CopyComponent"))
local cjson = require("cjson")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local labelStates = {
	chosen = {
		color = Color.New2(2489598463.0)
	},
	unchosen = {
		color = Color.New2(4294967295.0),
		effectColor = Color.New2(3634191359.0)
	}
}

function MissionItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.awardItemsArr = {}

	MissionItem.super.ctor(self, go)
end

function MissionItem:initUI()
	self.task_item = self.go
	self.progressBarUIProgressBar = self.task_item:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressLabel = self.progressBarUIProgressBar.transform:ComponentByName("progressLabel", typeof(UILabel))
	self.itemsGroup = self.task_item:NodeByName("awardGroup").gameObject
	self.itemsGroupUILayout = self.task_item:ComponentByName("awardGroup", typeof(UILayout))
	self.labelDesc = self.task_item:ComponentByName("labelDesc", typeof(UILabel))
	self.limitGroup = self.task_item:ComponentByName("limitGroup", typeof(UILayout))
	self.completeLable = self.task_item:ComponentByName("limitGroup/labelLimit", typeof(UILabel))
	self.completeNum = self.task_item:ComponentByName("limitGroup/limit", typeof(UILabel))
	self.bg = self.task_item:ComponentByName("bg", typeof(UISprite))
	UIEventListener.Get(self.bg.gameObject).onClick = handler(self, function ()
		if self.data_.get_way and self.data_.get_way > 0 then
			xyd.goWay(self.data_.get_way, nil, , function ()
				xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MISSION)
			end)
		end
	end)
end

function MissionItem:setInfo(data)
	if not data then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data_ = data
	self.id = data.id
	self.labelDesc.text = self.data_.desc
	self.value = self.data_.value
	self.completeLable.text = __("ACTIVITY_VAMPIRE_TASK_TEXT01") .. " : "

	for index, itemData in ipairs(self.data_.awards) do
		if not self.awardItemsArr[index] then
			self.awardItemsArr[index] = xyd.getItemIcon({
				notShowGetWayBtn = true,
				scale = 0.6018518518518519,
				uiRoot = self.itemsGroup,
				itemID = tonumber(itemData[1]),
				num = tonumber(itemData[2]),
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollViewMission_
			})
		else
			self.awardItemsArr[index]:setInfo({
				notShowGetWayBtn = true,
				scale = 0.6018518518518519,
				uiRoot = self.itemsGroup,
				itemID = tonumber(itemData[1]),
				num = tonumber(itemData[2]),
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollViewMission_
			})
		end
	end

	self.itemsGroupUILayout:Reposition()

	if self.data_.limit <= self.data_.is_completed then
		self.completeNum.text = self.data_.limit .. "/" .. self.data_.limit
		self.completeNum.color = Color.New2(1569849855)
		self.progressBarUIProgressBar.value = 1
		self.progressLabel.text = self.data_.complete_value .. "/" .. self.data_.complete_value

		for _, item in ipairs(self.awardItemsArr) do
			item:setChoose(true)
		end
	else
		self.completeNum.color = Color.New2(2889360639.0)
		self.completeNum.text = self.data_.is_completed .. "/" .. self.data_.limit
		self.progressBarUIProgressBar.value = self.data_.value / self.data_.complete_value
		self.progressLabel.text = self.data_.value .. "/" .. self.data_.complete_value

		for _, item in ipairs(self.awardItemsArr) do
			item:setChoose(false)
		end
	end

	self.limitGroup:Reposition()
end

function Activity4BirthdayMission:ctor(parentGO, params)
	self.curNav_ = params.pageType or 1
	self.missionItems_ = {}

	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MISSION)
	Activity4BirthdayMission.super.ctor(self, parentGO, params)
end

function Activity4BirthdayMission:getPrefabPath()
	return "Prefabs/Windows/activity/activity_4birsday_test"
end

function Activity4BirthdayMission:initUI()
	Activity4BirthdayMission.super.initUI(self)
	self:getUIComponent()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_4birthday_test_logo_" .. xyd.Global.lang)
	self:updateNav()
	self:updateCost()
	self:updateContent()
	self:register()
end

function Activity4BirthdayMission:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id == xyd.ActivityID.ACTIVITY_4BIRTHDAY_MISSION then
			local detail = cjson.decode(event.data.detail)
			local type = detail.type

			if type == 1 then
				self:updateCost()

				local items = detail.items

				xyd.itemFloat(items)

				local card_index = self.activityData:getTempOpenCard()

				if card_index and card_index > 0 then
					self:playCardEffect(card_index, "hit", 1, function ()
						self["cardItem" .. card_index]:SetActive(false)
					end)
				end

				self:updateFlowerEffect()

				return
			end

			self:updateContent()

			local items = detail.items

			xyd.itemFloat(items)
		end
	end)
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityByID))

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_4BIRTHDAY_TASK_HELP"
		})
	end

	UIEventListener.Get(self.addBtn_).onClick = function ()
		self:onClickNav(2)
	end
end

function Activity4BirthdayMission:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.costLabel_ = goTrans:ComponentByName("resGroup/countLabel", typeof(UILabel))
	self.addBtn_ = goTrans:NodeByName("resGroup/addBtn").gameObject
	self.navGroup_ = goTrans:NodeByName("navGroup")

	for i = 1, 2 do
		self["nav" .. i] = self.navGroup_:NodeByName("nav" .. i).gameObject
		self["navLabel" .. i] = self["nav" .. i]:ComponentByName("label", typeof(UILabel))
		self["navSeletImg" .. i] = self["nav" .. i]:NodeByName("selectImg").gameObject
		self["redPoint" .. i] = self["nav" .. i]:NodeByName("redPoint").gameObject
		self["navLabel" .. i].text = __("ACTIVITY_4BIRTHDAY_TASK_TEXT0" .. i)

		UIEventListener.Get(self["nav" .. i]).onClick = function ()
			self:onClickNav(i)
		end
	end

	self.scrollViewMission_ = goTrans:ComponentByName("scrollViewMission", typeof(UIScrollView))
	self.missionGrid_ = goTrans:ComponentByName("scrollViewMission/grid", typeof(UIGrid))
	self.missionItem_ = goTrans:NodeByName("missionItem").gameObject
	self.drawContent_ = goTrans:NodeByName("drawContent").gameObject
	self.cradPart_ = self.drawContent_:NodeByName("cradPart").gameObject

	for i = 1, 12 do
		self["cardItem" .. i] = self.cradPart_:NodeByName("grid/cardItem" .. i).gameObject
		self["card_effectRoot" .. i] = self["cardItem" .. i]:NodeByName("effectRoot").gameObject
		self["costLabel" .. i] = self["cardItem" .. i]:ComponentByName("costLabel", typeof(UILabel))

		self:playCardEffect(i, "idle", 0)

		UIEventListener.Get(self["cardItem" .. i]).onClick = function ()
			self:onClickCard(i)
		end
	end

	self.flowerGroup_ = self.drawContent_:NodeByName("flowerGroup").gameObject

	for i = 1, 8 do
		self["flowerItem" .. i] = self.flowerGroup_:NodeByName("flowerItem" .. i).gameObject
		self["icon" .. i] = self["flowerItem" .. i]:ComponentByName("icon", typeof(UISprite))
		self["labelNum" .. i] = self["flowerItem" .. i]:ComponentByName("labelNum", typeof(UILabel))
		self["effectRoot" .. i] = self["flowerItem" .. i]:NodeByName("effectRoot").gameObject
		self["bgImg" .. i] = self["flowerItem" .. i]:NodeByName("bgImg").gameObject
		self["select" .. i] = self["flowerItem" .. i]:NodeByName("imgChoose_").gameObject

		UIEventListener.Get(self["flowerItem" .. i]).onClick = function ()
			self:onClickFlower(i)
		end
	end

	self.redPoint2:SetActive(false)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_MISSION, self.redPoint1)
end

function Activity4BirthdayMission:playCardEffect(index, name, loop_time, callback)
	if not self.cardEffects_ then
		self.cardEffects_ = {}
	end

	if not self.cardEffects_[index] then
		self.cardEffects_[index] = xyd.Spine.new(self["card_effectRoot" .. index])

		self.cardEffects_[index]:setInfo("activity_4birthday_task", function ()
			self.cardEffects_[index]:play(name, loop_time, 1)
			self.cardEffects_[index]:SetLocalPosition(-30, -45, 0)
		end)
	else
		self.cardEffects_[index]:play(name, loop_time, 1)
	end

	if callback then
		self:waitForTime(1.4, function ()
			callback()
		end)
	end
end

function Activity4BirthdayMission:updateNav()
	for i = 1, 2 do
		if i == self.curNav_ then
			self:changeTextColor(self["navLabel" .. i], "chosen")
			self["navSeletImg" .. i]:SetActive(true)

			self["navLabel" .. i].effectStyle = UILabel.Effect.None
		else
			self:changeTextColor(self["navLabel" .. i], "unchosen")
			self["navSeletImg" .. i]:SetActive(false)

			self["navLabel" .. i].effectStyle = UILabel.Effect.Outline8
		end
	end
end

function Activity4BirthdayMission:changeTextColor(label, selectStr)
	label.color = labelStates[selectStr].color

	if labelStates[selectStr].effectColor then
		label.effectStyle = UILabel.Effect.Outline8
		label.effectColor = labelStates[selectStr].effectColor
	else
		label.effectStyle = UILabel.Effect.None
	end
end

function Activity4BirthdayMission:updateCost()
	self.costLabel_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.BIRTHDAY4_TEST_ICON)
end

function Activity4BirthdayMission:updateContent()
	if self.curNav_ == 1 then
		self.scrollViewMission_.gameObject:SetActive(false)
		self.drawContent_:SetActive(true)
		self:updateCards()
	else
		self.scrollViewMission_.gameObject:SetActive(true)
		self.drawContent_:SetActive(false)
		self:updateMission()
	end
end

function Activity4BirthdayMission:updateCards()
	local awards = self.activityData.detail.awards
	local extras = self.activityData.detail.extras
	local is_big = self.activityData.detail.big_award
	local cost = xyd.split(xyd.tables.miscTable:getVal("activity_4birthday_task_cost"), "#", true)
	local sp = xyd.split(xyd.tables.miscTable:getVal("activity_4birthday_task_awards"), "|")
	local extrasAward = {}

	for i = 1, #sp do
		extrasAward[i] = xyd.split(sp[i], "#", true)
	end

	local big_award = xyd.split(xyd.tables.miscTable:getVal("activity_4birthday_task_bigaward"), "#")

	for i = 1, 12 do
		if awards[i] and awards[i] == 1 then
			self["cardItem" .. i]:SetActive(false)
		else
			self["cardItem" .. i]:SetActive(true)

			self["costLabel" .. i].text = "x" .. cost[2]
		end
	end

	for i = 1, 7 do
		local award = extrasAward[i]
		local icon = xyd.tables.itemTable:getIcon(tonumber(award[1]))

		xyd.setUISpriteAsync(self["icon" .. i], nil, icon)

		self["labelNum" .. i].text = award[2]

		if extras and extras[i] == 1 then
			self["select" .. i]:SetActive(true)
		else
			self["select" .. i]:SetActive(false)
		end
	end

	local icon = xyd.tables.itemTable:getIcon(tonumber(big_award[1]))

	xyd.setUISpriteAsync(self["icon" .. 8], nil, icon)

	self["labelNum" .. 8].text = big_award[2]

	if is_big and is_big == 1 then
		self["select" .. 8]:SetActive(true)
	else
		self["select" .. 8]:SetActive(false)
	end

	self:updateFlowerEffect()
end

function Activity4BirthdayMission:updateFlowerEffect()
	local active_list = self.activityData:getExtraActiveList()

	if not self.flowerEffect_ then
		self.flowerEffect_ = {}
	end

	for i = 1, 7 do
		if xyd.arrayIndexOf(active_list, i) < 0 then
			if self.flowerEffect_[i] then
				self.flowerEffect_[i]:SetActive(false)
			end
		elseif not self.flowerEffect_[i] then
			self.flowerEffect_[i] = xyd.Spine.new(self["effectRoot" .. i])

			self.flowerEffect_[i]:setInfo("activity_4birthday_task", function ()
				self.flowerEffect_[i]:play("texiao01", 0, 1)
			end)
		else
			self.flowerEffect_[i]:SetActive(true)
		end
	end

	if self.activityData:getFinalActive() then
		if not self.flowerEffect_[8] then
			self.flowerEffect_[8] = xyd.Spine.new(self["effectRoot" .. 8])

			self.flowerEffect_[8]:setInfo("activity_4birthday_task", function ()
				self.flowerEffect_[8]:play("texiao01", 0, 1)
			end)
		else
			self.flowerEffect_[8]:SetActive(true)
		end
	elseif self.flowerEffect_[8] then
		self.flowerEffect_[8]:SetActive(false)
	end
end

function Activity4BirthdayMission:updateMission()
	local ids = xyd.tables.activity4BirthdayMissionTable:getIDs()

	table.sort(ids)

	local missionList = {}

	for _, id in ipairs(ids) do
		local params = {
			id = id
		}
		params.is_completed = self.activityData.detail.is_completeds[params.id]
		params.value = self.activityData.detail.values[params.id]
		params.limit = xyd.tables.activity4BirthdayMissionTable:getLimit(params.id)
		params.complete_value = xyd.tables.activity4BirthdayMissionTable:getCompValue(params.id)
		params.get_way = xyd.tables.activity4BirthdayMissionTable:getGetWay(params.id)
		params.awards = xyd.tables.activity4BirthdayMissionTable:getAward(params.id)
		params.desc = xyd.tables.activity4BirthdayMissionTable:getDesc(params.id)

		table.insert(missionList, params)
	end

	table.sort(missionList, function (a, b)
		local avalue = a.id
		local bvalue = b.id

		if a.limit <= a.is_completed then
			avalue = avalue + 1000
		end

		if b.limit <= b.is_completed then
			bvalue = bvalue + 1000
		end

		return avalue < bvalue
	end)

	for index, data in ipairs(missionList) do
		if not self.missionItems_[data.id] then
			local rootNew = NGUITools.AddChild(self.missionGrid_.gameObject, self.missionItem_)

			rootNew:SetActive(true)

			self.missionItems_[data.id] = MissionItem.new(rootNew, self)
		end

		self.missionItems_[data.id]:setInfo(data)
	end

	self:waitForFrame(1, function ()
		self.missionGrid_:Reposition()
		self.scrollViewMission_:ResetPosition()
	end)
end

function Activity4BirthdayMission:onClickNav(index)
	if index ~= self.curNav_ then
		self.curNav_ = index

		self:updateNav()
		self:updateContent()
	end
end

function Activity4BirthdayMission:onClickCard(card_index)
	local cost = xyd.split(xyd.tables.miscTable:getVal("activity_4birthday_task_cost"), "#", true)
	local sp = xyd.split(xyd.tables.miscTable:getVal("activity_4birthday_task_get"), "|")
	local itemInfo = {}

	for i = 1, #sp do
		itemInfo[i] = xyd.split(sp[i], "#", true)
	end

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("ACTIVITY_4BIRTHDAY_TASK_TIPS01"))

		return
	else
		xyd.WindowManager.get():openWindow("dates_alert_window", {
			itemPos = 2,
			descPos = 106,
			title = __("ACTIVITY_4BIRTHDAY_TASK_TEXT01"),
			desc = __("ACTIVITY_4BIRTHDAY_TASK_AWARD"),
			itemInfo = itemInfo,
			callback = function (yes_no)
				if not yes_no then
					return
				end

				local data = cjson.encode({
					type = 1,
					id = card_index
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_4BIRTHDAY_MISSION
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				self.activityData:setOpenCard(card_index)
			end
		})
	end
end

function Activity4BirthdayMission:onClickFlower(flower_index)
	if flower_index == 8 then
		if self.activityData:getFinalActive() then
			local data = cjson.encode({
				type = 3
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_4BIRTHDAY_MISSION
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		else
			local big_award = xyd.split(xyd.tables.miscTable:getVal("activity_4birthday_task_bigaward"), "#")
			local params = {
				notShowGetWayBtn = true,
				noClickSelected = true,
				show_has_num = true,
				itemID = tonumber(big_award[1]),
				itemNum = big_award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		end
	else
		local id_list = self.activityData:getExtraActiveList()

		if id_list and #id_list > 0 and xyd.arrayIndexOf(id_list, flower_index) > 0 then
			local data = cjson.encode({
				type = 2,
				indexs = id_list
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_4BIRTHDAY_MISSION
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		else
			local sp = xyd.split(xyd.tables.miscTable:getVal("activity_4birthday_task_awards"), "|")
			local extrasAward = {}

			for i = 1, #sp do
				extrasAward[i] = xyd.split(sp[i], "#", true)
			end

			local params = {
				notShowGetWayBtn = true,
				noClickSelected = true,
				show_has_num = true,
				itemID = tonumber(extrasAward[flower_index][1]),
				itemNum = extrasAward[flower_index][2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		end
	end
end

function Activity4BirthdayMission:onActivityByID()
	self:updateCost()
	self:updateContent()
end

return Activity4BirthdayMission
