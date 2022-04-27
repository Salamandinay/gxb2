local BaseWindow = import(".BaseWindow")
local ActivitySpringFestivalExchangeChooseWindow = class("ActivitySpringFestivalExchangeChooseWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local Choose_Item = class("Choose_Item", import("app.components.CopyComponent"))

function ActivitySpringFestivalExchangeChooseWindow:ctor(name, params)
	ActivitySpringFestivalExchangeChooseWindow.super.ctor(self, name, params)
end

function ActivitySpringFestivalExchangeChooseWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.allBg = self.groupAction:ComponentByName("allBg", typeof(UISprite))
	self.labelWinTitle = self.allBg:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.allBg:NodeByName("closeBtn").gameObject
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.explainText = self.centerCon:ComponentByName("explainText", typeof(UILabel))
	self.showResourseCon = self.centerCon:NodeByName("showResourseCon").gameObject
	self.resourseBg = self.showResourseCon:ComponentByName("resourseBg", typeof(UISprite))
	self.resourseIcon = self.showResourseCon:ComponentByName("resourseIcon", typeof(UISprite))
	self.resourseLabel = self.showResourseCon:ComponentByName("resourseLabel", typeof(UILabel))
	self.scrollerBg = self.centerCon:ComponentByName("scrollerBg", typeof(UISprite))
	self.scroller = self.centerCon:NodeByName("scroller").gameObject
	self.scroller_UIScrollView = self.centerCon:ComponentByName("scroller", typeof(UIScrollView))
	self.itemsGroup_ = self.scroller:NodeByName("itemsGroup_").gameObject
	self.itemsGroup_UIWrapContent = self.scroller:ComponentByName("itemsGroup_", typeof(UIWrapContent))
	self.drag = self.centerCon:NodeByName("drag").gameObject
	self.excgabgeBtn = self.centerCon:NodeByName("excgabgeBtn").gameObject
	self.btnIcon = self.excgabgeBtn:ComponentByName("btnIcon", typeof(UISprite))
	self.btnLabel = self.excgabgeBtn:ComponentByName("btnLabel", typeof(UILabel))
	self.scroller_item = self.centerCon:NodeByName("scroller_item").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.scroller_UIScrollView, self.itemsGroup_UIWrapContent, self.scroller_item, Choose_Item, self)
end

function ActivitySpringFestivalExchangeChooseWindow:initWindow()
	ActivitySpringFestivalExchangeChooseWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:layoutUI()
end

function ActivitySpringFestivalExchangeChooseWindow:addTitle()
	self.labelWinTitle.text = __("SPRING_FESTIVAL_TEXT01")
end

function ActivitySpringFestivalExchangeChooseWindow:layoutUI()
	self.explainText.text = __("SPRING_FESTIVAL_TEXT02")
	self.resourseLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SPRING_NEW_YEAR)
	self.btnLabel.text = xyd.tables.activitySpringFestivalAwardTble:getCost(self.params_.group_id)[2]
	self.group_id = self.params_.group_id
	self.awards = xyd.tables.activitySpringFestivalAwardTble:getAwards(self.group_id)
	local data = {}

	for i in pairs(self.awards) do
		local setData = {
			item_index = i,
			item_data = self.awards[i]
		}

		table.insert(data, setData)
	end

	self.wrapContent:setInfos(data, {})
end

function ActivitySpringFestivalExchangeChooseWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.excgabgeBtn).onClick = function ()
		if not self.choose_id then
			xyd.alert(xyd.AlertType.TIPS, __("SPRING_FESTIVAL_TEXT01"))

			return
		end

		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPRING_NEW_YEAR)

		if activityData and activityData.detail.limits[self.group_id] ~= 0 then
			xyd.alert(xyd.AlertType.TIPS, __("SPRING_FESTIVAL_TEXT02"))

			return
		end

		if xyd.models.backpack:getItemNumByID(xyd.ItemID.SPRING_NEW_YEAR) < xyd.tables.activitySpringFestivalAwardTble:getCost(self.group_id)[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.SPRING_NEW_YEAR)))

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_CHANGE"), function (yes)
			if yes then
				local json = require("cjson")
				local params = {
					table_id = self.group_id,
					index = self.choose_id
				}

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.SPRING_NEW_YEAR, json.encode(params))
			end
		end)
	end
end

