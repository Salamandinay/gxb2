local BaseWindow = import(".BaseWindow")
local ActivityBeachIslandAwardWindow = class("ActivityBeachIslandAwardWindow", BaseWindow)
local BeachStarAwardItem = class("BeachStarAwardItem", import("app.components.CopyComponent"))
local cjson = require("cjson")
local tableUse, activityUse = nil

function ActivityBeachIslandAwardWindow:ctor(name, params)
	ActivityBeachIslandAwardWindow.super.ctor(self, name, params)

	activityUse = params.activity_id or xyd.ActivityID.ACTIVITY_BEACH_SUMMER
	self.starNum_ = params.star or 0
	self.awarded_ = params.awarded or {}
	tableUse = xyd.tables.activityBeachStarAwardTable

	if activityUse == xyd.ActivityID.ENCONTER_STORY then
		tableUse = xyd.tables.activityEnconterStarAwardsTable
	end
end

function ActivityBeachIslandAwardWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:RegisterEvent()
end

function ActivityBeachIslandAwardWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.bgImg_ = goTrans:ComponentByName("e:image", typeof(UISprite))
	self.awardItemRoot_ = goTrans:NodeByName("award_item").gameObject
	self.closeBtn = goTrans:NodeByName("closeBtn").gameObject
	self.labelTitle_ = goTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.tipsGroup_ = goTrans:ComponentByName("tipsGroup", typeof(UILayout))
	self.labelTips_ = goTrans:ComponentByName("tipsGroup/labelTips", typeof(UILabel))
	self.lableNum_ = goTrans:ComponentByName("tipsGroup/lableNum", typeof(UILabel))
	self.scrollView_ = goTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = goTrans:ComponentByName("scrollView/grid", typeof(UIGrid))

	self.awardItemRoot_:SetActive(false)

	if activityUse == xyd.ActivityID.ENCONTER_STORY then
		self.bgImg_.height = 615

		goTrans:Y(-100)
	end
end

function ActivityBeachIslandAwardWindow:RegisterEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAwardStar))
end

function ActivityBeachIslandAwardWindow:onAwardStar(event)
	local details = require("cjson").decode(event.data.detail)
	local items = details.items

	xyd.itemFloat(items)

	self.awarded_ = xyd.models.activity:getActivity(activityUse).detail.awarded

	self:updateItems()
end

function ActivityBeachIslandAwardWindow:layout()
	self.labelTitle_.text = __("ACTIVITY_BEACH_ISLAND_TEXT08")
	self.labelTips_.text = __("ACTIVITY_BEACH_ISLAND_TEXT09")
	local totalNum = tableUse:getTotalPoint()
	self.lableNum_.text = self.starNum_ .. "/" .. totalNum

	self:initItemList()
end

function ActivityBeachIslandAwardWindow:initItemList()
	local ids = tableUse:getIDs()
	local itemInfos = {}
	self.itemList_ = {}

	for index, id in ipairs(ids) do
		local params = {
			id = id,
			star = self.starNum_,
			is_awarded = self.awarded_[index] or 0,
			complete_point = tableUse:getPoint(id)
		}

		table.insert(itemInfos, params)
	end

	table.sort(itemInfos, function (a, b)
		local valueA = a.id + 100 * a.is_awarded
		local valueB = b.id + 100 * b.is_awarded
		valueA = valueA + xyd.checkCondition(a.complete_point <= a.star, -10, 0)
		valueB = valueB + xyd.checkCondition(b.complete_point <= b.star, -10, 0)

		return valueA < valueB
	end)

	for _, info in ipairs(itemInfos) do
		local itemRoot = NGUITools.AddChild(self.grid_.gameObject, self.awardItemRoot_)

		itemRoot:SetActive(true)

		local itemNew = BeachStarAwardItem.new(itemRoot, info)

		table.insert(self.itemList_, itemNew)
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

function ActivityBeachIslandAwardWindow:updateItems()
	local ids = tableUse:getIDs()
	local itemInfos = {}

	for index, id in ipairs(ids) do
		local params = {
			id = id,
			star = self.starNum_,
			is_awarded = self.awarded_[index] or 0,
			complete_point = tableUse:getPoint(id)
		}

		table.insert(itemInfos, params)
	end

	for i = 1, #ids do
		local item = self.itemList_[i]

		for j = 1, #itemInfos do
			if item:getID() == ids[j] then
				item:updateInfos(itemInfos[j])
			end
		end
	end
end

function BeachStarAwardItem:ctor(go, params)
	self.info_ = params

	BeachStarAwardItem.super.ctor(self, go)
end

function BeachStarAwardItem:initUI()
	self:getUIComponent()
	self:layout()
	self:initItems()
end

function BeachStarAwardItem:getID()
	return self.info_.id
end

function BeachStarAwardItem:getUIComponent()
	local goTrans = self.go.transform
	self.labelDesc_ = goTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.itemGroup_ = goTrans:ComponentByName("itemGroup", typeof(UILayout))
	self.awardBtn_ = goTrans:ComponentByName("awardBtn", typeof(UISprite))
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.awardMask_ = goTrans:NodeByName("awardBtn/mask").gameObject
	self.awardImg_ = goTrans:ComponentByName("awardImg", typeof(UISprite))
	UIEventListener.Get(self.awardBtn_.gameObject).onClick = handler(self, self.onClickAward)
end

function BeachStarAwardItem:layout()
	local complete_point = self.info_.complete_point
	self.labelDesc_.text = __("ACTIVITY_BEACH_ISLAND_TEXT10", complete_point)
	self.awardBtnLabel_.text = __("GET2")

	if self.info_.is_awarded and tonumber(self.info_.is_awarded) == 1 then
		self.awardBtn_.gameObject:SetActive(false)
		self.awardImg_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang, nil, , true)
	else
		self.awardImg_.gameObject:SetActive(false)
		self.awardBtn_.gameObject:SetActive(true)

		if complete_point <= self.info_.star then
			self.awardMask_:SetActive(false)
			xyd.setUISpriteAsync(self.awardBtn_, nil, "blue_btn_60_60")

			self.awardBtnLabel_.color = Color.New2(4294967295.0)
			self.awardBtnLabel_.effectColor = Color.New2(1012112383)
		else
			self.awardMask_:SetActive(true)
			xyd.setUISpriteAsync(self.awardBtn_, nil, "white_btn_60_60")

			self.awardBtnLabel_.color = Color.New2(960513791)
			self.awardBtnLabel_.effectColor = Color.New2(4294967295.0)
		end
	end
end

function BeachStarAwardItem:initItems()
	local awards = tableUse:getAwards(self.info_.id)

	NGUITools.DestroyChildren(self.itemGroup_.transform)

	for _, itemData in ipairs(awards) do
		local params = {
			notShowGetWayBtn = true,
			scale = 0.7222222222222222,
			uiRoot = self.itemGroup_.gameObject,
			itemID = itemData[1],
			num = itemData[2]
		}

		xyd.getItemIcon(params)
	end

	self:waitForFrame(1, function ()
		self.itemGroup_:Reposition()
	end)
end

function BeachStarAwardItem:onClickAward()
	if self.info_.is_awarded and self.info_.is_awarded == 1 then
		return
	end

	if self.info_.complete_point <= self.info_.star then
		xyd.models.activity:reqAwardWithParams(activityUse, cjson.encode({
			activity_id = activityUse,
			table_id = self.info_.id
		}))
	end
end

function BeachStarAwardItem:updateInfos(params)
	self.info_ = params

	self:layout()
end

return ActivityBeachIslandAwardWindow
