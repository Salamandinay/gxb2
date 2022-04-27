local TavernMultimissionWindow = class("TavernMultimissionWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local FixedWrapContentItem = import("app.common.ui.FixedWrapContentItem")
local MissionItem = class("MissionItem", FixedWrapContentItem)
local CompleteItem = class("CompleteItem", FixedWrapContentItem)
local HeroIcon = import("app.components.HeroIcon")
local ItemIcon = import("app.components.ItemIcon")
local missionStatus = {
	UN_DO = 0,
	DOING = 1,
	DONE = 2
}
local tavernModel = xyd.models.tavern
local slotModel = xyd.models.slot
local pubMissionTable = xyd.tables.pubMissionTable
local maxMissions = tonumber(xyd.tables.miscTable:getVal("pub_mission_max"))

function TavernMultimissionWindow:ctor(name, params)
	TavernMultimissionWindow.super.ctor(self, name, params)

	self.choosenList = {}

	for i = 1, 7 do
		self.choosenList[i] = false
	end

	if params and params.chooseType then
		self.choosenList[params.chooseType] = true
	end

	self.state = params.state
	self.missionIDToSelectd = {}

	if self.state == "mission" then
		self:initMissionList()
	elseif self.state == "complete" then
		self:initCompleteList()
	end
end

function TavernMultimissionWindow:initCompleteList()
	self.completeList = {}
	local missionIDs = tavernModel:getMissions()

	for _, missionID in ipairs(missionIDs) do
		local mission = tavernModel:getMissionById(missionID)

		if mission.status == missionStatus.DONE then
			local star = xyd.tables.pubMissionTable:getStar(mission.table_id)
			self.completeList[star] = self.completeList[star] or {}

			table.insert(self.completeList[star], missionID)

			self.missionIDToSelectd[missionID] = false
		end
	end
end

function TavernMultimissionWindow:initMissionList()
	self.missionListByStar = {}
	self.doingOrDoneMissions = 0
	local missionIDs = tavernModel:getMissions()

	for _, missionID in ipairs(missionIDs) do
		local mission = tavernModel:getMissionById(missionID)

		if mission.status == missionStatus.UN_DO then
			local star = xyd.tables.pubMissionTable:getStar(mission.table_id)
			self.missionListByStar[star] = self.missionListByStar[star] or {}

			table.insert(self.missionListByStar[star], missionID)

			self.missionIDToSelectd[missionID] = true
		else
			self.doingOrDoneMissions = self.doingOrDoneMissions + 1
		end
	end

	for _, list in pairs(self.missionListByStar) do
		table.sort(list, function (a, b)
			local missionA = tavernModel:getMissionById(a)
			local missionB = tavernModel:getMissionById(b)

			if missionA.award[1] ~= missionB.award[1] then
				return missionB.award[1] < missionA.award[1]
			elseif missionA.award[2] ~= missionB.award[2] then
				return missionB.award[2] < missionA.award[2]
			else
				return missionA.name < missionB.name
			end

			return true
		end)
	end
end

function TavernMultimissionWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function TavernMultimissionWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.btnSure = groupAction:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
	self.btnSelectAll = groupAction:NodeByName("btnSelectAll").gameObject
	self.labelSelectAll = self.btnSelectAll:ComponentByName("button_label", typeof(UILabel))
	local chooseGroup = groupAction:NodeByName("choosePart/btnContent").gameObject
	self.chooseGoList = {}

	for i = 1, 7 do
		local root = chooseGroup:NodeByName(tostring(i)).gameObject

		table.insert(self.chooseGoList, {
			mask = root:NodeByName("mask").gameObject,
			btnIcon = root:NodeByName("btnIcon").gameObject,
			chosen = root:NodeByName("chosen").gameObject
		})
	end

	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("groupContent", typeof(UIWrapContent))
	local missionItem = groupAction:NodeByName("missionItem").gameObject
	local completeItem = groupAction:NodeByName("completeItem").gameObject

	if self.state == "mission" then
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, missionItem, MissionItem, self)

		completeItem:SetActive(false)
	else
		missionItem:SetActive(false)

		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, completeItem, CompleteItem, self)
	end

	self.groupNone_ = groupAction:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
end

