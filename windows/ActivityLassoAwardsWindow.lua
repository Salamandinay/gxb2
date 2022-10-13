local ActivityLassoAwardsWindow = class("ActivityLassoAwardsWindow", import(".BaseWindow"))
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AdvanceIcon = import("app.components.AdvanceIcon")

function ActivityLassoAwardsWindow:ctor(name, params)
	ActivityLassoAwardsWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LASSO)
end

function ActivityLassoAwardsWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function ActivityLassoAwardsWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.awardsContainer = self.groupAction:NodeByName("awardsContainer").gameObject
	self.scroller = self.groupAction:ComponentByName("awardsContainer", typeof(UIScrollView))
	self.rankListContainer_UIWrapContent = self.awardsContainer:ComponentByName("listContainer", typeof(UIWrapContent))
	self.award_item = self.window_:NodeByName("award_item").gameObject
	self.labelWinTitle_ = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.roundText = self.groupAction:ComponentByName("roundText", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller, self.rankListContainer_UIWrapContent, self.award_item, AwardItem, self)

	self.wrapContent:hideItems()
end

function ActivityLassoAwardsWindow:layout()
	self.labelWinTitle_.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.roundText.text = __("ACTIVITY_LASSO_TEXT02")
	local ids = xyd.tables.activityLassoAwardsTable:getIDs()

	self.wrapContent:setInfos(ids, {})

	local round = self.activityData.detail.round

	if round > 23 then
		round = 23
	end

	local moveY = round * 114 + 10
	local sp = SpringPanel.Begin(self.scroller.gameObject, Vector3(0, moveY, 0), 8)
end

function ActivityLassoAwardsWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go, parent)

	self.go = go
	self.parent = parent
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LASSO)
end

function AwardItem:initUI()
	self:getUIComponent()

	self.roundWords.text = __("ACTIVITY_SPACE_LEVEL_TEXT")

	xyd.setUISpriteAsync(self.theTurn, nil, "anniversary_cake_current_turn_" .. xyd.Global.lang, nil, , true)

	self.orWords1.text = __("ACTIVITY_LASSO_OR")
	self.orWords2.text = __("ACTIVITY_LASSO_OR")
	self.icons = {}
end

function AwardItem:getUIComponent()
	self.rank_item = self.go
	self.roundWords = self.rank_item:ComponentByName("roundWords", typeof(UILabel))
	self.theTurn = self.rank_item:ComponentByName("theTurn", typeof(UISprite))
	self.orWords1 = self.rank_item:ComponentByName("orWords1", typeof(UILabel))
	self.orWords2 = self.rank_item:ComponentByName("orWords2", typeof(UILabel))
end

function AwardItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	if info == 26 and xyd.Global.lang == "ja_jp" then
		self.roundWords.width = 204

		self.roundWords:X(-200)
	end

	local finalId = #xyd.tables.activityLassoAwardsTable:getIDs()
	self.info = info
	self.roundWords.text = __("ROUNDS", self.info)

	self.theTurn:SetActive(self.info == self.activityData.detail.round)

	if finalId < self.activityData.detail.round and self.info == finalId then
		self.theTurn:SetActive(true)
	end

	if self.info == finalId then
		self.roundWords.text = __("ACTIVITY_LASSO_TEXT04")
	end

	local awards = xyd.tables.activityLassoAwardsTable:getAwards(self.info)

	self.rank_item:NodeByName("orWords1"):SetActive(true)
	self.rank_item:NodeByName("orWords2").gameObject:SetActive(true)

	if #awards <= 2 then
		self.rank_item:NodeByName("orWords2").gameObject:SetActive(false)

		if #awards <= 1 then
			self.rank_item:NodeByName("orWords1").gameObject:SetActive(false)
		end
	end

	for i = 1, 3 do
		local iconGroup = self.rank_item:NodeByName("icon" .. i).gameObject

		if i <= #awards then
			iconGroup:SetActive(true)

			local params = {
				noClickSelected = true,
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6481481481481481,
				uiRoot = iconGroup,
				itemID = awards[i][1],
				num = awards[i][2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scroller,
				isNew = awards[i][1] == 6773
			}

			if self.icons[i] == nil then
				params.preGenarate = true
				self.icons[i] = AdvanceIcon.new(params)
			else
				self.icons[i]:setInfo(params)
			end

			self.icons[i]:setChoose(false)
		else
			iconGroup:SetActive(false)
		end
	end
end

return ActivityLassoAwardsWindow
