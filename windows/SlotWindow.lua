local UnityEngine = UnityEngine
local PartnerCard = import("app.components.PartnerCard")
local jobIds = {
	xyd.PartnerJob.WARRIOR,
	xyd.PartnerJob.MAGE,
	xyd.PartnerJob.RANGER,
	xyd.PartnerJob.ASSASSIN,
	xyd.PartnerJob.PRIEST
}
local SlotPartnerCard = class("SlotPartnerCard")

function SlotPartnerCard:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.partnerCard = PartnerCard.new(go, parent.renderPanel)
	self.win_ = xyd.WindowManager.get():getWindow("slot_window")

	self:init()
end

function SlotPartnerCard:init()
	UIEventListener.Get(self.go).onClick = handler(self, function ()
		local np = xyd.models.slot:getPartner(self.data.partner_id)

		if not self.data then
			return
		end

		local table_id = self.data.table_id
		self.partnerId_ = self.data.partner_id
		local is_guide = nil

		if table_id ~= nil then
			is_guide = true
		else
			is_guide = false
		end

		local params = {
			partner_id = self.data.partner_id,
			sort_key = self.data.key,
			table_id = self.data.table_id,
			is_group7_ex_gallery = self.data.is_group7_ex_gallery
		}

		if not is_guide then
			params.showMarkBtn = true

			xyd.WindowManager.get():openWindow("partner_detail_window", params)

			if np:getStar() >= 5 and xyd.checkRedMarkSetting(xyd.RedMarkType.NEW_FIVE_STAR) then
				local redParams = xyd.models.redMark:getRedMarkParams(xyd.RedMarkType.NEW_FIVE_STAR) or {}
				local npList = redParams.npList or {}

				if #npList == 0 then
					return
				end

				local pIndex = xyd.arrayIndexOf(npList, self.partnerId_)

				if pIndex > -1 then
					table.remove(npList, pIndex)

					redParams.npList = npList
					local hasNew = xyd.checkCondition(#npList > 0, true, false)

					xyd.models.redMark:setMark(xyd.RedMarkType.NEW_FIVE_STAR, hasNew, redParams)
				end
			end
		else
			params.partners = self.parent.guidePartners[params.sort_key]

			xyd.WindowManager.get():openWindow("guide_detail_window", params)
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	end)
end

function SlotPartnerCard:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info
	self.is_group7_ex_gallery = info.is_group7_ex_gallery

	self:updateInfo(info.partner_id, info.sort_key, info.red_point, info.table_id)
	self.go:SetActive(true)
end

function SlotPartnerCard:updateInfo(partner_id, sort_key, red_point, table_id, parent)
	if table_id then
		local info = {
			tableID = table_id,
			star = xyd.tables.partnerTable:getStar(table_id),
			lev = xyd.tables.partnerTable:getMaxlev(table_id),
			playOpenAnimation = self.win_.isPlayOpenAnimation
		}

		if self.is_group7_ex_gallery then
			info.star = xyd.models.slot:getGroup7ShowGuideInfo().max_star
			info.lev = xyd.models.slot:getGroup7ShowGuideInfo().max_lev
			local showIds = xyd.tables.partnerTable:getShowIds(table_id)
			info.show_id = showIds[xyd.models.slot:getGroup7ShowGuideInfo().max_show_guide_index]
		end

		self.partnerCard:setInfo(info)

		local collection = xyd.models.slot:getCollection()

		if self.is_group7_ex_gallery == nil then
			if not collection[table_id] then
				self.partnerCard:applyGrey()
			else
				self.partnerCard:applyOrigin()
			end
		elseif self.is_group7_ex_gallery then
			local exGallery = xyd.models.slot:getExGallery()

			if xyd.arrayIndexOf(exGallery, table_id) == -1 then
				self.partnerCard:applyGrey()
			else
				self.partnerCard:applyOrigin()
			end
		end

		self.partnerCard:setRedPoint(false)
		self.partnerCard:setUpgradeEffect(false)
	elseif partner_id then
		local slot = xyd.models.slot
		local partner = slot:getPartner(partner_id)

		self.partnerCard:setInfo(nil, partner)
		self.partnerCard:setRedPoint(red_point)
		self.partnerCard:setUpgradeEffect(slot:checkShenxueOrAwake(partner_id))
	end

	if parent then
		self.parent_ = parent
	end
end

function SlotPartnerCard:getGameObject()
	return self.go
end

local SlotWindow = class("SlotWindow", import(".BaseWindow"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local WindowTop = import("app.components.WindowTop")
local ResItem = import("app.components.ResItem")
SlotWindow.SlotPartnerCard = SlotPartnerCard

function SlotWindow:ctor(name, params)
	xyd.models.slot:getData()
	SlotWindow.super.ctor(self, name, params)

	self.isPlayOpenAnimation = false
	self.sortedPartners = {}
	self.guidePartners = {}
	self.sortType = xyd.partnerSortType.isCollected
	self.chosenGroup = 0
	self.currentJobId = 0
	self.guideChosenGroup = 1
	self.currentGuideJobId = 0
	local sortType = xyd.db.misc:getValue("slow_window_sort_type")

	if sortType then
		self.sortType = tonumber(sortType)
	end

	if params then
		if params.chosenGroup then
			self.chosenGroup = params.chosenGroup
		end

		if params.sortType then
			self.sortType = params.sortType
		end

		if params.jobId then
			self.currentJobId = params.jobId
		end
	end
end

function SlotWindow:initWindow()
	SlotWindow.super.initWindow(self)
	self:getUIComponent()
	self:initTopGroup()
	self:initLayout()
	self:registerEvent()
	self:initFixedMultiWrapContent(self.scrollView_, self.wrapContent_, self.partnerCard_, self.SlotPartnerCard)
	self:initData()

	if self.params_.type and tonumber(self.params_.type) > 0 then
		self:waitForFrame(1, function ()
			self.topBar_:setTabActive(self.params_.type, true)
		end)
	end

	self.middle.transform:SetLocalPosition(-1000, 0, 0)
end

function SlotWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.top = winTrans:NodeByName("top").gameObject
	self.middle = winTrans:NodeByName("middle").gameObject
	self.nav = winTrans:NodeByName("middle/nav").gameObject
	self.labelHero = self.nav:ComponentByName("tab_1/label", typeof(UILabel))
	self.labelGuide = self.nav:ComponentByName("tab_2/label", typeof(UILabel))
	self.partnerNone = winTrans:NodeByName("middle/partnerNone").gameObject
	self.labelNoneTips = self.partnerNone:ComponentByName("labelNoneTips", typeof(UILabel))
	local content = winTrans:NodeByName("middle/content").gameObject
	self.groupSelectLabel = content:ComponentByName("groupSelectLabel", typeof(UILabel))
	self.addSlotGroup = content:NodeByName("addSlotGroup").gameObject
	self.slotNum = self.addSlotGroup:ComponentByName("slotNum", typeof(UILabel))
	self.addSlotBtn = self.addSlotGroup:NodeByName("addSlotBtn").gameObject
	self.guideNum = content:ComponentByName("guideNum", typeof(UILabel))
	self.guideNumLabel = content:ComponentByName("guideNumLabel", typeof(UILabel))
	self.guideNumLabel.text = __("HAD_COLLECTED")
	local container = self.window_:NodeByName("middle/content/main_container")
	local scrollView = container:ComponentByName("scroll_view", typeof(UIScrollView))
	self.scrollView_ = scrollView
	self.renderPanel = container:ComponentByName("scroll_view", typeof(UIPanel))
	self.renderPanel_anchorObj = self.window_:NodeByName("middle/e:Image").gameObject
	self.wrapContent_ = scrollView:ComponentByName("wrap_content", typeof(MultiRowWrapContent))
	local partnerCard = container:NodeByName("partner_card").gameObject
	self.partnerCard_ = partnerCard
	local dragScrollView = partnerCard:AddComponent(typeof(UIDragScrollView))
	dragScrollView.scrollView = scrollView

	partnerCard:SetActive(false)

	self.filter = {}
	self.filterChosen = {}
	self.guideFilter = {}
	self.guideFilterChosen = {}
	self.filterNode = winTrans:NodeByName("middle/filter")
	self.guideFilterNode = winTrans:NodeByName("middle/guide_filter")
	local filterGroup = self.filterNode:NodeByName("filterGroup")
	local guideFilterGroup = self.guideFilterNode:NodeByName("filterGroup")

	for i = 1, xyd.GROUP_NUM do
		self.filter[i] = filterGroup:NodeByName("group" .. i).gameObject
		UIEventListener.Get(self.filter[i]).onClick = handler(self, function ()
			self:changeFilter(i)
		end)
		self.filterChosen[i] = filterGroup:NodeByName("group" .. i .. "/chosen").gameObject
		self.guideFilter[i] = guideFilterGroup:NodeByName("guide" .. i).gameObject
		UIEventListener.Get(self.guideFilter[i]).onClick = handler(self, function ()
			self:changeGuideFilter(i)
		end)
		self.guideFilterChosen[i] = guideFilterGroup:NodeByName("guide" .. i .. "/chosen").gameObject
	end

	self.sortBtn = self.filterNode:NodeByName("sortBtn").gameObject
	UIEventListener.Get(self.sortBtn).onClick = handler(self, self.onClickSortBtn)
	self.sortBtnCollider = self.sortBtn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.sortBtnArrow = self.sortBtn:NodeByName("arrow")
	self.sortBtnLable = self.sortBtn:ComponentByName("label", typeof(UILabel))
	self.sortBtnNew = self.filterNode:NodeByName("sortBtnNew").gameObject
	self.sortBtnNewLable = self.sortBtnNew:ComponentByName("label", typeof(UILabel))

	self:changeSortBtnNewLabel()

	UIEventListener.Get(self.sortBtnNew).onClick = handler(self, function ()
		print("sortType", self.sortType)
		xyd.WindowManager.get():openWindow("slot_sort_window", {
			sortType = self.sortType
		})
	end)
	self.sortPop = self.filterNode:NodeByName("sortPop").gameObject
	self.labelLev = self.sortPop:ComponentByName("tab_1/label", typeof(UILabel))
	self.labelQuality = self.sortPop:ComponentByName("tab_2/label", typeof(UILabel))

	for key, i in pairs(xyd.partnerSortType) do
		local j = i + 1
		self["label" .. tostring(j)] = self.sortPop:ComponentByName("tab_" .. tostring(j) .. "/label", typeof(UILabel))
		self["label" .. tostring(j)].text = __("SLOT_SORT" .. tostring(i))
	end

	self.jobSelectBtn = self.filterNode:NodeByName("jobSelectBtn").gameObject
	self.jobArrowUp = self.jobSelectBtn:NodeByName("jobArrowUp").gameObject
	self.jobArrowDown = self.jobSelectBtn:NodeByName("jobArrowDown").gameObject
	UIEventListener.Get(self.jobSelectBtn).onClick = handler(self, self.onJobSelectBtn)
	self.jobGroup = self.filterNode:NodeByName("jobGroup").gameObject
	self.job = {}
	self.jobChosen = {}

	for i = 1, xyd.PartnerJob.LENGTH do
		self.job[i] = self.jobGroup:NodeByName("group" .. i).gameObject
		UIEventListener.Get(self.job[i]).onClick = handler(self, function ()
			self:changeJobSelected(i)
		end)
		self.jobChosen[i] = self.jobGroup:NodeByName("group" .. i .. "/chosen").gameObject
	end

	self.guideJobSelectBtn = self.guideFilterNode:NodeByName("jobSelectBtn").gameObject
	self.guideJobArrowUp = self.guideJobSelectBtn:NodeByName("jobArrowUp").gameObject
	self.guideJobArrowDown = self.guideJobSelectBtn:NodeByName("jobArrowDown").gameObject
	UIEventListener.Get(self.guideJobSelectBtn).onClick = handler(self, self.onGuideJobSelectBtn)
	self.guideJobGroup = self.guideFilterNode:NodeByName("jobGroup").gameObject
	self.guideJob = {}
	self.guideJobChosen = {}

	for i = 1, xyd.PartnerJob.LENGTH do
		self.guideJob[i] = self.guideJobGroup:NodeByName("group" .. i).gameObject
		UIEventListener.Get(self.guideJob[i]).onClick = handler(self, function ()
			self:changeGuideJobSelected(i)
		end)
		self.guideJobChosen[i] = self.guideJobGroup:NodeByName("group" .. i .. "/chosen").gameObject
	end
end

function SlotWindow:initFixedMultiWrapContent(scrollView, wrapContent_, partnerCard, SlotPartnerCard)
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent_, partnerCard, SlotPartnerCard, self)
end

function SlotWindow:registerEvent()
	UIEventListener.Get(self.addSlotBtn).onClick = handler(self, self.addSlotSpace)
	self.topBar_ = CommonTabBar.new(self.nav, 2, function (index)
		local win = xyd.getWindow("slot_window")

		if not win then
			return
		end

		if index == 1 then
			xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
			self.guideFilterNode:SetActive(false)
			self.filterNode:SetActive(true)
			self.addSlotGroup:SetActive(true)
			self:updateDataGroup()

			self.groupSelectLabel.text = tonumber(self.chosenGroup) == 0 and "" or __("GROUP_" .. self.chosenGroup)
		else
			xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
			xyd.SoundManager.get():playSound(2128)
			self.guideFilterNode:SetActive(true)
			self.filterNode:SetActive(false)
			self.addSlotGroup:SetActive(false)
			self:updateDataGroup(true)

			self.groupSelectLabel.text = __("GROUP_" .. self.guideChosenGroup)
		end
	end)
	self.sortTab = CommonTabBar.new(self.sortPop, 11, function (index)
		self:changeSortType(index)
	end)

	self.eventProxy_:addEventListener(xyd.event.BUY_SLOT, function ()
		local slotNum = xyd.models.slot:getSlotNum()
		self.slotNum.text = tostring(#(self.sortedPartners[tostring(self.sortType) .. "_0"] or {})) .. "/" .. tostring(slotNum)
		local sequence = self:getSequence()
		local transform = self.slotNum.transform

		sequence:Append(transform:DOScale(Vector3(1.27, 1.27, 1), 0.2))
		sequence:Append(transform:DOScale(Vector3(1, 1, 1), 0.4))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			sequence = nil
		end)
	end)
	self.eventProxy_:addEventListener(xyd.event.VIP_CHANGE, function ()
		local slotNum = xyd.models.slot:getSlotNum()
		self.slotNum.text = tostring(#self.sortedPartners[tostring(self.sortType) .. "_0"]) .. "/" .. tostring(slotNum)
	end)
end

function SlotWindow:addSlotSpace()
	local mt = xyd.tables.miscTable
	local cost = xyd.split(mt:getVal("herobag_buy_new_cost"), "|")
	local buyTime = xyd.models.slot:getBuySlotTimes()
	cost = xyd.split(cost[buyTime + 1], "#", true)[2]
	local alertType = nil
	local message = ""
	local callback = nil

	if tonumber(mt:getVal("herobag_buy_limit")) <= buyTime then
		alertType = xyd.AlertType.TIPS
		message = __("FULL_BUY_SLOT_TIME")
	else
		alertType = xyd.AlertType.YES_NO
		message = __("OPEN_SLOT_TIPS", cost, mt:getVal("herobag_buy_num"))

		function callback(flag)
			if flag then
				if xyd.models.backpack:getCrystal() < cost then
					local message = __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL))

					xyd.alert(xyd.AlertType.TIPS, message)

					return
				end

				xyd.models.slot:buySlot()
			end
		end
	end

	xyd.alert(alertType, message, callback)
end

function SlotWindow:updateSlotNum()
	local slotNum = xyd.models.slot:getSlotNum()
	self.slotNum.text = tostring(xyd.models.slot:getPartnerNum()) .. "/" .. tostring(slotNum)
end

function SlotWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.top, self.name_, 5)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	if self.name_ == "slot_window" then
		self.windowTop:showQuickFormationBtn()

		self.quickFormationBtn = self.windowTop.quickFormationBtn
	end
