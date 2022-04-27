local FairArenaCollectionWindow = class("FairArenaCollectionWindow", import(".BaseWindow"))
local FairPartnerCard = class("FairPartnerCard")
local FairItemNode = class("FairItemNode")
local Partner = import("app.models.Partner")
local ItemIcon = import("app.components.ItemIcon")
local PartnerCard = import("app.components.PartnerCard")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function FairArenaCollectionWindow:ctor(name, params)
	FairArenaCollectionWindow.super.ctor(self, name, params)

	local select = xyd.db.misc:getValue("fair_arena_collection_select") or 1
	self.select = tonumber(select)

	if params then
		self.select = params.select
	end

	local flag = xyd.db.misc:getValue("fair_arena_collection_redpoint")

	if not flag then
		xyd.db.misc:setValue({
			key = "fair_arena_collection_redpoint",
			value = xyd.getServerTime()
		})

		local win = xyd.getWindow("fair_arena_entry_window")

		if win then
			win:updateRedMark()
		end
	end
end

function FairArenaCollectionWindow:initWindow()
	FairArenaCollectionWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initData()
	self:updateContent(self.select)
	self:register()
end

function FairArenaCollectionWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.tipsLabel_ = winTrans:ComponentByName("tipsLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.nav = winTrans:NodeByName("nav").gameObject
	local mainGroup = winTrans:NodeByName("mainGroup")
	self.partnerGroup = mainGroup:NodeByName("partnerGroup").gameObject
	self.scrollView1 = self.partnerGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup1 = self.partnerGroup:NodeByName("scrollView/itemGroup").gameObject
	self.partnerNode = self.partnerGroup:NodeByName("scrollView/partnerNode").gameObject
	local partnerFilter = self.partnerGroup:NodeByName("filter")
	local partnerFilterGroup = partnerFilter:NodeByName("filterGroup")
	self.partnerFilterChosen = {}

	for i = 1, 6 do
		local filter = partnerFilterGroup:NodeByName("group" .. i).gameObject
		UIEventListener.Get(filter).onClick = handler(self, function ()
			self:onPartnerGroupFilter(i, true)
		end)
		self.partnerFilterChosen[i] = filter:NodeByName("chosen").gameObject
	end

	self.partnerSortBtn = partnerFilter:NodeByName("sortBtnNew").gameObject
	self.partnerSortLable = self.partnerSortBtn:ComponentByName("label", typeof(UILabel))
	self.jobSelectBtn = partnerFilter:NodeByName("jobSelectBtn").gameObject
	self.jobSelectSprite = self.jobSelectBtn:GetComponent(typeof(UISprite))
	self.jobFilterGroup = partnerFilter:NodeByName("jobGroup").gameObject
	self.jobFilterChosen = {}

	for i = 1, xyd.PartnerJob.LENGTH do
		local filter = self.jobFilterGroup:NodeByName("group" .. i).gameObject
		UIEventListener.Get(filter).onClick = handler(self, function ()
			self:onPartnerJobFilter(i, true)
		end)
		self.jobFilterChosen[i] = filter:NodeByName("chosen").gameObject
	end

	self.artifactGroup = mainGroup:NodeByName("artifactGroup").gameObject
	self.scrollView2 = self.artifactGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup2 = self.artifactGroup:NodeByName("scrollView/itemGroup").gameObject
	self.itemNode = self.artifactGroup:NodeByName("scrollView/itemNode").gameObject
	local artifactFilter = self.artifactGroup:NodeByName("filter")
	local artifactFilterGroup = artifactFilter:NodeByName("filterGroup")
	self.artifactFilterChosen = {}

	for i = 1, 6 do
		local filter = artifactFilterGroup:NodeByName("group" .. i).gameObject
		UIEventListener.Get(filter).onClick = handler(self, function ()
			self:onArtifactGroupFilter(i, true)
		end)
		self.artifactFilterChosen[i] = filter:NodeByName("chosen").gameObject
	end

	self.NoneGroup = mainGroup:NodeByName("NoneGroup").gameObject
	self.labelNoneTips = self.NoneGroup:ComponentByName("labelNoneTips", typeof(UILabel))
end

function FairArenaCollectionWindow:initUIComponent()
	self.titleLabel_.text = __("FAIR_ARENA_COLLECTION")
	self.tipsLabel_.text = __("FAIR_ARENA_DESC_USE_ONLY")
	self.partnerSortLable.text = __("SORT")
	self.navGroup = CommonTabBar.new(self.nav, 2, function (index)
		if self.navFlag then
			self:updateContent(index)
		end

		self.navFlag = true
	end)

	self.navGroup:setTexts({
		__("PARTNER"),
		__("ARTIFACT")
	})
	self:waitForFrame(1, function ()
		self.navGroup:setTabActive(self.select, true)
	end)
end

function FairArenaCollectionWindow:initData()
	local PartnerBoxTable = xyd.tables.activityFairArenaBoxPartnerTable
	local ArtifactBoxTable = xyd.tables.activityFairArenaBoxEquipTable
	self.partners = {}
	self.artifactMap = ArtifactBoxTable:getIDs()
	local ids = PartnerBoxTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local p = Partner.new()

		p:populate({
			isHeroBook = true,
			table_id = PartnerBoxTable:getPartnerID(id),
			lev = PartnerBoxTable:getLv(id),
			grade = PartnerBoxTable:getGrade(id),
			equips = PartnerBoxTable:getEquips(id)
		})

		p.box_id = id
		p.isNew = PartnerBoxTable:checkIsNew(id) == 1
		p.isUp = PartnerBoxTable:checkIsUp(id) == 1

		table.insert(self.partners, p)
	end

	self.artifacts = {}
	local ids = ArtifactBoxTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local equipId = ArtifactBoxTable:getEquipID(id)

		table.insert(self.artifacts, equipId)
	end

	self.pAttrSort = xyd.partnerSortType.PARTNER_ID
	self.pGroupSort = 0
	self.pJobSort = 0
	self.aQualitySort = 0
	local lastPartnerSort1 = tonumber(xyd.db.misc:getValue("fair_arena_collection_partner_attr_sort")) or 2
	local lastPartnerSort2 = tonumber(xyd.db.misc:getValue("fair_arena_collection_partner_group_sort")) or 0
	local lastPartnerSort3 = tonumber(xyd.db.misc:getValue("fair_arena_collection_partner_job_sort")) or 0
	local lastArtifactSort = tonumber(xyd.db.misc:getValue("fair_arena_collection_artifact_group_sort")) or 0

	self:onPartnerAttrFilter(tonumber(lastPartnerSort1))
	self:onPartnerGroupFilter(tonumber(lastPartnerSort2))
	self:onPartnerJobFilter(tonumber(lastPartnerSort3))
	self:onArtifactGroupFilter(tonumber(lastArtifactSort))

	self.jobSelect = self.pJobSort == 0

	self:onJobSelectBtn()
end

function FairArenaCollectionWindow:updateContent(index)
	local collection = self:getCollection(index)

	if index == 1 then
		self.partnerGroup:SetActive(true)
		self.artifactGroup:SetActive(false)

		if not self.partnerWrapContent then
			local wrapContent = self.itemGroup1:GetComponent(typeof(MultiRowWrapContent))
			self.partnerWrapContent = FixedMultiWrapContent.new(self.scrollView1, wrapContent, self.partnerNode, FairPartnerCard, self)
		end

		self.partnerWrapContent:setInfos(collection, {})

		self.labelNoneTips.text = __("NO_PARTNER_2")
		self.partnerList = collection
	else
		self.partnerGroup:SetActive(false)
		self.artifactGroup:SetActive(true)

		if not self.artifactWrapContent then
			local wrapContent = self.itemGroup2:GetComponent(typeof(MultiRowWrapContent))
			self.artifactWrapContent = FixedMultiWrapContent.new(self.scrollView2, wrapContent, self.itemNode, FairItemNode, self)
		end

		self.artifactWrapContent:setInfos(collection, {})

		self.labelNoneTips.text = __("NO_ARTIFACT")
	end

	if #collection == 0 then
		self.NoneGroup:SetActive(true)
	else
		self.NoneGroup:SetActive(false)
	end

	xyd.db.misc:setValue({
		key = "fair_arena_collection_select",
		value = tostring(index)
	})
end

function FairArenaCollectionWindow:register()
	FairArenaCollectionWindow.super.register(self)

	UIEventListener.Get(self.jobSelectBtn).onClick = handler(self, self.onJobSelectBtn)
	UIEventListener.Get(self.partnerSortBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_collection_sort_window", {
			sortType = self.pAttrSort
		})
	end)
