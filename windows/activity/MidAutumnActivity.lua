local cjson = require("cjson")
local ActivityContent = import(".ActivityContent")
local MidAutumnActivity = class("MidAutumnActivity", ActivityContent)
local MidAutumnActivityItem = class("MidAutumnActivityItem", import("app.components.BaseComponent"))
local GiftbagIcon = import("app.components.GiftbagIcon")

function MidAutumnActivity:ctor(parentGO, params, parent)
	self.parent_ = parent
	self.cur_choose = {}
	self.itemList = {}
	self.usedQueue = {}
	self.activityFestivalId = 17
	self.cost_type = xyd.tables.activityFestivalTabel:getCost(1)[1]

	MidAutumnActivity.super.ctor(self, parentGO, params, parent)
end

function MidAutumnActivity:getPrefabPath()
	return "Prefabs/Windows/activity/midAutumnActivity"
end

function MidAutumnActivity:initUI()
	MidAutumnActivity.super.initUI(self)
	self:getUIComponent()
	self:setText()
	self:setItem()

	local duration = self.activityData:getUpdateTime() - xyd.getServerTime()

	if duration > 0 then
		self.timeLabel_.gameObject:SetActive(true)
		self.endLabel_.gameObject:SetActive(true)

		self.timeCount_ = import("app.components.CountDown").new(self.timeLabel_)

		self.timeCount_:setInfo({
			duration = duration
		})
	else
		self.timeLabel_.gameObject:SetActive(false)
		self.endLabel_.gameObject:SetActive(false)
	end

	self:initLayout()
	self:registerEvent()
end