end

function SlotWindow:addSortedPartners(sortedPartners, keyValue)
	if sortedPartners == nil then
		sortedPartners = xyd.models.slot:getSortedPartners()
	end

	if keyValue == nil then
		keyValue = self.sortType .. "_0"
	end

	for key in pairs(sortedPartners) do
		if tostring(key) == keyValue then
			local res = {}

			for _, partner_id in ipairs(sortedPartners[key]) do
				local params = {
					partner_id = partner_id,
					key = key,
					red_point = self:checkRedMark(partner_id)
				}

				table.insert(res, params)
			end

			self.sortedPartners[key] = res
		end
	end
end

function SlotWindow:initData()
	local p_model = xyd.models.slot
	local sortedPartners = p_model:getSortedPartners()

	self:addSortedPartners(sortedPartners)

	local slotNum = p_model:getSlotNum()
	self.slotNum.text = tostring(#sortedPartners[tostring(self.sortType) .. "_0"]) .. "/" .. tostring(slotNum)
	local guidePartners = {}
	local groupIds = xyd.tables.groupTable:getGroupIds()
	guidePartners[0] = {}

	for i = 1, xyd.GROUP_NUM do
		guidePartners[i] = {}

		for j = 1, #jobIds do
			guidePartners[jobIds[j] * 10 + i] = {}
		end
	end

	local heroConf = xyd.tables.partnerTable
	local heroIds = heroConf:getIds()

	for _, id in ipairs(heroIds) do
		local showInGuide = heroConf:getShowInGuide(id)

		if xyd.Global.isReview ~= 1 and showInGuide >= 1 and showInGuide < xyd.getServerTime() then
			local group = heroConf:getGroup(id)
			local job = heroConf:getJob(id)
			local key1 = group
			local param1 = {
				table_id = id,
				key = key1,
				parent = self
			}

			table.insert(guidePartners[key1], param1)
			self:checkGroup7GuidePartners(group, id, key1, guidePartners[key1])

			local key2 = job * 10 + group
			local param2 = {
				table_id = id,
				key = key2,
				parent = self
			}

			table.insert(guidePartners[key2], param2)
			self:checkGroup7GuidePartners(group, id, key2, guidePartners[key2])

			local key3 = 0
			local param3 = {
				table_id = id,
				key = tostring(key3),
				parent = self
			}

			table.insert(guidePartners[key3], param3)
			self:checkGroup7GuidePartners(group, id, key3, guidePartners[key3])
		elseif xyd.Global.isReview == 1 and heroConf:getShowInReviewGuide(id) == 1 then
			local group = heroConf:getGroup(id)
			local job = heroConf:getJob(id)

			table.insert(guidePartners[group], {
				table_id = id,
				key = job * 10 + group,
				parent = self
			})
			table.insert(guidePartners[job * 10 + group], {
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

	for i = 1, xyd.GROUP_NUM do
		guidePartners[i] = xyd.tableReverse(guidePartners[i])

		for j = 1, #jobIds do
			guidePartners[jobIds[j] * 10 + i] = xyd.tableReverse(guidePartners[jobIds[j] * 10 + i])
		end
	end

	self.guidePartners = guidePartners
end

function SlotWindow:checkGroup7GuidePartners(group, id, key, arr)
	if group == xyd.PartnerGroup.TIANYI then
		local parmTemp = {
			is_group7_ex_gallery = true,
			table_id = id,
			key = key,
			parent = self
		}

		table.insert(arr, parmTemp)
	end
end

function SlotWindow:initLayout()
	self.sortPop:SetActive(false)

	self.jobArrowState = true

	self.jobGroup:SetActive(false)

	for i = 1, xyd.PartnerJob.LENGTH do
		if i ~= self.currentJobId then
			self.jobChosen[i]:SetActive(false)
		else
			self.jobChosen[i]:SetActive(true)

			self.jobArrowState = false

			self.jobArrowUp:SetActive(false)
			self.jobArrowDown:SetActive(true)
			self.jobGroup:SetActive(true)
		end
	end

	self.guideJobArrowState = true

	self.guideJobGroup:SetActive(false)

	for i = 1, xyd.PartnerJob.LENGTH do
		if i ~= self.currentGuideJobId then
			self.guideJobChosen[i]:SetActive(false)
		else
			self.guideJobChosen[i]:SetActive(true)

			self.guideJobArrowState = false

			self.guideJobArrowUp:SetActive(false)
			self.guideJobArrowDown:SetActive(true)
			self.guideJobGroup:SetActive(true)
		end
	end

	if self.chosenGroup > 0 then
		self.filterChosen[self.chosenGroup]:SetActive(true)

		self.groupSelectLabel.text = __("GROUP_" .. self.chosenGroup)
	end

	self.guideFilterChosen[1]:SetActive(true)

	self.sortBtnLable.text = __("SORT")
	self.labelHero.text = __("PARTNER2")
	self.labelGuide.text = __("TUJIAN")
	self.labelLev.text = __("LEV")
	self.labelQuality.text = __("GRADE")
end

function SlotWindow:onClickSortBtn()
	self:moveSortPop()
end

function SlotWindow:onJobSelectBtn()
	if self.jobArrowState then
		self.jobArrowState = false

		self.jobArrowUp:SetActive(false)
		self.jobArrowDown:SetActive(true)
		self.jobGroup:SetActive(true)
	else
		self.jobArrowState = true

		self.jobArrowUp:SetActive(true)
		self.jobArrowDown:SetActive(false)
		self.jobGroup:SetActive(false)
	end
end

function SlotWindow:onGuideJobSelectBtn()
	if self.guideJobArrowState then
		self.guideJobArrowState = false

		self.guideJobArrowUp:SetActive(false)
		self.guideJobArrowDown:SetActive(true)
		self.guideJobGroup:SetActive(true)
	else
		self.guideJobArrowState = true

		self.guideJobArrowUp:SetActive(true)
		self.guideJobArrowDown:SetActive(false)
		self.guideJobGroup:SetActive(false)
	end
end

function SlotWindow:moveSortPop()
	local sequence2 = self:getSequence()
	local sortPopTrans = self.sortPop.transform
	local p = self.sortPop:GetComponent(typeof(UIPanel))
	local sortPopY = 92

	local function getter()
		return Color.New(1, 1, 1, p.alpha)
	end

	local function setter(color)
		p.alpha = color.a
	end

	if self.sortPop.activeSelf == true then
		self.sortBtnArrow.transform:SetLocalScale(1, 1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.067))
		sequence2:Insert(0.067, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0.1))
		sequence2:Insert(0.067, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0.1))
		sequence2:Insert(0.167, sortPopTrans:DOLocalMoveY(sortPopY, 0))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil

			self.sortPop:SetActive(false)
		end)
	else
		self.sortPop:SetActive(true)
		self.sortBtnArrow.transform:SetLocalScale(1, -1, 1)
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY - 58, 0))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
		sequence2:Insert(0, sortPopTrans:DOLocalMoveY(sortPopY + 17, 0.1))
		sequence2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
		sequence2:Insert(0.1, sortPopTrans:DOLocalMoveY(sortPopY, 0.2))
		sequence2:AppendCallback(function ()
			sequence2:Kill(false)

			sequence2 = nil
		end)
	end
