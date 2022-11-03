local ActivityContent = import(".ActivityContent")
local ActivityBlindBox = class("ActivityBlindBox", ActivityContent)
local ActivityBlindBoxItem = class("ActivityBlindBoxItem", import("app.components.CopyComponent"))
local cjson = require("cjson")
local CountDown = import("app.components.CountDown")

function ActivityBlindBoxItem:ctor(go, parent, type, index)
	self.parent_ = parent
	self.type_ = type
	self.index_ = index
	self.awardType = {
		5,
		2,
		2,
		3,
		1,
		2,
		3,
		3,
		4
	}
	self.awardOrder = {
		8,
		1,
		2,
		4,
		0,
		3,
		5,
		6,
		7
	}
	self.activityData = self.parent_.activityData

	dump(self.activityData)

	self.awardIndex_ = self.awardOrder[self.index_]
	self.colors = {
		4269998079.0,
		952283647,
		2110586623,
		4119117567.0,
		4072301311.0
	}

	ActivityBlindBoxItem.super.ctor(self, go)
end

function ActivityBlindBoxItem:initUI()
	self:getUIComponent()
	self:updateUI()
	self:register()
end

function ActivityBlindBoxItem:getUIComponent()
	local goTrans = self.go.transform
	self.bgImg_ = goTrans:ComponentByName("bgImg", typeof(UISprite))
	self.itemIcon_ = goTrans:ComponentByName("itemIcon", typeof(UISprite))
	self.resNum_ = goTrans:ComponentByName("resNum", typeof(UILabel))
	self.weight_ = goTrans:ComponentByName("weight", typeof(UILabel))
	self.redPoint_ = goTrans:ComponentByName("redPoint", typeof(UISprite))
	self.changeImg_ = goTrans:ComponentByName("changeBtn", typeof(UISprite))
	self.itemIcon_ = goTrans:NodeByName("itemIcon").gameObject
	self.nextBtn_ = goTrans:NodeByName("nextBtn").gameObject
	self.selectBtn_ = goTrans:NodeByName("bgImg").gameObject
	self.changeBtn_ = goTrans:NodeByName("changeBtn").gameObject
end

