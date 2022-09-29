local ActivityPirate = class("ActivityPirate", import(".ActivityContent"))
local cjson = require("cjson")
local PirateLandItem = class("PirateLandItem", import("app.components.CopyComponent"))

function PirateLandItem:ctor(goItem, index, parent)
	self.parent_ = parent
	self.index_ = index
	self.activityData = self.parent_.activityData

	PirateLandItem.super.ctor(self, goItem)
end

function PirateLandItem:initUI()
	PirateLandItem.super.initUI(self)
	self:getUIComponent()
	self:updateState()
end

function PirateLandItem:getUIComponent()
	local goTrans = self.go.transform
	self.swapBtn_ = goTrans:NodeByName("swapBtn").gameObject
	self.swapBtnLabel_ = goTrans:ComponentByName("swapBtn/label", typeof(UILabel))
	self.swapBtnRed_ = goTrans:NodeByName("swapBtn/redPoint").gameObject
	self.storyList_ = goTrans:ComponentByName("storyList", typeof(UILayout))
	self.storyItem_ = goTrans:NodeByName("storyItem").gameObject
	self.progressBar_ = goTrans:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel_ = goTrans:ComponentByName("progressBar/label", typeof(UILabel))
	self.swapBtnLabel_.text = __("ACTIVITY_PIRATE_TEXT05")
	UIEventListener.Get(self.swapBtn_).onClick = handler(self, self.onClickSwap)
end

function PirateLandItem:checkFinish(story_id)
	if story_id <= 0 then
		return true
	end

	return xyd.arrayIndexOf(self.activityData.detail.story_ids, story_id) > 0
end

function PirateLandItem:setRedState(state)
	self.swapBtnRed_:SetActive(state)
end

function PirateLandItem:updateState()
	if not self.storyItemList_ then
		self.storyItemList_ = {}
	end

	local storyList = xyd.tables.activityPiratePlotListTable:getIdsByMapId(self.index_)

	table.sort(storyList)

	local totalNum = 0
	local finishNum = 0
	local showNum = 0

	for index, id in ipairs(storyList) do
		local text_type = xyd.tables.activityPiratePlotListTable:getTextType(id)
		local needUnlocks = xyd.tables.activityPiratePlotListTable:getUnlockIDs(id)
		local disapperID = xyd.tables.activityPiratePlotListTable:getDisapperID(id)

		if text_type == 1 then
			totalNum = totalNum + 1

			if self:checkFinish(id) then
				finishNum = finishNum + 1
			end
		end

		if disapperID and disapperID > 0 and self:checkFinish(disapperID) then
			if self.storyItemList_[id] then
				self.storyItemList_[id].root:SetActive(false)
			end
		else
			local canShow = true

			for _, ID in pairs(needUnlocks) do
				if not self:checkFinish(ID) then
					canShow = false

					break
				end
			end

			if canShow then
				if not self.storyItemList_[id] then
					local NewItem = NGUITools.AddChild(self.storyList_.gameObject, self.storyItem_)
					local bgImg = NewItem:GetComponent(typeof(UISprite))
					local partnerImg = NewItem:ComponentByName("partnerIcon", typeof(UISprite))
					self.storyItemList_[id] = {
						root = NewItem,
						bgImg = bgImg,
						partnerImg = partnerImg
					}

					UIEventListener.Get(NewItem).onClick = function ()
						self:onClickStory(id, text_type)
					end
				end

				local partnerIconName = xyd.tables.activityPiratePlotListTable:getIconImg(id)

				self.storyItemList_[id].root:SetActive(true)
				xyd.setUISpriteAsync(self.storyItemList_[id].partnerImg, nil, partnerIconName)

				if self:checkFinish(id) then
					xyd.setUISpriteAsync(self.storyItemList_[id].bgImg, nil, "activity_pirate_story_bg2")
				else
					xyd.setUISpriteAsync(self.storyItemList_[id].bgImg, nil, "activity_pirate_story_bg1")
				end

				showNum = showNum + 1
			elseif self.storyItemList_[id] then
				self.storyItemList_[id].root:SetActive(false)
			end
		end
	end

	self.storyList_:Reposition()

	if totalNum <= finishNum then
		self.swapBtn_:SetActive(true)
		self.progressBar_.gameObject:SetActive(false)
		self.storyList_.gameObject:SetActive(false)
	else
		self.progressBar_.value = finishNum / totalNum
		self.progressLabel_.text = __("ACTIVITY_PIRATE_TEXT04") .. " " .. finishNum .. "/" .. totalNum

		self.swapBtn_:SetActive(false)
		self.progressBar_.gameObject:SetActive(true)
		self.storyList_.gameObject:SetActive(true)
	end

	if showNum <= 0 then
		self.progressBar_.gameObject:SetActive(false)
	end
end

function PirateLandItem:onClickSwap()
	xyd.WindowManager.get():openWindow("activity_pirate_swap_window", {
		land_id = self.index_
	})
end

