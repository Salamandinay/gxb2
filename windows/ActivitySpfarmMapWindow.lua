local ActivitySpfarmMapWindow = class("ActivitySpfarmMapWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local MapGridItem = class("MapGridItem", import("app.components.CopyComponent"))
local json = require("cjson")
PLACE_STATE = {
	EMPTY = 0,
	COMMON = 2,
	DOOR = 3,
	GREY = 1
}
DOOR_POS = 13

function ActivitySpfarmMapWindow:ctor(name, params)
	ActivitySpfarmMapWindow.super.ctor(self, name, params)
end

function ActivitySpfarmMapWindow:initWindow()
	self:getUIComponent()
	ActivitySpfarmMapWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function ActivitySpfarmMapWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.cardItem = self.centerCon:NodeByName("cardItem").gameObject
	self.cardCon = self.centerCon:NodeByName("cardCon").gameObject
	self.cardConUIGrid = self.centerCon:ComponentByName("cardCon", typeof(UIGrid))
	self.cardItem_doorLabelCon = self.centerCon:NodeByName("cardItem_doorLabelCon").gameObject
	self.cardItem_buildCon = self.centerCon:NodeByName("cardItem_buildCon").gameObject
end

function ActivitySpfarmMapWindow:reSize()
end

function ActivitySpfarmMapWindow:registerEvent()
end

function ActivitySpfarmMapWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 150)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

function ActivitySpfarmMapWindow:layout()
	self:initTop()

	self.gridPosArr = {}

	for i = 1, 25 do
		table.insert(self.gridPosArr, i)
	end

	self.gridArr = {}

	for i in pairs(self.gridPosArr) do
		local tmp = NGUITools.AddChild(self.cardCon.gameObject, self.cardItem.gameObject)
		local item = MapGridItem.new(tmp, self.gridPosArr[i], self)
		self.gridArr[self.gridPosArr[i]] = item
	end

	self.cardConUIGrid:Reposition()
	self:updateGridState()
end

function ActivitySpfarmMapWindow:updateGridState()
	for i in pairs(self.gridArr) do
		if self.gridArr[i]:getGridId() == DOOR_POS then
			self.gridArr[i]:updateState(PLACE_STATE.DOOR)
		else
			self.gridArr[i]:updateState(PLACE_STATE.EMPTY)
		end
	end
end

function ActivitySpfarmMapWindow:getFamousNum()
	return 0
end

function ActivitySpfarmMapWindow:getIsMySelf()
	return true
end

function MapGridItem:ctor(goItem, gridId, parent)
	self.goItem_ = goItem
	self.parent = parent
	self.gridId = gridId

	MapGridItem.super.ctor(self, goItem)
end

function MapGridItem:initUI()
	self:getUIComponent()
	MapGridItem.super.initUI(self)

	UIEventListener.Get(self.cardItemBaseBg.gameObject).onClick = handler(self, self.onTouch)
end

function MapGridItem:getUIComponent()
	local row = math.ceil(self.gridId / 5)
	self.depthNum = row * 15
	self.goUIWidget = self.go:GetComponent(typeof(UIWidget))
	self.goUIWidget.depth = 200 + self.depthNum
	self.cardItemBaseBg = self.go:ComponentByName("cardItemBaseBg", typeof(UISprite))
	self.cardItemBaseBg.depth = self.goUIWidget.depth
	self.cardItemBg = self.go:ComponentByName("cardItemBg", typeof(UISprite))
	self.cardItemBg.depth = self.goUIWidget.depth + 1
	self.cardItemMask = self.go:ComponentByName("cardItemMask", typeof(UISprite))
	self.stoneEffectCon = self.go:ComponentByName("stoneEffectCon", typeof(UITexture))
	self.doorEffectCon = self.go:ComponentByName("doorEffectCon", typeof(UITexture))
end

function MapGridItem:getGridId()
	return self.gridId
end

function MapGridItem:onTouch()
	if self.parent.activityData and self.parent.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	if self.state == PLACE_STATE.EMPTY and self.parent:getIsMySelf() then
		xyd.WindowManager.get():openWindow("activity_spfarm_build_window", {
			type = xyd.ActivitySpfarmBuildWindowType.BUILD
		})
	end
