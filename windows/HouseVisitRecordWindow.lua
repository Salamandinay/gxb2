local HouseVisitRecordItem = class("HouseVisitRecordItem")
local PlayerIcon = import("app.components.PlayerIcon")

function HouseVisitRecordItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
end

function HouseVisitRecordItem:getGameObject()
	return self.go
end

function HouseVisitRecordItem:initUI()
	local playerIcon1 = self.go:NodeByName("playerIcon1").gameObject
	self.groupTop1 = self.go:ComponentByName("groupTop1", typeof(UILayout))
	self.labelName1 = self.go:ComponentByName("groupTop1/labelName1", typeof(UILabel))
	self.labelServer1 = self.go:ComponentByName("groupTop1/groupIcons1/labelServer1", typeof(UILabel))
	self.labelTime1 = self.go:ComponentByName("labelTime1", typeof(UILabel))
	self.labelMsg1 = self.go:ComponentByName("labelMsg1", typeof(UILabel))
	self.btnVisit = self.go:NodeByName("btnVisit").gameObject
	self.playerIcon1 = PlayerIcon.new(playerIcon1)

	self.playerIcon1:setScale(0.7)
	self:layout()
end

function HouseVisitRecordItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function HouseVisitRecordItem:layout()
	self.btnVisit:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_49")
	UIEventListener.Get(self.btnVisit).onClick = handler(self, self.onClick)
end

function HouseVisitRecordItem:onClick()
	xyd.WindowManager.get():closeWindow("house_visit_record_window")
	xyd.WindowManager.get():closeWindow("house_friend_list_window")
	xyd.WindowManager.get():closeWindow("house_window")

	local wnd = xyd.WindowManager.get():getWindow("house_visit_window")

	if wnd then
		xyd.WindowManager.get():closeWindow("house_visit_window", nil, , true)
	end

	xyd.WindowManager.get():openWindow("house_visit_window", {
		close_back_house = true,
		other_player_id = self.data.player_id
	})
end

function HouseVisitRecordItem:updateInfo()
	self.labelName1.text = self.data.player_name
	self.labelMsg1.text = __("HOUSE_TEXT_48")
	local dateInfo = os.date("*t", self.data.like_time)
	local hour = xyd.checkCondition(dateInfo.hour < 10, "0" .. tostring(dateInfo.hour), dateInfo.hour)
	local min = xyd.checkCondition(dateInfo.min < 10, "0" .. tostring(dateInfo.min), dateInfo.min)
	local month = xyd.checkCondition(dateInfo.month < 10, "0" .. tostring(dateInfo.month), dateInfo.month)
	local day = xyd.checkCondition(dateInfo.day < 10, "0" .. tostring(dateInfo.day), dateInfo.day)
	self.labelTime1.text = "[ " .. tostring(hour) .. ":" .. tostring(min) .. " " .. tostring(month) .. "/" .. tostring(day) .. " ]"

	self.playerIcon1:setInfo({
		avatarID = self.data.avatar_id,
		lev = self.data.lev,
		avatar_frame_id = self.data.avatar_frame_id,
		callback = function ()
			if self.data.player_id ~= xyd.Global.playerID then
				xyd.WindowManager:get():openWindow("arena_formation_window", {
					add_friend = false,
					is_robot = false,
					player_id = self.data.player_id,
					server_id = self.data.server_id
				})
			end
		end
	})

	self.labelServer1.text = xyd.getServerNumber(self.data.server_id)

	self.groupTop1:Reposition()
end

local HouseVisitRecordWindow = class("HouseVisitRecordWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function HouseVisitRecordWindow:ctor(name, params)
	HouseVisitRecordWindow.super.ctor(self, name, params)

	self.house_ = xyd.models.house
	self.data_ = self.house_:getLikeRecords()
end

function HouseVisitRecordWindow:initWindow()
	HouseVisitRecordWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initList()
	self:registerEvent()
	self.house_:reqLikeRecords()
end

function HouseVisitRecordWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle_", typeof(UILabel))
	self.groupNone_ = winTrans:NodeByName("groupAction/groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	local scrollView = winTrans:ComponentByName("groupAction/scroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList_", typeof(UIWrapContent))
	local scrollItem = scrollView:NodeByName("house_visit_record_item").gameObject
	self.wrapContent_ = FixedWrapContent.new(scrollView, wrapContent, scrollItem, HouseVisitRecordItem, self)
end

function HouseVisitRecordWindow:layout()
	self.labelNoneTips_.text = __("TOWER_RECORD_TIP_1")
	self.labelTitle_.text = __("HOUSE_TEXT_39")
end

function HouseVisitRecordWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.HOUSE_GET_LIKE_RECORDS, handler(self, self.onGetRecordList))
end

function HouseVisitRecordWindow:onGetRecordList(event)
	self.data_ = event.data

	self:initList()
end

function HouseVisitRecordWindow:initList()
	if not self.data_ then
		return
	end

	local list = self.data_.records

	if #list == 0 then
		self.groupNone_:SetActive(true)
	end

	table.sort(list, function (a, b)
		return b.like_time < a.like_time
	end)
	self.wrapContent_:setInfos(list, {})
end

return HouseVisitRecordWindow