function PirateLandItem:onClickStory(id, text_type)
	if text_type == 1 then
		local start_id = xyd.tables.activityPiratePlotListTable:getPlotIdById(id)

		xyd.WindowManager.get():openWindow("story_window", {
			story_type = xyd.StoryType.ACTIVITY_PIRATE,
			story_id = start_id,
			callback = function ()
				local params = cjson.encode({
					type = 0,
					story_id = tonumber(id)
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PIRATE, params)
			end
		})
	else
		xyd.WindowManager.get():openWindow("activity_pirate_story_window", {
			story_id = id
		})
	end
end

function ActivityPirate:ctor(parentGO, params)
	self.landItemList_ = {}
	self.boxItemList_ = {}

	ActivityPirate.super.ctor(self, parentGO, params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_PIRATE, function ()
		self.activityData.touchTime = xyd.getServerTime()
	end)
end

function ActivityPirate:initUI()
	self:getUIComponent()
	self:updateHeight()
	self:updateLayout()
	self:updateItemNum()
	self:updateLandRed()
	self:updateGiftbagRed()

	if xyd.arrayIndexOf(self.activityData.detail.story_ids, 1) <= 0 and not xyd.GuideController.get():isPlayGuide() then
		local start_id = xyd.tables.activityPiratePlotListTable:getPlotIdById(1)

		xyd.WindowManager.get():openWindow("story_window", {
			story_type = xyd.StoryType.ACTIVITY_PIRATE,
			story_id = start_id,
			callback = function ()
				local params = cjson.encode({
					type = 0,
					story_id = tonumber(1)
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PIRATE, params)
			end
		})
	end
end

function ActivityPirate:onRegister()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))

	UIEventListener.Get(self.topGiftBagIcon_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_pirate_giftbag_window")
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_PIRATE_HELP"
		})
	end

	UIEventListener.Get(self.reviewBtn_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_pirate_story_list_window")
	end

	UIEventListener.Get(self.itemContent1_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.PIRATE_SWAP_ITEM
		})
	end

	UIEventListener.Get(self.itemContent2_).onClick = function ()
		local params = {
			select = 330,
			activity_type = 2
		}
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PIRATE_SHOP)
		activityData.select = 1

		xyd.goToActivityWindowAgain(params)
	end

	UIEventListener.Get(self.goBtn_).onClick = function ()
		local params = {
			select = 330,
			activity_type = 2
		}
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PIRATE_SHOP)
		activityData.select = 2

		xyd.goToActivityWindowAgain(params)
	end
end

function ActivityPirate:getPrefabPath()
	return "Prefabs/Windows/activity/activity_pirate_plot"
end

function ActivityPirate:getUIComponent()
	local goTrans = self.go.transform
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.reviewBtn_ = goTrans:NodeByName("reviewBtn").gameObject
	self.titleImg_ = goTrans:ComponentByName("titleImg", typeof(UISprite))
	self.topPart_ = goTrans:NodeByName("topPart").gameObject
	self.tipsLabel1_ = self.topPart_:ComponentByName("tipsLabel", typeof(UILabel))
	self.giftbagLabel_ = self.topPart_:ComponentByName("giftbagLabel", typeof(UILabel))
	self.topGiftBagIcon_ = self.topPart_:NodeByName("giftbagIcon").gameObject
	self.giftbagRedIcon_ = self.topPart_:ComponentByName("giftbagRedIcon", typeof(UISprite))
	self.topProgress_ = self.topPart_:ComponentByName("progressBar", typeof(UIProgressBar))
	self.topProgressLabel_ = self.topPart_:ComponentByName("progressBar/labelValue", typeof(UILabel))
	self.bottomPart_ = goTrans:NodeByName("bottomPart").gameObject
	self.labelTips2_ = self.bottomPart_:ComponentByName("labelTips", typeof(UILabel))
	self.boxList_ = self.bottomPart_:ComponentByName("boxList", typeof(UILayout))
	self.boxItem_ = self.bottomPart_:NodeByName("boxItem").gameObject
	self.goBtn_ = self.bottomPart_:NodeByName("goBtn").gameObject
	self.goBtnLabel_ = self.bottomPart_:ComponentByName("goBtn/label", typeof(UILabel))
	self.itemGroup_ = goTrans:NodeByName("itemGroup").gameObject
	self.itemContent1_ = goTrans:NodeByName("itemGroup/itemContent1").gameObject
	self.itemLabel1_ = goTrans:ComponentByName("itemGroup/itemContent1/labelNum", typeof(UILabel))
	self.itemContent2_ = goTrans:NodeByName("itemGroup/itemContent2").gameObject
	self.itemLabel2_ = goTrans:ComponentByName("itemGroup/itemContent2/labelNum", typeof(UILabel))
	self.landRoot_ = goTrans:NodeByName("landRoot").gameObject

	for i = 1, 6 do
		self["line" .. i] = self.landRoot_:NodeByName("line" .. i).gameObject
	end

	for i = 1, 5 do
		self["landPart" .. i] = goTrans:NodeByName("landRoot/landPart" .. i).gameObject
		self.landItemList_[i] = PirateLandItem.new(self["landPart" .. i], i, self)
	end
