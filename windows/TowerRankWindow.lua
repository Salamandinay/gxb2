local BaseWindow = import(".BaseWindow")
local TowerRankWindow = class("TowerRankWindow", BaseWindow)
local BaseComponent = import("app.components.BaseComponent")
local TowerRankItem = class("TowerRankItem", BaseComponent)

function TowerRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "TowerRankWindowSkin"
	self.map = xyd.models.map
end

function TowerRankWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()
	self.map:getRank(xyd.MapType.TOWER)
end

function TowerRankWindow:getUIComponent()
	local trans = self.window_.transform
end

function TowerRankWindow:setLayout()
end

function TowerRankWindow:registe()
	TowerRankWindow.super.registe(self)
	self.eventProxy_:addEventListener(xyd.event.GET_MAP_INFO, handler(self, self.onMapsInfo))
end

function TowerRankWindow:onMapsInfo(event)
	local data = event.data

	if data.map_type ~= xyd.MapType.TOWER or #data.list <= 0 then
		return
	end

	self.wrapContent:setInfos(data.list)
end

function TowerRankItem:ctor(parentGo)
	TowerRankItem.super.ctor(self, parentGo)
end

function TowerRankItem:initUI()
	TowerRankItem.super.initUI(self)

	local go = self.go
end

function TowerRankItem:dataChanged()
	if self.data.rank <= 3 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. self.data.rank)
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = self.data.rank

		self.labelRank:SetActive(true)
	end

	self.labelLevel.text = self.data.lev
	self.labelPlayerName.text = self.data.player_name
	self.labelCurrentNum.text = self.data.score
end

return TowerRankWindow
