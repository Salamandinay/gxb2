local ActivitySantaVisit = class("ActivitySantaVisit", import(".ActivityContent"))
local ActivitySantaVisitItem = class("ActivitySantaVisitItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivitySantaVisit:ctor(parentGO, params)
	ActivitySantaVisit.super.ctor(self, parentGO, params)
end

function ActivitySantaVisit:getPrefabPath()
	return "Prefabs/Windows/activity/activity_santa_visit"
end

function ActivitySantaVisit:resizeToParent()
	ActivitySantaVisit.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874
end

function ActivitySantaVisit:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SANTA_VISIT)
	self.activityData.PerSignInRedPoint = false
	self.effectTimes = {
		1.2,
		0.8,
		2.4,
		0.6,
		1.2,
		1.8,
		0.2,
		2.7,
		3.7,
		0.2
	}
	self.helpEffectFlags = {}

	self:getUIComponent()
	ActivitySantaVisit.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivitySantaVisit:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.titleImg_ = self.groupAction:ComponentByName("titleImg_", typeof(UITexture))
	self.btnLevelAward = self.groupAction:NodeByName("btnLevelAward").gameObject
	self.labelLevel = self.btnLevelAward:ComponentByName("labelLevel", typeof(UILabel))
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.btnHelp = self.topGroup:NodeByName("btnHelp").gameObject
	self.btnHaveGotAward = self.topGroup:NodeByName("btnHaveGotAward").gameObject
	self.resourcesGroup = self.topGroup:NodeByName("resourcesGroup").gameObject
	self.resource1Group = self.resourcesGroup:NodeByName("resource1Group").gameObject
	self.imgResource1 = self.resource1Group:ComponentByName("img_", typeof(UISprite))
	self.labelResource1 = self.resource1Group:ComponentByName("label_", typeof(UILabel))
	self.addBtn1 = self.resource1Group:NodeByName("addBtn").gameObject
	self.resource2Group = self.resourcesGroup:NodeByName("resource2Group").gameObject
	self.imgResource2 = self.resource2Group:ComponentByName("img_", typeof(UISprite))
	self.labelResource2 = self.resource2Group:ComponentByName("label_", typeof(UILabel))
	self.addBtn2 = self.resource2Group:NodeByName("addBtn").gameObject
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.awardGroup = self.midGroup:NodeByName("awardGroup").gameObject
	self.grid1 = self.awardGroup:ComponentByName("grid1", typeof(UIGrid))
	self.grid2 = self.awardGroup:ComponentByName("grid2", typeof(UIGrid))
	self.grid3 = self.awardGroup:ComponentByName("grid3", typeof(UIGrid))
	self.awardItem = self.awardGroup:NodeByName("item").gameObject
	self.btnAward = self.midGroup:NodeByName("btnAward").gameObject
	self.labelbtnAward = self.btnAward:ComponentByName("label", typeof(UILabel))
end