end

function FairArenaCollectionWindow:onPartnerAttrFilter(index, canFresh)
	if index == xyd.partnerSortType.PARTNER_ID then
		self.pAttrSort = xyd.partnerSortType.PARTNER_ID
		self.partnerSortLable.text = __("SORT")
	else
		self.pAttrSort = index
		self.partnerSortLable.text = __("SLOT_SORT" .. index)
	end

	if canFresh then
		self:updateContent(1)
		xyd.db.misc:setValue({
			key = "fair_arena_collection_partner_attr_sort",
			value = tostring(self.pAttrSort)
		})
	end
end

function FairArenaCollectionWindow:onPartnerGroupFilter(chosenGroup, canFresh)
	if self.pGroupSort == chosenGroup then
		self.pGroupSort = 0
	else
		self.pGroupSort = chosenGroup
	end

	for k, v in ipairs(self.partnerFilterChosen) do
		if k == self.pGroupSort then
			v:SetActive(true)
		else
			v:SetActive(false)
		end
	end

	if canFresh then
		self:updateContent(1)
		xyd.db.misc:setValue({
			key = "fair_arena_collection_partner_group_sort",
			value = tostring(self.pGroupSort)
		})
	end
end

function FairArenaCollectionWindow:onPartnerJobFilter(jobId, canFresh)
	if self.pJobSort == jobId then
		self.pJobSort = 0
	else
		self.pJobSort = jobId
	end

	for i = 1, xyd.PartnerJob.LENGTH do
		if i == self.pJobSort then
			self.jobFilterChosen[i]:SetActive(true)
		else
			self.jobFilterChosen[i]:SetActive(false)
		end
	end

	if canFresh then
		self:updateContent(1)
		xyd.db.misc:setValue({
			key = "fair_arena_collection_partner_job_sort",
			value = tostring(self.pJobSort)
		})
	end
