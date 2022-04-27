local ActivitySpaceExploreCheckBuffWindow = class("ActivitySpaceExploreCheckBuffWindow", import(".BaseWindow"))

function ActivitySpaceExploreCheckBuffWindow:ctor(name, params)
	ActivitySpaceExploreCheckBuffWindow.super.ctor(self, name, params)

	if params and params.buff_list then
		self.buffListData_ = params.buff_list
	else
		self.buffListData_ = {
			0,
			0,
			0,
			0,
			0
		}
	end
end

function ActivitySpaceExploreCheckBuffWindow:initWindow()
	ActivitySpaceExploreCheckBuffWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function ActivitySpaceExploreCheckBuffWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = goTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.wordLine_ = goTrans:NodeByName("wordLine").gameObject
	self.buffGroup_ = goTrans:ComponentByName("buffGroup", typeof(UILayout))
end

function ActivitySpaceExploreCheckBuffWindow:layout()
	self.winTitle_.text = __("SPACE_EXPLORE_CHECK_BUFF_WINDOW")
	local ids = xyd.tables.miscTable:split2num("space_explore_buff_look", "value", "|")
	local null_ids = xyd.tables.miscTable:split2num("space_explore_buff_look_null", "value", "|")
	local totalHeight = 88

	for idx, value in ipairs(self.buffListData_) do
		local labelNewGameObject = NGUITools.AddChild(self.buffGroup_.gameObject, self.wordLine_.gameObject)
		local labelNew = labelNewGameObject:GetComponent(typeof(UILabel))

		if tonumber(value) == 0 then
			labelNew.color = Color.New2(2829955839.0)

			if idx <= 3 then
				labelNew.text = xyd.tables.activitySpaceExploreSkillTextTable:getDesc(null_ids[idx], {
					tostring(value * 100) .. "%"
				})
			else
				labelNew.text = xyd.tables.activitySpaceExploreSkillTextTable:getDesc(ids[idx], {
					tostring(value * 100) .. "%"
				})
			end
		else
			labelNew.text = xyd.tables.activitySpaceExploreSkillTextTable:getDesc(ids[idx], {
				tostring(value * 100) .. "%"
			})
		end

		totalHeight = totalHeight + labelNew.height
	end

	self.buffGroup_:Reposition()

	self.buffGroup_:GetComponent(typeof(UIWidget)).height = totalHeight
end

return ActivitySpaceExploreCheckBuffWindow
