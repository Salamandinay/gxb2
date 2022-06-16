local DressChoiceFragmentWindow = class("DressChoiceFragmentWindow", import(".BaseWindow"))
local ItemRender = class("testItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function DressChoiceFragmentWindow:ctor(name, params)
	DressChoiceFragmentWindow.super.ctor(self, name, params)

	self.item_id = params.item_id
	self.self_item_fragment_id = params.self_item_fragment_id
	self.is_common = params.is_common
	self.choice_yet_infos = {}

	if params.choice_yet_infos then
		for i in pairs(params.choice_yet_infos) do
			table.insert(self.choice_yet_infos, params.choice_yet_infos[i])
		end
	end

	self.all_num = params.all_num
end

function DressChoiceFragmentWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DressChoiceFragmentWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.backBtn = self.groupAction:NodeByName("backBtn").gameObject
	self.fragmentScroller = self.groupAction:NodeByName("fragmentScroller").gameObject
	self.fragmentScroller_UIScrollView = self.groupAction:ComponentByName("fragmentScroller", typeof(UIScrollView))
	self.wrapContent = self.fragmentScroller:NodeByName("wrapContent").gameObject
	self.wrapContent_UIWrapContent = self.fragmentScroller:ComponentByName("wrapContent", typeof(UIWrapContent))
	self.item = self.groupAction:NodeByName("item").gameObject
	self.btnChoice = self.groupAction:NodeByName("btnChoice").gameObject
	self.btnChoice_button_label = self.btnChoice:ComponentByName("button_label", typeof(UILabel))
	self.btnYes = self.groupAction:NodeByName("btnYes").gameObject
	self.btnYes_button_label = self.btnYes:ComponentByName("button_label", typeof(UILabel))
	self.fragmentNone = self.groupAction:NodeByName("fragmentNone").gameObject
	self.noFragmentLabel = self.fragmentNone:ComponentByName("noFragmentLabel", typeof(UILabel))
	self.wrapContent_ = FixedMultiWrapContent.new(self.fragmentScroller_UIScrollView, self.wrapContent_UIWrapContent, self.item, ItemRender, self)
end

function DressChoiceFragmentWindow:layout()
	self.noFragmentLabel.text = __("NO_DEBRIS")
	self.title.text = __("DRESS_CHOOSE_FRAGMENT_WINDOW_3")
	self.btnChoice_button_label.text = __("DRESS_CHOOSE_FRAGMENT_WINDOW_6")
	self.btnYes_button_label.text = __("FOR_SURE")

	if not self.is_common then
		local num = xyd.models.backpack:getItemNumByID(self.item_id)

		if num > 0 then
			self.arr = {
				{
					is_can_use = 1,
					item_id = self.item_id,
					item_num = num,
					is_common = self.is_common
				}
			}

			self.fragmentScroller.gameObject:SetActive(true)
			self.fragmentNone.gameObject:SetActive(false)
			self.wrapContent_:setInfos(self.arr, {})
			self:waitForFrame(1, function ()
				self.fragmentScroller_UIScrollView:ResetPosition()
			end)
		else
			self.fragmentScroller.gameObject:SetActive(false)
			self.fragmentNone.gameObject:SetActive(true)
		end
	else
		local qlt = self.item_id
		self.arr = xyd.models.dress:getCommonQltFragmentArr(qlt, self.self_item_fragment_id)

		if #self.arr > 0 then
			self.fragmentScroller.gameObject:SetActive(true)
			self.fragmentNone.gameObject:SetActive(false)
			self.wrapContent_:setInfos(self.arr, {})
			self:waitForFrame(1, function ()
				self.fragmentScroller_UIScrollView:ResetPosition()
			end)
		else
			self.fragmentScroller.gameObject:SetActive(false)
			self.fragmentNone.gameObject:SetActive(true)
		end
	end
end

function DressChoiceFragmentWindow:registerEvent()
	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.btnYes.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.btnChoice.gameObject).onClick = handler(self, function ()
		local all_num_yet = 0

		for i in pairs(self.choice_yet_infos) do
			all_num_yet = all_num_yet + self.choice_yet_infos[i].item_num
		end

		if self.all_num <= all_num_yet then
			xyd.alertTips(__("DRESS_CHOOSE_FRAGMENT_WINDOW_4"))

			return
		end

		local can_choice_num = self.all_num - all_num_yet

		if not self.arr or self.arr and #self.arr == 0 then
			xyd.alertTips(__("DRESS_CHOOSE_FRAGMENT_WINDOW_7"))

			return
		end

		for i in pairs(self.arr) do
			if self.arr[i].is_can_use == 1 then
				local is_choice_index = -1

				for k in pairs(self.choice_yet_infos) do
					if self.arr[i].item_id == self.choice_yet_infos[k].item_id then
						is_choice_index = k
					end
				end

				if is_choice_index == -1 then
					if can_choice_num <= self.arr[i].item_num then
						table.insert(self.choice_yet_infos, {
							item_id = self.arr[i].item_id,
							item_num = can_choice_num
						})

						can_choice_num = 0
						self.arr[i].is_update = true

						break
					else
						table.insert(self.choice_yet_infos, {
							item_id = self.arr[i].item_id,
							item_num = self.arr[i].item_num
						})

						self.arr[i].is_update = true
						can_choice_num = can_choice_num - self.arr[i].item_num
					end
				elseif can_choice_num <= self.arr[i].item_num - self.choice_yet_infos[is_choice_index].item_num then
					self.arr[i].is_update = true
					self.choice_yet_infos[is_choice_index].item_num = self.choice_yet_infos[is_choice_index].item_num + can_choice_num
					can_choice_num = 0

					break
				else
					self.arr[i].is_update = true
					self.choice_yet_infos[is_choice_index].item_num = self.arr[i].item_num
					can_choice_num = can_choice_num - (self.arr[i].item_num - self.choice_yet_infos[is_choice_index].item_num)
				end
			end
		end

		if can_choice_num <= 0 then
			xyd.alertTips(__("DRESS_CHOOSE_FRAGMENT_WINDOW_8"))
		else
			xyd.alertTips(__("DRESS_CHOOSE_FRAGMENT_WINDOW_7"))
		end

		self.wrapContent_:setInfos(self.arr, {
			keepPosition = true
		})
	end)