function ActivityBlindBoxItem:updateUI()
	self.typeLevel_ = self.awardType[self.index_]
	self.textColor_ = self.colors[self.typeLevel_]

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
		self.resNum_.fontSize = 16
	end

	self.resNum_.color = Color.New2(self.textColor_)
	self.weight_.color = Color.New2(self.textColor_)

	xyd.setUISpriteAsync(self.bgImg_, nil, "activity_blind_box_add_card_" .. self.typeLevel_)
	xyd.setUISpriteAsync(self.changeImg_, nil, "activity_blind_box_btn_exchange_" .. self.typeLevel_)
	xyd.setUISpriteAsync(self.mask_, nil, "activity_blind_box_card_mask_" .. self.typeLevel_)

	if self.typeLevel_ == 1 then
		local cycle = self.activityData.detail_.round
		self.awardId = xyd.tables.activityBlindBoxTable:getFirstPrizeID(cycle)
		local award = xyd.tables.activityBlindBoxTable:getAwards(self.awardId)

		if self.activityData.detail_.buy_times[1] == 1 and cycle == 1 then
			if self.icon then
				NGUITools.Destroy(self.icon:getGameObject())
			end

			self.resNum_.text = __("ACTIVITY_BLIND_BOX_TEXT01", 0)

			self.changeBtn_:SetActive(false)
			self.redPoint_:SetActive(false)
			self.bgImg_:SetActive(false)
			self.resNum_:SetActive(true)
			self.weight_:SetActive(false)
			self.nextBtn_:SetActive(true)
		else
			if self.icon then
				NGUITools.Destroy(self.icon:getGameObject())
			end

			self.icon = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.7407407407407407,
				uiRoot = self.itemIcon_.gameObject,
				itemID = award[1],
				num = award[2]
			}, xyd.ItemIconType.ADVANCE_ICON)
			self.itemIcon_.transform.localPosition = Vector3(0, 0, 0)

			UIEventListener.Get(self.go).onClick = function ()
				xyd.WindowManager.get():openWindow("item_tips_window", {
					show_has_num = true,
					notShowGetWayBtn = true,
					itemID = award[1]
				})
			end

			local totalNum = xyd.tables.activityBlindBoxTable:getNum(self.awardId)
			local gotNum = self.activityData.detail_.buy_times[self.awardOrder[self.index_] + 1]
			self.resNum_.text = __("ACTIVITY_BLIND_BOX_TEXT01", totalNum - gotNum)

			if self.parent_.totalWeight == -1 then
				self.weight_:SetActive(false)
			else
				local itemWeight = (totalNum - gotNum) * xyd.tables.activityBlindBoxTable:getWeight(self.awardId) / self.parent_.totalWeight * 100
				self.weight_.text = string.format("%.2f", itemWeight) .. "%"

				self.weight_:SetActive(true)
			end

			if totalNum - gotNum == 0 then
				self.icon:setChoose(true)
				self.weight_:SetActive(false)
			else
				self.icon:setChoose(false)
			end

			self.changeBtn_:SetActive(false)
			self.redPoint_:SetActive(false)
			self.bgImg_:SetActive(false)
			self.resNum_:SetActive(true)
			self.nextBtn_:SetActive(false)
		end

		return
	end

	self.awardId = self.activityData.detail_.selects[self.awardIndex_]

	if self.awardId ~= 0 then
		local award = xyd.tables.activityBlindBoxTable:getAwards(self.awardId)

		if self.icon then
			NGUITools.Destroy(self.icon:getGameObject())
		end

		self.icon = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7407407407407407,
			uiRoot = self.itemIcon_.gameObject,
			itemID = award[1],
			num = award[2]
		}, xyd.ItemIconType.ADVANCE_ICON)
		self.itemIcon_.transform.localPosition = Vector3(0, 0, 0)
		local totalNum = xyd.tables.activityBlindBoxTable:getNum(self.awardId)
		local gotNum = self.activityData.detail_.buy_times[self.awardOrder[self.index_] + 1]
		self.resNum_.text = __("ACTIVITY_BLIND_BOX_TEXT01", totalNum - gotNum)

		if self.parent_.totalWeight == -1 then
			self.weight_:SetActive(false)
		else
			local itemWeight = (totalNum - gotNum) * xyd.tables.activityBlindBoxTable:getWeight(self.awardId) / self.parent_.totalWeight * 100
			self.weight_.text = string.format("%.2f", itemWeight) .. "%"

			self.weight_:SetActive(true)
		end

		if totalNum - gotNum == 0 then
			self.icon:setChoose(true)
			self.weight_:SetActive(false)
		else
			self.icon:setChoose(false)
		end

		if self.activityData:isSummoned() then
			self.changeBtn_:SetActive(false)
		else
			self.changeBtn_:SetActive(true)
		end

		self.itemIcon_:SetActive(true)
		self.redPoint_:SetActive(false)
		self.bgImg_:SetActive(false)
		self.resNum_:SetActive(true)
		self.weight_:SetActive(true)
	else
		self.itemIcon_:SetActive(false)
		self.changeBtn_:SetActive(false)
		self.redPoint_:SetActive(true)
		self.bgImg_:SetActive(true)
		self.resNum_:SetActive(false)
		self.weight_:SetActive(false)
	end
end

function ActivityBlindBoxItem:register()
	UIEventListener.Get(self.selectBtn_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_blind_box_select_window")
	end

	UIEventListener.Get(self.changeBtn_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_blind_box_select_window")
	end

	UIEventListener.Get(self.nextBtn_).onClick = function ()
		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_BLIND_BOX_TEXT08"), function (flag)
			if flag then
				local info = {
					type = 3
				}
				local params = cjson.encode(info)

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_BLIND_BOX, params)
			end
		end)
	end
end

function ActivityBlindBox:ctor(parentGO, params, parent)
	self.itemList_ = {}
	self.totalWeight = -1

	ActivityBlindBox.super.ctor(self, parentGO, params, parent)
end

function ActivityBlindBox:getPrefabPath()
	return "Prefabs/Windows/activity/activity_blind_box"
end

function ActivityBlindBox:initUI()
	self:getTotalWeight()
	self:getUIComponent()
	self:layout()
	self:updateItemNum()
	self:register()
end

function ActivityBlindBox:getUIComponent()
	local goTrans = self.go.transform
	self.bg_ = goTrans:ComponentByName("bg", typeof(UISprite))
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.timeGroup = goTrans:NodeByName("timeGroup").gameObject
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.detailBtn_ = goTrans:NodeByName("detailBtn").gameObject
	self.contentGroup = goTrans:NodeByName("contentGroup").gameObject
	self.resItem_ = self.contentGroup:NodeByName("resItem").gameObject
	self.resItemNum_ = self.contentGroup:ComponentByName("resItem/num", typeof(UILabel))
	self.summonBtn1_ = self.contentGroup:NodeByName("summonBtn1").gameObject
	self.summonBtn1Label_ = self.contentGroup:ComponentByName("summonBtn1/label", typeof(UILabel))
	self.summonBtn1Red_ = self.contentGroup:NodeByName("summonBtn1/redPoint").gameObject
	self.summonBtn5_ = self.contentGroup:NodeByName("summonBtn5").gameObject
	self.summonBtn5Label_ = self.contentGroup:ComponentByName("summonBtn5/label", typeof(UILabel))
	self.summonBtn5Red_ = self.contentGroup:NodeByName("summonBtn5/redPoint").gameObject
	self.boxItem_ = goTrans:NodeByName("boxItem").gameObject
	self.itemGroup_ = self.contentGroup:NodeByName("itemGroup")

	for i = 1, 9 do
		local itemRoot = self.itemGroup_:NodeByName("item" .. i).gameObject
		local newRoot = NGUITools.AddChild(itemRoot, self.boxItem_)
		self.itemList_[i] = ActivityBlindBoxItem.new(newRoot, self, "normal", i)
	end

	self:resizePosY(self.logoImg_.transform, 45, -49)
	self:resizePosY(self.contentGroup.transform, -535, -697)
	self:resizePosY(self.timeGroup.transform, -185, -287)
	self:resizePosY(self.bg_, -490, -528)
