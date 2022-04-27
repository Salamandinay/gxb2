local BaseWindow = import(".BaseWindow")
local BattleBuffListWindow = class("BattleBuffListWindow", BaseWindow)
local BattleBuffListWindowItem = class("BattleBuffListWindowItem", import("app.components.CopyComponent"))
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local DBuffTable = xyd.tables.dBuffTable

function BattleBuffListWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fighter = params.fighter
	self.showIcons = params.showIcons
end

function BattleBuffListWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItems()
	self:register()
end

function BattleBuffListWindow:getUIComponent()
	local trans = self.window_.transform
	self.windowItem = trans:NodeByName("windowItem").gameObject
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.rankNode = self.groupAction:NodeByName("rankNode").gameObject
	self.rankListScroller = self.rankNode:NodeByName("rankListScroller").gameObject
	self.tableNode = self.rankListScroller:NodeByName("tableNode").gameObject
	self.tableNodeUITable = self.rankListScroller:ComponentByName("tableNode", typeof(UITable))
	self.drag = self.rankNode:NodeByName("drag").gameObject
	self.topNode = self.tableNode:NodeByName("topNode").gameObject
	self.partnerIconNode = self.topNode:NodeByName("partnerIconNode").gameObject
	self.partnerNameText = self.topNode:ComponentByName("partnerNameText", typeof(UILabel))
end

function BattleBuffListWindow:layout()
	self:updateFighterIcon()
end

function BattleBuffListWindow:updateFighterIcon()
	local icon = nil
	local data = self.fighter
	local tableId = data.tableID_
	local lev = data.level
	local partnerInfo = nil
	self.partnerNameText.text = ""

	if data.isMonster then
		lev = xyd.tables.monsterTable:getShowLev(tableId)
		local pTableID = xyd.tables.monsterTable:getPartnerLink(tableId)
		local star = xyd.tables.partnerTable:getStar(pTableID)
		partnerInfo = {
			noClick = true,
			tableID = pTableID,
			lev = lev,
			star = star,
			skin_id = data:getSkin()
		}
	else
		local partner = Partner.new()

		partner:populate({
			table_id = tableId,
			lev = lev,
			awake = data.awake,
			show_skin = data.isShowSkin_,
			equips = {
				0,
				0,
				0,
				0,
				0,
				0,
				data:getSkin()
			}
		})

		partnerInfo = partner:getInfo()
		partnerInfo.noClick = true
	end

	icon = HeroIcon.new(self.partnerIconNode)

	icon:setInfo(partnerInfo)

	icon.scale = 0.7

	if partnerInfo then
		self.partnerNameText.text = xyd.tables.partnerTable:getName(partnerInfo.tableID)
	end
end

function BattleBuffListWindow:initItems()
	for i = 1, #self.showIcons do
		local desData = xyd.tables.skillBuffTextTable:getDetailByBuff(self.showIcons[i].name, self.showIcons[i].value)

		if desData.name and desData.name ~= "" then
			local goRoot = NGUITools.AddChild(self.tableNode, self.windowItem)

			BattleBuffListWindowItem.new(goRoot, self, self.showIcons[i])
		end
	end

	self.windowItem:SetActive(false)
	self.tableNodeUITable:Reposition()
end

function BattleBuffListWindowItem:ctor(parentGo, parent, params)
	self.parent_ = parent
	self.params_ = params

	BattleBuffListWindowItem.super.ctor(self, parentGo)
end

function BattleBuffListWindowItem:initUI()
	BattleBuffListWindowItem.super.initUI(self)

	local goTrans = self.go.transform
	self.topBg = goTrans:NodeByName("topBg").gameObject
	self.buffImg = self.topBg:ComponentByName("buffImg", typeof(UISprite))
	self.buffNameText = self.topBg:ComponentByName("buffNameText", typeof(UILabel))
	self.desText = goTrans:ComponentByName("desText", typeof(UILabel))
	self.desLayout = goTrans:ComponentByName("desText", typeof(UIWidget))
	self.pLayout = self.go:GetComponent(typeof(UIWidget))

	self:initLayout()
end

function BattleBuffListWindowItem:initLayout()
	xyd.setUISprite(self.buffImg, xyd.Atlas.BATTLE, self.params_.path)

	local desData = xyd.tables.skillBuffTextTable:getDetailByBuff(self.params_.name, self.params_.value)

	if not desData.name then
		return
	end

	self.buffNameText.text = desData.name

	if self.params_.num > 1 then
		self.buffNameText.text = self.buffNameText.text .. " x" .. self.params_.num
	end

	self.desText.text = desData.desc

	if self.desLayout.height > 54 then
		self.pLayout.height = self.desLayout.height + 72
	end
end

return BattleBuffListWindow
