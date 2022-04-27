local BaseWindow = import(".BaseWindow")
local ReplaceProbabilityWindow = class("ReplaceProbabilityWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ReplaceProbabilityItem = class("ReplaceProbabilityItem", import("app.common.ui.FixedMultiWrapContentItem"))
local DropboxShowTable = xyd.tables.dropboxShowTable
local PartnerReplaceTable = xyd.tables.partnerReplaceTable
local HeroIcon = import("app.components.HeroIcon")

function ReplaceProbabilityItem:ctor(go, parent)
	ReplaceProbabilityItem.super.ctor(self, go, parent)
end

function ReplaceProbabilityItem:initUI()
	local go = self.go
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	local icon = HeroIcon.new(self.groupIcon)

	icon:setDragScrollView(self.scroller)

	self.icon_ = icon
end

function ReplaceProbabilityItem:updateInfo()
	self.table_id_ = self.data.tableId
	local data = DropboxShowTable:getItem(self.table_id_)
	self.itemID = data[1]

	self.icon_:setInfo({
		scale = 1.1,
		not_show_ways = true,
		uiRoot = self.groupIcon,
		itemID = self.itemID,
		num = self.num
	})
end

function ReplaceProbabilityWindow:ctor(name, params)
	ReplaceProbabilityWindow.super.ctor(self, name, params)

	self.partner = params.partner
	self.ids = {}
end

function ReplaceProbabilityWindow:initWindow()
	ReplaceProbabilityWindow.super.initWindow(self)
	self:getUIComponent()
	self:initData()
	self:initLayout()
	self:registerEvent()
end

function ReplaceProbabilityWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.scroller = winTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.dropItem = winTrans:NodeByName("heroRoot").gameObject
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, self.dropItem, ReplaceProbabilityItem, self)
end

function ReplaceProbabilityWindow:initData()
	local partnerId = self.partner:getTableID()
	local replaceId = PartnerReplaceTable:getDropBoxId(partnerId)
	local ids = DropboxShowTable:getIds()

	for _, id in ipairs(ids) do
		local summonId = DropboxShowTable:getDropboxId(id)
		local data = DropboxShowTable:getItem(id)

		if data[1] ~= self.partner:getTableID() and summonId == replaceId then
			table.insert(self.ids, {
				tableId = id
			})
		end
	end
end

function ReplaceProbabilityWindow:initLayout()
	self.labelTitle.text = __("ALTAR_PREVIEW_TEXT")

	table.sort(self.ids, function (a, b)
		return b.tableId < a.tableId
	end)
	self.wrapContent:setInfos(self.ids, {})
end

function ReplaceProbabilityWindow:registerEvent()
	ReplaceProbabilityWindow.super.register(self)
end

return ReplaceProbabilityWindow