end

function SlotWindow:changeSortType(index)
	local sortType = index - 1

	if sortType ~= self.sortType then
		self.sortType = sortType

		self:updateDataGroup()
		self:changeSortBtnNewLabel()
		xyd.db.misc:setValue({
			key = "slow_window_sort_type",
			value = self.sortType
		})
	end
end

function SlotWindow:changeSortBtnNewLabel()
	self.sortBtnNewLable.text = __("SLOT_SORT" .. self.sortType)

	if self.name_ == "activity_entrance_test_slot_window" and self.sortType == xyd.partnerSortType.SHENXUE then
		self.sortBtnNewLable.text = __("ENTRANCE_TEST_SORT")
	end
end

function SlotWindow:changeFilter(chosenGroup)
	if self.chosenGroup == chosenGroup then
		self.chosenGroup = 0
		self.groupSelectLabel.text = ""
	else
		self.chosenGroup = chosenGroup
		self.groupSelectLabel.text = tonumber(self.chosenGroup) == 0 and "" or __("GROUP_" .. chosenGroup)
	end

	for k, v in ipairs(self.filterChosen) do
		if k == self.chosenGroup then
			v:SetActive(true)
		else
			v:SetActive(false)
		end
	end

	self:updateDataGroup()
end

function SlotWindow:changeJobSelected(jobId)
	if self.currentJobId == jobId then
		self.currentJobId = 0
	else
		self.currentJobId = jobId
	end

	for i = 1, xyd.PartnerJob.LENGTH do
		if i == self.currentJobId then
			self.jobChosen[i]:SetActive(true)
		else
			self.jobChosen[i]:SetActive(false)
		end
	end

	self:updateDataGroup()