end

function FairArenaCollectionWindow:onJobSelectBtn()
	self.jobSelect = not self.jobSelect

	if self.jobSelect then
		xyd.setUISpriteAsync(self.jobSelectSprite, nil, "btn_sq")
		self.jobFilterGroup:SetActive(true)
	else
		xyd.setUISpriteAsync(self.jobSelectSprite, nil, "btn_zk")
		self.jobFilterGroup:SetActive(false)
	end
end

function FairArenaCollectionWindow:onArtifactGroupFilter(chosenGroup, canFresh)
	if self.aQualitySort == chosenGroup then
		self.aQualitySort = 0
	else
		self.aQualitySort = chosenGroup
	end

	for k, v in ipairs(self.artifactFilterChosen) do
		if k == self.aQualitySort then
			v:SetActive(true)
		else
			v:SetActive(false)
		end
	end

	if canFresh then
		self:updateContent(2)
		xyd.db.misc:setValue({
			key = "fair_arena_collection_artifact_group_sort",
			value = tostring(self.aQualitySort)
		})
	end
end

function FairArenaCollectionWindow:getCollection(index)
	local collection = {}

	if index == 1 then
		local attr = tonumber(self.pAttrSort)
		local group = tonumber(self.pGroupSort)
		local job = tonumber(self.pJobSort)

		for i = 1, #self.partners do
			local p = self.partners[i]

			if (group == 0 or group == p:getGroup()) and (job == 0 or job == p:getJob()) then
				table.insert(collection, p)
			end
		end

		self:sortPartners(collection, attr)
	else
		local quality = self.aQualitySort

		for i = 1, #self.artifacts do
			local id = self.artifacts[i]

			if quality == 0 or quality == xyd.tables.equipTable:getQuality(id) then
				table.insert(collection, id)
			end
		end

		table.sort(collection)
	end

	return collection