end

function MapGridItem:updateState(state)
	self.state = state
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE)

	self:setDoorConVisible(false)

	if state ~= PLACE_STATE.EMPTY then
		self.cardItemBg.gameObject:SetActive(true)
	end

	if state == PLACE_STATE.EMPTY then
		self.cardItemBg.gameObject:SetActive(false)
	elseif state == PLACE_STATE.DOOR then
		self:setDoorConVisible(true)

		local famousNum = self.parent:getFamousNum()
		self.doorLabel.text = tostring(famousNum)
		local famousLevelArr = xyd.tables.miscTable:split2num("activity_spfarm_gate_style", "value", "|")

		for i = #famousLevelArr, 1, -1 do
			if famousLevelArr[i] <= famousNum then
				local imgStr = "activity_spfarm_gate_3"

				if i == 2 then
					imgStr = "activity_spfarm_gate_2"
				elseif i == 1 then
					imgStr = "activity_space_explore_bg_m_1"
				end

				xyd.setUISpriteAsync(self.cardItemBg, nil, imgStr)

				break
			end
		end
	end
end

function MapGridItem:getState()
	return self.state
end

function MapGridItem:setChildrenDepth(go)
	local depth = self.goUIWidget.depth

	for i = 1, go.transform.childCount do
		local child = go.transform:GetChild(i - 1).gameObject
		local widget = child:GetComponent(typeof(UIWidget))

		if widget then
			widget.depth = depth + widget.depth
		end

		if child.transform.childCount > 0 then
			self:setChildrenDepth(child, depth)
		end
	end
end

function MapGridItem:getDoorCon()
	if not self.doorCon then
		self.doorCon = NGUITools.AddChild(self.go.gameObject, self.parent.cardItem_doorLabelCon.gameObject)
		self.doorLabelBg = self.doorCon:ComponentByName("doorLabelBg", typeof(UISprite))
		self.doorLabel = self.doorLabelBg:ComponentByName("doorLabel", typeof(UILabel))

		self:setChildrenDepth(self.doorCon)
	end

	return self.doorCon
end

function MapGridItem:setDoorConVisible(visible)
	if visible and not self.doorCon then
		self:getDoorCon()
	end

	if self.doorCon then
		self.doorCon:SetActive(visible)
	end
end

function MapGridItem:getBuildCon()
	if not self.buildCon then
		self.buildCon = NGUITools.AddChild(self.go.gameObject, self.parent.cardItem_buildCon.gameObject)
		self.buildImg = self.go:ComponentByName("buildImg", typeof(UISprite))
		self.buildLevLabel = self.go:ComponentByName("buildLevLabel", typeof(UILabel))
		self.tipsCon = self.go:ComponentByName("tipsCon", typeof(UISprite))
		self.tipsFsIcon = self.tipsCon:ComponentByName("tipsFsIcon", typeof(UISprite))
		self.tipsGetIcon = self.tipsCon:ComponentByName("tipsGetIcon", typeof(UISprite))
		self.tipsGetLabel = self.tipsCon:ComponentByName("tipsGetLabel", typeof(UILabel))

		self:setChildrenDepth(self.buildCon)
	end

	return self.buildCon
end

function MapGridItem:setBuildConVisible(visible)
	if visible and not self.buildCon then
		self:getBuildCon()
	end

	if self.buildCon then
		self.buildCon:SetActive(visible)
	end
end

function MapGridItem:getSelectCon()
	if not self.selectCon then
		self.selectCon = NGUITools.AddChild(self.go.gameObject, self.parent.cardItem_selectCon.gameObject)

		self:setChildrenDepth(self.selectCon)
	end

	return self.selectCon
end

function MapGridItem:setSelectConVisible(visible)
	if visible and not self.selectCon then
		self:getSelectCon()
	end

	if self.selectCon then
		self.selectCon:SetActive(visible)
	end
end

return ActivitySpfarmMapWindow