function ActivitySantaVisit:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateResGroup()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id == xyd.ActivityID.ACTIVITY_SANTA_VISIT then
			self:onGetMsg(event)
		end
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_SOCKS_GAMBLE_HELP"
		})
	end

	UIEventListener.Get(self.btnHaveGotAward).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_space_explore_awarded_window", {
			data = self.activityData:getHaveGotAwardList(),
			labelNone = __("ACTIVITY_SOCKS_GAMBLE_NONE"),
			winTitle = __("ACTIVITY_CHRISTMAS_SIGN_UP_TEXT01")
		})
	end

	UIEventListener.Get(self.addBtn1).onClick = function ()
		local data = self.activityData:getResource1()
		local params = {
			showGetWays = true,
			itemID = data[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.addBtn2).onClick = function ()
		xyd.goToActivityWindowAgain({
			activity_type = xyd.tables.activityTable:getType2(xyd.ActivityID.ACTIVITY_SANTA_VISIT),
			select = xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE
		})
	end

	UIEventListener.Get(self.btnLevelAward).onClick = function ()
		self:clickBtnLevelAward()
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		if #self.effectList == 0 then
			self:initEffectGroup()
		end

		if #self.effectList == 0 then
			return
		end

		self:clickBtnAward()
	end
end

function ActivitySantaVisit:initUIComponent()
	self.labelbtnAward.text = __("ACTIVITY_SOCKS_GAMBLE_BUTTON")
	self.btnLevelAward:ComponentByName("label", typeof(UILabel)).text = __("TOWER_TEXT02")

	xyd.setUITextureByNameAsync(self.titleImg_, "activity_santa_visit_logo_" .. xyd.Global.lang)
	self:updateAwardGroup()
	self:updateResGroup()
	self:updateRedPoint()
	self:updateLevelGroup()
end

function ActivitySantaVisit:updateAwardGroup()
	if not self.awardItems then
		self.awardItems = {}
		local awardDataList = self.activityData:getAwardList()

		for i = 1, #awardDataList do
			local award = awardDataList[i]
			local awardItem = nil
			local index = i % 2
			local low = nil

			if i <= 3 then
				awardItem = NGUITools.AddChild(self.grid1.gameObject, self.awardItem)

				if index == 0 then
					index = 1
				else
					index = 2
				end
			elseif i <= 7 then
				if index == 0 then
					index = 2
				else
					index = 1
				end

				awardItem = NGUITools.AddChild(self.grid2.gameObject, self.awardItem)
			else
				low = true
				index = index == 0 and 2 or 1
				awardItem = NGUITools.AddChild(self.grid3.gameObject, self.awardItem)
			end

			xyd.setUITextureByNameAsync(awardItem:ComponentByName("line", typeof(UITexture)), "activity_santa_icon_xian_" .. index, true)
			xyd.setUITextureByNameAsync(awardItem:ComponentByName("line", typeof(UITexture)), "activity_santa_icon_xian_" .. index, true)

			local item = ActivitySantaVisitItem.new(awardItem, self)

			item:setInfo({
				award = award,
				index = i,
				low = low
			})
			table.insert(self.awardItems, item)
		end

		self:initEffectGroup()
	else
		local awardDataList = self.activityData:getAwardList()

		for i = 1, #awardDataList do
			local award = awardDataList[i]

			self.awardItems[i]:setInfo({
				award = award,
				index = i
			})
		end
	end

	self.grid1:Reposition()
	self.grid2:Reposition()
	self.grid3:Reposition()
end

function ActivitySantaVisit:initEffectGroup()
	local awardDataList = self.activityData:getAwardList()
	self.effectList = {}

	for i = 1, #self.awardItems do
		local effect = self.awardItems[i]:getEffect()
		self.effectList[i] = effect
	end
end

function ActivitySantaVisit:playEffect(index, effectName)
end

function ActivitySantaVisit:updateLevelGroup()
	local curLevel = self.activityData:getCurLevel()
	self.labelLevel.text = __("ACTIVITY_SOCKS_GAMBLE_LEVEL", curLevel)
end

function ActivitySantaVisit:updateResGroup()
	local res1Data = self.activityData:getResource1()

	xyd.setUISpriteAsync(self.imgResource1, nil, xyd.tables.itemTable:getIcon(res1Data[1]))

	self.labelResource1.text = xyd.models.backpack:getItemNumByID(res1Data[1])
	local res2Data = self.activityData:getResource2()

	xyd.setUISpriteAsync(self.imgResource2, nil, xyd.tables.itemTable:getIcon(res2Data[1]))

	self.labelResource2.text = xyd.models.backpack:getItemNumByID(res2Data[1])
end

function ActivitySantaVisit:showDrawResult()
	xyd.models.itemFloatModel:pushNewItems(self.awards)
	self:updateRedPoint()
	self:updateResGroup()
	self:updateLevelGroup()
	self:updateAwardGroup()
end

function ActivitySantaVisit:updateRedPoint()
	local awardRedPoint = self.btnAward:NodeByName("redPoint").gameObject

	awardRedPoint:SetActive(self.activityData:getRedPointOfDraw())

	local levelRedPoint = self.btnLevelAward:NodeByName("redPoint").gameObject

	levelRedPoint:SetActive(self.activityData:getRedPointOfCanGetLevelAward())
end

function ActivitySantaVisit:clickBtnLevelAward()
	local all_info = {}
	local ids = xyd.tables.activityChristmasSocksLevelTable:getIDs()

	for j in pairs(ids) do
		local data = {
			id = j,
			max_value = xyd.tables.activityChristmasSocksLevelTable:getLevel(j)
		}
		data.name = __("ACTIVITY_SOCKS_LEVEL_AWARD", math.floor(data.max_value))
		data.cur_value = self.activityData:getCurLevel()

		if data.max_value < data.cur_value then
			data.cur_value = data.max_value
		end

		data.items = xyd.tables.activityChristmasSocksLevelTable:getAwards(j)

		if self.activityData:getLevelAwardedData()[j] == 0 then
			if data.cur_value == data.max_value then
				data.state = 1
			else
				data.state = 2
			end
		else
			data.state = 3
		end

		table.insert(all_info, data)
	end

	xyd.WindowManager.get():openWindow("common_progress_award_window", {
		if_sort = true,
		all_info = all_info,
		title_text = __("ACTIVITY_SOCKS_LEVEL_TITLE"),
		click_callBack = function (info)
			if self.activityData:getEndTime() <= xyd.getServerTime() then
				xyd.alertTips(__("ACTIVITY_END_YET"))

				return
			end

			self:getLevelAward(info.id)
		end,
		wnd_type = xyd.CommonProgressAwardWindowType.ACTIVITY_SANTA_VISIT
	})
end

function ActivitySantaVisit:clickBtnAward()
	local singleCost = self.activityData:getSingleCost()
	local resNum = xyd.models.backpack:getItemNumByID(singleCost[1])

	if resNum < singleCost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(singleCost[1])))

		return
	end

	local singleMaxTime = self.activityData:getSingleDrawLimit()
	local canDrawTime = math.floor(resNum / singleCost[2])
	local select_max_num = math.min(canDrawTime, singleMaxTime)

	xyd.WindowManager.get():openWindow("common_use_cost_window", {
		select_max_num = select_max_num,
		show_max_num = select_max_num * singleCost[2],
		select_multiple = singleCost[2],
		icon_info = {
			height = 45,
			width = 45,
			name = xyd.tables.itemTable:getIcon(singleCost[1])
		},
		title_text = __("ACTIVITY_SOCKS_GAMBLE_TITLE"),
		explain_text = __("ACTIVITY_SOCKS_GAMBLE_TEXT01"),
		sure_callback = function (num)
			self:getAward(num)

			local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

			if common_use_cost_window_wd then
				xyd.WindowManager.get():closeWindow("common_use_cost_window")
			end
		end
	})
