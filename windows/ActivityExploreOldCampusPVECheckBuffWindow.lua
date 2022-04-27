local ActivityExploreOldCampusPVECheckBuffWindow = class("ActivityExploreOldCampusPVECheckBuffWindow", import(".BaseWindow"))
local skillIconSmall = import("app.components.SkillIconSmall")
local skillDetail = import("app.components.ActivityExploreOldCampusWayAlert")

function ActivityExploreOldCampusPVECheckBuffWindow:ctor(name, params)
	ActivityExploreOldCampusPVECheckBuffWindow.super.ctor(self, name, params)

	self.buffList_ = params.buff_list or {}
end

function ActivityExploreOldCampusPVECheckBuffWindow:initWindow()
	ActivityExploreOldCampusPVECheckBuffWindow.super.initWindow(self)
	self:getUIComponent()
	self:initBuffList()
end

function ActivityExploreOldCampusPVECheckBuffWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = goTrans:ComponentByName("winTitle", typeof(UILabel))
	self.bg_ = goTrans:NodeByName("bg").gameObject
	self.closeBtn_ = goTrans:NodeByName("closeBtn").gameObject
	self.scrollView_ = goTrans:ComponentByName("groupContent", typeof(UIScrollView))
	self.grid_ = goTrans:ComponentByName("groupContent/grid", typeof(UIGrid))
	self.contentPanel_ = goTrans:ComponentByName("checkPanel", typeof(UIPanel))
	self.detailRoot_ = goTrans:NodeByName("checkPanel/checkRoot").gameObject
	self.groupNone_ = goTrans:NodeByName("groupNone").gameObject
	self.noneLabel_ = goTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.bg_).onClick = function ()
		if self.skillDetailGroup_ then
			self.skillDetailGroup_:SetActive(false)
		end
	end

	self.winTitle_.text = __("ACTIVITY_EXPLORE_CAMPUS_12")
	self.noneLabel_.text = __("ACTIVITY_EXPLORE_CAMPUS_13")
end

function ActivityExploreOldCampusPVECheckBuffWindow:initBuffList()
	if not self.buffList_ or #self.buffList_ <= 0 then
		self.groupNone_:SetActive(true)

		return
	end

	for _, buff_id in ipairs(self.buffList_) do
		local params = {
			dragScrollView = self.scrollView_,
			score = xyd.tables.oldBuildingBuffTable:getPoint(buff_id),
			posTransform = self.window_.transform,
			tipsCallBack = function (buff_id, posy)
				self:showTipsCon(buff_id, posy)
			end
		}
		local skillIcon = skillIconSmall.new(self.grid_.gameObject)

		skillIcon:setInfo(buff_id, params)
		skillIcon:setTipsClickOpen(true)
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

function ActivityExploreOldCampusPVECheckBuffWindow:showTipsCon(buff_id, posy)
	xyd.WindowManager.get():openWindow("activity_explore_old_campus_ways_alert_window", {
		buff_id = buff_id,
		posy = posy
	})
end

return ActivityExploreOldCampusPVECheckBuffWindow
