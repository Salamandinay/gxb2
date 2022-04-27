local ActivityTaskGetAwardWindows = class("ActivityTaskGetAwardWindows", import(".BaseWindow"))
local AwardItem = class("AwardItem", import("app.common.ui.FixedWrapContentItem"))
local cjson = require("cjson")

function ActivityTaskGetAwardWindows:ctor(name, params)
	self.hasNav = params.hasNav
	self.titleText = params.titleText or ""
	self.tipsText = params.tipsText or ""
	self.taskList = params.taskList
	self.activity_id = params.activity_id

	ActivityTaskGetAwardWindows.super.ctor(self, name, params)
end

function ActivityTaskGetAwardWindows:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivityTaskGetAwardWindows:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction/groupMain").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.titleLabel = self.groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.tipsLabel = self.groupAction:ComponentByName("tipsLabel", typeof(UILabel))
	self.navGroup = self.groupAction:NodeByName("navGroup").gameObject
	self.scrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	local itemRoot = self.groupAction:NodeByName("itemRoot").gameObject
	local wrapContent = self.scrollView:ComponentByName("groupContent", typeof(UIWrapContent))
	self.wrapContent = import("app.common.ui.FixedWrapContent").new(self.scrollView, wrapContent, itemRoot, AwardItem, self)
	self.scrollerBg = self.groupAction:NodeByName("scrollerBg").gameObject
end

function ActivityTaskGetAwardWindows:layout()
	if not self.params_.hasNav then
		self.navGroup:SetActive(false)
		self.tipsLabel:SetActive(true)

		self.tipsLabel.text = self.tipsText

		self.scrollerBg:Y(-444)

		self.bg.height = 814
	else
		self.navGroup:SetActive(true)
		self.tipsLabel:SetActive(false)
	end

	self.titleLabel.text = self.titleText

	self.wrapContent:setInfos(self.taskList, {})
	self:waitForFrame(1, function ()
		self.scrollView:ResetPosition()
	end)
end

function ActivityTaskGetAwardWindows:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

function ActivityTaskGetAwardWindows:onAward(event)
	if self.activity_id ~= event.data.activity_id then
		return
	end

	local items = cjson.decode(event.data.detail).items

	xyd.models.itemFloatModel:pushNewItems(items)
end

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go, parent)
end

function AwardItem:initUI()
	local goTrans = self.go
	self.dragBg_ = goTrans:ComponentByName("e:image", typeof(UIDragScrollView))
	self.awardGroup_ = goTrans:ComponentByName("awardGroup", typeof(UIGrid))
	self.tipsLabel_ = goTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.awardBtn_ = goTrans:ComponentByName("awardBtn", typeof(UISprite))
	self.awardBtnGrey_ = goTrans:NodeByName("awardBtnGrey").gameObject
	self.awardBtnGreyLabel_ = goTrans:ComponentByName("awardBtnGrey/label", typeof(UILabel))
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.awardImg_ = goTrans:ComponentByName("awardImg", typeof(UISprite))
	self.valueLabel_ = goTrans:ComponentByName("valueLabel", typeof(UILabel))
	UIEventListener.Get(self.awardBtn_.gameObject).onClick = handler(self, self.onClickAward)
	UIEventListener.Get(self.dragBg_.gameObject).onClick = handler(self, self.jump)
	self.dragBg_.scrollView = self.parent.scrollView

	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang)

	self.awardBtnLabel_.text = __("MIDAS_TEXT04")
	self.awardBtnGreyLabel_.text = __("MIDAS_TEXT04")
	self.awardItemList = {}
end

function AwardItem:updateInfo()
	self.tipsLabel_.text = self.data.des
	self.valueLabel_.text = "(" .. self.data.count .. "/" .. self.data.complete .. ")"

	if self.data.isAwarded == 1 then
		self.awardImg_:SetActive(true)
		self.awardBtn_:SetActive(false)
		self.awardBtnGrey_:SetActive(false)
	elseif self.data.count < self.data.complete then
		self.awardImg_:SetActive(false)
		self.awardBtn_:SetActive(false)
		self.awardBtnGrey_:SetActive(true)
	else
		self.awardImg_:SetActive(false)
		self.awardBtn_:SetActive(true)
		self.awardBtnGrey_:SetActive(false)
	end

	local len = math.max(#self.awardItemList, #self.data.awards)

	for i = 1, len do
		if self.data.awards[i] then
			local item = self.data.awards[i]

			if not self.awardItemList[i] then
				self.awardItemList[i] = xyd.getItemIcon({
					show_has_num = true,
					scale = 0.7962962962962963,
					itemID = item[1],
					num = item[2],
					uiRoot = self.awardGroup_.gameObject,
					dragScrollView = self.parent.scrollView
				})
			else
				self.awardItemList[i]:SetActive(true)
				self.awardItemList[i]:setInfo({
					show_has_num = true,
					scale = 0.7962962962962963,
					itemID = item[1],
					num = item[2],
					dragScrollView = self.parent.scrollView
				})
			end
		elseif self.awardItemList[i] then
			self.awardItemList[i]:SetActive(false)
		end
	end

	self.awardGroup_:Reposition()
end

function AwardItem:onClickAward()
	local params = cjson.encode({
		mission_id = self.data.id
	})

	xyd.models.activity:reqAwardWithParams(self.data.activity_id, params)
	self.awardBtn_:SetActive(false)
	self.awardImg_:SetActive(true)
end

function AwardItem:jump()
	if not self.data.goWayList or not next(self.data.goWayList) then
		return
	end

	for _, getWayID in ipairs(self.data.goWayList) do
		local function_id = xyd.tables.getWayTable:getFunctionId(getWayID)
		local windows = xyd.tables.getWayTable:getGoWindow(getWayID)
		local params = xyd.tables.getWayTable:getGoParam(getWayID)

		if xyd.checkFunctionOpen(function_id) and (windows[1] ~= "activity_window" or windows[1] == "activity_window" and xyd.models.activity:getActivity(params[1].select)) then
			xyd.WindowManager.get():closeWindow("activity_task_get_award_window")
			xyd.goWay(getWayID, nil, , self.data.closeCallback)

			break
		end
	end
end

return ActivityTaskGetAwardWindows
