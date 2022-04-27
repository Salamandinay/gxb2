local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestAddHeroWindow = class("ActivityEntranceTestAddHeroWindow", BaseWindow)
local PartnerFilter = import("app.components.PartnerFilter")
local ActivityEntranceTestHeroIcon = class("ActivityEntranceTestHeroIcon")
local HeroIcon = import("app.components.HeroIcon")

function ActivityEntranceTestAddHeroWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = nil
	self.needSound = false
	self.selectedHeros = {}
	self.mapsModel = xyd.models.map
	self.StageTable = xyd.tables.StageTable
	self.FortTable = xyd.tables.fortTable
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.sortKey = params.sort_key
	self.firstChosenGroup = params.chosenGroup or 0
end

function ActivityEntranceTestAddHeroWindow:willOpen(params)
	BaseWindow.willOpen(self, params)
end

function ActivityEntranceTestAddHeroWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initPartnerList()

	self.needSound = true
end

function ActivityEntranceTestAddHeroWindow:getUIComponent()
	local trans = self.window_.transform
	self.mainNode = trans:NodeByName("mainNode").gameObject
	self.chooseGroup = self.mainNode:NodeByName("chooseGroup").gameObject
	self.fGroup = self.chooseGroup:NodeByName("fGroup").gameObject
	self.partnerScroller = self.chooseGroup:NodeByName("partnerScroller").gameObject
	self.partnerScroller_uiPanel = self.partnerScroller:GetComponent(typeof(UIPanel))
	self.partnerScroller_uiScrollView = self.partnerScroller:GetComponent(typeof(UIScrollView))
	self.partnerContainer = self.partnerScroller:NodeByName("partnerContainer").gameObject
	self.partnerListWarpContent_ = self.partnerContainer:GetComponent(typeof(MultiRowWrapContent))
	self.heroRoot = self.chooseGroup:NodeByName("hero_root").gameObject
	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScroller_uiScrollView, self.partnerListWarpContent_, self.heroRoot, ActivityEntranceTestHeroIcon, self)
end

function ActivityEntranceTestAddHeroWindow:playOpenAnimations(preWinName, callback)
	callback(_G)

	local oldTop = self.chooseGroup.top
	local oldBottom = self.chooseGroup.bottom
	self.chooseGroup.top = 1090
	self.chooseGroup.bottom = oldBottom * -1
	local action2 = TimelineLite.new({
		onComplete = function ()
			self:setWndComplete()
		end
	})

	action2:to(self.chooseGroup, 0.5, {
		top = oldTop
	})

	local action4 = TimelineLite.new()

	action4:to(self.chooseGroup, 0.5, {
		bottom = oldBottom
	})
end

function ActivityEntranceTestAddHeroWindow:onSelectGroup(group)
	if self.selectGroup_ == group then
		return
	end

	local win = xyd.WindowManager.get():getWindow("activity_entrance_test_slot_window")

	win:changeFilter(group)

	self.selectGroup_ = group

	self:iniPartnerData(group)
end

function ActivityEntranceTestAddHeroWindow:initPartnerList()
	local params = {
		isCanUnSelected = 1,
		scale = 1,
		gap = 20,
		callback = handler(self, function (self, group)
			self:onSelectGroup(group)
		end),
		width = self.fGroup:GetComponent(typeof(UIWidget)).width,
		chosenGroup = self.firstChosenGroup
	}
	local selectGroup = PartnerFilter.new(self.fGroup.gameObject, params)

	for key, p in pairs(self.activityData:getCanUsePartners()) do
		if p.partnerID then
			p.noClick = true

			table.insert(self.selectedHeros, p)
		end
	end

	local arr = xyd.split(self.sortKey, "_", true)

	self:iniPartnerData(arr[2])
end

function ActivityEntranceTestAddHeroWindow:initNormalPartnerData(groupID)
	local partnerList = self.activityData:getSortedPartners()
	local sortedList = partnerList[tostring(xyd.partnerSortType.SHENXUE) .. "_" .. tostring(groupID)]
	local partnerDataList = {}

	for key, partnerInfo in pairs(sortedList) do
		partnerInfo.noClick = true
		local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.tableID)

		if partnerInfo.partnerID ~= nil and partnerInfo.partnerID ~= 0 then
			partnerInfo.selected = true
		end

		local data = {
			callbackFunc = handler(self, function (a, heroIcon, isChoose, realIndex, item)
				self:onClickheroIcon(heroIcon, isChoose, realIndex, item)
			end),
			partnerInfo = partnerInfo
		}

		table.insert(partnerDataList, data)
	end

	return partnerDataList
end