function TavernMultimissionWindow:layout()
	self.labelTitle.text = self.state == "mission" and __("PUB_MISSION_AUTO_TEXT02") or __("PUB_MISSION_AUTO_TEXT4")
	self.labelSure.text = __("SURE")
	self.labelNoneTips_.text = self.state == "mission" and __("PUB_MISSION_AUTO_TEXT01") or __("PUB_MISSION_AUTO_TEXT2")

	for i = 1, 7 do
		self.chooseGoList[i].mask:SetActive(self.choosenList[i])
		self.chooseGoList[i].chosen:SetActive(self.choosenList[i])
	end

	self:updateContent()
	self:updateSelectAllBtn()
	self:updateWinTitle()
end

function TavernMultimissionWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	for i = 1, 7 do
		UIEventListener.Get(self.chooseGoList[i].btnIcon).onClick = function ()
			self.choosenList[i] = not self.choosenList[i]

			self.chooseGoList[i].mask:SetActive(self.choosenList[i])
			self.chooseGoList[i].chosen:SetActive(self.choosenList[i])
			self:updateContent()
			self:updateSelectAllBtn()
			self:updateWinTitle()
		end
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		if self.state == "mission" then
			self:goToMission()
			self:close()
		else
			self:goToComplete()
		end
	end

	UIEventListener.Get(self.btnSelectAll).onClick = function ()
		self:onClickSelectAllBtn()
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		local key = self.state == "mission" and "PUB_MISSION_AUTO_HELP" or "PUB_MISSION_AUTO_HELP2"

		xyd.WindowManager.get():openWindow("help_window", {
			key = key
		})
	end
end

function TavernMultimissionWindow:goToMission()
	local missionList = {}

	for _, item in ipairs(self.contentList) do
		if item.selected then
			table.insert(missionList, {
				missionID = item.missionID,
				partners = item.partners
			})
		end
	end

	if #missionList > 0 then
		tavernModel:startMultiMissions(missionList)
	end
end

function TavernMultimissionWindow:goToComplete()
	local missionList = {}
	local hasHigh = false

	for _, item in ipairs(self.contentList) do
		if item.selected then
			table.insert(missionList, item.missionID)

			if not hasHigh then
				local mission = tavernModel:getMissionById(item.missionID)
				local star = pubMissionTable:getStar(mission.table_id)
				hasHigh = star > 5
			end
		end
	end

	if #missionList > 0 then
		if hasHigh then
			xyd.alert(xyd.AlertType.YES_NO, __("PUB_MISSION_AUTO_TEXT3"), function (yes)
				if yes then
					tavernModel:completeMultiMission(missionList)
					self:close()
				end
			end)
		else
			tavernModel:completeMultiMission(missionList)
			self:close()
		end
	else
		self:close()
	end
end

