local ShrineHurdleRecordWindow = class("ShrineHurdleRecordWindow", import(".BaseWindow"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local CopyComponent = import("app.components.CopyComponent")
local HeroIcon = import("app.components.HeroIcon")
local TowerRecordItem = class("TowerRecordItem", CopyComponent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function TowerRecordItem:ctor(go, parent)
	self.parent = parent

	TowerRecordItem.super.ctor(self, go)
end

function TowerRecordItem:initUI()
	self:getUIComponent()
	self:register()
end

function TowerRecordItem:register()
	UIEventListener.Get(self.videoBtn).onClick = function ()
		xyd.models.shrineHurdleModel:reqShineHurdleReport(self.record_id, self.floor_id)
	end
end

function TowerRecordItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.floor_id = info.floor_id
	self.score = info.score
	self.record_id = info.record_id
	self.partners = info.partners

	self:layout()
end

function TowerRecordItem:layout()
	local ids = xyd.tables.shrineHurdleTable:getIDs()
	local count = xyd.models.shrineHurdleModel:getCount()
	count = math.fmod(count - 1, 3) + 1
	local route_id = xyd.models.shrineHurdleModel:getRouteID()

	if not route_id or route_id <= 0 then
		route_id = xyd.models.shrineHurdleModel:getLastRouteID()
	end

	local enviroments = xyd.tables.shrineHurdleRouteTable:getEnviroment(route_id, count)
	self.labelName.text = xyd.tables.shrineHurdleRouteTextTable:getTitle(enviroments[1]) .. " " .. self.floor_id .. "/" .. #ids

	if self.score and self.score > 0 then
		self.labelScore.gameObject:SetActive(true)

		self.labelScore.text = __("SHRINE_HURDLE_TEXT10", " +" .. self.score)

		xyd.setUISpriteAsync(self.resultImg_, nil, "arena_3v3_win_" .. xyd.Global.lang)
	else
		xyd.setUISpriteAsync(self.resultImg_, nil, "arena_3v3_lost_" .. xyd.Global.lang)
		self.labelScore.gameObject:SetActive(false)
	end

	local posList = {}

	for index, partner_info in pairs(self.partners) do
		local partner_id = partner_info.partner_id
		local info = xyd.models.shrineHurdleModel:getPartner(partner_id)
		info.noClick = true
		local pos = partner_info.pos
		posList[pos] = true

		self["hero" .. tostring(pos)]:setInfo(info)
	end

	for i = 1, 6 do
		if posList[i] then
			self["hero" .. tostring(i)]:SetActive(true)
		else
			self["hero" .. tostring(i)]:SetActive(false)
		end
	end
end

function TowerRecordItem:getUIComponent()
	local go = self.go
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))
	self.labelScore = go:ComponentByName("labelScore", typeof(UILabel))
	self.videoBtn = go:NodeByName("videoBtn").gameObject
	self.resultImg_ = go:ComponentByName("resultImg", typeof(UISprite))
	self.heroContainer1 = go:NodeByName("group1/icon1/hero1").gameObject
	self.heroContainer2 = go:NodeByName("group1/icon2/hero2").gameObject
	self.heroContainer3 = go:NodeByName("group2/icon3/hero3").gameObject
	self.heroContainer4 = go:NodeByName("group2/icon4/hero4").gameObject
	self.heroContainer5 = go:NodeByName("group2/icon5/hero5").gameObject
	self.heroContainer6 = go:NodeByName("group2/icon6/hero6").gameObject

	for i = 1, 6 do
		self["hero" .. i] = HeroIcon.new(self["heroContainer" .. i])
	end
end

function TowerRecordItem:getGameObject()
	return self.go
end

function ShrineHurdleRecordWindow:ctor(name, params)
	ShrineHurdleRecordWindow.super.ctor(self, name, params)

	self.records_ = params.records or {}
end

function ShrineHurdleRecordWindow:initWindow()
	self:getUIComponent()
	self:initNav()
	self:initInfoGroup()
	self:initRecordList()
	self:updateContent()

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHRINE_HURDLE_HELP"
		})
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ShrineHurdleRecordWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.helpBtn_ = self.window_:NodeByName("helpBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.groupNav_ = winTrans:NodeByName("groupNav").gameObject
	self.battleRecordScorllView_ = winTrans:ComponentByName("battleRecordScorllView", typeof(UIScrollView))
	self.recordGrid_ = winTrans:ComponentByName("battleRecordScorllView/grid", typeof(UIWrapContent))
	self.recordItem_ = winTrans:NodeByName("battleRecordScorllView/recordItem").gameObject
	self.dragRecordScorllView_ = winTrans:NodeByName("dragRecordScorllView").gameObject
	self.wrapContent = FixedWrapContent.new(self.battleRecordScorllView_, self.recordGrid_, self.recordItem_, TowerRecordItem, self)
	self.battleInfoGroup_ = winTrans:ComponentByName("battleInfoGroup", typeof(UIScrollView))
	self.dragInfoScorllView_ = winTrans:NodeByName("dragInfoScorllView").gameObject
	local infoTrans = self.battleInfoGroup_.transform
	self.buffItem_ = infoTrans:NodeByName("buffItem").gameObject
	self.totalWidgt_ = infoTrans:ComponentByName("totalWidgt", typeof(UIWidget))
	local widgtTrans = self.totalWidgt_.transform
	self.textLabel1_ = widgtTrans:ComponentByName("labelGroup1/label", typeof(UILabel))
	self.textLabel2_ = widgtTrans:ComponentByName("labelGroup2/label", typeof(UILabel))
	self.textLabel3_ = widgtTrans:ComponentByName("labelGroup3/label", typeof(UILabel))
	self.textLabel4_ = widgtTrans:ComponentByName("labelGroup4/label", typeof(UILabel))
	self.textLabel5_ = widgtTrans:ComponentByName("labelGroup5/label", typeof(UILabel))
	self.environment1_ = widgtTrans:NodeByName("environment1").gameObject
	self.environment1Widgt = self.environment1_:GetComponent(typeof(UIWidget))
	self.imgIcon1_ = self.environment1_:ComponentByName("imgIcon", typeof(UISprite))
	self.labelName1_ = self.environment1_:ComponentByName("labelName", typeof(UILabel))
	self.labelDesc1_ = self.environment1_:ComponentByName("labelDesc", typeof(UILabel))
	self.environment2_ = widgtTrans:NodeByName("environment2").gameObject
	self.environment2Widgt = self.environment2_:GetComponent(typeof(UIWidget))
	self.imgIcon2_ = self.environment2_:ComponentByName("imgIcon", typeof(UISprite))
	self.labelName2_ = self.environment2_:ComponentByName("labelName", typeof(UILabel))
	self.labelDesc2_ = self.environment2_:ComponentByName("labelDesc", typeof(UILabel))
	self.buffGroup_ = widgtTrans:ComponentByName("buffGroup", typeof(UILayout))
	self.groupNone_ = winTrans:NodeByName("groupNone").gameObject
	self.noneTips_ = winTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))
