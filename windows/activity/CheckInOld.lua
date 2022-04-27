local ActivityContent = import(".ActivityContent")
local CheckInOld = class("CheckInOld", ActivityContent)
local CheckInItem = class("CheckInItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function CheckInOld:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.items = {}

	self:getUIComponent()
	self:initUIComponent()
	self:onRegisterEvent()
end

function CheckInOld:getPrefabPath()
	return "Prefabs/Windows/activity/check_in_old"
end

function CheckInOld:getUIComponent()
	local go = self.go
	self.btnCheckIn = go:NodeByName("bottom/btnCheckIn").gameObject
	self.btnCheckIn_label = go:ComponentByName("bottom/btnCheckIn/button_label", typeof(UILabel))
	self.btnCheckInImg = go:ComponentByName("bottom/btnCheckIn", typeof(UISprite))
	self.btnCheckInMask = self.btnCheckIn:NodeByName("imgMask").gameObject
	self.textScroller = go:ComponentByName("textScroller", typeof(UIScrollView))
	self.labelText01 = go:ComponentByName("textScroller/labelText01", typeof(UILabel))
	self.labelNum = go:ComponentByName("labelNum", typeof(UILabel))
	self.imgText = go:ComponentByName("imgText", typeof(UITexture))
	self.check_in_item = go:NodeByName("check_in_item").gameObject
	self.bottom = self.go:NodeByName("bottom").gameObject
	self.itemScroller = go:ComponentByName("itemScroller", typeof(UIScrollView))
	self.itemScroller_uipanel = go:ComponentByName("itemScroller", typeof(UIPanel))
	self.groupItems = go:NodeByName("itemScroller/groupItems").gameObject
	local wrapContent = self.groupItems:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.itemScroller, wrapContent, self.check_in_item, CheckInItem, self)
end

function CheckInOld:initUIComponent()
	self:setText()
	self:setItems()
	self:setBtnState()
end

function CheckInOld:onRegisterEvent()
	xyd.setDarkenBtnBehavior(self.btnCheckIn, self, self.requestAward)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onActivityAward))
end

function CheckInOld:setText()
	self.labelText01.text = __("CHECKIN_TEXT01")
	self.labelNum.text = tostring(self.activityData.detail.count % 30) .. "/30"
	self.btnCheckIn_label.text = __("CHECKIN_TEXT04")

	xyd.setUITextureByNameAsync(self.imgText, "activity_text01_" .. xyd.Global.lang, true)
end

function CheckInOld:requestAward()
	if self.activityData.detail.online_days <= self.activityData.detail.count then
		return
	end

	local msg = messages_pb:get_activity_award_req()
	msg.activity_id = xyd.ActivityID.CHECKIN

	xyd.Backend:get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function CheckInOld:setItems()
	local loopExclude = xyd.tables.miscTable:getNumber("login_loop_exclude", "value")
	local loop = #xyd.tables.checkInTable:getIDs() - loopExclude
	self.activityData = xyd.models.activity:getActivity(self.id)
	local count = self.activityData.detail.count
	local onlineDays = self.activityData.detail.online_days
	local id = math.floor(count / 30) * 30
	self.showId = id
	self.items = {}

	for i = id + 1, id + 30 do
		local data = {
			index = i,
			content = self
		}

		table.insert(self.items, data)
	end

	self.wrapContent:setInfos(self.items, {})
	self.wrapContent:jumpToIndex(count % 30, 75)
end

function CheckInOld:onActivityAward(event)
	local id = event.data.activity_id

	if id ~= self.activityData.id then
		return
	end

	local i = self.activityData.detail.count % 30
	local items = self.wrapContent:getItems()

	if i >= 1 then
		items[i]:setState()
	else
		items[30]:setState()
	end

	self.labelNum.text = tostring(self.activityData.detail.count % 30) .. "/30"
	local checkInID = self.activityData.detail.count
	local loopExclude = xyd.tables.miscTable:getNumber("login_loop_exclude", "value")
	local loop = #xyd.tables.checkInTable:getIDs() - loopExclude
	checkInID = self.activityData.detail.count

	if checkInID > loop + loopExclude then
		if (checkInID - loopExclude) % loop == 0 then
			checkInID = #xyd.tables.checkInTable:getIDs()
		else
			checkInID = (checkInID - loopExclude) % loop + loopExclude
		end
	end

	local award = xyd.tables.checkInTable:getRewards(checkInID)

	xyd.alertItems({
		{
			item_id = award[1],
			item_num = award[2]
		}
	})
	self:setBtnState()

	if self.activityData.detail.count >= self.showId + 30 then
		self:setItems()
	end
end

