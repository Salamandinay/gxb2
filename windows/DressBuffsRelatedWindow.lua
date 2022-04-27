local DressBuffsRelatedWindow = class("DressBuffsRelatedWindow", import(".BaseWindow"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local DressItem = class("DressItem", import("app.components.CopyComponent"))

function DressBuffsRelatedWindow:ctor(name, params)
	DressBuffsRelatedWindow.super.ctor(self, name, params)

	self.buffId = params.buffId
	self.itemsGroupIds = xyd.tables.senpaiDressSkillBuffTable:getRelatedDress(self.buffId)
end

function DressBuffsRelatedWindow:initWindow()
	self:getUIComponent()
	DressBuffsRelatedWindow.super.initWindow(self)
	self:layout()
	self:registerEvent()
end

function DressBuffsRelatedWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scrollerCon = self.groupAction:NodeByName("scrollerCon").gameObject
	self.award_item = self.scrollerCon:NodeByName("award_item").gameObject
	self.scroller1 = self.scrollerCon:NodeByName("scroller1").gameObject
	self.scroller1UIScrollView = self.scrollerCon:ComponentByName("scroller1", typeof(UIScrollView))
	self.itemGroup1 = self.scroller1:NodeByName("itemGroup1").gameObject
	self.itemGroup1UIWrapContent = self.scroller1:ComponentByName("itemGroup1", typeof(UIWrapContent))
	self.drag1 = self.scrollerCon:NodeByName("drag1").gameObject
	self.wrapContent_ = FixedMultiWrapContent.new(self.scroller1UIScrollView, self.itemGroup1UIWrapContent, self.award_item, DressItem, self)
end

function DressBuffsRelatedWindow:layout()
	self.labelTitle.text = __("PERSON_DRESS_RELATED_DRESS")
	local items = {}
	items = self:getItems(items)

	self.wrapContent_:setInfos(items, {})
	self.scroller1UIScrollView:ResetPosition()
end

function DressBuffsRelatedWindow:getItems(items)
	local checkDressIds = xyd.tables.senpaiDressGroupTable:getUnit(self.itemsGroupIds[1])
	local allDressIds = xyd.models.dress:getHasDressIds(0)

	for i, id in pairs(checkDressIds) do
		if xyd.arrayIndexOf(allDressIds, id) > -1 then
			local allItems = xyd.tables.senpaiDressTable:getItems(id)

			for k = #allItems, 1, -1 do
				if xyd.models.backpack:getItemNumByID(allItems[k]) > 0 then
					table.insert(items, {
						id = allItems[k]
					})
				end
			end
		end
	end

	table.remove(self.itemsGroupIds, 1)

	if #self.itemsGroupIds == 0 then
		return items
	end

	return self:getItems(items)
end

function DressBuffsRelatedWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function DressItem:ctor(go, parent)
	self.go = go
	self.parent = parent
end

function DressItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.id = info.id
	local params = {
		isAddUIDragScrollView = true,
		show_has_num = false,
		isShowSelected = false,
		itemID = info.id,
		scale = Vector3(1.0462962962962963, 1.0462962962962963, 1),
		uiRoot = self.go.gameObject
	}

	if not self.item then
		self.item = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.item:setInfo(params)
	end
end

return DressBuffsRelatedWindow