end

function SlotWindow:changeGuideFilter(guideChosenGroup)
	if self.guideChosenGroup == guideChosenGroup then
		return
	else
		self.guideChosenGroup = guideChosenGroup
		self.groupSelectLabel.text = __("GROUP_" .. tostring(guideChosenGroup))
	end

	for k, v in ipairs(self.guideFilterChosen) do
		if k == self.guideChosenGroup then
			v:SetActive(true)
		else
			v:SetActive(false)
		end
	end

	self:updateDataGroup(true)
end

function SlotWindow:changeGuideJobSelected(jobId)
	if self.currentGuideJobId == jobId then
		self.currentGuideJobId = 0
	else
		self.currentGuideJobId = jobId
	end

	for i = 1, xyd.PartnerJob.LENGTH do
		if i == self.currentGuideJobId then
			self.guideJobChosen[i]:SetActive(true)
		else
			self.guideJobChosen[i]:SetActive(false)
		end
	end

	self:updateDataGroup(true)
end

function SlotWindow:updateDataGroup(isGuide, isEvent)
	if isGuide then
		local guidePartners = self.guidePartners[self.currentGuideJobId * 10 + self.guideChosenGroup]
		local collection = xyd.models.slot:getCollection()
		local exGallery = xyd.models.slot:getExGallery()
		local guideNum = 0

		for i = 1, #guidePartners do
			if guidePartners[i].is_group7_ex_gallery == nil and collection[guidePartners[i].table_id] then
				guideNum = guideNum + 1
			elseif guidePartners[i].is_group7_ex_gallery == true and xyd.arrayIndexOf(exGallery, guidePartners[i].table_id) > 0 then
				guideNum = guideNum + 1
			end
		end

		self.guideNum.text = guideNum .. "/" .. #guidePartners

		self.multiWrap_:setInfos(guidePartners, {})
		self.partnerNone:SetActive(false)

		if #guidePartners <= 0 then
			self.partnerNone:SetActive(true)

			self.labelNoneTips.text = __("NO_PARTNER_2")
		end

		self.guideNum:SetActive(true)
		self.guideNumLabel:SetActive(true)
	else
		self.guideNum:SetActive(false)
		self.guideNumLabel:SetActive(false)

		local key = nil

		if self.currentJobId == 0 then
			key = tostring(self.sortType) .. "_" .. tostring(self.chosenGroup)
		else
			key = tostring(self.sortType) .. "_" .. tostring(self.chosenGroup) .. "_" .. tostring(self.currentJobId)
		end

		if self.name_ == "activity_entrance_test_slot_window" then
			key = tostring(self.sortType) .. "_" .. tostring(self.chosenGroup) .. "_" .. tostring(self.currentJobId)
		end

		if self.sortedPartners[key] == nil then
			self:addSortedPartners(nil, key)
		end

		self.multiWrap_:setInfos(self.sortedPartners[key], {})

		if #self.sortedPartners[key] <= 0 then
			self.partnerNone:SetActive(true)

			self.labelNoneTips.text = __("NO_PARTNER_2")
		else
			self.partnerNone:SetActive(false)
		end
	end
