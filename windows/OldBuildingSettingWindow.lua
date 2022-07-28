local OldBuildingSettingWindow = class("OldBuildingSettingWindow", import(".BaseWindow"))
local cjson = require("cjson")

function OldBuildingSettingWindow:ctor(name, params)
	OldBuildingSettingWindow.super.ctor(self, name, params)

	self.floor_id_ = params.floor_id
end

function OldBuildingSettingWindow:initWindow()
	OldBuildingSettingWindow.super.initWindow(self)

	if xyd.models.oldSchool:seasonType() == 1 then
		self.oldBuildingFloorTable = xyd.tables.oldBuildingATable
	else
		self.oldBuildingFloorTable = xyd.tables.oldBuildingBTable
	end

	self:getUIComponent()
	self:readState()
	self:layout()
end

function OldBuildingSettingWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.windowTitle_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	local selectGroup = winTrans:NodeByName("selectGroup")
	self.labelTips_ = selectGroup:ComponentByName("labelTips", typeof(UILabel))
	self.floorGrid_ = selectGroup:ComponentByName("grid", typeof(UILayout))

	for i = 1, 3 do
		self["floor" .. i] = selectGroup:NodeByName("grid/selectItem" .. i).gameObject
		self["pickIcon" .. i] = self["floor" .. i]:ComponentByName("pickIcon", typeof(UISprite))

		UIEventListener.Get(self["pickIcon" .. i].gameObject).onClick = function ()
			self:onClickPickIcon(i)
		end
	end

	local selectGroup2 = winTrans:NodeByName("selectGroup2")
	self.labelTips2_ = selectGroup2:ComponentByName("labelTips", typeof(UILabel))

	for i = 1, 2 do
		self["selectItem" .. i] = selectGroup2:ComponentByName("selectItem" .. i, typeof(UISprite))
		self["labelDesc" .. i] = selectGroup2:ComponentByName("selectItem" .. i .. "/labelDesc", typeof(UILabel))
		self["labelDesc" .. i].text = __("OLD_SCHOOL_FLOOR_11_TEXT" .. 13 + i)

		UIEventListener.Get(self["selectItem" .. i].gameObject).onClick = function ()
			self:onClickSelectItem(i)
		end
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function OldBuildingSettingWindow:layout()
	self.windowTitle_.text = __("OLD_SCHOOL_FLOOR_11_TEXT11")
	self.labelTips_.text = __("OLD_SCHOOL_FLOOR_11_TEXT12")
	self.labelTips2_.text = __("OLD_SCHOOL_FLOOR_11_TEXT13")

	self:updateSelectState()

	local stageArr = self.oldBuildingFloorTable:getStage(self.floor_id_)

	for i = 1, 3 do
		if i > #stageArr then
			self["floor" .. i]:SetActive(false)
		else
			self["floor" .. i]:SetActive(true)
		end
	end

	self.floorGrid_:Reposition()
end

function OldBuildingSettingWindow:readState()
	local selectInfo = xyd.db.misc:getValue("old_building_setting")

	if selectInfo and type(selectInfo) == "string" then
		self.selectInfo_ = cjson.decode(selectInfo)
	else
		self.selectInfo_ = {
			floor = {},
			select = 0
		}
	end
end

function OldBuildingSettingWindow:updateSelectState()
	for i = 1, 3 do
		if self.selectInfo_.floor[i] and self.selectInfo_.floor[i] == 1 then
			xyd.setUISpriteAsync(self["pickIcon" .. i], nil, "setting_up_pick")
		else
			xyd.setUISpriteAsync(self["pickIcon" .. i], nil, "setting_up_unpick")
		end
	end

	for i = 1, 2 do
		if self.selectInfo_.select and self.selectInfo_.select == i then
			xyd.setUISpriteAsync(self["selectItem" .. i], nil, "setting_up_pick")
		else
			xyd.setUISpriteAsync(self["selectItem" .. i], nil, "setting_up_unpick")
		end
	end
end

function OldBuildingSettingWindow:onClickPickIcon(index)
	if self.selectInfo_.floor[index] and self.selectInfo_.floor[index] == 1 then
		self.selectInfo_.floor[index] = 0
	else
		self.selectInfo_.floor[index] = 1
	end

	self:updateSelectState()
end

function OldBuildingSettingWindow:onClickSelectItem(index)
	if self.selectInfo_.select and self.selectInfo_.select == index then
		self.selectInfo_.select = 0
	else
		self.selectInfo_.select = index
	end

	self:updateSelectState()
end

function OldBuildingSettingWindow:willClose()
	local selectInfo = cjson.encode(self.selectInfo_)

	dump(selectInfo)
	xyd.db.misc:setValue({
		key = "old_building_setting",
		value = selectInfo
	})
end

return OldBuildingSettingWindow
