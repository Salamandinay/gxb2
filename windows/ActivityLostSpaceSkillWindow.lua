local ActivityLostSpaceSkillWindow = class("ActivityLostSpaceSkillWindow", import(".BaseWindow"))
local SpaceSkillItem = class("SpaceSkillItem", import("app.components.CopyComponent"))
local json = require("cjson")

function SpaceSkillItem:ctor(go, parent)
	SpaceSkillItem.super.ctor(self, go)

	self.parent = parent
end

function SpaceSkillItem:initUI()
	local goTrans = self.go
	self.skillIcon_ = goTrans:ComponentByName("skillIcon", typeof(UISprite))
	self.skillName_ = goTrans:ComponentByName("skillName", typeof(UILabel))
	self.skillPoint_ = goTrans:ComponentByName("skillCost", typeof(UILabel))
	self.skillDesc_ = goTrans:ComponentByName("skillDesc", typeof(UILabel))
	self.btnSelect_ = goTrans:NodeByName("btnSelect").gameObject
	self.btnSelectLabel_ = goTrans:ComponentByName("btnSelect/label", typeof(UILabel))

	UIEventListener.Get(self.btnSelect_).onClick = function ()
		self:onClickBtn()
	end
end

function SpaceSkillItem:setInfo(id, is_use)
	self.id_ = id
	local iconName = xyd.tables.activityLostSpaceSkillTable:getIcon(self.id_)

	xyd.setUISpriteAsync(self.skillIcon_, nil, iconName)

	local change_num = xyd.tables.activityLostSpaceSkillTable:getLevelUpCost(self.id_)
	local level = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE):getLevel(self.id_)
	self.skillName_.text = xyd.tables.activityLostSpaceSkillTable:getName(self.id_)
	self.skillDesc_.text = xyd.tables.activityLostSpaceSkillTable:getDesc(self.id_, level)

	if xyd.tables.activityLostSpaceSkillTable:getCanLevelUp(self.id_) == 1 then
		local point = xyd.tables.activityLostSpaceSkillTable:getEnergy(self.id_)
		self.skillPoint_.text = __("ACTIVITY_LOST_SPACE_SKILL_ENERGY_COST", point - change_num * level)
	else
		self.skillPoint_.text = __("ACTIVITY_LOST_SPACE_SKILL_ENERGY_COST", xyd.tables.activityLostSpaceSkillTable:getEnergy(self.id_))
	end

	self.btnSelectLabel_.text = __("ACTIVITY_LOST_SPACE_SKILL_CHOOSE")

	if is_use then
		xyd.setEnabled(self.btnSelect_, false)
	else
		xyd.setEnabled(self.btnSelect_, true)
	end
end

function SpaceSkillItem:onClickBtn()
	local choose_id = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE):getChooseSkill()

	if choose_id and choose_id > 0 then
		xyd.alertYesNo(__("ACTIVITY_LOST_SPACE_SKILL_CHANGE"), function (yes_no)
			if yes_no then
				local params = {
					type = xyd.ActivityLostSpaceType.CHOICE_SKILL,
					id = self.id_
				}

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode(params))
				self.parent:close()
			end
		end)
	else
		local params = {
			type = xyd.ActivityLostSpaceType.CHOICE_SKILL,
			id = self.id_
		}

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode(params))
	end
end

function ActivityLostSpaceSkillWindow:ctor(name, params)
	ActivityLostSpaceSkillWindow.super.ctor(self, name, params)

	self.itemList_ = {}
end

function ActivityLostSpaceSkillWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityLostSpaceSkillWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.itemNode_ = winTrans:NodeByName("itemNode").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(UITable))
end

function ActivityLostSpaceSkillWindow:layout()
	self.titleLabel_.text = __("SUIT_SKILL_DETAIL_WINDOW_TITLE")
	local ids = xyd.tables.activityLostSpaceSkillTable:getIds()
	local choose_id = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE):getChooseSkill()

	for index, id in ipairs(ids) do
		if not self.itemList_[index] then
			local newItemRoot = NGUITools.AddChild(self.grid_.gameObject, self.itemNode_)
			self.itemList_[index] = SpaceSkillItem.new(newItemRoot, self)
		end

		self.itemList_[index]:setInfo(id, tonumber(choose_id) == tonumber(id))
		self:waitForFrame(1, function ()
			self.grid_:Reposition()
			self.scrollView_:ResetPosition()
		end)
	end
end

function ActivityLostSpaceSkillWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivityLostSpaceSkillWindow:willClose()
	ActivityLostSpaceSkillWindow.super.willClose(self)

	local choose_id = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE):getChooseSkill()

	if choose_id == 0 then
		local activityLostSpaceMapWd = xyd.WindowManager.get():getWindow("activity_lost_space_map_window")

		if activityLostSpaceMapWd then
			xyd.WindowManager.get():closeWindow("activity_lost_space_map_window")
		end
	end
end

return ActivityLostSpaceSkillWindow
