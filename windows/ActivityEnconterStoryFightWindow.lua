local BaseWindow = import(".BaseWindow")
local ActivityEnconterStoryFightWindow = class("ActivityEnconterStoryFightWindow", BaseWindow)
local FightItem = class("FightItem", import("app.components.CopyComponent"))
local ChallengeComponent = import("app.components.ChallengeComponent")
local CountDown = import("app.components.CountDown")
local BattleTable = xyd.tables.activityEnconterBattleTable

function FightItem:ctor(parentGO, parent)
	self.parent_ = parent

	FightItem.super.ctor(self, parentGO)
end

function FightItem:initUI()
	FightItem.super.initUI(self)
	self:getUIComponent()
end

function FightItem:getUIComponent()
	local goTrans = self.go.transform
	self.widgt = goTrans:GetComponent(typeof(UIWidget))
	self.challengRoot = goTrans:NodeByName("challengRoot")
	self.bottomPart = goTrans:NodeByName("bottomPart")
	self.lockGroup = goTrans:NodeByName("lockGroup").gameObject
	self.lockTimeLabel = goTrans:ComponentByName("lockGroup/timeLabel", typeof(UILabel))
	self.lockEndLabel = goTrans:ComponentByName("lockGroup/endLabel", typeof(UILabel))
	self.starGroup = goTrans:NodeByName("starGroup").gameObject

	for i = 1, 3 do
		self["star" .. i] = goTrans:ComponentByName("starGroup/starImg" .. i, typeof(UISprite))
	end

	self.labelDesc = goTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.redPoint = goTrans:NodeByName("redPoint")

	UIEventListener.Get(self.go).onClick = function ()
		self:onClickSelf()
	end

	self.lockEndLabel.text = __("ACTIVITY_ENCOUNTER_STORY_TEXT04")
end

function FightItem:setInfo(params)
	self.info_ = params
	local id = self.info_.id
	self.labelDesc.text = __("ACTIVITY_ENCOUNTER_STORY_TEXT03", id)

	for i = 1, 3 do
		if self.info_.challengeState[i] and tonumber(self.info_.challengeState[i]) == 1 then
			xyd.setUISpriteAsync(self["star" .. i], nil, "activity_beach_star_icon")
		else
			xyd.setUISpriteAsync(self["star" .. i], nil, "activity_beach_star_icon2")
		end
	end

	local stageNow = self.parent_.activityData.detail.stage
	local activity_open_time = self.parent_.activityData:startTime()
	self.info_.activity_open_time = activity_open_time

	if xyd.getServerTime() < activity_open_time + xyd.DAY_TIME * self.info_.open_time then
		self.lockGroup:SetActive(true)

		local countData = {
			duration = activity_open_time + xyd.DAY_TIME * self.info_.open_time - xyd.getServerTime(),
			callback = function ()
				self.parent_:updateFightItem()
			end
		}

		if not self.countDown then
			self.countDown = CountDown.new(self.lockTimeLabel, countData)
		else
			self.countDown:setInfo(countData)
		end

		if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
			self.lockTimeLabel.transform:SetSiblingIndex(2)
			self.lockGroup:GetComponent(typeof(UILayout)):Reposition()
		end

		self.labelDesc.gameObject:SetActive(false)
		self.starGroup:SetActive(false)
		self.redPoint:SetActive(false)
	else
		if stageNow < 0 or self.info_.id < stageNow then
			self.redPoint:SetActive(false)
		else
			self.redPoint:SetActive(true)
		end

		self.lockGroup:SetActive(false)
		self.labelDesc.gameObject:SetActive(true)
		self.starGroup:SetActive(true)
	end

	if self.challengeComponent_ then
		self.challengeComponent_:setInfo(self.info_)
	end
end

function FightItem:showComponent()
	if not self.challengeComponent_ then
		self.challengeComponent_ = ChallengeComponent.new(self.challengRoot.gameObject)
	end

	self.isShow = true

	self.challengeComponent_:setInfo(self.info_)

	self.widgt.height = 607

	self.parent_.grid_:Reposition()

	local seq = self:getSequence(function ()
		self.parent_.isShowChange_ = false
	end)

	seq:Insert(0.2, self.challengRoot:DOScale(Vector3(1, 1, 1), 0.2))
	seq:Insert(0.2, self.bottomPart:DOLocalMove(Vector3(0, -580, 0), 0.2))
end

function FightItem:hideComponent()
	self.isShow = false
	self.challengRoot.localScale = Vector3(1, 0, 1)

	self.bottomPart:Y(-50)

	self.widgt.height = 69
end

function FightItem:onClickSelf()
	local activity_open_time = self.parent_.activityData:startTime()

	if xyd.getServerTime() < activity_open_time + xyd.DAY_TIME * self.info_.open_time then
		return
	end

	if not self.isShow then
		self.parent_:showComponent(self.info_.id)
	end
end