function ActivitySpringFestivalExchangeChooseWindow:willClose()
	ActivitySpringFestivalExchangeChooseWindow.super.willClose(self)

	local partner_info_component = xyd.WindowManager.get():getWindow("partner_info_component")

	if partner_info_component then
		xyd.WindowManager.get():closeWindow("partner_info_component")
	end
end

function ActivitySpringFestivalExchangeChooseWindow:clickItem(id)
	local infoItems = self.wrapContent:getItems()

	if self.choose_id and self.choose_id == id then
		for i in pairs(infoItems) do
			if infoItems[i] and infoItems[i].info and infoItems[i].info.item_index == id then
				infoItems[i]:setClick(false)

				break
			end
		end

		local partner_info_component = xyd.WindowManager.get():getWindow("partner_info_component")

		if partner_info_component then
			xyd.WindowManager.get():closeWindow("partner_info_component")
		end

		self:waitForTime(0.1, function ()
			local actionMana = self:getSequence()

			actionMana:Append(self.groupAction.transform:DOLocalMoveY(0, 0.1))
			actionMana:AppendCallback(function ()
				actionMana:Kill(true)
			end)
		end)

		self.choose_id = nil

		return
	end

	self.choose_id = id

	for i in pairs(infoItems) do
		if infoItems[i] and infoItems[i].info then
			if infoItems[i].info.item_index == id then
				infoItems[i]:setClick(true)
			else
				infoItems[i]:setClick(false)
			end
		end
	end
end

function Choose_Item:ctor(go, parent)
	Choose_Item.super.ctor(self, go)

	self.parent_ = parent

	self:getUIComponent()
end

function Choose_Item:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id = info.item_index
	self.info = info

	self:initUIComponent()
end

function Choose_Item:getUIComponent()
	self.item_con = self.go:NodeByName("item_con").gameObject
	self.choose_img = self.go:ComponentByName("choose_img", typeof(UITexture))
end

function Choose_Item:initUIComponent()
	NGUITools.DestroyChildren(self.item_con.transform)

	self.icon = xyd.getItemIcon({
		noClickSelected = true,
		not_show_ways = true,
		uiRoot = self.item_con,
		itemID = self.info.item_data[1],
		num = self.info.item_data[2],
		scale = Vector3(0.9, 0.9, 1),
		callback = function ()
			if self.isCanClick ~= nil and self.isCanClick == false then
				return
			end

			if not self.parent_.choose_id or self.id ~= self.parent_.choose_id then
				local partner_info_component_close = xyd.WindowManager.get():getWindow("partner_info_component")
				local isNeedWait = false

				if partner_info_component_close then
					xyd.WindowManager.get():closeWindow("partner_info_component")

					isNeedWait = true
				end

				local waitTime = 0

				if isNeedWait then
					waitTime = 0.1
				end

				self:waitForTime(waitTime, function ()
					if not isNeedWait then
						local actionMana = self:getSequence()

						actionMana:Append(self.parent_.groupAction.transform:DOLocalMoveY(-250, 0.1))
						actionMana:AppendCallback(function ()
							actionMana:Kill(true)
							self:openPartnerInfo()
						end)

						return
					end

					self:openPartnerInfo()
				end)
			end

			self.parent_:clickItem(self.id)
		end
	})

	self.icon:AddUIDragScrollView()
	self.choose_img:SetActive(false)
	self:updateGrey()
end

function Choose_Item:openPartnerInfo()
	local tableId = xyd.tables.itemTable:partnerCost(self.info.item_data[1])
	local partner_info_component = xyd.WindowManager.get():openWindow("partner_info_component", {
		notShowWays = true,
		table_id = tableId[1]
	})

	if partner_info_component then
		partner_info_component.window_:Y(245)
	end
end

function Choose_Item:setClick(flag)
	self.icon:setChoose(flag)
end

function Choose_Item:updateGrey()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPRING_NEW_YEAR)

	if activityData and xyd.tables.activitySpringFestivalAwardTble:getLimit(self.parent_.group_id)[self.id] <= activityData.detail.buy_times[self.parent_.group_id][self.id] then
		self.isCanClick = false

		if self.icon then
			xyd.applyChildrenGrey(self.item_con.gameObject)
			self.choose_img:SetActive(true)
		end
	end
end

return ActivitySpringFestivalExchangeChooseWindow
