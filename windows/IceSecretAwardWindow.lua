local IceSecretAwardWindow = class("IceSecretAwardWindow", import(".BaseWindow"))
local IceSecretAwardItem = class("IceSecretAwardItem", import("app.components.CopyComponent"))

function IceSecretAwardWindow:ctor(name, params)
	IceSecretAwardWindow.super.ctor(self, name, params)

	self.round_ = params.round
	self.awardedList_ = params.awardedList
	self.bigRewardList_ = params.bigRewardList
	self.selectAwardsList_ = {}
end

function IceSecretAwardWindow:initWindow()
	IceSecretAwardWindow.super.initWindow(self)
	self:getComponent()
	self:layout()
end

function IceSecretAwardWindow:getComponent()
	local winTrans = self.window_:NodeByName("actionGroup")
	self.winTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/warpcontent", typeof(MultiRowWrapContent))
	self.icon_root = winTrans:NodeByName("icon_root").gameObject
	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, self.icon_root, IceSecretAwardItem, self)
end

function IceSecretAwardWindow:layout()
	self.winTitle_.text = __("ACTIVITY_ICE_SECRET_GAME_TITLE")

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	local tempList = {}

	for _, id in ipairs(self.bigRewardList_) do
		local data = {
			id = id,
			award = xyd.tables.activityIceSecretAwardsTable:getAwards(id),
			limit = xyd.tables.activityIceSecretAwardsTable:getLimit(id),
			level = xyd.tables.activityIceSecretAwardsTable:getLevel(id),
			round = self.round_
		}

		if self.chooseId_ == id then
			data.hasGotNum = 1
		else
			data.hasGotNum = 0
		end

		tempList[id] = data
	end

	for _, id in ipairs(self.awardedList_) do
		if tempList[id] then
			tempList[id].hasGotNum = tempList[id].hasGotNum + 1
		end
	end

	for _, id in ipairs(self.bigRewardList_) do
		local data = tempList[id]

		table.insert(self.selectAwardsList_, data)
	end

	table.sort(self.selectAwardsList_, function (a, b)
		return tonumber(a.id) < tonumber(b.id)
	end)
	self.partnerMultiWrap_:setInfos(self.selectAwardsList_, {})
end

function IceSecretAwardItem:ctor(parentGo, parent)
	self.parent_ = parent

	IceSecretAwardItem.super.ctor(self, parentGo)
end

function IceSecretAwardItem:getIconRoot()
	return self.go
end

function IceSecretAwardItem:initUI()
	IceSecretAwardItem.super.initUI(self)

	self.labelNum_ = self.go:ComponentByName("labelNum", typeof(UILabel))
	local drag = self.go:AddComponent(typeof(UIDragScrollView))
	drag.scrollView = self.parent_.scrollView_
end

function IceSecretAwardItem:update(_, _, info)
	if not info or not info.id then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data_ = info
	self.labelNum_.text = self.data_.limit - self.data_.hasGotNum .. "/" .. self.data_.limit
	self.num_ = info.hasGotNum
	local params = {
		show_has_num = true,
		uiRoot = self.go,
		itemID = info.award[1],
		num = info.award[2],
		dragScrollView = self.parent_.scrollView_,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	}

	if self.itemIcon_ then
		NGUITools.Destroy(self.itemIcon_.go)
	end

	self.itemIcon_ = xyd.getItemIcon(params)

	self.itemIcon_:setItemIconDepth(self.go:GetComponent(typeof(UIWidget)).depth + 1)
end

return IceSecretAwardWindow