function TavernMultimissionWindow:updateContent()
	if self.state == "mission" then
		self:getContentList()
	else
		self:getCompleteList()
	end

	self.wrapContent:setInfos(self.contentList, {})
	self.groupNone_:SetActive(#self.contentList == 0)
end

function TavernMultimissionWindow:getCompleteList()
	self.contentList = {}
	local choosenStars = {}

	for i = 7, 1, -1 do
		if self.choosenList[i] then
			table.insert(choosenStars, i)
		end
	end

	if #choosenStars == 0 then
		choosenStars = {
			7,
			6,
			5,
			4,
			3,
			2,
			1
		}
	end

	for _, star in ipairs(choosenStars) do
		local list = self.completeList[star] or {}

		for _, missionID in ipairs(list) do
			table.insert(self.contentList, {
				missionID = missionID,
				selected = self.missionIDToSelectd[missionID]
			})
		end
	end
end

function TavernMultimissionWindow:getContentList()
	self.contentList = {}

	if maxMissions <= self.doingOrDoneMissions then
		return
	end

	local willDoing = 0
	local choosenStars = {}

	for i = 7, 1, -1 do
		if self.choosenList[i] then
			table.insert(choosenStars, i)
		end
	end

	if #choosenStars == 0 then
		choosenStars = {
			7,
			6,
			5,
			4,
			3,
			2,
			1
		}
	end

	self.choosenPartnersNum = 0
	self.choosenPartners = self:getSelectedPartners()

	for _, star in ipairs(choosenStars) do
		local missionIDs = self.missionListByStar[star]

		if missionIDs and #missionIDs > 0 then
			for _, missionID in ipairs(missionIDs) do
				local flag, tmpPartners = self:checkCanStartMission(missionID)

				if flag then
					local partners = {}

					for partnerId in pairs(tmpPartners) do
						table.insert(partners, partnerId)

						self.choosenPartners[partnerId] = true
						self.choosenPartnersNum = self.choosenPartnersNum + 1
					end

					table.insert(self.contentList, {
						missionID = missionID,
						partners = partners,
						selected = self.missionIDToSelectd[missionID]
					})

					willDoing = willDoing + 1
				end

				if maxMissions <= self.doingOrDoneMissions + willDoing then
					return
				end
			end
		end
	end
end

function TavernMultimissionWindow:checkCanStartMission(missionID)
	local mission = tavernModel:getMissionById(missionID)
	local needNum = pubMissionTable:getPartnerNum(mission.table_id)
	local partnerStar = pubMissionTable:getPartnerStar(mission.table_id)
	local sortPartners = slotModel:getSortedPartners()
	local allStarPartners = sortPartners[xyd.partnerSortType.STAR .. "_0"] or {}
	local conditions = {
		job = {},
		group = {}
	}

	for _, id in ipairs(mission.conditions) do
		local job = xyd.tables.pubConditionTable:getJob(id)
		local group = xyd.tables.pubConditionTable:getGroup(id)

		if job > 0 then
			table.insert(conditions.job, job)
		end

		if group > 0 then
			table.insert(conditions.group, group)
		end
	end

	local tmpPartners = {}
	local tmpPartnersNum = 0
	local flag = nil

	if partnerStar > 0 then
		flag = false

		for i = #allStarPartners, 1, -1 do
			local partnerID = allStarPartners[i]

			if not self.choosenPartners[partnerID] then
				local partner = slotModel:getPartner(partnerID)
				local star = partner:getStar()

				if partnerStar <= star then
					tmpPartners[partnerID] = true
					flag = true
					tmpPartnersNum = tmpPartnersNum + 1

					break
				end
			end
		end

		if not flag then
			return flag
		end
	end

	for _, group in ipairs(conditions.group) do
		local partnerList = sortPartners[xyd.partnerSortType.STAR .. "_" .. group] or {}
		flag = false

		for i = #partnerList, 1, -1 do
			local partnerID = partnerList[i]

			if not self.choosenPartners[partnerID] and not tmpPartners[partnerID] then
				tmpPartners[partnerID] = true
				flag = true
				tmpPartnersNum = tmpPartnersNum + 1

				break
			end
		end

		if not flag then
			return flag
		end
	end

	for _, job in ipairs(conditions.job) do
		local partnerList = sortPartners[xyd.partnerSortType.STAR .. "_0_" .. job] or {}
		flag = false

		for i = #partnerList, 1, -1 do
			local partnerID = partnerList[i]

			if not self.choosenPartners[partnerID] and not tmpPartners[partnerID] then
				tmpPartners[partnerID] = true
				flag = true
				tmpPartnersNum = tmpPartnersNum + 1

				break
			end
		end

		if not flag then
			return flag
		end
	end

	if tmpPartnersNum < needNum then
		for i = #allStarPartners, 1, -1 do
			local partnerID = allStarPartners[i]

			if not self.choosenPartners[partnerID] and not tmpPartners[partnerID] then
				tmpPartners[partnerID] = true
				tmpPartnersNum = tmpPartnersNum + 1
			end

			if tmpPartnersNum == needNum then
				break
			end
		end

		if tmpPartnersNum < needNum then
			return false
		end
	end

	return true, tmpPartners
end

function TavernMultimissionWindow:getSelectedPartners()
	local list = {}
	local partners = tavernModel:getPartners()

	for _, id in ipairs(partners) do
		list[id] = true
		self.choosenPartnersNum = self.choosenPartnersNum + 1
	end

	return list
end

function TavernMultimissionWindow:changeMissionSelected(missionID, flag)
	self.missionIDToSelectd[missionID] = flag

	self:updateWinTitle()
end

function TavernMultimissionWindow:updateSelectAllBtn()
	self.isSelectAll = true

	if self.contentList and #self.contentList > 0 then
		for _, info in ipairs(self.contentList) do
			if info.selected == false then
				self.isSelectAll = false

				break
			end
		end
	else
		self.isSelectAll = false
	end

	if self.isSelectAll == false then
		self.labelSelectAll.text = __("SELECT_ALL_YES")

		xyd.setBgColorType(self.btnSelectAll, xyd.ButtonBgColorType.blue_btn_60_60)
	else
		self.labelSelectAll.text = __("SELECT_ALL_NO")

		xyd.setBgColorType(self.btnSelectAll, xyd.ButtonBgColorType.white_btn_60_60)
	end
end

function TavernMultimissionWindow:onClickSelectAllBtn()
	if self.contentList and #self.contentList > 0 then
		self.isSelectAll = not self.isSelectAll

		for _, info in ipairs(self.contentList) do
			info.selected = self.isSelectAll
			self.missionIDToSelectd[info.missionID] = self.isSelectAll
		end

		self:updateSelectAllBtn()
		self.wrapContent:setInfos(self.contentList, {})
		self:updateWinTitle()
	else
		xyd.alert(xyd.AlertType.TIPS, __("SELECT_ALL_TEXT01"))
	end
end

function TavernMultimissionWindow:updateWinTitle()
	local titleText = self.state == "mission" and __("PUB_MISSION_AUTO_TEXT02") or __("PUB_MISSION_AUTO_TEXT4")
	local totalMissionNum = 0
	local selectedMissionNum = 0

	if self.contentList and #self.contentList > 0 then
		for _, info in ipairs(self.contentList) do
			totalMissionNum = totalMissionNum + 1

			if info.selected == true then
				selectedMissionNum = selectedMissionNum + 1
			end
		end
	end

	self.labelTitle.text = titleText .. "(" .. selectedMissionNum .. "/" .. totalMissionNum .. ")"
end

function CompleteItem:initUI()
	self.starBg = self.go:ComponentByName("starBg", typeof(UISprite))
	self.gridOfStar = self.starBg:ComponentByName("gridOfStar", typeof(UIGrid))
	self.starIcon = self.starBg:NodeByName("starIcon").gameObject
	self.starList = {}

	for i = 1, 7 do
		local star = NGUITools.AddChild(self.gridOfStar.gameObject, self.starIcon)

		table.insert(self.starList, star)
	end

	self.progressBar_ = self.go:NodeByName("progressPart").gameObject
	self.labelDesc = self.progressBar_:ComponentByName("labelDesc", typeof(UILabel))
	self.lockBtn = self.go:NodeByName("lockBtn").gameObject
	self.awardRoot = self.go:NodeByName("awardRoot").gameObject
	self.missionName = self.go:ComponentByName("missionName", typeof(UILabel))
	self.selectBtn = self.go:NodeByName("selectBtn").gameObject
	self.selectedImg = self.selectBtn:NodeByName("selected").gameObject
	self.itemIcon = ItemIcon.new(self.awardRoot)
	self.heroIcon = HeroIcon.new(self.awardRoot)
	self.labelDesc.text = __("PUB_MISSION_COMPLETE2")
	self.progressEffect_ = xyd.Spine.new(self.progressBar_)

	self.progressEffect_:setInfo("dagon_jingdutiao", function ()
		self.progressEffect_:SetLocalPosition(0, 0, 0)
		self.progressEffect_:SetLocalScale(0.98, 1.01, 1)
		self.progressEffect_:setRenderTarget(self.labelDesc:GetComponent(typeof(UIWidget)), 0)
		self.progressEffect_:play("texiao01", -1, 1)
	end)
end

function CompleteItem:registerEvent()
	UIEventListener.Get(self.selectBtn).onClick = function ()
		self.data.selected = not self.data.selected

		self.selectedImg:SetActive(self.data.selected)
		self.parent:changeMissionSelected(self.data.missionID, self.data.selected)
	end

	UIEventListener.Get(self.lockBtn).onClick = function ()
		xyd.showToast(__("PUB_LOCK_MISSION"))
	end
end

function CompleteItem:updateInfo()
	local mission = tavernModel:getMissionById(self.data.missionID)
	self.missionName.text = __(xyd.tables.pubMissionNameTextTable:getName(mission.name))
	local star = pubMissionTable:getStar(mission.table_id)

	xyd.setUISpriteAsync(self.starBg, nil, "pub_mission_star" .. star, nil, )

	for i = 1, 7 do
		self.starList[i]:SetActive(i <= star)
	end

	self.gridOfStar:Reposition()

	local type_ = xyd.tables.itemTable:getType(mission.award[1])

	if type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS and type_ ~= xyd.ItemType.SKIN then
		self.itemIcon:SetActive(true)
		self.heroIcon:SetActive(false)
		self.itemIcon:setInfo({
			show_has_num = true,
			scale = 0.7037037037037037,
			itemID = mission.award[1],
			num = mission.award[2],
			dragScrollView = self.parent.scrollView
		})
	else
		self.heroIcon:SetActive(true)
		self.itemIcon:SetActive(false)
		self.heroIcon:setInfo({
			show_has_num = true,
			scale = 0.7037037037037037,
			itemID = mission.award[1],
			num = mission.award[2],
			dragScrollView = self.parent.scrollView
		})
	end

	self.selectedImg:SetActive(self.data.selected)
end

function MissionItem:initUI()
	self.starBg = self.go:ComponentByName("starBg", typeof(UISprite))
	self.gridOfStar = self.starBg:ComponentByName("gridOfStar", typeof(UIGrid))
	self.starIcon = self.starBg:NodeByName("starIcon").gameObject
	self.starList = {}

	for i = 1, 7 do
		local star = NGUITools.AddChild(self.gridOfStar.gameObject, self.starIcon)

		table.insert(self.starList, star)
	end

	self.awardRoot = self.go:NodeByName("awardRoot").gameObject
	self.timeGroup = self.go:NodeByName("timeGroup").gameObject
	self.labelTime = self.go:ComponentByName("timeGroup/labelTime", typeof(UILabel))
	self.missionName = self.go:ComponentByName("missionName", typeof(UILabel))
	self.heroGroupRoot = self.go:ComponentByName("heroGroup", typeof(UILayout))
	self.selectBtn = self.go:NodeByName("selectBtn").gameObject
	self.selectedImg = self.selectBtn:NodeByName("selected").gameObject
	self.itemIcon = ItemIcon.new(self.awardRoot)
	self.heroIcon = HeroIcon.new(self.awardRoot)

	if xyd.Global.lang == "fr_fr" then
		self.timeGroup:X(210)
	end
end

function MissionItem:registerEvent()
	UIEventListener.Get(self.selectBtn).onClick = function ()
		self.data.selected = not self.data.selected

		self.selectedImg:SetActive(self.data.selected)
		self.parent:changeMissionSelected(self.data.missionID, self.data.selected)
	end
end

function MissionItem:updateInfo()
	local mission = tavernModel:getMissionById(self.data.missionID)
	self.missionName.text = __(xyd.tables.pubMissionNameTextTable:getName(mission.name))
	local star = pubMissionTable:getStar(mission.table_id)

	xyd.setUISpriteAsync(self.starBg, nil, "pub_mission_star" .. star, nil, )

	for i = 1, 7 do
		self.starList[i]:SetActive(i <= star)
	end

	self.gridOfStar:Reposition()

	local missionTime = pubMissionTable:getMissionTime(mission.table_id)
	self.labelTime.text = xyd.getRoughDisplayTime(missionTime)
	local type_ = xyd.tables.itemTable:getType(mission.award[1])

	if type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS and type_ ~= xyd.ItemType.SKIN then
		self.itemIcon:SetActive(true)
		self.heroIcon:SetActive(false)
		self.itemIcon:setInfo({
			show_has_num = true,
			scale = 0.7037037037037037,
			itemID = mission.award[1],
			num = mission.award[2],
			dragScrollView = self.parent.scrollView
		})
	else
		self.heroIcon:SetActive(true)
		self.itemIcon:SetActive(false)
		self.heroIcon:setInfo({
			show_has_num = true,
			scale = 0.7037037037037037,
			itemID = mission.award[1],
			num = mission.award[2],
			dragScrollView = self.parent.scrollView
		})
	end

	if not self.partnerList then
		self.partnerList = {}

		for i = 1, 4 do
			local heroIcon = HeroIcon.new(self.heroGroupRoot.gameObject)

			table.insert(self.partnerList, heroIcon)
		end
	end

	local partners = self.data.partners

	for i = 1, 4 do
		local partnerId = partners[i]

		if partnerId then
			self.partnerList[i]:SetActive(true)

			local partner = slotModel:getPartner(partnerId)

			self.partnerList[i]:setInfo({
				scale = 0.6018518518518519,
				noClick = true,
				tableID = partner:getTableID(),
				skin_id = partner:getSkinId(),
				star = partner:getStar(),
				dragScrollView = self.parent.scrollView
			})
		else
			self.partnerList[i]:SetActive(false)
		end
	end

	self.heroGroupRoot:Reposition()
	self.selectedImg:SetActive(self.data.selected)
end

return TavernMultimissionWindow
