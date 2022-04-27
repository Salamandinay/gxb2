local ActivityBaoxiangAwardWindow = class("ActivityBaoxiangAwardWindow", import(".BaseWindow"))
local BaoxiangAwardItem = class("BaoxiangAwardItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityBaoxiangAwardWindow:ctor(name, params)
	ActivityBaoxiangAwardWindow.super.ctor(self, name, params)

	self.itemPointList_ = {}
	self.itemPartnerList_ = {}
end

function ActivityBaoxiangAwardWindow:initWindow()
	ActivityBaoxiangAwardWindow.super.initWindow(self)
	self:getUIComponent()

	self.winTitle_.text = __("ACTIVTIY_NEWYEAR_COST")

	self:setContent()
	self:register()
end

function ActivityBaoxiangAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid = self.scrollView:NodeByName("grid").gameObject
	self.itemRoot_ = winTrans:NodeByName("itemRoot").gameObject
end

function ActivityBaoxiangAwardWindow:register()
	ActivityBaoxiangAwardWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityBaoxiangAwardWindow:setContent()
	local ids = xyd.tables.activityNewyearAwardTable:getIds()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEWYEAR_BAOXIANG)
	local awardedData = activityData.detail.awarded
	local list = {}

	for i = 1, #ids do
		local id = ids[i]
		local itemID = xyd.tables.activityNewyearAwardTable:getItemID(id)
		local value = activityData.detail["point_" .. itemID] or 0
		local canAward = xyd.tables.activityNewyearAwardTable:getPoint(id) <= value and 1 or 0

		table.insert(list, {
			id = id,
			isAwarded = awardedData[id],
			canAward = canAward,
			value = value,
			parent = self
		})
	end

	table.sort(list, function (a, b)
		if a.isAwarded ~= b.isAwarded then
			return a.isAwarded == 0
		elseif a.canAward ~= b.canAward then
			return a.canAward == 1
		else
			return a.id < b.id
		end
	end)

	self.cotentList = {}

	for i = 1, #list do
		local temp = NGUITools.AddChild(self.grid, self.itemRoot_)
		local item = BaoxiangAwardItem.new(temp, list[i])
		self.cotentList[list[i].id] = item
	end

	self.scrollView:ResetPosition()
end

function ActivityBaoxiangAwardWindow:onGetAward(event)
	if event.data.activity_id == xyd.ActivityID.NEWYEAR_BAOXIANG then
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEWYEAR_BAOXIANG)
		local awardedId = activityData.awardId
		local awards = xyd.tables.activityNewyearAwardTable:getAward(awardedId)
		local item = {
			item_id = awards[1],
			item_num = awards[2]
		}

		xyd.models.itemFloatModel:pushNewItems({
			item
		})
		self.cotentList[awardedId]:onAward()
	end
end

function BaoxiangAwardItem:ctor(parentGo, params)
	self.id = params.id
	self.parent_ = params.parent
	self.canAward = params.canAward
	self.isAwarded = params.isAwarded
	self.value = params.value

	BaoxiangAwardItem.super.ctor(self, parentGo)
end

function BaoxiangAwardItem:initUI()
	self:getUIComponent()
	self:initContent()

	UIEventListener.Get(self.awardBtn_.gameObject).onClick = handler(self, self.onClickAward)
end

function BaoxiangAwardItem:getUIComponent()
	local goTrans = self.go.transform
	self.awardGroup_ = goTrans:ComponentByName("awardGroup", typeof(UIGrid))
	self.tipsLabel_ = goTrans:ComponentByName("tipsLabel", typeof(UILabel))
	self.awardBtn_ = goTrans:ComponentByName("awardBtn", typeof(UISprite))
	self.awardBtnGrey_ = goTrans:NodeByName("awardBtnGrey").gameObject
	self.awardBtnGreyLabel_ = goTrans:ComponentByName("awardBtnGrey/label", typeof(UILabel))
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.awardImg_ = goTrans:ComponentByName("awardImg", typeof(UISprite))
	self.valueLabel_ = goTrans:ComponentByName("valueLabel", typeof(UILabel))
end

function BaoxiangAwardItem:initContent()
	local point = xyd.tables.activityNewyearAwardTable:getPoint(self.id)
	local itemID = xyd.tables.activityNewyearAwardTable:getItemID(self.id)
	self.tipsLabel_.text = __("ACTIVTIY_NEWYEAR_TITLE", point, xyd.tables.itemTable:getName(itemID))

	if point < self.value then
		self.value = point
	end

	self.valueLabel_.text = "(" .. self.value .. "/" .. point .. ")"

	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang)
	xyd.setDragScrollView(self.awardBtn_.gameObject, self.parent_.scrollView)

	self.awardBtnLabel_.text = __("MIDAS_TEXT04")
	self.awardBtnGreyLabel_.text = __("MIDAS_TEXT04")
	local awards = xyd.tables.activityNewyearAwardTable:getAward(self.id)
	local item = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.7962962962962963,
		itemID = awards[1],
		num = awards[2],
		uiRoot = self.awardGroup_.gameObject,
		dragScrollView = self.parent_.scrollView
	})

	self:setBtn()
end

function BaoxiangAwardItem:setBtn()
	if self.canAward == 0 then
		self.awardBtn_.gameObject:SetActive(false)
		self.awardBtnGrey_:SetActive(true)
	else
		self.awardBtnGrey_:SetActive(false)
		self.awardBtn_.gameObject:SetActive(true)
	end

	if self.isAwarded == 1 then
		self.awardBtn_.gameObject:SetActive(false)
		self.awardImg_:SetActive(true)
	end
end

function BaoxiangAwardItem:onClickAward()
	local params = json.encode({
		award_id = tonumber(self.id)
	})

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.NEWYEAR_BAOXIANG, params)
	xyd.models.activity:getActivity(xyd.ActivityID.NEWYEAR_BAOXIANG):setAwardId(self.id)
end

function BaoxiangAwardItem:onAward()
	self.isAwarded = 1

	self:setBtn()
end

return ActivityBaoxiangAwardWindow
