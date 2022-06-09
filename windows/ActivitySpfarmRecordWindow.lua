local ActivitySpfarmRecordWindow = class("ActivitySpfarmRecordWindow", import(".BaseWindow"))
local PersonItem = class("PersonItem", import("app.components.CopyComponent"))

function ActivitySpfarmRecordWindow:ctor(name, params)
	ActivitySpfarmRecordWindow.super.ctor(self, name, params)

	self.list_ = params.list
	self.indexNum = 0
	self.recordItemList_ = {}
end

function ActivitySpfarmRecordWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivitySpfarmRecordWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.helpBtn_ = self.groupAction:NodeByName("helpBtn").gameObject
	self.winTitle_ = self.topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.scrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid = self.groupAction:ComponentByName("scrollView/grid", typeof(UIWrapContent))
	self.item = self.groupAction:NodeByName("item").gameObject
	self.recordWrap_ = require("app.common.ui.FixedWrapContent").new(self.scrollView, self.grid, self.item, PersonItem, self)
end

function ActivitySpfarmRecordWindow:layout()
	self.winTitle_.text = __("ACTIVITY_SPFARM_TEXT74")

	table.sort(self.list_, function (a, b)
		return b.time < a.time
	end)
	self.recordWrap_:setInfos(self.list_, {})
	self.scrollView:ResetPosition()
end

function ActivitySpfarmRecordWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.helpBtn_).onClick = function (arg1, arg2, arg3)
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_SPFARM_TEXT113"
		})
	end
end

function PersonItem:ctor(goItem, parent)
	self.goItem = goItem
	self.parent = parent

	PersonItem.super.ctor(self, goItem)
	self:setDepth(self.parent.indexNum * 30 + 100)

	self.parent.indexNum = self.parent.indexNum + 1
end

function PersonItem:getUIComponent()
	self.item = self.go
	self.bottomBg = self.item:ComponentByName("bottomBg", typeof(UISprite))
	self.personCon = self.item:NodeByName("personCon").gameObject
	self.timeCon = self.item:NodeByName("timeCon").gameObject
	self.timeLabel = self.timeCon:ComponentByName("timeLabel", typeof(UILabel))
	self.levCon = self.item:NodeByName("levCon").gameObject
	self.levBg = self.levCon:ComponentByName("levBg", typeof(UISprite))
	self.levLeftLabel = self.levCon:ComponentByName("levLeftLabel", typeof(UILabel))
	self.levRightLabel = self.levCon:ComponentByName("levRightLabel", typeof(UILabel))
	self.btnCon = self.item:NodeByName("btnCon").gameObject
	self.btnSprite = self.btnCon:GetComponent(typeof(UISprite))
	self.btnLabel = self.btnCon:ComponentByName("btnLabel", typeof(UILabel))
	self.btnIcon = self.btnCon:NodeByName("btnIcon").gameObject
	self.tipCon = self.item:NodeByName("tipCon").gameObject
	self.tipConLayout = self.item:ComponentByName("tipCon", typeof(UILayout))
	self.tipLabel = self.item:ComponentByName("tipCon/label", typeof(UILabel))
end

function PersonItem:initUI()
	self:getUIComponent()
	self:register()

	self.btnLabel.text = __("ACTIVITY_SPFARM_TEXT40")
end

function PersonItem:register()
	UIEventListener.Get(self.btnCon.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_spfarm_record_detail_window", {
			log = self.log
		})
	end)

	UIEventListener.Get(self.tipCon).onClick = function ()
		xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT71"), nil, __("SURE"))
	end
end

function PersonItem:update(_, info)
	self.info = info

	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local resTime = xyd.getServerTime() - info.time
	local min = resTime / 60
	local hour = min / 60
	local day = hour / 24

	if day >= 1 then
		self.timeLabel.text = __("DAY_BEFORE", math.floor(day))
	elseif hour >= 1 then
		self.timeLabel.text = __("HOUR_BEFORE", math.floor(hour))
	elseif min >= 1 then
		self.timeLabel.text = __("MIN_BEFORE", math.floor(min))
	else
		self.timeLabel.text = __("SECOND_BEFORE")
	end

	self.log = info.log
	local ids = info.dress_style

	if self.log[1] and tonumber(self.log[1]) == 0 then
		xyd.setUISpriteAsync(self.btnSprite, nil, "activity_spfarm_record_btn1")

		self.btnLabel.text = __("ACTIVITY_SPFARM_TEXT72")
		self.btnLabel.effectColor = Color.New2(1012250111)
		self.levLeftLabel.text = __("ACTIVITY_SPFARM_TEXT110")
	else
		xyd.setUISpriteAsync(self.btnSprite, nil, "activity_spfarm_record_btn2")

		self.btnLabel.text = __("ACTIVITY_SPFARM_TEXT73")
		self.btnLabel.effectColor = Color.New2(2604671743.0)
		ids[4] = xyd.tables.miscTable:getNumber("activity_spfarm_dress", "value")
		self.levLeftLabel.text = __("ACTIVITY_SPFARM_TEXT109")
	end

	if self.log[1] and tonumber(self.log[1]) == 2 then
		self.tipCon:SetActive(true)

		self.tipLabel.text = __("ACTIVITY_SPFARM_TEXT70")

		self.tipConLayout:Reposition()
	else
		self.tipCon:SetActive(false)
	end

	local allBuildLev = 0

	for i = 3, #self.log do
		local date = xyd.split(self.log[i], "#", false)
		allBuildLev = allBuildLev + (date[2] or 0)
	end

	self.levRightLabel.text = tostring(allBuildLev)

	if not self.normalModel_ then
		self.normalModel_ = import("app.components.SenpaiModel").new(self.personCon.gameObject)
	end

	self.normalModel_:setModelInfo({
		isNewClipShader = true,
		ids = ids
	})
end

return ActivitySpfarmRecordWindow
