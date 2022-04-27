local BaseWindow = import(".BaseWindow")
local ActivityCourseResearchSelectWindow = class("ActivityCourseResearchSelectWindow", BaseWindow)
local ActivityCourseResearchSelectItem = class("ActivityCourseResearchSelectItem", import("app.components.CopyComponent"))

function ActivityCourseResearchSelectWindow:ctor(name, params)
	ActivityCourseResearchSelectWindow.super.ctor(self, name, params)

	self.awards = params.awards
	self.roundID = params.roundID
	self.chosenItem = nil
end

function ActivityCourseResearchSelectWindow:initWindow()
	self:getUIComponent()
	ActivityCourseResearchSelectWindow.super.initWindow(self)
	self:initLayout()
	self:registerEvent()
	self:initData()
end

function ActivityCourseResearchSelectWindow:playOpenAnimation(callback)
	ActivityCourseResearchSelectWindow.super.playOpenAnimation(self, callback)
	self.groupTop:SetLocalPosition(0, 810, 0)
	self.chooseGroup:SetLocalPosition(0, -1090, 0)

	self.top_tween = self:getSequence()

	self.top_tween:Append(self.groupTop.transform:DOLocalMoveY(83, 0.5))
	self.top_tween:AppendCallback(function ()
		if self.top_tween then
			self.top_tween:Kill(true)
		end
	end)

	self.down_tween = self:getSequence()

	self.down_tween:Append(self.chooseGroup.transform:DOLocalMoveY(-399, 0.5))
	self.down_tween:AppendCallback(function ()
		if self.down_tween then
			self.down_tween:Kill(true)
		end
	end)
end

function ActivityCourseResearchSelectWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainNode = winTrans:NodeByName("mainNode").gameObject
	self.mySelectIcon = mainNode:NodeByName("groupTop/selectedGroup/mySelectIconGroup/myAssistantIcon").gameObject
	self.mySelectIcon_uiPanel = mainNode:ComponentByName("groupTop/selectedGroup/mySelectIconGroup/myAssistantIcon", typeof(UIPanel))
	self.btnSure = mainNode:NodeByName("groupTop/selectedGroup/btnSure").gameObject
	self.btnSure_label = mainNode:ComponentByName("groupTop/selectedGroup/btnSure/button_label", typeof(UILabel))
	self.btnCancle = mainNode:NodeByName("groupTop/selectedGroup/btnCancle").gameObject
	self.btnCancle_label = mainNode:ComponentByName("groupTop/selectedGroup/btnCancle/button_label", typeof(UILabel))
	self.labelChoose = mainNode:ComponentByName("chooseGroup/labelChoose", typeof(UILabel))
	self.partnerScroller = mainNode:NodeByName("chooseGroup/scroller").gameObject
	self.partnerScroller_scroller = mainNode:ComponentByName("chooseGroup/scroller", typeof(UIScrollView))
	self.partnerScroller_uiPanel = mainNode:ComponentByName("chooseGroup/scroller", typeof(UIPanel))
	self.partnerContainer = mainNode:NodeByName("chooseGroup/scroller/container").gameObject
	self.partnerContainer_MultiRowWrapContent = mainNode:ComponentByName("chooseGroup/scroller/container", typeof(MultiRowWrapContent))
	self.labelWinTitle_ = mainNode:ComponentByName("groupTop/labelWinTitle", typeof(UILabel))
	self.groupTop = mainNode:NodeByName("groupTop").gameObject
	self.chooseGroup = mainNode:NodeByName("chooseGroup").gameObject
	self.closeBtn = mainNode:NodeByName("groupTop/closeBtn").gameObject
	self.icon_root = mainNode:NodeByName("chooseGroup/icon_root").gameObject
	self.partnerScroller_uiPanel.depth = winTrans:GetComponent(typeof(UIPanel)).depth + 1
	self.mySelectIcon_uiPanel.depth = self.partnerScroller_uiPanel.depth + 1
	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScroller_scroller, self.partnerContainer_MultiRowWrapContent, self.icon_root, ActivityCourseResearchSelectItem, self)
end

function ActivityCourseResearchSelectWindow:initLayout()
	self.labelWinTitle_.text = __("ACTIVITY_COURSE_LEARNING_TEXT04")
	self.labelChoose.text = __("ACTIVITY_COURSE_LEARNING_TEXT15")
	self.btnSure_label.text = __("SURE")
	self.btnCancle_label.text = __("PROPHET_BTN_CANCEL")
end