end

function FairArenaCollectionWindow:sortPartners(collection, attr)
	local sortFunc = nil

	if attr == xyd.partnerSortType.PARTNER_ID then
		function sortFunc(a, b)
			return b.box_id < a.box_id
		end
	elseif attr == xyd.partnerSortType.POWER then
		function sortFunc(a, b)
			return b:getPower() < a:getPower()
		end
	elseif attr == xyd.partnerSortType.ATK then
		function sortFunc(a, b)
			local key_a = a:getBattleAttrs().atk
			local key_b = b:getBattleAttrs().atk

			if key_a ~= key_b then
				return key_b < key_a
			else
				return b.box_id < a.box_id
			end
		end
	elseif attr == xyd.partnerSortType.HP then
		function sortFunc(a, b)
			local key_a = a:getBattleAttrs().hp
			local key_b = b:getBattleAttrs().hp

			if key_a ~= key_b then
				return key_b < key_a
			else
				return b.box_id < a.box_id
			end
		end
	elseif attr == xyd.partnerSortType.ARM then
		function sortFunc(a, b)
			local key_a = a:getBattleAttrs().arm
			local key_b = b:getBattleAttrs().arm

			if key_a ~= key_b then
				return key_b < key_a
			else
				return b.box_id < a.box_id
			end
		end
	elseif attr == xyd.partnerSortType.SPD then
		function sortFunc(a, b)
			local key_a = a:getBattleAttrs().spd
			local key_b = b:getBattleAttrs().spd

			if key_a ~= key_b then
				return key_b < key_a
			else
				return b.box_id < a.box_id
			end
		end
	end

	return table.sort(collection, sortFunc)
end

function FairArenaCollectionWindow:getPartnerList()
	return self.partnerList or {}
end

function FairArenaCollectionWindow:setPartnerAttrSort(sortType)
	if sortType ~= self.pAttrSort then
		self:onPartnerAttrFilter(sortType, true)
	end
end

function FairPartnerCard:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.partnerCard = PartnerCard.new(go, parent.renderPanel)

	self:init()
end

function FairPartnerCard:init()
	self.go:SetLocalScale(0.92, 0.92, 0.92)
	self.partnerCard.go:Y(-10)

	UIEventListener.Get(self.go).onClick = handler(self, function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if not self.data then
			return
		end

		xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
			isCollection = true,
			partner = self.data,
			list = self.parent:getPartnerList()
		})
	end)
end

function FairPartnerCard:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function FairPartnerCard:updateInfo()
	if self.data then
		self.isNew = self.data.isNew or false
		self.isUp = self.data.isUp or false

		self.partnerCard:setInfo(nil, self.data)

		if self.isNew then
			self.partnerCard:setNewIcon(self.isNew)
		else
			self.partnerCard:setUpIcon(self.isUp)
		end
	end
end

function FairPartnerCard:getGameObject()
	return self.go
end

function FairItemNode:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ItemIcon.new(go)

	self.item.go:Y(-10)
end

function FairItemNode:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function FairItemNode:updateInfo()
	if self.data then
		self.item:setInfo({
			uiRoot = self.go,
			itemID = self.data,
			dragScrollView = self.parent.scrollView2
		})
	end
end

function FairItemNode:getGameObject()
	return self.go
end

return FairArenaCollectionWindow