end

function SlotWindow:updateByDetailWnd(params)
	local key = tostring(self.sortType) .. "_" .. tostring(self.chosenGroup)

	if self.currentJobId ~= 0 then
		key = tostring(self.sortType) .. "_" .. tostring(self.chosenGroup) .. "_" .. tostring(self.currentJobId)
	end

	self.sortedPartners = {}

	if self.sortedPartners[key] == nil then
		self:addSortedPartners(nil, key)
	end

	self.multiWrap_:setInfos(self.sortedPartners[key], {
		keepPosition = true
	})
end

function SlotWindow:playOpenAnimation(callback)
	if callback then
		callback()
	end

	self.middle:X(-1000)
	self:waitForTime(0.2, function ()
		self.isPlayOpenAnimation = true
		local sequence = self:getSequence()

		sequence:Append(self.middle.transform:DOLocalMoveX(50, 0.3):SetEase(DG.Tweening.Ease.InOutSine))
		sequence:Append(self.middle.transform:DOLocalMoveX(0, 0.27):SetEase(DG.Tweening.Ease.InOutSine))
		sequence:AppendCallback(handler(self, function ()
			sequence:Kill(false)

			sequence = nil

			self:setWndComplete()
			self:endOpenAnimation()
		end))
	end, nil)
end

