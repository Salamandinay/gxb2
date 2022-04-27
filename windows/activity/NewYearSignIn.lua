local ActivityContent = import(".ActivityContent")
local NewYearSignIn = class("NewYearSignIn", ActivityContent)
local NewYearSignInItem = class("NewYearSignInItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ActivityFestivalLoginTable = xyd.tables.activityFestivalLoginTable

function NewYearSignIn:ctor(parentGO, params, parent)
	self.items_ = {}
	self.total_days_ = ActivityFestivalLoginTable:getDays()

	ActivityContent.ctor(self, parentGO, params, parent)
end

function NewYearSignIn:getPrefabPath()
	return "Prefabs/Windows/activity/new_year_signin"
end

function NewYearSignIn:initUI()
	ActivityContent.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
	self:setItems()
	self:updateStatus()
	self.go:Y(-520)

	local height = self.parentGo:GetComponent(typeof(UIPanel)).height

	self.contentGroup:Y(-30 + (867 - height) * 0.25)
end

function NewYearSignIn:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.scroller = self.contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.sign_item = self.scroller:NodeByName("new_year_signin_item").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.sign_item, NewYearSignInItem, self)
	self.signTextLabel = self.contentGroup:ComponentByName("textGroup/signTextLabel", typeof(UILabel))
	self.signCountLabel = self.contentGroup:ComponentByName("textGroup/signCountLabel", typeof(UILabel))
	self.signInBtn = self.contentGroup:NodeByName("signInBtn").gameObject
end

function NewYearSignIn:initUIComponent()
	self.signTextLabel.text = __("NEWYEAR_TEXT02")
	self.signInBtn:ComponentByName("button_label", typeof(UILabel)).text = __("CHECKIN_TEXT04")

	xyd.setUISpriteAsync(self.textImg, nil, "new_year_sign_text_" .. xyd.Global.lang)
end

function NewYearSignIn:setItems()
	self.items_ = {}
	local ids = ActivityFestivalLoginTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])
		local info = {
			id = id,
			is_completed = self:getStatus(id)
		}

		table.insert(self.items_, info)
	end

	table.sort(self.items_, function (a, b)
		if a.is_completed ~= b.is_completed then
			if a.is_completed then
				return false
			else
				return true
			end
		end

		return a.id < b.id
	end)
	self.wrapContent:setInfos(self.items_, {})
end

function NewYearSignIn:updateStatus()
	if not self:checkCanSign() then
		xyd.setEnabled(self.signInBtn, false)
	end

	self.signCountLabel.text = self.activityData.detail.count .. "/" .. self.total_days_
end

function NewYearSignIn:onRegister()
	UIEventListener.Get(self.signInBtn).onClick = handler(self, self.onTouchSign)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function NewYearSignIn:onTouchSign()
	if self:checkCanSign() then
		xyd.models.activity:reqAward(self.id)
	end
end

function NewYearSignIn:onGetAward(event)
	self:updateStatus()
	self:setItems()

	local items = {}
	local data = ActivityFestivalLoginTable:getAwards(self.activityData.detail.count)

	for i = 1, #data do
		table.insert(items, {
			item_id = data[i][1],
			item_num = data[i][2]
		})
	end

	xyd.openWindow("gamble_rewards_window", {
		wnd_type = 2,
		data = items
	})
end

function NewYearSignIn:getStatus(id)
	return id <= self.activityData.detail.count
end

function NewYearSignIn:checkCanSign()
	return self.activityData.detail.count < math.min(self.total_days_, self.activityData.detail.online_days)
end

function NewYearSignInItem:ctor(go, parent)
	NewYearSignInItem.super.ctor(self, go, parent)

	self.is_completed_ = false
end

function NewYearSignInItem:initUI()
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.timeLabel = self.go:ComponentByName("timeLabel", typeof(UILabel))
end

function NewYearSignInItem:updateInfo()
	self.id_ = self.data.id
	self.is_completed_ = self.data.is_completed
	self.timeLabel.text = __("LOGIN_DAY_" .. self.id_)
	local awards = ActivityFestivalLoginTable:getAwards(self.id_)

	NGUITools.DestroyChildren(self.itemGroup.transform)

	self.items_ = {}

	for i = 1, #awards do
		local data = awards[i]
		local item = xyd.getItemIcon({
			show_has_num = true,
			hideText = true,
			scale = 0.7,
			uiRoot = self.itemGroup,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scroller
		})

		table.insert(self.items_, item)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	if self.is_completed_ then
		self:setStatus(true)
	end
end

function NewYearSignInItem:setStatus(flag)
	for i = 1, #self.items_ do
		self.items_[i]:setChoose(flag)
	end
end

return NewYearSignIn