end

function DressChoiceFragmentWindow:updateScroller(item_id, num)
	for i in pairs(self.arr) do
		if self.arr[i].item_id == item_id then
			self.arr[i].is_update = true
		end
	end

	local is_search = false

	for i in pairs(self.choice_yet_infos) do
		if self.choice_yet_infos[i].item_id == item_id then
			is_search = true
			self.choice_yet_infos[i].item_num = num

			break
		end
	end

	if not is_search then
		table.insert(self.choice_yet_infos, {
			item_id = item_id,
			item_num = num
		})
	end

	self.wrapContent_:setInfos(self.arr, {
		keepPosition = true
	})
end

function DressChoiceFragmentWindow:willClose()
	local dress_item_up_Wd = xyd.WindowManager.get():getWindow("dress_item_up_window")

	if dress_item_up_Wd then
		dress_item_up_Wd:updateFragmentNum(self.item_id, self.choice_yet_infos)
	end

	DressChoiceFragmentWindow.super.willClose(self)
end

function ItemRender:ctor(go, parent)
	ItemRender.super.ctor(self, go, parent)

	self.parent = parent
end

function ItemRender:initUI()
	local go = self.go
	self.itemCon = self.go:NodeByName("itemCon").gameObject
	self.numText = self.go:ComponentByName("numText", typeof(UILabel))
end

function ItemRender:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.item_id and self.item_num and info and info.item_id and info.item_num and self.item_id == info.item_id and self.item_num == info.item_num then
		if not info.is_update then
			return
		end

		info.is_update = false
	end

	self.info = info
	self.item_id = info.item_id
	self.item_num = info.item_num
	self.is_common = info.is_common
	self.is_can_use = info.is_can_use
	self.choice_yet_num = 0

	for i, info in pairs(self.parent.choice_yet_infos) do
		if info.item_id == self.item_id then
			self.choice_yet_num = info.item_num
		end
	end

	if not self.icon_ then
		self.icon_ = xyd.getItemIcon({
			noClickSelected = true,
			uiRoot = self.go,
			itemID = self.item_id,
			num = self.item_num,
			callback = handler(self, self.clickIcon)
		})
	else
		self.icon_:setInfo({
			noClickSelected = true,
			itemID = self.item_id,
			num = self.item_num,
			callback = handler(self, self.clickIcon)
		})
	end

	self.numText.text = self.choice_yet_num .. "/" .. self.parent.all_num

	if self.choice_yet_num < self.parent.all_num then
		self.numText.color = Color.New2(4278124287.0)
	else
		self.numText.color = Color.New2(2986279167.0)
	end

	if self.is_can_use == 1 then
		self.icon_:setMask(false)
	else
		self.icon_:setMask(true)
	end

	self.icon_:AddUIDragScrollView()
end

function ItemRender:getIsCanUse()
	return self.is_can_use
end

function ItemRender:clickIcon()
	if self.is_can_use == 0 then
		xyd.alertTips(__("DRESS_CHOOSE_FRAGMENT_WINDOW_2"))

		return
	end

	local has_all_other_num = 0

	for i in pairs(self.parent.choice_yet_infos) do
		if self.parent.choice_yet_infos[i].item_id ~= self.item_id then
			has_all_other_num = has_all_other_num + self.parent.choice_yet_infos[i].item_num
		end
	end

	local max_num = self.parent.all_num - has_all_other_num

	if max_num <= 0 then
		xyd.alertTips(__("DRESS_CHOOSE_FRAGMENT_WINDOW_4"))

		return
	end

	if self.item_num < max_num then
		max_num = self.item_num
	end

	local curNumInit = self.choice_yet_num
	local params = {
		minNum = 0,
		itemID = self.item_id,
		itemNum = self.item_num,
		callback = function (num)
			self.parent:updateScroller(self.item_id, num)
		end,
		maxLimitNum = max_num,
		curNumInit = curNumInit,
		tipsLabelText = __("ACTIVITY_ICE_SUMMER_INPUT"),
		maxLimitTips = __("DRESS_CHOOSE_FRAGMENT_WINDOW_5")
	}

	xyd.WindowManager.get():openWindow("artifact_offer_window", params)
end

return DressChoiceFragmentWindow
