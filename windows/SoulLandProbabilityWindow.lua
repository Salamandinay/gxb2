local SoulLandProbabilityWindow = class("SoulLandProbabilityWindow", import(".BaseWindow"))
local SoulLandProbabilityItem = class("SoulLandProbabilityItem", import("app.components.CopyComponent"))
local SoulLandProbabilityState = {
	CUR = 1,
	NEXT = 2
}

function SoulLandProbabilityWindow:ctor(name, params)
	SoulLandProbabilityWindow.super.ctor(self, name, params)
end

function SoulLandProbabilityWindow:initWindow()
	self:getUIComponent()
	SoulLandProbabilityWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function SoulLandProbabilityWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.wdCon = self.groupAction:NodeByName("wdCon").gameObject
	self.winNameLabel = self.wdCon:ComponentByName("winNameLabel", typeof(UILabel))
	self.closeBtn = self.wdCon:NodeByName("closeBtn").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.upConBg = self.upCon:ComponentByName("upConBg", typeof(UISprite))
	self.upNameCon = self.upCon:NodeByName("upNameCon").gameObject
	self.upNameConBg = self.upNameCon:ComponentByName("upNameConBg", typeof(UISprite))
	self.upNameConDot = self.upNameCon:ComponentByName("upNameConDot", typeof(UISprite))
	self.upNameConLabel = self.upNameCon:ComponentByName("upNameConLabel", typeof(UILabel))
	self.upConDesc = self.upCon:ComponentByName("upConDesc", typeof(UILabel))
	self.upConGrid = self.upCon:NodeByName("upConGrid").gameObject
	self.upConGridUIGrid = self.upCon:ComponentByName("upConGrid", typeof(UIGrid))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.downNameCon = self.downCon:NodeByName("downNameCon").gameObject
	self.downNameConBg = self.downNameCon:ComponentByName("downNameConBg", typeof(UISprite))
	self.downNameConDot = self.downNameCon:ComponentByName("downNameConDot", typeof(UISprite))
	self.downNameConLabel = self.downNameCon:ComponentByName("downNameConLabel", typeof(UILabel))
	self.downConDesc = self.downCon:ComponentByName("downConDesc", typeof(UILabel))
	self.curLevCon = self.downCon:NodeByName("curLevCon").gameObject
	self.nextLevCon = self.downCon:NodeByName("nextLevCon").gameObject
end

function SoulLandProbabilityWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function SoulLandProbabilityWindow:layout()
	self.winNameLabel.text = __("SOUL_LAND_TEXT13")
	self.upNameConLabel.text = __("SOUL_LAND_TEXT14")
	self.upConDesc.text = __("SOUL_LAND_TEXT15")
	self.downNameConLabel.text = __("SOUL_LAND_TEXT16")
	self.downConDesc.text = __("SOUL_LAND_TEXT17")
	self.curItem = SoulLandProbabilityItem.new(self.curLevCon.gameObject, {
		state = SoulLandProbabilityState.CUR
	}, self)
	local summonInfo = xyd.models.soulLand:getSummonBaseInfo()
	local nextLv = xyd.tables.soulLandEquip2DropboxTable:getNextId(summonInfo.lv)

	if nextLv ~= -1 then
		self.nextItem = SoulLandProbabilityItem.new(self.nextLevCon.gameObject, {
			state = SoulLandProbabilityState.NEXT
		}, self)
	else
		self.nextLevCon.gameObject:SetActive(false)
	end

	local equips = xyd.tables.soulLandEquip2DropboxTable:getEquip2(summonInfo.lv)

	for i, groupId in pairs(equips) do
		local itemId = xyd.tables.soulEquip2GroupTable:getItem(groupId)
		local item = {
			show_has_num = false,
			num = 1,
			isShowSelected = false,
			itemID = itemId,
			scale = Vector3(0.7962962962962963, 0.7962962962962963, 1),
			uiRoot = self.upConGrid.gameObject
		}
		local icon = xyd.getItemIcon(item)
	end

	self.upConGridUIGrid:Reposition()
end