function MidAutumnActivity:getUIComponent()
	local goTrans = self.go.transform
	self.textImg_ = goTrans:ComponentByName("textImg", typeof(UITexture))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.costImg2_ = goTrans:NodeByName("costImg2").gameObject
	self.textLabel01_ = goTrans:ComponentByName("groupTop/textLabel01", typeof(UILabel))
	self.costImg_ = goTrans:ComponentByName("groupTop/costImg", typeof(UISprite))
	self.universalBtn_ = goTrans:NodeByName("groupTop/universalBtn").gameObject
	self.sumLabel_ = goTrans:ComponentByName("groupTop/sumLabel", typeof(UILabel))
	self.timeLabel_ = goTrans:ComponentByName("groupTop/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("groupTop/endLabel", typeof(UILabel))
	self.scrollView_ = goTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.groupItem_ = goTrans:ComponentByName("scrollView/groupItem", typeof(UIGrid))
end

function MidAutumnActivity:initLayout()
	xyd.setUITextureAsync(self.textImg_, "Textures/activity_text_web/mid_autumn_activity_text01_" .. xyd.Global.lang)

	local itemName = xyd.tables.itemTable:getIcon(self.cost_type)

	xyd.setUISpriteAsync(self.costImg_, nil, itemName)
end

function MidAutumnActivity:registerEvent()
	local awardExchange = xyd.tables.activityFestivalTabel:getAward(self.activityFestivalId)[1]
	local costExchange = xyd.tables.activityFestivalTabel:getCost(self.activityFestivalId)
	local limitExchange = xyd.tables.activityFestivalTabel:getLimit(self.activityFestivalId)

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ZHONGQIU_FESTIVAL_TEXT"
		})
	end

	UIEventListener.Get(self.universalBtn_).onClick = function ()
		local win = self
		local params = {
			notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
			hasMaxMin = true,
			titleKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_TITLE",
			buyType = awardExchange[1],
			buyNum = awardExchange[2],
			costType = costExchange[1],
			costNum = costExchange[2],
			purchaseCallback = function (_, num)
				local data = cjson.encode({
					award_id = self.activityFestivalId,
					num = num
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.MID_AUTUMN_ACTIVITY
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				win:setCurChoose({
					id = self.activityFestivalId,
					num = num
				})
			end,
			limitNum = xyd.checkCondition(limitExchange == -1, 100000000, 1),
			eventType = xyd.event.GET_ACTIVITY_AWARD
		}

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function MidAutumnActivity:setText()
	self.endLabel_.text = __("END_TEXT")
	self.textLabel01_.text = __("ZHONGQIU_FESTIVAL_TEXT")
end

function MidAutumnActivity:setItem()
	self.itemParams_ = {}
	local ids = xyd.tables.activityFestivalTabel:getIDs()
	local tempIds = {}

	for i = 1, #ids do
		local id = ids[i]
		local lit = xyd.tables.activityFestivalTabel:getLimit(id)

		if lit and lit ~= -1 and lit <= self.activityData.detail.buy_times[i] then
			table.insert(self.usedQueue, id)
		else
			table.insert(tempIds, id)
		end

		local isHide = xyd.tables.activityFestivalTabel:isHide(id)

		if not isHide or isHide ~= 1 then
			local award_data = xyd.tables.activityFestivalTabel:getAward(id)
			local cost_data = xyd.tables.activityFestivalTabel:getCost(id)
			local src = xyd.tables.itemTable:getIcon(cost_data[1])
			local count = #award_data
			self.itemParams_[id] = {
				id = i,
				cost_type = cost_data[1],
				cost_cnt = cost_data[2],
				award_type = award_data[1][1],
				award_cnt = award_data[1][2],
				cur_cnt = self.activityData.detail.buy_times[id],
				limit = xyd.tables.activityFestivalTabel:getLimit(id),
				icon_src = src,
				win = self,
				count = count,
				awards = award_data,
				icon = xyd.tables.activityFestivalTabel:getAwardIcon(id),
				desc = xyd.tables.activityFestivalTabel:getAwardDesc(id)
			}
		end
	end

	xyd.tableConcat(tempIds, self.usedQueue)

	for i = 1, #tempIds do
		local id = tempIds[i]
		local isHide = xyd.tables.activityFestivalTabel:isHide(id)

		if not isHide or isHide ~= 1 then
			local item = MidAutumnActivityItem.new(self.groupItem_.gameObject)

			table.insert(self.itemList, item)

			local params = self.itemParams_[id]
			params.realIndex = i

			item:setInfo(params)
		end
	end

	self.groupItem_:Reposition()
	self.scrollView_:ResetPosition()
	self:updateSum(self.cost_type)
end

function MidAutumnActivity:updateSum(type_)
	self.sumLabel_.text = tostring(xyd.models.backpack:getItemNumByID(type_))
end

function MidAutumnActivity:setCurChoose(data)
	table.insert(self.cur_choose, data)
	self.activityData:setChoose(data)
end

function MidAutumnActivity:onAward(evt)
	while #self.cur_choose > 0 do
		local id = self.cur_choose[1].id
		local num = self.cur_choose[1].num
		local realIndex = self.cur_choose[1].index

		table.remove(self.cur_choose, 1)

		if realIndex ~= self.activityFestivalId then
			local item = self.itemList[realIndex]

			if item then
				item:setBuyCnt(self.activityData.detail.buy_times[id])
			end
		end

		local data = xyd.tables.activityFestivalTabel:getAward(id)
		local items = {}

		if xyd.tables.itemTable:getType(data[1][1]) == xyd.ItemType.SKIN and id ~= self.activityFestivalId then
			xyd.onGetNewPartnersOrSkins({
				skins = {
					data[1][1]
				},
				callback = function ()
					self.parent_:itemFloat({
						{
							item_id = data[1][1],
							item_num = data[1][2]
						}
					})
				end
			})
		else
			for i = 1, #data do
				table.insert(items, {
					item_id = data[i][1],
					item_num = data[i][2] * num
				})
			end

			xyd.alertItems(items)
		end
	end
end

function MidAutumnActivity:onItemChange()
	self:updateSum(self.cost_type)
end

function MidAutumnActivity:getRetTimes(id)
	return xyd.tables.activityFestivalTabel:getLimit(id) - self.activityData.detail.buy_times[id]
end

function MidAutumnActivityItem:ctor(parentGO)
	MidAutumnActivityItem.super.ctor(self, parentGO)
end

function MidAutumnActivityItem:getPrefabPath()
	return "Prefabs/Components/mid_autumn_activity_item"
end

function MidAutumnActivityItem:initUI()
	MidAutumnActivityItem.super.initUI(self)
	self:getComponent()
end

function MidAutumnActivityItem:getComponent()
	local goTrans = self.go.transform
	self.textImg_ = goTrans:ComponentByName("textImg", typeof(UISprite))
	self.limitLabel = self.textImg_:ComponentByName("limitLabel", typeof(UILabel))
	self.itemGroup_ = goTrans:NodeByName("itemGroup").gameObject
	self.confirmBtn_ = goTrans:NodeByName("confirmBtn").gameObject
	self.confirmBtnLabel_ = goTrans:ComponentByName("confirmBtn/label", typeof(UILabel))
	self.confirmBtnCostImg_ = goTrans:ComponentByName("confirmBtn/costImg", typeof(UISprite))
	self.newImg = goTrans:ComponentByName("itemGroup/newImg", typeof(UISprite))
end

function MidAutumnActivityItem:setInfo(params)
	self.id = params.id
	self.realIndex_ = params.realIndex
	self.cost_type = params.cost_type
	self.cost_cnt = params.cost_cnt
	self.cur_cnt = params.cur_cnt
	self.award_type = params.award_type
	self.award_cnt = params.award_cnt
	self.limit = params.limit
	self.icon_src = params.icon_src
	self.win = params.win
	self.count = params.count
	self.awards = params.awards
	self.icon = params.icon
	self.desc = params.desc

	self:layout()
end

function MidAutumnActivityItem:layout()
	if self.limit == -1 then
		self.textImg_.gameObject:SetActive(false)
	else
		self.textImg_.gameObject:SetActive(true)
	end

	if xyd.tables.activityFestivalTabel:getIsNew(self.id) == 1 then
		self.newImg:SetActive(true)
	end

	xyd.setUISpriteAsync(self.confirmBtnCostImg_, nil, self.icon_src)

	self.confirmBtnLabel_.text = self.cost_cnt
	UIEventListener.Get(self.confirmBtn_).onClick = handler(self, self.onClickConfirmBtn)
	local icon = nil

	if self.count > 1 then
		local src = self.icon
		local str = self.desc
		icon = GiftbagIcon.new(self.itemGroup_, {
			icon_src = src,
			awards = self.awards,
			title = str,
			dragScrollView = self.win.scrollView_
		})
	else
		icon = xyd.getItemIcon({
			noClickSelected = true,
			show_has_num = true,
			uiRoot = self.itemGroup_,
			itemID = self.award_type,
			num = self.award_cnt,
			dragScrollView = self.win.scrollView_,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self:updateStatus()
end

function MidAutumnActivityItem:updateStatus()
	if self.limit == -1 then
		return
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", math.max(self.limit - self.cur_cnt, 0))

	if self.limit <= self.cur_cnt then
		xyd.applyChildrenGrey(self.confirmBtn_)

		self.confirmBtn_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		XYDCo.WaitForFrame(1, function ()
			self.confirmBtnLabel_.effectStyle = UILabel.Effect.None
			self.confirmBtnLabel_.color = Color.New2(4294967295.0)
		end, nil)
	end
end

function MidAutumnActivityItem:setBuyCnt(val)
	self.cur_cnt = val

	self:updateStatus()
end

function MidAutumnActivityItem:onClickConfirmBtn()
	local realIndex = self.realIndex_

	if xyd.models.backpack:getItemNumByID(self.cost_type) < self.cost_cnt then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.cost_type)))

		return
	end

	if self.limit ~= -1 and self.win:getRetTimes(self.id) == 1 then
		xyd.alertYesNo(__("MID_AUTUMN_ACTIVITY_CONFIRM"), function (flag)
			if not flag then
				return
			end

			local data = cjson.encode({
				num = 1,
				award_id = self.id
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.MID_AUTUMN_ACTIVITY
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			self.win:setCurChoose({
				num = 1,
				id = self.id,
				index = realIndex
			})
		end, nil, false, nil, __("MID_AUTUMN_ACTIVITY_EXCHANGE_TITLE_2"))

		return
	end

	local itemNum = xyd.models.backpack:getItemNumByID(self.cost_type)
	local limitBuyNum = self.limit - self.cur_cnt
	limitBuyNum = xyd.checkCondition(itemNum >= limitBuyNum * self.cost_cnt, math.floor(itemNum / self.cost_cnt))
	local params = {
		notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
		hasMaxMin = true,
		titleKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_TITLE",
		buyType = self.award_type,
		buyNum = self.award_cnt,
		costType = self.cost_type,
		costNum = self.cost_cnt,
		purchaseCallback = function (_, num)
			local data = cjson.encode({
				award_id = self.id,
				num = num
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.MID_AUTUMN_ACTIVITY
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			self.win:setCurChoose({
				id = self.id,
				index = realIndex,
				num = num
			})
		end,
		limitNum = xyd.checkCondition(self.limit == -1, 100000000, limitBuyNum),
		eventType = xyd.event.GET_ACTIVITY_AWARD
	}

	if self.limit ~= -1 and self.win:getRetTimes(self.id) > 0 then
		params.limitNum = self.win:getRetTimes(self.id)
	end

	xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
end

return MidAutumnActivity
