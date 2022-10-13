local Activity2LoveWindow = class("Activity2LoveWindow", import(".BaseWindow"))
local CountDown = import("app.components.CountDown")
local CardItem = class("CardItem", import("app.components.CopyComponent"))
local json = require("cjson")

function CardItem:ctor(name, parent)
	self.parent_ = parent

	CardItem.super.ctor(self, name)
end

function CardItem:initUI()
	CardItem.super.initUI(self)
	self:getUIComponent()
end

function CardItem:hideClick()
	self.go:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

function CardItem:showClick()
	self.go:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
end

function CardItem:getUIComponent()
	local goTrans = self.go.transform
	self.maskImg_ = goTrans:NodeByName("maskImg").gameObject
	self.effectRoot_ = goTrans:NodeByName("effectRoot").gameObject
	self.itemRoot_ = goTrans:NodeByName("itemRoot").gameObject
	self.bgImg_ = goTrans:ComponentByName("bgImg", typeof(UISprite))
	self.selectLabel_ = goTrans:ComponentByName("selectLabel", typeof(UILabel))
	UIEventListener.Get(self.go).onClick = handler(self, self.onClickItem)
end

function CardItem:setFinish(is_finish)
	if self.awardItem_ then
		self.selectLabel_.text = __("ACTIVITY_2LOVE_TEXT08")

		self.selectLabel_.gameObject:SetActive(is_finish)
	end
end

function CardItem:setInfo(id, index)
	if self.id_ and self.id_ == 0 and id ~= 0 then
		self.id_ = id
		self.index_ = index

		self:playOpenEffect()
	else
		self.id_ = id
		self.index_ = index

		self:updateInfo()
	end
end