function SlotWindow:endOpenAnimation()
	self.isPlayOpenAnimation = false
end

function SlotWindow:willCloseAnimation(callback)
	local sequence = self:getSequence()

	sequence:Append(self.middle.transform:DOLocalMoveX(50, 0.14):SetEase(DG.Tweening.Ease.InOutSine))
	sequence:Append(self.middle.transform:DOLocalMoveX(-1000, 0.15):SetEase(DG.Tweening.Ease.InOutSine))
	sequence:AppendCallback(handler(self, function ()
		sequence:Kill(false)

		sequence = nil

		if callback then
			callback()
		end
	end))
end

function SlotWindow:dispose()
	SlotWindow.super.dispose(self)
end

function SlotWindow:checkRedMark(partnerId)
	local res1 = xyd.checkPartnerRedMark(partnerId, xyd.RedMarkType.NEW_FIVE_STAR)
	local res2 = xyd.checkPartnerRedMark(partnerId, xyd.RedMarkType.PROMOTABLE_PARTNER)
	local res3 = xyd.checkPartnerRedMark(partnerId, xyd.RedMarkType.AVAILABLE_EQUIPMENT)

	if res1 ~= nil and res1 == true or res2 ~= nil and res2 == true or res3 ~= nil and res3 == true then
		return true
	else
		return false
	end
