local BaseWindow = import(".BaseWindow")
local DatesListWindow = class("DatesListWindow", BaseWindow)
local DatesPartnerCard = class("DatesPartnerCard")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local WindowTop = import("app.components.WindowTop")
local PartnerTable = xyd.tables.partnerTable
local PartnerCard = import("app.components.PartnerCard")
local PartnerAchievementTable = xyd.tables.partnerAchievementTable

function DatesListWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.sortedPartners = {}
	self.sortType = xyd.partnerSortType.LOVE_POINT
	self.chosenGroup = 0

	if params and params.enterType then
		self.enterType = params.enterType
	end

	if params and params.chosenGroup then
		self.chosenGroup = params.chosenGroup
	end

	if params and params.sortType then
		self.sortType = params.sortType
	end

	if params then
		self.isBackToBackpack = params.isBackToBackpack
		self.item_id = params.item_id
	end

	self.sortState_ = false
	self.isFirstTouch_ = true
end

function DatesListWindow:willOpen()
	DatesListWindow.super.willOpen(self)

	local needSort = xyd.models.slot:getNeedSort()

	if needSort then
		xyd.models.slot:sortPartners()
		xyd.models.slot:setNeedSort(false)
	end
end

function DatesListWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initTopGroup()
	self:initLayout()
	self:registerEvent()
	self:initData()
end

function DatesListWindow:getUIComponent()
	local winTrans = self.window_.transform
	local bottom = winTrans:NodeByName("bottom").gameObject
	local main = winTrans:NodeByName("main").gameObject
	local filter = bottom:NodeByName("filter").gameObject

	for i = 1, 6 do
		self["group" .. i] = filter:NodeByName("e:Group/group" .. i).gameObject
		self["group" .. i .. "_chosen"] = self["group" .. i]:NodeByName("group" .. i .. "_chosen").gameObject
	end

	self.sortBtn = filter:NodeByName("sortBtn").gameObject
	self.sortPop = filter:NodeByName("sortPop").gameObject
	self.starSort = self.sortPop:NodeByName("starSort").gameObject
	self.levSort = self.sortPop:NodeByName("levSort").gameObject
	self.loveSort = self.sortPop:NodeByName("loveSort").gameObject
	self.partnerNone = main:NodeByName("partnerNone").gameObject
	self.labelNoneTips = self.partnerNone:ComponentByName("labelNoneTips", typeof(UILabel))
	local scrollView = main:ComponentByName("scrollview", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("partnersGroup", typeof(MultiRowWrapContent))
	local item = main:NodeByName("item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, item, DatesPartnerCard, self)
	self.sortTap = CommonTabBar.new(nil, 0, handler(self, self.changeSortType))

	self.sortTap:initCustomTabs({
		self.levSort,
		self.starSort,
		self.loveSort
	}, {
		0,
		1,
		3
	})

	self.sortBtnIcon = self.sortBtn:NodeByName("icon").gameObject
	self.sortAni = filter:GetComponent(typeof(UnityEngine.Animation))
	self.openAni = winTrans:GetComponent(typeof(UnityEngine.Animation))
	local event = winTrans:GetComponent(typeof(LuaAnimationEvent))

	function event.callback(eventName)
		if eventName == "complete" then
			self:setWndComplete()
		end
	end
end

function DatesListWindow:registerEvent()
	for i = 1, 6 do
		UIEventListener.Get(self["group" .. i]).onClick = function ()
			self:changeFilter(i)
		end
	end

	UIEventListener.Get(self.sortBtn).onClick = handler(self, self.onClickSortBtn)
end

function DatesListWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 11, true, handler(self, self.closeSelf))
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function DatesListWindow:closeSelf()
	self:close()
end

function DatesListWindow:initData()
	local slot = xyd.models.slot
	local sortedPartners = slot:getSortedPartners()

	for key in pairs(sortedPartners) do
		local res = {}

		for _, partner_id in ipairs(sortedPartners[key]) do
			local params = {
				partner_id = partner_id,
				key = key
			}
			local partner = slot:getPartner(partner_id)

			if partner and not PartnerTable:checkPuppetPartner(partner:getTableID()) then
				table.insert(res, params)
			end
		end

		self.sortedPartners[key] = res
	end

	self:updateDataGroup()
end

function DatesListWindow:initLayout()
	self.sortPop:SetActive(false)

	local groupIds = xyd.tables.groupTable:getGroupIds()

	for _, id in ipairs(groupIds) do
		self["group" .. tostring(id) .. "_chosen"]:SetActive(false)
	end

	if self.chosenGroup > 0 then
		self["group" .. tostring(self.chosenGroup) .. "_chosen"]:SetActive(true)
	end

	xyd.setBtnLabel(self.sortBtn, {
		text = __("SORT")
	})
	xyd.setBtnLabel(self.levSort, {
		name = "label",
		text = __("LEV")
	})
	xyd.setBtnLabel(self.starSort, {
		name = "label",
		text = __("GRADE")
	})
	xyd.setBtnLabel(self.loveSort, {
		name = "label",
		text = __("LOVE_POINT_TEXT")
	})
	self.sortBtnIcon:SetLocalScale(1, 1, 1)

	self.labelNoneTips.text = __("NO_PARTNER_2")
end

function DatesListWindow:onClickSortBtn()
	self.sortState_ = not self.sortState_

	self:moveSortPop()

	local scaleY = self.sortState_ == true and -1 or 1

	self.sortBtnIcon:SetLocalScale(1, scaleY, 1)
end

function DatesListWindow:moveSortPop()
	if self.sortState_ then
		self.sortAni:Play("sortPopAni1")
	else
		self.sortAni:Play("sortPopAni2")
	end
end

function DatesListWindow:changeSortType(sortType)
	if sortType ~= self.sortType then
		self.sortType = sortType

		self:updateDataGroup()
	end

	if not self.isFirstTouch_ then
		self:onClickSortBtn()
	end

	self.isFirstTouch_ = false
end

function DatesListWindow:changeFilter(chosenGroup)
	if self.chosenGroup == chosenGroup then
		self.chosenGroup = 0
	else
		self.chosenGroup = chosenGroup
	end

	local groupIds = xyd.tables.groupTable:getGroupIds()

	for _, id in ipairs(groupIds) do
		if id == self.chosenGroup then
			self["group" .. tostring(id) .. "_chosen"]:SetActive(true)
		else
			self["group" .. tostring(id) .. "_chosen"]:SetActive(false)
		end
	end

	self:updateDataGroup()
end

function DatesListWindow:updateDataGroup()
	local key = tostring(self.sortType) .. "_" .. tostring(self.chosenGroup)

	self.multiWrap_:setInfos(self.sortedPartners[key], {})

	if #self.sortedPartners[key] <= 0 then
		self.partnerNone:SetActive(true)
	else
		self.partnerNone:SetActive(false)
	end
end

function DatesListWindow:getChosenGroup()
	return self.chosenGroup
end

function DatesPartnerCard:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)

	self.win_ = xyd.WindowManager:get():getWindow("dates_list_window")

	self:initUI()