end

function ShrineHurdleRecordWindow:initRecordList()
end

function ShrineHurdleRecordWindow:initInfoGroup()
	self:layout()

	self.noneTips_.text = __("TOWER_RECORD_TIP_1")

	self.battleInfoGroup_:ResetPosition()
end

function ShrineHurdleRecordWindow:layout()
	local diff = xyd.models.shrineHurdleModel:getDiffNum()
	self.textLabel1_.text = __("SHRINE_HURDLE_TEXT03") .. " : " .. diff
	local floor_id, floor_index, floorType = xyd.models.shrineHurdleModel:getFloorInfo()
	self.floor_id = floor_id
	local ids = xyd.tables.shrineHurdleTable:getIDs()
	self.textLabel2_.text = __("SHRINE_HURDLE_TEXT09") .. " : " .. self.floor_id .. "/" .. #ids
	self.textLabel3_.text = __("SHRINE_HURDLE_TEXT10", " " .. xyd.models.shrineHurdleModel:getScore())
	self.textLabel4_.text = __("SHRINE_HURDLE_TEXT01")
	self.textLabel5_.text = __("SHRINE_HURDLE_TEXT11")
	local count = xyd.models.shrineHurdleModel:getCount()
	count = math.fmod(count - 1, 3) + 1
	local route_id = xyd.models.shrineHurdleModel:getRouteID()

	if not route_id or route_id <= 0 then
		route_id = xyd.models.shrineHurdleModel:getLastRouteID()
	end

	local enviroments = xyd.tables.shrineHurdleRouteTable:getEnviroment(route_id, count)
	local icon1 = xyd.tables.skillTable:getSkillIcon(enviroments[1])
	local icon2 = xyd.tables.skillTable:getSkillIcon(enviroments[2])

	xyd.setUISpriteAsync(self.imgIcon1_, nil, icon1)
	xyd.setUISpriteAsync(self.imgIcon2_, nil, icon2)

	self.labelName1_.text = xyd.tables.shrineHurdleRouteTextTable:getName(enviroments[1])
	self.labelDesc1_.text = xyd.tables.shrineHurdleRouteTextTable:getDesc(enviroments[1])
	self.labelName2_.text = xyd.tables.shrineHurdleRouteTextTable:getName(enviroments[2])
	self.labelDesc2_.text = xyd.tables.shrineHurdleRouteTextTable:getDesc(enviroments[2])

	if self.labelDesc1_.height >= 54 then
		self.environment1Widgt.height = 106 + self.labelDesc1_.height - 46
	end

	if self.labelDesc1_.height < 36 then
		self.labelDesc1_.transform:Y(-56)
	end

	if self.labelDesc2_.height < 36 then
		self.labelDesc2_.transform:Y(-56)
		self.environment2Widgt:SetAnchor(self.environment1_, 0, 0, 0, -(118 + self.labelDesc2_.height - 26), 1, 0, 0, -12)
	else
		self.environment2Widgt:SetAnchor(self.environment1_, 0, 0, 0, -(118 + self.labelDesc2_.height - 46), 1, 0, 0, -12)
	end

	self:waitForFrame(1, function ()
		self.wrapContent:setInfos(self.records_, {})
	end)