end

function SlotWindow:iosTestChangeUI()
	local winTrans = self.window_

	winTrans:ComponentByName("imgBg/bg_", typeof(UISprite)):SetActive(false)
	winTrans:ComponentByName("imgBg/bg2_", typeof(UISprite)):SetActive(false)

	local iosBG = NGUITools.AddChild(winTrans, "iosBG"):AddComponent(typeof(UITexture))
	iosBG.height = winTrans:GetComponent(typeof(UIPanel)).height
	iosBG.width = winTrans:GetComponent(typeof(UIPanel)).width

	xyd.setUITexture(iosBG, "Textures/texture_ios/bg_ios_test")

	for i = 1, 2 do
		xyd.setUISprite(self.nav:ComponentByName("tab_" .. i .. "/chosen", typeof(UISprite)), nil, "nav_btn_blue_ios_test")
		xyd.setUISprite(self.nav:ComponentByName("tab_" .. i .. "/unchosen", typeof(UISprite)), nil, "nav_btn_white_ios_test")
	end

	local allChildren = self.middle:GetComponentsInChildren(typeof(UISprite), true)

	for i = 0, allChildren.Length - 1 do
		local sprite = allChildren[i]

		xyd.setUISprite(sprite, nil, sprite.spriteName .. "_ios_test")
	end
end

return SlotWindow
