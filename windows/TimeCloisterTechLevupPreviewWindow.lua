local TimeCloisterTechLevupPreviewWindow = class("TimeCloisterTechLevupPreviewWindow", import(".BaseWindow"))

function TimeCloisterTechLevupPreviewWindow:ctor(name, params)
	self.skillID = params.skill_id
	self.curLv = params.curLv
	self.maxLv = params.maxLv

	TimeCloisterTechLevupPreviewWindow.super.ctor(self, name, params)
end

function TimeCloisterTechLevupPreviewWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TimeCloisterTechLevupPreviewWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.contentGroup = groupAction:NodeByName("contentGroup").gameObject
	self.nameLabel = self.contentGroup:ComponentByName("nameLabel", typeof(UILabel))
	self.descLabel = self.contentGroup:ComponentByName("descLabel", typeof(UILabel))
	self.scrollView = self.contentGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.groupItems = self.scrollView:ComponentByName("groupItems", typeof(UITable))
	self.labelItem = self.contentGroup:NodeByName("labelItem").gameObject
end

function TimeCloisterTechLevupPreviewWindow:layout()
	local tecTextTable = xyd.tables.timeCloisterTecTextTable
	self.titleLabel.text = __("TIME_CLOISTER_TEXT42")
	local num = xyd.tables.timeCloisterTecTable:getNum(self.skillID)
	local text = tecTextTable:getDesc(self.skillID)
	local type = xyd.tables.timeCloisterTecTable:getType(self.skillID)
	self.nameLabel.text = tecTextTable:getName(self.skillID)

	if type == 3 then
		self.descLabel.text = xyd.stringFormat(text, num[math.min(self.curLv + 1, self.maxLv)])
	else
		self.descLabel.text = xyd.stringFormat(text, num[math.max(self.curLv, 1)])
	end

	for i = 1, self.maxLv do
		local obj = NGUITools.AddChild(self.groupItems.gameObject, self.labelItem)
		local levelLabel = obj:ComponentByName("levelLabel", typeof(UILabel))
		local descLabel = obj:ComponentByName("descLabel", typeof(UILabel))
		levelLabel.text = i

		if type == 3 then
			descLabel.text = xyd.stringFormat(text, num[math.min(i + 1, self.maxLv)])
		else
			descLabel.text = xyd.stringFormat(text, num[i])
		end
	end

	self.groupItems:Reposition()
	self.scrollView:ResetPosition()
end

function TimeCloisterTechLevupPreviewWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

return TimeCloisterTechLevupPreviewWindow
