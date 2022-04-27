local ActivityContent = import(".ActivityContent")
local ActivityTreeGroup = class("ActivityTreeGroup", ActivityContent)

function ActivityTreeGroup:ctor(parentGO, params, parent)
	ActivityTreeGroup.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_TREE_GROUP, function ()
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_tree_group_redmark"
		})
	end)
end

function ActivityTreeGroup:getPrefabPath()
	return "Prefabs/Windows/activity/activity_tree_group"
end

function ActivityTreeGroup:initUI()
	self:getUIComponent()
	ActivityTreeGroup.super.initUI(self)
	self:initUIComponent()
	self:initContentGroup()
	self:update()
end

function ActivityTreeGroup:getUIComponent()
	local go = self.go
	self.Bg2_ = go:NodeByName("Bg2_")
	self.textImg_ = go:ComponentByName("textImg_", typeof(UISprite))
	self.labelText01 = go:ComponentByName("labelText01", typeof(UILabel))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLable_ = self.timeGroup:ComponentByName("timeLable_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.awardGroup = self.contentGroup:NodeByName("awardGroup").gameObject

	for i = 1, 5 do
		self["groupTrans" .. i] = self.awardGroup:NodeByName("group" .. i)
		self["progress" .. i] = self["groupTrans" .. i]:ComponentByName("progress", typeof(UISlider))
		self["progress_label" .. i] = self["groupTrans" .. i]:ComponentByName("progress/label", typeof(UILabel))
	end

	self.jumpBtn_ = self.contentGroup:NodeByName("jumpBtn_").gameObject
	self.jumpBtn_label = self.jumpBtn_:ComponentByName("button_label", typeof(UILabel))
end

function ActivityTreeGroup:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "activity_tree_group_text_" .. xyd.Global.lang, nil, , true)

	self.labelText01.text = __("ACTIVITY_TREE_GROUP_TEXT")
	self.endLabel_.text = __("TEXT_END")
	self.jumpBtn_label.text = __("GO_TO_PROPHET")

	import("app.components.CountDown").new(self.timeLable_, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})
end

function ActivityTreeGroup:initContentGroup()
	local awardTable = xyd.tables.activityTreeGroupAwardTable

	for i = 1, 5 do
		local itemNode = self["groupTrans" .. i]:NodeByName("item").gameObject
		local groupLabel = self["groupTrans" .. i]:ComponentByName("label_", typeof(UILabel))

		if i < 5 then
			groupLabel.text = __("GROUP_" .. i)
		elseif i == 5 then
			groupLabel.text = __("GROUP_5_6")
		end

		local award = awardTable:getAwards(i)
		local item = xyd.getItemIcon({
			scale = 0.7962962962962963,
			isShowSelected = false,
			uiRoot = itemNode,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end
end

function ActivityTreeGroup:update()
	local awardTable = xyd.tables.activityTreeGroupAwardTable

	for i = 1, 5 do
		local point = awardTable:getPoint(i)
		self["progress" .. i].value = self.activityData.detail.points[i] % point / point
		self["progress_label" .. i].text = self.activityData.detail.points[i] % point .. "/" .. point
	end
end

function ActivityTreeGroup:onRegister()
	ActivityTreeGroup.super.onRegister(self)
	self:registerEvent(xyd.event.WINDOW_WILL_CLOSE, handler(self, self.reqData))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onUpdate))

	UIEventListener.Get(self.jumpBtn_).onClick = handler(self, function ()
		if xyd.checkFunctionOpen(xyd.FunctionID.PROPHET) then
			xyd.WindowManager.get():openWindow("prophet_window")
		end
	end)
end

function ActivityTreeGroup:reqData(event)
	local win_name = event.params.windowName

	if win_name == "prophet_window" then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_TREE_GROUP)
	end
end

function ActivityTreeGroup:onUpdate(event)
	self.activityData.detail = require("cjson").decode(event.data.act_info.detail)

	self:update()
end

function ActivityTreeGroup:resizeToParent()
	ActivityTreeGroup.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.Bg2_:Y(63 - (p_height - 874) * 0.45)
	self.labelText01:Y(-200 - (p_height - 874) * 0.5)

	if xyd.Global.lang == "en_en" then
		self.labelText01.width = 280
	elseif xyd.Global.lang == "fr_fr" then
		for i = 1, 5 do
			local groupLabel = self["groupTrans" .. i]:ComponentByName("label_", typeof(UILabel))
			groupLabel.pivot = UIWidget.Pivot.Center

			groupLabel:SetLocalPosition(0, -38, 0)
		end
	elseif xyd.Global.lang == "ja_jp" then
		self.labelText01.width = 260

		self.jumpBtn_label:X(10)
	elseif xyd.Global.lang == "de_de" then
		for i = 1, 5 do
			local groupLabel = self["groupTrans" .. i]:ComponentByName("label_", typeof(UILabel))
			groupLabel.pivot = UIWidget.Pivot.Center

			groupLabel:SetLocalPosition(0, -38, 0)
		end

		self.timeGroup:Y(-135)

		self.timeGroup:GetComponent(typeof(UISprite)).width = 300
		self.labelText01.width = 260
		self.labelText01.fontSize = 20

		self.labelText01:Y(self.labelText01.transform.localPosition.y + 20)
	end
end

return ActivityTreeGroup
