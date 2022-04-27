local ArenaAllServerFightAwardPreviewWindow = class("ArenaAllServerFightAwardPreviewWindow", import(".BaseWindow"))
local ArenaAllServerFightAwardPreviewItem = class("ArenaAllServerFightAwardPreviewItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ArenaAllServerFightAwardPreviewWindow:ctor(name, params)
	ArenaAllServerFightAwardPreviewWindow.super.ctor(self, name, params)

	self.params = params
end

function ArenaAllServerFightAwardPreviewWindow:initWindow()
	ArenaAllServerFightAwardPreviewWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaAllServerFightAwardPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.titleLabel = self.groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scrollerGroup = self.groupAction:NodeByName("scrollerGroup").gameObject
	self.item = self.scrollerGroup:NodeByName("item").gameObject
	self.scroller = self.scrollerGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.drag = self.scrollerGroup:NodeByName("drag").gameObject
end

function ArenaAllServerFightAwardPreviewWindow:layout()
	self.titleLabel.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.item, ArenaAllServerFightAwardPreviewItem, self)
	local data = {}
	local ids = xyd.tables.arenaAllServerAwardTable:getIDs()

	for i = 1, #ids do
		local params = {}
		local id = i
		params.id = id
		params.rank = xyd.tables.arenaAllServerAwardTable:getRank(id)
		params.awards = xyd.tables.arenaAllServerAwardTable:getAwards(id)

		table.insert(data, params)
	end

	self.wrapContent:setInfos(data, {})
end

function ArenaAllServerFightAwardPreviewWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow("arena_all_server_fight_award_preview_window")
	end
end

function ArenaAllServerFightAwardPreviewItem:ctor(go, parent)
	ArenaAllServerFightAwardPreviewItem.super.ctor(self, go, parent)
end

function ArenaAllServerFightAwardPreviewItem:initUI()
	local go = self.go
	self.descLabel = self.go:ComponentByName("descLabel", typeof(UILabel))
	self.descIcon = self.go:ComponentByName("descIcon", typeof(UISprite))
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.playerIcons = {}
	self.heroIcons = {}
	self.itemIcons = {}

	for i = 1, 4 do
		local params = {
			scale = 0.7037037037037037,
			uiRoot = self.itemGroup,
			dragScrollView = self.parent.scroller
		}
		self.playerIcons[i] = xyd.getItemIcon(params, xyd.ItemIconType.PLAYER_ICON)
		self.heroIcons[i] = xyd.getItemIcon(params, xyd.ItemIconType.HERO_ICON)
		self.itemIcons[i] = xyd.getItemIcon(params, xyd.ItemIconType.ITEM_ICON)
	end
end

function ArenaAllServerFightAwardPreviewItem:updateInfo()
	self.id = self.data.id
	self.awards = self.data.awards
	self.rank = self.data.rank
	self.descLabel.text = __("NEW_ARENA_ALL_SERVER_TEXT_19", self.rank)

	if self.rank == 1 then
		self.descLabel:SetActive(false)
		self.descIcon.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.descIcon, nil, "rank_icon01")
	else
		self.descLabel:SetActive(true)
		self.descIcon:SetActive(false)
	end

	for i = 1, #self.itemIcons do
		self.itemIcons[i]:getIconRoot():SetActive(false)
	end

	for i = 1, #self.heroIcons do
		self.heroIcons[i]:getIconRoot():SetActive(false)
	end

	for i = 1, #self.playerIcons do
		self.playerIcons[i].go:SetActive(false)
	end

	for i = 1, #self.awards do
		local data = self.awards[i]
		local type_ = xyd.tables.itemTable:getType(data[1])
		local icon = nil
		local params = {
			show_has_num = true,
			hideText = true,
			scale = 0.7037037037037037,
			uiRoot = self.itemGroup,
			itemID = data[1],
			num = data[2],
			dragScrollView = self.parent.scroller
		}

		if type_ == xyd.ItemType.AVATAR_FRAME then
			params.avatar_frame_id = data[1]
			icon = self.playerIcons[i]
		elseif type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS and type_ ~= xyd.ItemType.SKIN then
			icon = self.itemIcons[i]
		else
			icon = self.heroIcons[i]
		end

		icon.go:SetActive(true)
		icon:setInfo(params)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return ArenaAllServerFightAwardPreviewWindow
