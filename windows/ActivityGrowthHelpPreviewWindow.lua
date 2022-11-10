local BaseWindow = import(".BaseWindow")
local ActivityGrowthHelpPreviewWindow = class("ActivityGrowthHelpPreviewWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local BaseComponent = import("app.components.BaseComponent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function ActivityGrowthHelpPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.icons1 = {}
	self.icons2 = {}
end

function ActivityGrowthHelpPreviewWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.imgTitle = self.groupAction:ComponentByName("imgTitle", typeof(UISprite))
	self.labelDesc = self.groupAction:ComponentByName("labelDesc", typeof(UILabel))
	self.btnJump = self.groupAction:NodeByName("btnJump").gameObject
	self.labelJump = self.btnJump:ComponentByName("labelJump", typeof(UILabel))
	self.awardGroup1 = self.groupAction:NodeByName("awardGroup1").gameObject
	self.iconGroup1 = self.awardGroup1:NodeByName("iconGroup").gameObject
	self.iconGroup1Grid = self.awardGroup1:ComponentByName("iconGroup", typeof(UIGrid))
	self.labelTitle1 = self.awardGroup1:ComponentByName("labelTitle", typeof(UILabel))
	self.awardGroup2 = self.groupAction:NodeByName("awardGroup2").gameObject
	self.iconGroup2 = self.awardGroup2:NodeByName("iconGroup").gameObject
	self.iconGroup2Grid = self.awardGroup2:ComponentByName("iconGroup", typeof(UIGrid))
	self.labelTitle2 = self.awardGroup2:ComponentByName("labelTitle", typeof(UILabel))
	self.timeGroup = self.groupAction:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.groupAction:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.dumpIcon = self.groupAction:ComponentByName("dumpIcon", typeof(UISprite))
	self.labelText = self.dumpIcon:ComponentByName("labelText", typeof(UILabel))
	self.labelNum = self.dumpIcon:ComponentByName("labelNum", typeof(UILabel))
end

function ActivityGrowthHelpPreviewWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()
	xyd.db.misc:setValue({
		key = "activity_new_growth_plan_preview_time_stamp",
		value = xyd.getServerTime()
	})

	self.labelDesc.text = __("ACTIVITY_NEW_GROWTH_PLAN_TEXT20")
	self.labelJump.text = __("ACTIVITY_LOST_SPACE_TEXT05")
	self.labelTitle1.text = __("ACTIVITY_NEW_GROWTH_PLAN_TEXT21")
	self.labelTitle2.text = __("ACTIVITY_NEW_GROWTH_PLAN_TEXT22")
	self.labelText.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT09")
	self.endLabel_.text = __("END")

	if xyd.Global.lang == "de_de" then
		self.labelTitle1.width = 160
		self.labelTitle2.width = 250
	end

	self.labelNum.text = "+" .. xyd.tables.miscTable:getNumber("activity_new_growth_plan_show3", "value") .. "%"
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN)

	CountDown.new(self.timeLabel_, {
		duration = self.activityData.detail.start_time + xyd.tables.miscTable:getNumber("activity_new_growth_plan_start3", "value") * 24 * 60 * 60 - xyd.getServerTime()
	})

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeGroupLayout:Reposition()
	xyd.setUISpriteAsync(self.imgTitle, nil, "activity_new_growth_plan_logo_" .. xyd.Global.lang)

	local awards = xyd.tables.miscTable:split2Cost("activity_new_growth_plan_show1", "value", "|")

	for i = 1, #awards do
		local award = awards[i]
		local params = {
			notShowGetWayBtn = true,
			noWays = true,
			show_has_num = false,
			scale = 0.7037037037037037,
			uiRoot = self.iconGroup1,
			itemID = award,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}
		self.icons1[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.iconGroup1Grid:Reposition()

	awards = xyd.tables.miscTable:split2Cost("activity_new_growth_plan_show2", "value", "|#")

	for i = 1, #awards do
		local award = awards[i]
		local params = {
			notShowGetWayBtn = true,
			show_has_num = false,
			scale = 0.7037037037037037,
			uiRoot = self.iconGroup2,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}
		self.icons2[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	end

	self.iconGroup2Grid:Reposition()
end

function ActivityGrowthHelpPreviewWindow:register()
	UIEventListener.Get(self.btnJump).onClick = function ()
		xyd.openWindow("activity_growth_plan_window", {
			ActivityID = xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN
		})
		self:close()
	end
end

return ActivityGrowthHelpPreviewWindow