end

function DatesPartnerCard:initUI()
	self.partnerCard = PartnerCard.new(self.go)
	self.imgAlert_ = self.go:NodeByName("alertIcon").gameObject

	self.imgAlert_:SetActive(false)

	UIEventListener.Get(self.go).onClick = function ()
		local params = {
			partner_id = self.data.partner_id,
			chosenGroup = self.win_:getChosenGroup(),
			sort_key = self.data.key,
			isBackToBackpack = self.parent.isBackToBackpack,
			item_id = self.parent.item_id
		}

		xyd.WindowManager.get():openWindow("dates_window", params, function ()
			xyd.WindowManager.get():closeWindow("dates_list_window")
		end)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	end
end

function DatesPartnerCard:getGameObject()
	return self.go
end

function DatesPartnerCard:init(partner_id, parent)
	local partner = xyd.models.slot:getPartner(partner_id)

	self.partnerCard:setDatesCard(nil, partner)

	if parent then
		self.parent_ = parent
	end

	local ids = PartnerTable:getAchievementIDs(partner:getTableID())
	local achievementData = xyd.models.achievement:getPartnerAchievement(partner:getTableID())
	local redMark = #ids > 0 and achievementData and PartnerAchievementTable:getLastID(achievementData.table_id) ~= 0 and achievementData.is_complete and not achievementData.is_reward

	self.imgAlert_:SetActive(redMark)
end

function DatesPartnerCard:update(wrapIndex, index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:init(self.data.partner_id, self.data.parent)
end

return DatesListWindow