end

function ActivityPirate:updateItemNum()
	self.itemLabel1_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PIRATE_SWAP_ITEM)
	self.itemLabel2_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PIRATE_SHOP_ITEM)

	self:updateLandRed()
end

function ActivityPirate:updateLayout()
	xyd.setUISpriteAsync(self.titleImg_, nil, "activity_pirate_logo_" .. xyd.Global.lang)

	self.tipsLabel1_.text = __("ACTIVITY_PIRATE_TEXT01")
	self.labelTips2_.text = __("ACTIVITY_PIRATE_TEXT03")
	self.goBtnLabel_.text = __("ACTIVITY_PIRATE_TEXT06")
	self.giftbagLabel_.text = __("ACTIVITY_PIRATE_TEXT02")

	self:updateProgress()
	self:updateMission()
	self:updateGiftbagRed()
end

function ActivityPirate:updateProgress()
	local progressValue = self.activityData:getGiftbagProgress()
	local progress = 0
	progress = progressValue == 1 and "100" or string.format("%.3f", progressValue * 100)
	self.topProgressLabel_.text = progress .. "%"
	self.topProgress_.value = progressValue
end

function ActivityPirate:updateMission()
	local shopData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PIRATE_SHOP)
	local mission_infos = {}

	if shopData then
		mission_infos = shopData.detail.missions
	end

	local missions = xyd.tables.activityPirateMissionTable:getIDs()

	for index, mission_id in ipairs(missions) do
		if not self.boxItemList_[index] then
			local boxItem = NGUITools.AddChild(self.boxList_.gameObject, self.boxItem_)

			boxItem:SetActive(true)

			local boxImg = boxItem:GetComponent(typeof(UISprite))

			xyd.setUISpriteAsync(boxImg, nil, "activity_pirate_icon_box" .. index, function ()
				self.boxList_:Reposition()
			end, nil, true)

			self.boxItemList_[index] = {
				root = boxItem,
				label = boxItem:ComponentByName("label", typeof(UILabel))
			}
		end

		local value = 0

		for index, info in ipairs(mission_infos) do
			if tonumber(info.mission_id) == tonumber(mission_id) then
				value = info.value
				local completeValue = xyd.tables.activityPirateMissionTable:getCompleteValue(mission_id)

				if info.is_awarded == 1 or info.is_complete == 1 then
					value = completeValue
				end
			end
		end

		self.boxItemList_[index].label.text = value .. "/" .. xyd.tables.activityPirateMissionTable:getCompleteValue(mission_id)
	end
end

function ActivityPirate:onGetAward(event)
	local data = event.data

	if type(data) == "number" then
		-- Nothing
	else
		local detail = require("cjson").decode(data.detail)

		if detail.type == 0 then
			for i = 1, 5 do
				self.landItemList_[i]:updateState()
			end
		elseif detail.type == 1 then
			local items = detail.items
			local newItems = {}
			local tmpData = {}

			for _, item in ipairs(items) do
				local itemID = item.item_id

				if tmpData[itemID] == nil then
					tmpData[itemID] = 0
				end

				tmpData[itemID] = tmpData[item.item_id] + item.item_num
			end

			for k, v in pairs(tmpData) do
				table.insert(newItems, {
					item_id = tonumber(k),
					item_num = v,
					cool = xyd.tables.activityPirateMissionTable:checkIsCool(tonumber(k))
				})
			end

			xyd.openWindow("gamble_rewards_window", {
				layoutCenter = true,
				wnd_type = 2,
				data = newItems
			})
			self:updateMission()
		end
	end

	self:updateGiftbagRed()
end

function ActivityPirate:updateLandRed()
	local redFlag = false
	local cost = xyd.split(xyd.tables.miscTable:getVal("activity_pirate_explore_cost"), "#", true)

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		redFlag = true
	end

	for i = 1, 5 do
		self.landItemList_[i]:setRedState(redFlag)
	end
end

function ActivityPirate:updateGiftbagRed()
	self.giftbagRedIcon_:SetActive(self.activityData:getGiftbagRedMarkState())
end

function ActivityPirate:updateHeight()
	self:resizePosY(self.titleImg_.gameObject, 30, 27)
	self:resizePosY(self.bottomPart_, -755, -929)
	self:resizePosY(self.topPart_, -171, -178)
	self:resizePosY(self.itemGroup_, -748, -908)
	self:resizePosY(self.landRoot_, 50, 0)
	self:resizePosY(self.landPart1, -683, -783)
	self:resizePosY(self.landPart3, -537, -577)
	self:resizePosY(self.landPart4, -557, -575)
	self:resizePosY(self.landPart2, -352, -352)
	self:resizePosY(self.landPart5, -227, -239)
	self:resizePosY(self.line1, -666, -806)
	self:resizePosY(self.line2, -400, -438)
	self:resizePosY(self.line3, -660, -759)
	self:resizePosX(self.line3, 80, 45)
	self:resizePosY(self.line5, -531, -633)
	self:resizePosY(self.line6, -308, -284)
end

return ActivityPirate