end

function ActivityBlindBox:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_blind_box_bg_title_" .. xyd.Global.lang)

	self.summonBtn1Label_.text = __("ACTIVITY_BLIND_BOX_TEXT02")
	self.summonBtn5Label_.text = __("ACTIVITY_BLIND_BOX_TEXT03")
	self.endLabel_.text = __("END")

	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end
end

function ActivityBlindBox:updateItemNum()
	local itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.BLIND_BOX_TICKET)
	self.resItemNum_.text = itemNum
	local resCnt = self.activityData:getTotalRes()

	self.summonBtn1Red_:SetActive(itemNum >= 1 and resCnt >= 1)
	self.summonBtn5Red_:SetActive(itemNum >= 5 and resCnt >= 5)
end

function ActivityBlindBox:updateCards()
	for i = 1, 9 do
		self.itemList_[i]:updateUI()
	end
end

function ActivityBlindBox:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_BLIND_BOX_HELP"
		})
	end

	UIEventListener.Get(self.detailBtn_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_blind_box_award_window")
	end

	UIEventListener.Get(self.summonBtn1_).onClick = function ()
		self:summon(1)
	end

	UIEventListener.Get(self.summonBtn5_).onClick = function ()
		self:summon(5)
	end

	UIEventListener.Get(self.resItem_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.BLIND_BOX_TICKET
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
end

function ActivityBlindBox:summonReq(num)
	local info = {
		type = 2,
		num = num
	}
	local params = cjson.encode(info)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_BLIND_BOX, params)
end

function ActivityBlindBox:summon(num)
	for i = 1, 8 do
		if self.activityData.detail_.selects[i] == 0 then
			xyd.alertTips(__("ACTIVITY_BLIND_BOX_TEXT06"))

			return
		end
	end

	if self.activityData:getTotalRes() < num then
		xyd.alertTips(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS04"))

		return
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.BLIND_BOX_TICKET) < num then
		local name = xyd.tables.itemTable:getName(xyd.ItemID.BLIND_BOX_TICKET)

		xyd.alertTips(__("NOT_ENOUGH", name))

		return
	end

	if not self.activityData:isSummoned() then
		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_BLIND_BOX_TEXT07"), function (flag)
			if flag then
				self:summonReq(num)
			end
		end)
	else
		self:summonReq(num)
	end
end

function ActivityBlindBox:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local detail = cjson.decode(data.detail)
	local items = {}
	local getItems = detail.items
	local surpriseItems = {}
	local round = detail.round

	if getItems ~= nil then
		for i = 1, #detail.ids do
			local award = xyd.tables.activityBlindBoxTable:getAwards(detail.ids[i])

			if detail.ids[i] == xyd.tables.activityBlindBoxTable:getFirstPrizeID(round) then
				table.insert(surpriseItems, {
					item_id = award[1],
					item_num = award[2]
				})
			else
				table.insert(items, {
					item_id = award[1],
					item_num = award[2]
				})
			end
		end
	end

	if #surpriseItems > 0 then
		xyd.openWindow("gamble_rewards_window", {
			layoutCenter = true,
			wnd_type = 2,
			data = surpriseItems,
			closeCallBack = function ()
				if self.activityData.detail_.round == 1 then
					xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_BLIND_BOX_TEXT08"), function (flag)
						if flag then
							local info = {
								type = 3
							}
							local params = cjson.encode(info)

							xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_BLIND_BOX, params)
						end
					end)
				else
					xyd.alert(xyd.AlertType.CONFIRM, __("ACTIVITY_BLIND_BOX_TEXT11"), function ()
					end)
				end
			end
		})
	end

	xyd.itemFloat(items)
	self:updateItemNum()
	self:getTotalWeight()
	self:updateCards()
end

function ActivityBlindBox:getTotalWeight()
	self.totalWeight = self.activityData:getTotalWeight()
end

return ActivityBlindBox
