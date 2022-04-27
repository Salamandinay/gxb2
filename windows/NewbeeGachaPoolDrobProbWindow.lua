local BaseWindow = import(".BaseWindow")
local NewbeeGachaPoolDrobProbWindow = class("NewbeeGachaPoolDrobProbWindow", BaseWindow)
local ProbabilityRender = class("ProbabilityRender", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local DropboxShowTable = xyd.tables.dropboxShowTable

function NewbeeGachaPoolDrobProbWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.isNewVersion = params.isNewVersion
	self.boxId = params.boxId
end

function NewbeeGachaPoolDrobProbWindow:initWindow()
	NewbeeGachaPoolDrobProbWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function NewbeeGachaPoolDrobProbWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupActionTrans = winTrans:NodeByName("groupAction")
	self.labelTitle = groupActionTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupActionTrans:NodeByName("closeBtn").gameObject
	self.scrollView = groupActionTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.dropItem = groupActionTrans:NodeByName("scroller/dropItem").gameObject
	self.itemGroup = groupActionTrans:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.dropItem, ProbabilityRender, self)
end

function NewbeeGachaPoolDrobProbWindow:initUIComponent()
	self.labelTitle.text = __("DROP_PROBABILITY_WINDOW_TITLE")
	local boxId = nil

	if self.isNewVersion then
		boxId = xyd.tables.miscTable:getNumber("activity_newbee_gacha_dropbox_new", "value")
	else
		boxId = xyd.tables.miscTable:getNumber("activity_newbee_gacha_dropbox", "value")
	end

	if self.boxId then
		boxId = self.boxId
	end

	local collection = {}

	if type(boxId) == "number" then
		local info = DropboxShowTable:getIdsByBoxId(boxId)
		local all_proba = info.all_weight
		local list = info.list

		for i = 1, #list do
			local table_id = list[i]
			local weight = DropboxShowTable:getWeight(table_id)
			local data = DropboxShowTable:getItem(table_id)
			local itemID = data[1]

			if weight then
				table.insert(collection, {
					table_id = table_id,
					all_proba = all_proba,
					itemID = itemID
				})
			end
		end
	else
		local all_proba = 0

		for _, id in ipairs(boxId) do
			local info = DropboxShowTable:getIdsByBoxId(id)
			all_proba = all_proba + info.all_weight
		end

		for _, id in ipairs(boxId) do
			local info = DropboxShowTable:getIdsByBoxId(id)
			local list = info.list

			for i = 1, #list do
				local table_id = list[i]
				local weight = DropboxShowTable:getWeight(table_id)

				if weight and weight > 0 then
					local info = {
						table_id = table_id,
						all_proba = all_proba
					}

					table.insert(collection, info)
				end
			end
		end
	end

	table.sort(collection, function (a, b)
		if self.isNewVersion then
			return b.table_id < a.table_id
		else
			return a.table_id < b.table_id
		end
	end)
	self.wrapContent:setInfos(collection, {})
end

function NewbeeGachaPoolDrobProbWindow:iosTestChangeUI()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	local allChildren = groupAction:GetComponentsInChildren(typeof(UISprite), true)

	for i = 0, allChildren.Length - 1 do
		local sprite = allChildren[i]

		xyd.setUISprite(sprite, nil, sprite.spriteName .. "_ios_test")
	end
end

function ProbabilityRender:ctor(go, parent)
	ProbabilityRender.super.ctor(self, go, parent)
end

function ProbabilityRender:initUI()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.label = go:ComponentByName("label", typeof(UILabel))
	local HeroIcon = import("app.components.HeroIcon")
	local icon = HeroIcon.new(self.groupIcon)

	icon:setDragScrollView(self.scroller)

	self.icon_ = icon
end

function ProbabilityRender:updateInfo()
	self.table_id_ = self.data.table_id
	self.all_proba_ = self.data.all_proba
	local data = DropboxShowTable:getItem(self.table_id_)
	self.itemID = data[1]
	self.num = data[2]
	local proba = DropboxShowTable:getWeight(self.table_id_)
	local show_proba = math.ceil(proba * 1000000 / self.all_proba_)
	show_proba = show_proba / 10000
	self.label.text = tostring(show_proba) .. "%"

	self.icon_:setInfo({
		scale = 1.1,
		notShowGetWayBtn = true,
		noWays = true,
		not_show_ways = true,
		uiRoot = self.groupIcon,
		itemID = self.itemID,
		num = self.num
	})
end

return NewbeeGachaPoolDrobProbWindow
