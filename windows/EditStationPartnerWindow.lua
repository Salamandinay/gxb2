local BaseWindow = import(".BaseWindow")
local EditStationPartnerWindow = class("EditStationPartnerWindow", BaseWindow)
local PartnerCard = import("app.components.PartnerCard")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local StationPersonPictureItem = class("StationPersonPictureItem", import("app.common.ui.FixedMultiWrapContentItem"))
local cjson = require("cjson")
local ItemTable = xyd.tables.itemTable
local PartnerTable = xyd.tables.partnerTable
local PartnerPictureTable = xyd.tables.partnerPictureTable
local GroupTable = xyd.tables.groupTable
local PartnerComment = xyd.models.partnerComment
local PartnerDataStation = xyd.models.partnerDataStation

function EditStationPartnerWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selfPlayer = xyd.models.selfPlayer
	self.backpack = xyd.models.backpack
	self.selectIndex = 0
	self.items_ = {}
	self.sortState_ = false
	self.sortType = xyd.pictureSortType.DEFAULT
	self.isFirstTouch_ = true
	self.confirmCallback_ = params.confirmCallback
	self.guidePartners = {}
	self.lock = 2
	self.itemClass = StationPersonPictureItem
end

function EditStationPartnerWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:loadFilterFromStorage()
	self:initData(self.sortType)
	self:layout()
	self:registerEvent()
end

function EditStationPartnerWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.btns = groupAction:NodeByName("btns").gameObject

	for i = 1, 6 do
		self["group" .. i] = self.btns:NodeByName("group" .. i).gameObject
		self["group" .. i .. "_chosen"] = self["group" .. i]:NodeByName("group" .. i .. "_chosen").gameObject
	end

	self.sortBtn = groupAction:NodeByName("sortBtn").gameObject
	self.sortPop = groupAction:NodeByName("sortPop").gameObject
	self.typeSort = self.sortPop:NodeByName("typeSort").gameObject
	self.qualitySort = self.sortPop:NodeByName("qualitySort").gameObject
	self.defaultSort = self.sortPop:NodeByName("defaultSort").gameObject
	local scrollView = groupAction:ComponentByName("scroller_", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("groupMain_", typeof(MultiRowWrapContent))
	local item = groupAction:NodeByName("item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, item, self.itemClass, self)
	self.sortTap = CommonTabBar.new(nil, 0, handler(self, self.changeSortType))

	self.sortTap:initCustomTabs({
		self.typeSort,
		self.qualitySort,
		self.defaultSort
	}, {
		0,
		1,
		2
	})

	self.sortBtnIcon = self.sortBtn:NodeByName("icon").gameObject
	self.sortAni = groupAction:GetComponent(typeof(UnityEngine.Animation))
end

function EditStationPartnerWindow:loadFilterFromStorage()
	self.sortType = xyd.pictureSortType.QUALITY
end

function EditStationPartnerWindow:layout()
	self.labelTitle_.text = __("EDIT_PICTURE_WINDOW")

	self.sortPop:SetActive(false)

	local groupIds = xyd.tables.groupTable:getGroupIds()

	for _, id in ipairs(groupIds) do
		self["group" .. tostring(id) .. "_chosen"]:SetActive(false)
	end

	if self.selectIndex > 0 then
		self["group" .. tostring(self.selectIndex) .. "_chosen"]:SetActive(true)
	end

	xyd.setBtnLabel(self.sortBtn, {
		text = __("SORT")
	})
	xyd.setBtnLabel(self.typeSort, {
		name = "label",
		text = __("TYPE")
	})
	xyd.setBtnLabel(self.qualitySort, {
		name = "label",
		text = __("GRADE")
	})
	xyd.setBtnLabel(self.defaultSort, {
		name = "label",
		text = __("EMOTION_DEFAULT_TEXT")
	})
	self.sortBtnIcon:SetLocalScale(1, 1, 1)

	self.labelTitle_.text = __("STATION_EDIT_PICTURE_WINDOW")

	self.sortBtn:SetActive(false)

	local pos = self.btns.transform.localPosition

	self.btns:SetLocalPosition(-260, pos.y, pos.z)
end

function EditStationPartnerWindow:willClose()
	BaseWindow.willClose(self)
	self:willCloseFunc()
end

function EditStationPartnerWindow:willCloseFunc()
	self.backpack:clearNewPictures()
	xyd.EventDispatcher:inner():dispatchEvent({
		name = xyd.event.NEW_PICTURES,
		data = {}
	})
	xyd.db.misc:setValue({
		key = "kbn_filter",
		value = cjson.encode({
			index = self.selectIndex,
			sortType = self.sortType
		})
	})

	if self.confirmCallback_ then
		self.confirmCallback_()
	end
end

function EditStationPartnerWindow:initData(type)
	local guidePartners = {}
	local groupIds = GroupTable:getGroupIds()

	dump(groupIds)

	guidePartners[0] = {}

	for i = 1, #groupIds do
		guidePartners[groupIds[i]] = {}
	end

	local heroConf = PartnerTable
	local list = heroConf:getIds()
	local heroIds = {}

	dump(list)

	for i = 1, #list do
		if not PartnerTable:checkPuppetPartner(list[i]) then
			table.insert(heroIds, list[i])
		end
	end

	for _, id in ipairs(heroIds) do
		local showInGuide = heroConf:getShowInGuide(id)

		if xyd.Global.isReview ~= 1 and showInGuide >= 1 and showInGuide < xyd.getServerTime() then
			local group = heroConf:getGroup(id)

			table.insert(guidePartners[group], {
				table_id = id,
				key = group,
				parent = self
			})
			table.insert(guidePartners[0], {
				key = "0",
				table_id = id,
				parent = self
			})
		elseif xyd.Global.isReview == 1 and heroConf:getShowInReviewGuide(id) == 1 then
			local group = heroConf:getGroup(id)

			table.insert(guidePartners[group], {
				table_id = id,
				key = group,
				parent = self
			})
			table.insert(guidePartners[0], {
				key = "0",
				table_id = id,
				parent = self
			})
		end
	end

	table.sort(guidePartners[0], function (a, b)
		local startA = PartnerTable:getStar(a.table_id)
		local startB = PartnerTable:getStar(b.table_id)

		if startA ~= startB then
			return startB < startA
		end

		return a.table_id < b.table_id
	end)

	for i = 1, #groupIds do
		table.sort(guidePartners[groupIds[i]], function (a, b)
			local startA = PartnerTable:getStar(a.table_id)
			local startB = PartnerTable:getStar(b.table_id)

			if startA ~= startB then
				return startB < startA
			end

			return a.table_id < b.table_id
		end)
	end

	self.guidePartners = guidePartners

	self:changeDataGroup()
end

function EditStationPartnerWindow:changeDataGroup()
	self.multiWrap_:setInfos(self.guidePartners[self.selectIndex], {})
end

function EditStationPartnerWindow:sortPictures(pictures, type_)
	local itemTable = ItemTable
	local partnerTable = PartnerTable

	table.sort(pictures, function (a, b)
		local aTmpType = itemTable:getType(a)
		local bTmpType = itemTable:getType(b)
		local aType = (aTmpType == xyd.ItemType.SKIN or aTmpType == xyd.ItemType.KANBAN) and 1 or 0
		local bType = (bTmpType == xyd.ItemType.SKIN or bTmpType == xyd.ItemType.KANBAN) and 1 or 0
		local aStar = partnerTable:getStar(a)
		local bStar = partnerTable:getStar(b)
		local aGroup = partnerTable:getGroup(a)
		local bGroup = partnerTable:getGroup(b)

		if type_ == xyd.pictureSortType.DEFAULT then
			if aType ~= bType then
				return aType - bType < 0
			elseif aStar ~= bStar then
				return aStar - bStar < 0
			elseif aGroup ~= bGroup then
				return aGroup - bGroup < 0
			else
				return a - b < 0
			end
		elseif type_ == xyd.pictureSortType.TYPE then
			if aType ~= bType then
				return bType - aType < 0
			elseif aStar ~= bStar then
				return aStar - bStar < 0
			elseif aGroup ~= bGroup then
				return aGroup - bGroup < 0
			else
				return a - b < 0
			end
		elseif type_ == xyd.pictureSortType.QUALITY then
			if aType ~= bType then
				return aType - bType < 0
			elseif aStar ~= bStar then
				return bStar - aStar < 0
			elseif aGroup ~= bGroup then
				return aGroup - bGroup < 0
			else
				return a - b < 0
			end
		end
	end)
end

function EditStationPartnerWindow:registerEvent()
	self:register()

	for i = 1, 6 do
		UIEventListener.Get(self["group" .. i]).onClick = function ()
			self:changeGroup(i)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_PARTNER_DATA_INFO, handler(self, self.onInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_PARTNER_COMMENTS, handler(self, self.onInfo))
end

function EditStationPartnerWindow:onInfo()
	self.lock = self.lock - 1

	if self.lock ~= 0 then
		return
	end

	local wnd = xyd.WindowManager.get():getWindow("partner_data_station_window")
	local curId = 0

	if PartnerTable:getStar(self.partner_id) ~= 10 and PartnerTable:getStar10(self.partner_id) == 0 then
		curId = 2
	end

	local params = {
		comment_id = self.comment_id,
		partner_table_id = self.partner_id,
		curId = curId
	}

	if wnd then
		wnd.isFirstOpen = true

		wnd:resetWindow(params)
	end

	xyd.WindowManager.get():closeWindow("edit_station_partner_window")
end

function EditStationPartnerWindow:setParams(params)
	self.partner_id = params.partner_id
	self.comment_id = params.comment_id
end

function EditStationPartnerWindow:changeGroup(index)
	if self.selectIndex == index then
		self.selectIndex = 0
	else
		self.selectIndex = index
	end

	for i = 1, 6 do
		if self.selectIndex == i then
			self["group" .. tostring(i) .. "_chosen"]:SetActive(true)
		else
			self["group" .. tostring(i) .. "_chosen"]:SetActive(false)
		end
	end

	self:changeDataGroup()
end

function EditStationPartnerWindow:onClickSortBtn()
	self.sortState_ = not self.sortState_

	self:moveSortPop()

	local scaleY = self.sortState_ == true and -1 or 1

	self.sortBtnIcon:SetLocalScale(1, scaleY, 1)
end

function EditStationPartnerWindow:moveSortPop()
	if self.sortState_ then
		self.sortAni:Play("sortPopAni1")
	else
		self.sortAni:Play("sortPopAni2")
	end
end

function EditStationPartnerWindow:changeSortType(sortType)
	if sortType ~= self.sortType then
		self.sortType = sortType

		self:initData()
	end

	if not self.isFirstTouch_ then
		self:onClickSortBtn()
	end

	self.isFirstTouch_ = false
end

function StationPersonPictureItem:ctor(go, parentGo)
	StationPersonPictureItem.super.ctor(self, go, parentGo)
end

function StationPersonPictureItem:initUI()
	self.partnerCard_ = PartnerCard.new(self.go)

	self.partnerCard_:SetLocalScale(0.95, 0.91, 1)

	UIEventListener.Get(self.go).onClick = handler(self, self.onTouchPicture)
end

function StationPersonPictureItem:updateInfo()
	local itemID = self.data.table_id
	local info = {
		tableID = itemID,
		star = PartnerTable:getStar(itemID)
	}

	self.partnerCard_:setInfo(info)
end

function StationPersonPictureItem:onTouchPicture()
	local id = self.data.table_id
	local comment_id = PartnerTable:getCommentID(id)
	local wnd = xyd.WindowManager.get():getWindow("edit_station_partner_window")

	if wnd then
		wnd:setParams({
			partner_id = id,
			comment_id = comment_id
		})
		PartnerDataStation:reqFormation({
			table_id = comment_id
		})
		PartnerComment:reqCommentsData(comment_id)
	end
end

return EditStationPartnerWindow
