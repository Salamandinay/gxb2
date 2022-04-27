local BaseWindow = import(".BaseWindow")
local LeadSkinChooseWindow = class("LeadSkinChooseWindow", BaseWindow)
local itemContent = class("itemContent", import("app.components.CopyComponent"))

function itemContent:ctor(go, parent)
	self.parent_ = parent

	itemContent.super.ctor(self, go)
end

function itemContent:initUI()
	self.iconGroup_ = self.go:NodeByName("iconGroup").gameObject
	self.itemName_ = self.go:ComponentByName("nameLabel", typeof(UILabel))
end

function itemContent:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.style_id and info and self.style_id == info.style_id and not info.isMustUpdate then
		return
	end

	self.style_id = info.style_id
	self.itemName_.text = info.name
	self.info = info
	local params = {
		isAddUIDragScrollView = true,
		uiRoot = self.iconGroup_,
		styleID = info.style_id,
		callback = function ()
			local is_can_rm = xyd.tables.senpaiDressSlotTable:getCanRm(self.parent_.pos_)

			self.parent_:setClickIconState(true)
			xyd.WindowManager.get():openWindow("leadskin_tips_window", {
				state = 2,
				is_can_rm = is_can_rm,
				styleID = info.style_id
			})
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		end
	}

	if not self.dressIcon then
		self.dressIcon = xyd.getItemIcon(params, xyd.ItemIconType.DRESS_STYLE_ICON)
	else
		self.dressIcon:setInfo(params)
	end
end

function LeadSkinChooseWindow:ctor(name, params)
	LeadSkinChooseWindow.super.ctor(self, name, params)

	self.dressIdList = params.dressIdList or {}
	self.pos_ = params.pos or 1
	self.styleID = params.styleID
	self.clickIcon = false
end

function LeadSkinChooseWindow:initWindow()
	LeadSkinChooseWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function LeadSkinChooseWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.itemRoot_ = self.window_:NodeByName("leadskin_choose_item").gameObject
	self.labelTitle_ = winTrans:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.itemScroller_ = winTrans:ComponentByName("mainGroup/itemScroller", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("mainGroup/itemScroller/itemGroup", typeof(MultiRowWrapContent))
	self.noneGroup_ = winTrans:NodeByName("mainGroup/noneGroup").gameObject
	self.noneTips_ = winTrans:ComponentByName("mainGroup/noneGroup/label", typeof(UILabel))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.itemScroller_, self.grid_, self.itemRoot_, itemContent, self)
end

function LeadSkinChooseWindow:layout()
	self.labelTitle_.text = __("PERSON_INFO_LABEL_3")
	self.noneTips_.text = __("PERSON_DRESS_MAIN_" .. 16 + self.pos_)

	if #self.dressIdList <= 0 then
		self.noneGroup_:SetActive(true)
	else
		self.noneGroup_:SetActive(false)

		self.list = {}

		for _, dress_id in ipairs(self.dressIdList) do
			local items = xyd.tables.senpaiDressTable:getItems(dress_id)
			local style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[1]
			local local_choice = xyd.models.dress:getLocalChoice(dress_id)

			if local_choice then
				local all_styles = xyd.tables.senpaiDressTable:getStyles(dress_id)

				for k in pairs(all_styles) do
					if all_styles[k] == local_choice then
						style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[k]

						break
					end
				end
			end

			table.insert(self.list, {
				style_id = style_id,
				dress_id = dress_id,
				name = xyd.tables.itemTable:getName(items[1])
			})
		end

		self:sortList()
		self.multiWrap_:setInfos(self.list, {})
	end

	UIEventListener.Get(self.closeBtn_).onClick = handler(self, self.onClickCloseButton)
end

function LeadSkinChooseWindow:willClose()
	LeadSkinChooseWindow.super.willClose(self)

	if self.styleID and not self.clickIcon then
		local is_can_rm = xyd.tables.senpaiDressSlotTable:getCanRm(self.pos_)

		xyd.WindowManager.get():openWindow("leadskin_tips_window", {
			state = 1,
			is_can_rm = is_can_rm,
			styleID = self.styleID
		})
	end
end

function LeadSkinChooseWindow:setClickIconState(state)
	self.clickIcon = state
end

function LeadSkinChooseWindow:updateDressIconShowNum(style_id)
	local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(style_id)

	for i in pairs(self.list) do
		if self.list[i].dress_id == dress_id then
			self.list[i].isMustUpdate = true

			break
		end
	end

	self.multiWrap_:setInfos(self.list, {
		keepPosition = true
	})
	self:waitForFrame(2, function ()
		for i in pairs(self.list) do
			if self.list[i].dress_id == dress_id then
				self.list[i].isMustUpdate = false

				break
			end
		end
	end)
end

function LeadSkinChooseWindow:sortList()
	table.sort(self.list, function (a, b)
		local a_item = xyd.tables.senpaiDressTable:getItems(a.dress_id)[1]
		local a_qlt = xyd.tables.itemTable:getQuality(a_item)
		local b_item = xyd.tables.senpaiDressTable:getItems(b.dress_id)[1]
		local b_qlt = xyd.tables.itemTable:getQuality(b_item)

		if a_qlt ~= b_qlt then
			return b_qlt < a_qlt
		else
			return a_item < b_item
		end
	end)
end

return LeadSkinChooseWindow