function ActivityCourseResearchSelectWindow:registerEvent()
	UIEventListener.Get(self.mySelectIcon.gameObject).onClick = handler(self, self.onClickSelectedIcon)
	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, self.onSelectedTouch)

	UIEventListener.Get(self.btnCancle.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityCourseResearchSelectWindow:onClickSelectedIcon()
	if self.chooseId_ == nil then
		return
	end

	self.chosenItem:setChoose(false)

	if self.copyIcon_tween then
		self.copyIcon_tween:Kill(true)
	end

	self.chosenItem = nil
	self.chooseId_ = nil

	NGUITools.DestroyChildren(self.mySelectIcon.transform)
end

function ActivityCourseResearchSelectWindow:initData()
	self.selectAwardsList_ = {}

	for i, award in ipairs(self.awards) do
		local data = {
			item_id = award[1],
			item_num = award[2],
			id = i
		}

		table.insert(self.selectAwardsList_, data)
	end

	self.partnerMultiWrap_:setInfos(self.selectAwardsList_, {})
end

function ActivityCourseResearchSelectWindow:onClickheroIcon(item)
	local itemData = item:getInfo()

	if self.chooseId_ ~= nil then
		if self.chooseId_ == itemData.id then
			self.chooseId_ = nil

			item:setChoose(false)

			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end

			NGUITools.DestroyChildren(self.mySelectIcon.transform)

			self.chosenItem = nil

			return
		else
			NGUITools.DestroyChildren(self.mySelectIcon.transform)

			if self.chosenItem then
				self.chosenItem:setChoose(false)
			end

			if self.copyIcon_tween then
				self.copyIcon_tween:Kill(true)
			end

			self.chosenItem = item
		end
	else
		self.chosenItem = item
	end

	self.chooseId_ = itemData.id

	item:setChoose(true)

	local copyIcon = xyd.getItemIcon({
		uiRoot = self.mySelectIcon,
		itemID = itemData.item_id,
		num = itemData.item_num
	})
	self.selectedIcon_ = item
	local nowVectoryPos = self.mySelectIcon.transform.position
	copyIcon:getIconRoot().transform.position = item:getIconRoot().transform.position
	self.copyIcon_tween = self:getSequence()

	self.copyIcon_tween:Append(copyIcon:getIconRoot().transform:DOMove(nowVectoryPos, 0.2))
	self.copyIcon_tween:AppendCallback(function ()
		if self.copyIcon_tween then
			self.copyIcon_tween:Kill(true)
		end
	end)
end

function ActivityCourseResearchSelectWindow:onSelectedTouch()
	if self.chooseId_ then
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = self.params_.activityID
		msg.params = require("cjson").encode({
			table_id = self.roundID,
			index = self.chooseId_
		})

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	elseif not self.chooseId_ then
		xyd.showToast(__("ACTIVITY_COURSE_LEARNING_TEXT16"))

		return
	end
end

function ActivityCourseResearchSelectItem:ctor(parentGo, parent)
	self.parent_ = parent

	ActivityCourseResearchSelectItem.super.ctor(self, parentGo)
end

function ActivityCourseResearchSelectItem:getIconRoot()
	return self.go
end

function ActivityCourseResearchSelectItem:initUI()
	ActivityCourseResearchSelectItem.super.initUI(self)

	UIEventListener.Get(self.go).onClick = handler(self, self.onClick)

	UIEventListener.Get(self.go).onPress = function (go, isPressed)
		if isPressed then
			self:waitForTime(1, function ()
				local params = {
					showGetWay = false,
					show_has_num = true,
					itemID = self.data_.item_id,
					itemNum = self.data_.item_num,
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					callback = function ()
					end
				}

				xyd.WindowManager.get():openWindow("item_tips_window", params)
			end, "activity_ice_secret_select_pressed")
		else
			XYDCo.StopWait("activity_ice_secret_select_pressed")
		end
	end
end

function ActivityCourseResearchSelectItem:update(_, _, info)
	if not info or not info.id then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data_ = info
	self.num_ = info.hasGotNum
	local params = {
		noClick = true,
		uiRoot = self.go,
		itemID = info.item_id,
		num = info.item_num
	}

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon(params)
	else
		NGUITools.Destroy(self.itemIcon_.go)

		self.itemIcon_ = xyd.getItemIcon(params)
	end

	self.itemIcon_:setChoose(false)
end

function ActivityCourseResearchSelectItem:setChoose(flag)
	self.itemIcon_:setChoose(flag)
end

function ActivityCourseResearchSelectItem:getInfo()
	return self.data_
end

function ActivityCourseResearchSelectItem:onClick()
	self.parent_:onClickheroIcon(self)
end

return ActivityCourseResearchSelectWindow
