local HouseFriendListItem = import("app.components.HouseFriendListItem")
local ScrollItem = class("ScrollItem")

function ScrollItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item_ = HouseFriendListItem.new(go)

	self.item_:setDragScrollView(parent.scrollView)
	self.go:SetActive(false)
end

function ScrollItem:getGameObject()
	return self.go
end

function ScrollItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self.item_:update(info)
end

local HouseFriendListWindow = class("HouseFriendListWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function HouseFriendListWindow:ctor(name, params)
	HouseFriendListWindow.super.ctor(self, name, params)

	self.curSelect_ = 1
	self.collection_ = {}
	self.house_ = xyd.models.house
end

function HouseFriendListWindow:initWindow()
	HouseFriendListWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:updateBtnSelect()
	self:registerEvent()

	self.data_ = self.house_:getRecommendDorms()

	if self.data_ then
		self:initList()
	else
		self.house_:reqGetRecommendDorms()
	end
end

function HouseFriendListWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelWinTitle = winTrans:ComponentByName("groupAction/labelWinTitle", typeof(UILabel))
	self.labelPraise = winTrans:ComponentByName("groupAction/groupPraise/praiseTips1/labelPraise", typeof(UILabel))
	self.labelPraiseNum = winTrans:ComponentByName("groupAction/groupPraise/praiseTips2/labelPraiseNum", typeof(UILabel))
	self.btnTop1 = winTrans:NodeByName("groupAction/topBtn/btnTop1").gameObject
	self.btnTop2 = winTrans:NodeByName("groupAction/topBtn/btnTop2").gameObject
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.groupNone_ = winTrans:NodeByName("groupAction/groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.btnRecord_ = winTrans:NodeByName("groupAction/btnRecord_").gameObject
	local scrollView = winTrans:ComponentByName("groupAction/scroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList_", typeof(UIWrapContent))
	local scrollItem = scrollView:NodeByName("scrollItem").gameObject
	self.wrapContent_ = FixedWrapContent.new(scrollView, wrapContent, scrollItem, ScrollItem, self)
end

function HouseFriendListWindow:layout()
	self.labelNoneTips_.text = __("HOUSE_TEXT_43")
	self.btnRecord_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_39")
	self.labelPraise.text = __("HOUSE_TEXT_40")
	self.labelPraiseNum.text = self.house_:getSelfPraiseNum()
	self.btnTop1:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_41")
	self.btnTop2:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_42")
end

function HouseFriendListWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnRecord_).onClick = handler(self, self.onRecordTouch)

	UIEventListener.Get(self.btnTop1).onClick = function ()
		self:onTopTouch(1)
	end

	UIEventListener.Get(self.btnTop2).onClick = function ()
		self:onTopTouch(2)
	end

	self.eventProxy_:addEventListener(xyd.event.HOUSE_GET_RECOMMEND_DORMS, handler(self, self.onGetList))
end

function HouseFriendListWindow:onTopTouch(index)
	self.curSelect_ = index

	self:updateBtnSelect()
	self:updateItemList()
end

function HouseFriendListWindow:updateBtnSelect()
	for i = 1, 2 do
		local btn = self["btnTop" .. tostring(i)]
		local params = {
			color = 960513791,
			strokeColor = 4294967295.0
		}

		if i == self.curSelect_ then
			btn:GetComponent(typeof(UIButton)):SetEnabled(false)

			params = {
				color = 4294967295.0,
				strokeColor = 1012112383
			}
		else
			btn:GetComponent(typeof(UIButton)):SetEnabled(true)
		end

		xyd.setBtnLabel(btn, params)
	end
end

function HouseFriendListWindow:onRecordTouch()
	xyd.WindowManager.get():openWindow("house_visit_record_window")
end

function HouseFriendListWindow:onGetList(event)
	self.data_ = event.data

	self:initList()
end

function HouseFriendListWindow:initList()
	if not self.data_ then
		return
	end

	local friendList = self.data_.friend_list or {}
	self.collection_[1] = friendList
	local recommendList = self.data_.recommend_list or {}
	self.collection_[2] = recommendList

	self:updateItemList()
end

function HouseFriendListWindow:updateItemList()
	local collection = self.collection_[self.curSelect_] or {}

	if not collection or #collection == 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	if self.curSelect_ == 1 then
		self.labelNoneTips_.text = __("HOUSE_TEXT_43")
	else
		self.labelNoneTips_.text = __("HOUSE_TEXT_44")
	end

	self.wrapContent_:setInfos(collection, {})
end

return HouseFriendListWindow