function ActivityEntranceTestAddHeroWindow:iniPartnerData(groupID)
	local partnerDataList = nil
	self.partnerDataList = self:initNormalPartnerData(groupID)

	self.partnerMultiWrap_:setInfos(self.partnerDataList, {})
end

function ActivityEntranceTestAddHeroWindow:getTargetLocal(targetObj, container)
	local targetGlobalPos = targetObj:localToGlobal()
	local targetContainerPos = container:globalToLocal(targetGlobalPos.x, targetGlobalPos.y)

	return targetContainerPos
end

function ActivityEntranceTestAddHeroWindow:refreshDataGroup(updatePartnerInfo, realIndex)
	for i in pairs(self.partnerDataList) do
		local partnerInfo = self.partnerDataList[i].partnerInfo

		if partnerInfo.tableIndex == updatePartnerInfo.tableIndex then
			local item = self.partnerDataList[i]

			self.partnerMultiWrap_:updateInfo(realIndex, item)

			break
		end
	end
end

function ActivityEntranceTestAddHeroWindow:onClickheroIcon(heroIcon, isChoose, realIndex, item)
	if not isChoose then
		if xyd.tables.miscTable:getNumber("activity_warmup_arena_partner_limit", "value") <= #self.activityData.detail.partner_list then
			xyd.showToast(__("ENTRANCE_TEST_HERO_LIMIT_TIP"))

			return
		end
	elseif #self.activityData.detail.partner_list <= 1 then
		xyd.showToast(__("ALTAR_DECOMPOSE_TIP2"))

		return
	end

	if self.needSound then
		xyd.SoundManager.get():playSound("2037")
	end

	local win_ = xyd.WindowManager.get():getWindow("activity_entrance_test_slot_window")
	local partnerInfo = heroIcon:getPartnerInfo()
	partnerInfo.selected = not isChoose

	if isChoose then
		self:unSelectHero(heroIcon, realIndex, item)
		self.activityData:deletePartner(partnerInfo)
		win_:updateDataGroup()
	else
		table.insert(self.selectedHeros, partnerInfo)
		self.activityData:addNewPartner(partnerInfo)
		self:refreshDataGroup(partnerInfo, realIndex)
		item:setIsChoose(true)
		win_:addNewPartner(partnerInfo)
	end
end

function ActivityEntranceTestAddHeroWindow:unSelectHero(copyIcon, realIndex, item)
	local partnerInfo = copyIcon:getPartnerInfo()
	partnerInfo.selected = false

	item:setIsChoose(false)

	for i in pairs(self.selectedHeros) do
		if self.selectedHeros[i] == partnerInfo then
			table.remove(self.selectedHeros, i)

			break
		end
	end

	self:refreshDataGroup(partnerInfo, realIndex)
end

function ActivityEntranceTestAddHeroWindow:willClose()
	BaseWindow.willClose(self)
end

function ActivityEntranceTestAddHeroWindow:excuteCallBack()
	if self.callback then
		self:callback()
	end
end

function ActivityEntranceTestHeroIcon:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
end

function ActivityEntranceTestHeroIcon:setIsChoose(status)
	self.isSelected = status

	self.heroIcon_:setChoose(status)
end

function ActivityEntranceTestHeroIcon:getHeroIcon()
	return self.heroIcon_
end

function ActivityEntranceTestHeroIcon:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function ActivityEntranceTestHeroIcon:getGameObject()
	return self.uiRoot_
end

function ActivityEntranceTestHeroIcon:init(data)
	if not self.heroIcon_ then
		self.heroIcon_ = HeroIcon.new(self.uiRoot_, self.parent_.partnerScroller_uiPanel)
	end

	self.partner_ = data.partnerInfo
	self.partner_.callback = handler(self, self.onTouch)
	self.partner_.noClick = false
	self.partner_.isShowSelected = false
	self.partner_.dragScrollView = self.parent_.partnerScroller_uiScrollView

	self.heroIcon_:setInfo(self.partner_)

	self.heroIcon_.choose = data.partnerInfo.selected

	self.heroIcon_:setEntranceTestFinish()

	self.name = "icon_" .. tostring(self.itemIndex)
end

function ActivityEntranceTestHeroIcon:createChildren()
end

function ActivityEntranceTestHeroIcon:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	self.realIndex = realIndex
	self.data = info

	self:init(self.data)
end

function ActivityEntranceTestHeroIcon:getHeroIcon()
	return self.heroIcon_
end

function ActivityEntranceTestHeroIcon:onTouch()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	self.data.callbackFunc(self.heroIcon_, self.heroIcon_.choose, self.realIndex, self)
	self.heroIcon_:setEntranceTestFinish()
end

return ActivityEntranceTestAddHeroWindow