end

function ActivitySantaVisit:getAward(num)
	self.btnAward.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SANTA_VISIT, json.encode({
		type = 1,
		num = num
	}))
end

function ActivitySantaVisit:onGetMsg(event)
	local data = event.data
	local detail = json.decode(data.detail)
	local costData = xyd.models.activity:getActivity(xyd.ActivityID.CHRISTMAS_COST)

	if costData and costData.detail and costData.detail.times and detail.num then
		costData.detail.times = costData.detail.times + detail.num
	end

	if not detail.table_id then
		local index = detail.award_ids[1]
		self.alphaSequence1 = self:getSequence()

		self.alphaSequence1:Insert(2.2, xyd.getTweenAlpha(self.awardItems[index]:getUIRoot():ComponentByName("", typeof(UIWidget)), 0.01, 0.1))
		self.alphaSequence1:Insert(3, xyd.getTweenAlpha(self.awardItems[index]:getUIRoot():ComponentByName("", typeof(UIWidget)), 1, 0.5))
		self.alphaSequence1:AppendCallback(function ()
			if self.alphaSequence1 then
				self.alphaSequence1:Kill(true)

				self.alphaSequence1 = nil
			end
		end)

		self.helpEffectFlags[detail.award_ids[1]] = true

		self.effectList[detail.award_ids[1]]:play("texiao02", 1, 1, function ()
			self:showDrawResult()

			self.btnAward.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			self.effectList[detail.award_ids[1]]:play("texiao01", 0, 1, function ()
			end, true)
		end, true)

		self.awards = detail.items
	else
		local items = xyd.tables.activityChristmasSocksLevelTable:getAwards(self.level_tableID)
		local awards = {}

		for i = 1, #items do
			table.insert(awards, {
				item_id = items[i][1],
				item_num = items[i][2]
			})
		end

		xyd.models.itemFloatModel:pushNewItems(awards)

		local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

		if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_SANTA_VISIT then
			common_progress_award_window_wn:updateItemState(self.level_tableID, 3)
		end

		self.level_tableID = nil
	end

	self:updateRedPoint()