function ActivityEnconterStoryFightWindow:ctor(name, params)
	ActivityEnconterStoryFightWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENCONTER_STORY)
	self.itemList_ = {}
end

function ActivityEnconterStoryFightWindow:initWindow()
	ActivityEnconterStoryFightWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityEnconterStoryFightWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.fightItemRoot_ = winTrans:NodeByName("fightItem").gameObject

	self.fightItemRoot_:SetActive(false)

	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.awardBtn_ = winTrans:NodeByName("awardBtn").gameObject
	self.awardRed_ = winTrans:NodeByName("awardBtn/redPoint")
	self.contentGroup_ = winTrans:ComponentByName("contentGroup", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("contentGroup/grid", typeof(UILayout))
end

function ActivityEnconterStoryFightWindow:layout()
	self.winTitle_.text = __("ACTIVITY_ENCOUNTER_STORY_TEXT02")
	local ids = BattleTable:getIDs()
	self.stageNow = self.activityData.detail.stage
	local showStage = 1
	local activity_open_time = self.activityData:startTime()
	self.initPos = self.contentGroup_.transform.localPosition.y

	for index, id in ipairs(ids) do
		local params = self:getChallengeInfo(id)
		local RootNew = NGUITools.AddChild(self.grid_.gameObject, self.fightItemRoot_)

		RootNew:SetActive(true)

		local itemNew = FightItem.new(RootNew, self)

		itemNew:setInfo(params)

		self.itemList_[tonumber(id)] = itemNew

		if id == self.stageNow and params.open_time * xyd.DAY_TIME + activity_open_time <= xyd.getServerTime() then
			showStage = id
		elseif id == self.stageNow - 1 and self:getChallengeInfo(id).open_time * xyd.DAY_TIME + activity_open_time <= xyd.getServerTime() then
			showStage = id
		elseif self.stageNow < 0 then
			showStage = #ids
		end
	end

	if showStage then
		local itemNew = self.itemList_[tonumber(showStage)]

		itemNew:showComponent()
		self:waitForFrame(1, function ()
			local sp = self.contentGroup_.gameObject:GetComponent(typeof(SpringPanel))
			local dis = 315 + (showStage - 1) * 77

			if showStage >= #ids - 1 then
				dis = 315 + (#ids - 3) * 77
			end

			sp.Begin(sp.gameObject, Vector3(0, dis, 0), 12)
		end)
	end

	self.grid_:Reposition()
	self.contentGroup_:ResetPosition()
	self:updateRed()
end

function ActivityEnconterStoryFightWindow:register()
	ActivityEnconterStoryFightWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:onClickCloseButton()
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_beach_island_award_window", {
			activity_id = xyd.ActivityID.ENCONTER_STORY,
			awarded = self.activityData.detail.awarded,
			star = self.activityData.detail.star_num
		})
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onUpdateActivityInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateRed))
end

function ActivityEnconterStoryFightWindow:updateRed()
	self.awardRed_:SetActive(self.activityData:getRedPointStar())
end

function ActivityEnconterStoryFightWindow:onUpdateActivityInfo()
	local ids = BattleTable:getIDs()

	for index, id in ipairs(ids) do
		local params = self:getChallengeInfo(id)
		local item = self.itemList_[tonumber(id)]

		item:setInfo(params)
	end

	self:updateRed()
end

function ActivityEnconterStoryFightWindow:getChallengeInfo(id)
	local params = {
		id = id,
		battle_id = BattleTable:getBattleID(id),
		initial_partner = BattleTable:getOptionalPartners(id),
		awards = BattleTable:getAwards(id),
		open_time = BattleTable:getOpenDay(id),
		text = {}
	}
	local stageNow = self.activityData.detail.stage
	params.canNotFight = stageNow < id and stageNow > 0
	params.hasAwarded = xyd.checkCondition(stageNow < 0 or id < stageNow, true, false)

	for i = 1, 3 do
		params.text[i] = BattleTable:getChallengeText(id, i)
	end

	params.challengeState = self.activityData.detail.battles[tonumber(id)]

	return params
end

function ActivityEnconterStoryFightWindow:showComponent(id)
	local ids = BattleTable:getIDs()

	if self.isShowChange_ then
		return
	end

	if id and id > 0 then
		self.isShowChange_ = true
	end

	for index, item in ipairs(self.itemList_) do
		if index == id then
			item:showComponent()
		else
			item:hideComponent()
		end
	end

	self.grid_:Reposition()

	if id ~= self.stageNow then
		local sp = self.contentGroup_.gameObject:GetComponent(typeof(SpringPanel))
		local dis = 315 + (id - 1) * 77

		if id >= #ids - 1 then
			dis = 315 + (#ids - 3) * 77
		end

		sp.Begin(sp.gameObject, Vector3(0, dis, 0), 8)
	else
		self.contentGroup_:ResetPosition()
	end

	self.stageNow = id
end

function ActivityEnconterStoryFightWindow:updateFightItem()
end

return ActivityEnconterStoryFightWindow