function CheckInOld:setBtnState()
	local imgPath = "check_in_blue_btn"
	local canTouch = true

	if self.activityData.detail.online_days <= self.activityData.detail.count then
		canTouch = false
		self.btnCheckIn_label.color = Color.New2(960513791)
		self.btnCheckIn_label.effectColor = Color.New2(4294967040.0)
		imgPath = "check_in_white_btn"

		self.btnCheckInMask:SetActive(true)
	else
		self.btnCheckIn_label.color = Color.New2(4294967295.0)
		self.btnCheckIn_label.effectColor = Color.New2(1012112383)

		self.btnCheckInMask:SetActive(false)
	end

	xyd.setUISpriteAsync(self.btnCheckInImg, nil, imgPath)
	xyd.setTouchEnable(self.btnCheckIn, canTouch)
end

function CheckInOld:getScrollView()
	return self.itemScroller
end

function CheckInItem:ctor(go, checkIn)
	CheckInItem.super.ctor(self, go)

	self.checkIn = checkIn

	self:setDragScrollView(checkIn:getScrollView())
	self:getUIComponent()
end

function CheckInItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.index = info.index
	local loopExclude = xyd.tables.miscTable:getNumber("login_loop_exclude", "value")
	local loop = #xyd.tables.checkInTable:getIDs() - loopExclude

	if self.index > loop + loopExclude then
		if (self.id - loopExclude) % loop == 0 then
			self.id = #xyd.tables.checkInTable:getIDs()
		else
			self.id = (self.index - loopExclude) % loop + loopExclude
		end
	else
		self.id = self.index
	end

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.CHECKIN)
	local award = xyd.tables.checkInTable:getRewards(self.id)
	self.itemID = award[1]
	self.num = award[2]

	self:initUIComponent()
end

function CheckInItem:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.imgReward = go:ComponentByName("imgReward", typeof(UISprite))
	local labelTime = go:ComponentByName("labelTime", typeof(UILabel))
	self.labelTime = require("app.components.CountDown").new(labelTime)
	self.effectCon = go:ComponentByName("effectCon", typeof(UITexture))
end

function CheckInItem:initUIComponent()
	NGUITools.DestroyChildren(self.groupIcon.transform)

	local icon = xyd.getItemIcon({
		hideText = true,
		uiRoot = self.groupIcon,
		itemID = self.itemID,
		num = self.num
	})

	icon:SetLocalScale(0.8333333333333334, 0.8333333333333334, 1)
	icon:setDragScrollView(self.checkIn:getScrollView())

	self.icon = icon

	self:setState()
end

function CheckInItem:effectBorder(state)
	if state == false then
		self.effectCon.gameObject:SetActive(false)

		if self.effect then
			self.effect:destroy()
		end
	else
		if self.effect == nil then
			self.effect = xyd.Spine.new(self.effectCon.gameObject)

			self.effect:setInfo("fx_ui_qiandao", function ()
				self.effect:setRenderTarget(self.effectCon, 1)
				self.effect:setRenderPanel(self.checkIn.itemScroller_uipanel)
				self.effect:play("texiao02", 0)
			end, true)
		end

		self.effectCon.gameObject:SetActive(true)
	end
end

function CheckInItem:setState()
	local detail = self.activityData.detail

	self.icon:setMask(self.index <= detail.count)
	self.imgReward:SetActive(self.index <= detail.count)

	if self.index == detail.online_days + 1 then
		self.labelTime:SetActive(true)
		self.labelTime:setInfo({
			duration = xyd.getUpdateTime()
		})
	else
		self.labelTime:SetActive(false)
	end

	if xyd.tables.checkInTable:getBack(self.id) == 0 then
		xyd.setUISpriteAsync(self.imgBg, nil, "activity_bg05")
	else
		xyd.setUISpriteAsync(self.imgBg, nil, "activity_bg06")
	end

	if detail.count < self.index and self.index <= detail.online_days then
		self.imgBg:SetActive(false)
		self:effectBorder(true)
	else
		self.imgBg:SetActive(true)
		self:effectBorder(false)
	end
end

function CheckInItem:playAnimation()
	if self.db0 then
		self.db0:play("texiao02", 0, 1, nil, true, true)
	else
		self.db0 = xyd.Spine.new(self.go)

		self.db0:setInfo("fx_ui_qiandao")
		self.db0:play("texiao02", 0, 1, nil, true, true)
	end

	if self.db1 then
		self.db1:play("texiao01", 0, 1, nil, true, true)
	else
		self.db1 = xyd.Spine.new(self.groupIcon)

		self.db1:setInfo("fx_ui_qiandao")
		self.db1:play("texiao01", 0, 1, nil, true, true)
	end
end

function CheckInItem:stopAnimation()
	if self.db0 then
		self.db0:stop()
		self.db0:SetActive(false)
	end

	if self.db1 then
		self.db1:SetActive(false)
		self.db1:stop()
	end
end

return CheckInOld