end

function ActivitySantaVisit:getLevelAward(tableID)
	self.level_tableID = tableID

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SANTA_VISIT, json.encode({
		type = 2,
		table_id = tableID
	}))
end

function ActivitySantaVisit:dispose()
	ActivitySantaVisit.super.dispose(self)
end

function ActivitySantaVisitItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	ActivitySantaVisitItem.super.ctor(self, go)
	self:initUI()
end

function ActivitySantaVisitItem:initUI()
	self:getUIComponent()
end

function ActivitySantaVisitItem:getUIComponent()
	self.imgIcon = self.go:ComponentByName("imgIcon", typeof(UISprite))
	self.labelNum = self.go:ComponentByName("labelNum", typeof(UILabel))
	self.labelLevel = self.go:ComponentByName("labelLevel", typeof(UILabel))
	self.clickMask = self.go:NodeByName("clickMask").gameObject
	self.effectPos = self.go:ComponentByName("effectPos", typeof(UITexture))

	UIEventListener.Get(self.clickMask).onClick = function ()
		local params = {
			itemID = self.award[1],
			itemNum = self.award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivitySantaVisitItem:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if not self.effect then
		self.effect = xyd.Spine.new(self.effectPos.gameObject)

		self.effect:setInfo("fx_christmas_sock", function ()
			self.effect:setRenderTarget(self.effectPos.gameObject:GetComponent(typeof(UITexture)), 11 - params.index)
			self.effect:SetLocalPosition(-360, 600, 0)
			self.effect:followBone("200k", self.labelNum.gameObject)
			self.effect:followBone("lv", self.labelLevel.gameObject)
			self.effect:followBone("icon1", self.imgIcon.gameObject)
			self:waitForTime(self.parent.effectTimes[params.index], function ()
				if self.parent.helpEffectFlags[params.index] then
					return
				end

				self.effect:play("texiao01", 0, 1, function ()
				end, true)
			end)
		end)
	end

	self.award = params.award
	self.item_id = self.award[1]
	self.item_num = self.award[2]
	self.level = self.award[3]
	self.labelLevel.text = "LV." .. self.level

	if xyd.Global.lang == "fr_fr" then
		self.labelLevel.text = "Niv." .. self.level
	end

	self.labelNum.text = xyd.getRoughDisplayNumber(self.item_num)
	local type = xyd.tables.itemTable:getType(self.item_id)

	xyd.setUISpriteAsync(self.imgIcon, nil, xyd.tables.itemTable:getIcon(self.item_id))
end

function ActivitySantaVisitItem:getEffect()
	return self.effect
end

function ActivitySantaVisitItem:getUIRoot()
	return self.go
end

return ActivitySantaVisit