end

function ShrineHurdleRecordWindow:initNowBuffList()
	local skillList = xyd.models.shrineHurdleModel:getSkillList()
	local idList = {}

	for skill_id, skill_lv in pairs(skillList) do
		table.insert(idList, tonumber(skill_id))
	end

	table.sort(idList)

	for _, id in ipairs(idList) do
		local level = skillList[tostring(id)] or skillList[tonumber(id)]
		local newItem = NGUITools.AddChild(self.buffGroup_.gameObject, self.buffItem_)

		newItem:SetActive(true)

		local icon = newItem:ComponentByName("iconImg", typeof(UISprite))
		local labelName = newItem:ComponentByName("labelName", typeof(UILabel))
		local labelDesc = newItem:ComponentByName("labelDesc", typeof(UILabel))
		local skillNum = xyd.tables.shrineHurdleBuffTable:getSkillNum(id)[level]
		local addLevText = ""

		if level ~= 1 then
			addLevText = "+" .. level - 1
		end

		local skill_icon = xyd.tables.shrineHurdleBuffTable:getSkillIcon(id)

		xyd.setUISpriteAsync(icon, nil, skill_icon)

		labelDesc.text = xyd.tables.shrineHurdleBuffTextTable:getDesc(id, skillNum)
		labelName.text = xyd.tables.shrineHurdleBuffTextTable:getTitle(id) .. addLevText
		local height = labelDesc.height

		if height >= 60 then
			newItem:GetComponent(typeof(UIWidget)).height = 106 + height - 60
		elseif height <= 20 then
			labelDesc.transform:Y(-50)
		end

		self.buffGroup_:Reposition()
	end

	self.battleInfoGroup_:ResetPosition()
end

function ShrineHurdleRecordWindow:initNav()
	if not self.tab_ then
		local unchosen = {
			color = Color.New2(4160223231.0),
			effectColor = Color.New2(876106751)
		}
		local chosen = {
			color = Color.New2(4160223231.0),
			effectColor = Color.New2(1012112383)
		}
		local colorParams = {
			chosen = chosen,
			unchosen = unchosen
		}
		self.tab_ = CommonTabBar.new(self.groupNav_, 2, function (index)
			self:changeShow(index)
		end, nil, colorParams, true, 2)
		local tableLabels = {
			__("SHRINE_HURDLE_TEXT12"),
			__("SHRINE_HURDLE_TEXT08")
		}

		self.tab_:setTexts(tableLabels)
	end
end

function ShrineHurdleRecordWindow:changeShow(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	self.showIndex_ = index

	self:updateContent()
end

function ShrineHurdleRecordWindow:updateContent()
	if self.showIndex_ == 1 then
		self.battleRecordScorllView_.gameObject:SetActive(true)
		self.dragRecordScorllView_:SetActive(true)
		self.battleInfoGroup_.gameObject:SetActive(false)
		self.dragInfoScorllView_.gameObject:SetActive(false)

		if not self.records_ or #self.records_ <= 0 then
			self.groupNone_:SetActive(true)
		end
	else
		if not self.hasInit_ then
			self:initNowBuffList()

			self.hasInit_ = true
		end

		self.battleInfoGroup_.gameObject:SetActive(true)
		self.dragInfoScorllView_.gameObject:SetActive(true)
		self.battleRecordScorllView_.gameObject:SetActive(false)
		self.dragRecordScorllView_:SetActive(false)
		self:waitForFrame(1, function ()
			self.battleInfoGroup_:ResetPosition()
		end)
		self.groupNone_:SetActive(false)
	end
end

return ShrineHurdleRecordWindow