function CardItem:showFake(id)
	if id == 0 then
		self.maskImg_:SetActive(true)
		self.itemRoot_:SetActive(false)
	else
		self.itemRoot_:SetActive(true)
		self.maskImg_:SetActive(false)

		local imgName = xyd.tables.activity2LoveAwardsTable:getImgName(id)
		local is_slip = xyd.tables.activity2LoveAwardsTable:getFlip(id)

		if is_slip and is_slip == 1 then
			self.bgImg_.transform.localScale = Vector3(-1, 1, 1)
		else
			self.bgImg_.transform.localScale = Vector3(1, 1, 1)
		end

		xyd.setUISpriteAsync(self.bgImg_, nil, imgName)

		local award = xyd.tables.activity2LoveAwardsTable:getAward(id)

		if not self.awardItem_ then
			self.awardItem_ = xyd.getItemIcon({
				uiRoot = self.itemRoot_,
				itemID = award[1],
				num = award[2]
			}, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.awardItem_:setInfo({
				uiRoot = self.itemRoot_,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end
end

function CardItem:updateInfo()
	if self.id_ == 0 then
		self.maskImg_:SetActive(true)
		self.itemRoot_:SetActive(false)
	else
		self.itemRoot_:SetActive(true)
		self.maskImg_:SetActive(false)

		local imgName = xyd.tables.activity2LoveAwardsTable:getImgName(self.id_)
		local is_slip = xyd.tables.activity2LoveAwardsTable:getFlip(self.id_)

		if is_slip and is_slip == 1 then
			self.bgImg_.transform.localScale = Vector3(-1, 1, 1)
		else
			self.bgImg_.transform.localScale = Vector3(1, 1, 1)
		end

		xyd.setUISpriteAsync(self.bgImg_, nil, imgName)

		local award = xyd.tables.activity2LoveAwardsTable:getAward(self.id_)

		if not self.awardItem_ then
			self.awardItem_ = xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				uiRoot = self.itemRoot_,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.awardItem_:setInfo({
				show_has_num = true,
				notShowGetWayBtn = true,
				uiRoot = self.itemRoot_,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end

		if self.id_ ~= 0 and self.parent_:checkFinish(self.id_) then
			self:setFinish(true)
		else
			self:setFinish(false)
		end
	end
end

function CardItem:playOpenEffect()
	self.effectRoot_:SetActive(true)
	self:waitForFrame(2, function ()
		self.maskImg_.gameObject:SetActive(false)
		self.bgImg_.gameObject:SetActive(false)
	end)
	self:waitForTime(0.1, function ()
		if not self.effect_ then
			self.effect_ = xyd.Spine.new(self.effectRoot_)

			self.effect_:setInfo("fx_2love_flop", function ()
				local animation = xyd.tables.activity2LoveAwardsTable:getAnimationName(self.id_)

				self.effect_:play(animation, 1, 1, function ()
					self:updateInfo()
					self.bgImg_.gameObject:SetActive(true)
					self.effectRoot_:SetActive(false)
					self:waitForFrame(10, function ()
						self:showClick()
					end)
				end)
			end)
		else
			local animation = xyd.tables.activity2LoveAwardsTable:getAnimationName(self.id_)

			self.effect_:play(animation, 1, 1, function ()
				self.effectRoot_:SetActive(false)
				self.bgImg_.gameObject:SetActive(true)
				self:updateInfo()
				self:waitForFrame(10, function ()
					self:showClick()
				end)
			end)
		end
	end)
end

function CardItem:getID()
	return self.id_
end

function CardItem:onClickItem()
	if self.parent_.isCost_ == 1 and (not self.id_ or self.id_ == 0) then
		self.parent_:openCard(self.index_)
	end
end

function Activity2LoveWindow:ctor(name, params)
	Activity2LoveWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_2LOVE)

	dump(self.activityData.detail, "self.activityData")

	self.cost_ = xyd.split(xyd.tables.miscTable:getVal("activity_2love_random_cost"), "#")
	self.cardList_ = {}
	self.isCost_ = self.activityData.detail.is_cost
end

function Activity2LoveWindow:initWindow()
	Activity2LoveWindow.super.initWindow(self)
	self:initUIComponent()
	self:layout()
	self:refresResItems()
	self:updateCardList()
	self:updateBtnType()
	self:register()
end

function Activity2LoveWindow:initUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.logoImg_ = winTrans:ComponentByName("logoImg", typeof(UISprite))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.detailBtn_ = winTrans:NodeByName("detailBtn").gameObject
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.timeGroup_ = winTrans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = winTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = winTrans:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.labelDesc_ = winTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.itemGroup_ = winTrans:NodeByName("itemGroup").gameObject
	self.itemNumLabel_ = winTrans:ComponentByName("itemGroup/labelNum", typeof(UILabel))
	self.sureBtn_ = winTrans:NodeByName("sureBtn").gameObject
	self.sureBtnSprite_ = winTrans:ComponentByName("sureBtn", typeof(UISprite))
	self.sureCostImg_ = winTrans:NodeByName("sureBtn/itemImg").gameObject
	self.sureCostLabel_ = winTrans:ComponentByName("sureBtn/itemImg/costLabel", typeof(UILabel))
	self.sureBtnRed_ = winTrans:NodeByName("sureBtn/redPoint").gameObject
	self.sureBtnLabel_ = winTrans:ComponentByName("sureBtn/label", typeof(UILabel))
	self.cardGrid_ = winTrans:ComponentByName("cardGrid", typeof(UIGrid))
	self.cardItem_ = winTrans:NodeByName("cardItem").gameObject
end

function Activity2LoveWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_2LOVE_HELP"
		})
	end

	UIEventListener.Get(self.detailBtn_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_2love_detail_window")
	end

	UIEventListener.Get(self.itemGroup_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_2love_mission_window")
	end

	UIEventListener.Get(self.sureBtn_).onClick = handler(self, self.onClickStartBtn)

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refresResItems))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function Activity2LoveWindow:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_2love_text_" .. xyd.Global.lang)

	local endTime = self.activityData:getEndTime()
	local timeCount = CountDown.new(self.timeLabel_)

	timeCount:setInfo({
		duration = endTime - xyd:getServerTime()
	})

	self.endLabel_.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeGroup_:Reposition()

	self.labelDesc_.text = __("ACTIVITY_2LOVE_TEXT01")
	self.sureCostLabel_.text = self.cost_[2]
end

function Activity2LoveWindow:refresResItems()
	self.itemNumLabel_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LOVE2_ITEM)
end

function Activity2LoveWindow:updateBtnType()
	local isOver = true
	local idsData = self.activityData.detail.ids

	for index, id in ipairs(idsData) do
		if id == 0 or not id then
			isOver = false
		end
	end

	if isOver then
		xyd.setUISpriteAsync(self.sureBtnSprite_, nil, "activity_2love_text_open_disabled_btn")

		self.sureBtn_.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.sureBtnLabel_.text = __("ACTIVITY_2LOVE_TEXT05")

		self.sureBtnRed_:SetActive(false)
	elseif self.isCost_ and tonumber(self.isCost_) == 1 then
		xyd.setUISpriteAsync(self.sureBtnSprite_, nil, "activity_2love_text_open_disabled_btn")

		self.sureBtn_.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.sureBtnLabel_.text = __("ACTIVITY_2LOVE_TEXT04")

		self.sureBtnRed_:SetActive(false)
	else
		xyd.setUISpriteAsync(self.sureBtnSprite_, nil, "activity_2love_text_open_btn")

		self.sureBtn_.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

		if self.activityData.detail.free_count == 0 then
			self.sureCostImg_:SetActive(false)
			self.sureBtnRed_:SetActive(true)
			self.sureBtnLabel_.transform:X(0)

			self.sureBtnLabel_.text = __("ACTIVITY_2LOVE_TEXT02")
		else
			self.sureBtnLabel_.transform:X(29)

			self.sureBtnLabel_.text = __("ACTIVITY_2LOVE_TEXT03")

			self.sureCostImg_:SetActive(true)
			self.sureBtnRed_:SetActive(tonumber(self.cost_[2]) <= xyd.models.backpack:getItemNumByID(tonumber(self.cost_[1])))
		end

		self:showFake()
	end
end

function Activity2LoveWindow:updateCardList()
	local idsData = self.activityData.detail.ids

	for index, id in ipairs(idsData) do
		if not self.cardList_[index] then
			local newRoot = NGUITools.AddChild(self.cardGrid_.gameObject, self.cardItem_)

			newRoot:SetActive(true)

			self.cardList_[index] = CardItem.new(newRoot, self)
		end

		self.cardList_[index]:setInfo(id, index)

		if id ~= 0 and self:checkFinish(id) then
			self.cardList_[index]:setFinish(true)
		else
			self.cardList_[index]:setFinish(false)
		end
	end
end

function Activity2LoveWindow:checkFinish(card_id)
	local group = xyd.tables.activity2LoveAwardsTable:getGroup(card_id)
	local groupList = xyd.tables.activity2LoveAwardsTable:getGroupList()
	local groupIDs = groupList[group]
	local idsData = self.activityData.detail.ids

	for _, id in ipairs(groupIDs) do
		if xyd.arrayIndexOf(idsData, id) < 0 then
			return false
		end
	end

	return true
end

function Activity2LoveWindow:showFake()
	local resIds = self:getResIDs()
	local idsData = self.activityData.detail.ids

	for index, id in ipairs(idsData) do
		if id == 0 then
			self.cardList_[index]:showFake(resIds[1])
			table.remove(resIds, 1)
		end
	end
end

function Activity2LoveWindow:playShuffleAni()
	self.isInShuffAni_ = true

	self:waitForFrame(45, function ()
		for index, item in ipairs(self.cardList_) do
			local id = item:getID()

			if not id or id == 0 then
				item:showFake(0)
				self:waitForFrame(index * 2, function ()
					local startPos = item.go.transform.localPosition
					local action = self:getSequence()

					action:Append(item.go.transform:DOLocalMove(Vector3(0, 0, 0), 0.2))
					action:AppendInterval(0.6)
					action:Append(item.go.transform:DOLocalMove(Vector3(startPos.x, startPos.y, 0), 0.2))
				end)
			end
		end
	end)
	self:waitForFrame(100, function ()
		self.isInShuffAni_ = false
	end)
end

function Activity2LoveWindow:getResIDs()
	local idsData = self.activityData.detail.ids
	local ids = xyd.tables.activity2LoveAwardsTable:getIDs()
	local hasList = {}
	local notList = {}

	for index, id in ipairs(idsData) do
		if id and id > 0 then
			table.insert(hasList, id)
		end
	end

	for index, id in ipairs(ids) do
		if xyd.arrayIndexOf(hasList, id) < 0 then
			table.insert(notList, id)
		end
	end

	return notList
end

function Activity2LoveWindow:onClickStartBtn()
	if not self.isCost_ or self.isCost_ == 0 then
		if xyd.models.backpack:getItemNumByID(tonumber(self.cost_[1])) < tonumber(self.cost_[2]) and self.activityData.detail.free_count ~= 0 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost_[1])))

			return
		end

		local params = json.encode({
			award_type = 1
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_2LOVE, params)

		self.needOpenAni_ = true
	end
end

function Activity2LoveWindow:openCard(index)
	if not self.inOpenAni_ and not self.isInShuffAni_ and not self.isOpenCard_ then
		self.cardList_[index]:hideClick()

		self.isOpenCard_ = true
		local params = json.encode({
			award_type = 2,
			id = index
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_2LOVE, params)
	end
end

function Activity2LoveWindow:onAward(event)
	local id = event.data.activity_id

	if id ~= xyd.ActivityID.ACTIVITY_2LOVE then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	local info = json.decode(data.detail)

	if self.needOpenAni_ then
		self.isCost_ = info.is_cost
		self.needOpenAni_ = false

		self:updateBtnType()
		self:playShuffleAni()
	else
		local flip_id = info.flip_id

		self:updateCardList()
		self:waitForFrame(20, function ()
			self.isOpenCard_ = false
		end)

		if self.isCost_ ~= info.is_cost then
			self.isCost_ = info.is_cost

			self:waitForTime(0.7, function ()
				local award = xyd.tables.activity2LoveAwardsTable:getAward(flip_id)

				xyd.openWindow("gamble_rewards_window", {
					wnd_type = 2,
					data = {
						{
							item_id = award[1],
							item_num = award[2]
						}
					}
				})
			end)
			self:updateBtnType()
		end
	end
end

return Activity2LoveWindow