function SoulLandProbabilityItem:ctor(goItem, data, parent)
	self.state = data.state
	self.parent = parent

	SoulLandProbabilityItem.super.ctor(self, goItem)
end

function SoulLandProbabilityItem:initUI()
	self:getUIComponent()
	SoulLandProbabilityItem.super.initUI(self)
	self:register()
	self:layout()
end

function SoulLandProbabilityItem:getUIComponent()
	self.curLevCon = self.go.gameObject
	self.levLabelName = self.curLevCon:ComponentByName("levLabelName", typeof(UILabel))
	self.levLabel = self.curLevCon:ComponentByName("levLabel", typeof(UILabel))
	self.baseCon = self.curLevCon:NodeByName("baseCon").gameObject
	self.baseIcon = self.baseCon:ComponentByName("baseIcon", typeof(UISprite))
	self.baseLabel1 = self.baseCon:ComponentByName("baseLabel1", typeof(UILabel))
	self.baseLabel2 = self.baseCon:ComponentByName("baseLabel2", typeof(UILabel))
	self.baseLabel3 = self.baseCon:ComponentByName("baseLabel3", typeof(UILabel))
	self.baseLabel4 = self.baseCon:ComponentByName("baseLabel4", typeof(UILabel))
	self.baseLabel5 = self.baseCon:ComponentByName("baseLabel5", typeof(UILabel))
	self.baseLabel6 = self.baseCon:ComponentByName("baseLabel6", typeof(UILabel))
	self.highCon = self.curLevCon:NodeByName("highCon").gameObject
	self.highIcon = self.highCon:ComponentByName("highIcon", typeof(UISprite))
	self.highLabel1 = self.highCon:ComponentByName("highLabel1", typeof(UILabel))
	self.highLabel2 = self.highCon:ComponentByName("highLabel2", typeof(UILabel))
	self.highLabel3 = self.highCon:ComponentByName("highLabel3", typeof(UILabel))
	self.highLabel4 = self.highCon:ComponentByName("highLabel4", typeof(UILabel))
	self.highLabel5 = self.highCon:ComponentByName("highLabel5", typeof(UILabel))
	self.highLabel6 = self.highCon:ComponentByName("highLabel6", typeof(UILabel))
end

function SoulLandProbabilityItem:register()
end

function SoulLandProbabilityItem:layout()
	local summonInfo = xyd.models.soulLand:getSummonBaseInfo()
	local baseWeights, highWeights = nil
	local lvText = "Lv"

	if xyd.Global.lang == "fr_fr" then
		lvText = "Niv"
	end

	if self.state == SoulLandProbabilityState.CUR then
		self.levLabelName.text = __("SOUL_LAND_TEXT18")
		self.levLabel.text = "(" .. lvText .. "." .. summonInfo.lv .. ")"
		baseWeights = xyd.tables.soulLandEquip2DropboxTable:getWeight1(summonInfo.lv)
		highWeights = xyd.tables.soulLandEquip2DropboxTable:getWeight2(summonInfo.lv)
	elseif self.state == SoulLandProbabilityState.NEXT then
		self.levLabelName.text = __("SOUL_LAND_TEXT19")
		self.levLabel.text = "(" .. lvText .. "." .. summonInfo.lv + 1 .. ")"
		baseWeights = xyd.tables.soulLandEquip2DropboxTable:getWeight1(summonInfo.lv + 1)
		highWeights = xyd.tables.soulLandEquip2DropboxTable:getWeight2(summonInfo.lv + 1)
	end

	local allBaseWeight = 0

	for i, num in pairs(baseWeights) do
		allBaseWeight = allBaseWeight + num
	end

	for i, num in pairs(baseWeights) do
		self["baseLabel" .. i].text = math.floor(num * 10000 / allBaseWeight) / 100 .. "%"
	end

	local allhighWeight = 0

	for i, num in pairs(highWeights) do
		allhighWeight = allhighWeight + num
	end

	for i, num in pairs(highWeights) do
		self["highLabel" .. i].text = math.floor(num * 10000 / allBaseWeight) / 100 .. "%"
	end
end

return SoulLandProbabilityWindow
