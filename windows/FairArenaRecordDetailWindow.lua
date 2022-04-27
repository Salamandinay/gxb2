local BaseWindow = import(".BaseWindow")
local FairArenaRecordDetailWindow = class("FairArenaRecordDetailWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local GroupBuffIcon = import("app.components.GroupBuffIcon")

function FairArenaRecordDetailWindow:ctor(name, params)
	FairArenaRecordDetailWindow.super.ctor(self, name, params)

	self.data = params
end

function FairArenaRecordDetailWindow:initWindow()
	FairArenaRecordDetailWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initPartners()
	self:initBuffs()
end

function FairArenaRecordDetailWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.pNode = winTrans:NodeByName("pIcon").gameObject
	self.pNameLabel_ = winTrans:ComponentByName("pNameLabel_", typeof(UILabel))
	self.severLabel_ = winTrans:ComponentByName("serverGroup/severLabel_", typeof(UILabel))
	self.textLabel_ = winTrans:ComponentByName("textLabel_", typeof(UILabel))
	self.powerLabel_ = winTrans:ComponentByName("powerGroup/powerLabel_", typeof(UILabel))

	for i = 1, 5 do
		self["buffNode" .. i] = winTrans:NodeByName("buffGroup/icon" .. i .. "/buff" .. i).gameObject
	end

	self.awardIcon_ = winTrans:ComponentByName("awardIcon_", typeof(UISprite))
	self.awardLabel_ = winTrans:ComponentByName("awardIcon_/awardLabel_", typeof(UILabel))
	self.heroContainer1 = winTrans:NodeByName("group1/icon1/hero1").gameObject
	self.heroContainer2 = winTrans:NodeByName("group1/icon2/hero2").gameObject
	self.heroContainer3 = winTrans:NodeByName("group2/icon3/hero3").gameObject
	self.heroContainer4 = winTrans:NodeByName("group2/icon4/hero4").gameObject
	self.heroContainer5 = winTrans:NodeByName("group2/icon5/hero5").gameObject
	self.heroContainer6 = winTrans:NodeByName("group2/icon6/hero6").gameObject

	for i = 1, 6 do
		self["hero" .. i] = HeroIcon.new(self["heroContainer" .. i])

		self["hero" .. i]:SetActive(false)
	end
end

function FairArenaRecordDetailWindow:initUIComponent()
	local serverId = xyd.models.selfPlayer:getServerID()
	self.titleLabel_.text = __("HISTORY_PARTNER_STATION_LINEUP")
	self.textLabel_.text = __("DEFFORMATION")
	self.pNameLabel_.text = xyd.Global.playerName
	self.severLabel_.text = xyd.getServerNumber(serverId)
	self.pIcon = PlayerIcon.new(self.pNode)

	self.pIcon:setInfo({
		avatarID = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		lev = xyd.models.backpack:getLev()
	})

	self.awardLabel_.text = __("FAIR_ARENA_TITLE_GIFT", xyd.tables.activityFairArenaLevelTable:getLevel(self.data.stage))
	local style = xyd.tables.activityFairArenaLevelTable:getStyle(self.data.stage)

	xyd.setUISpriteAsync(self.awardIcon_, nil, "fair_arena_awardbox_icon" .. style)
end

function FairArenaRecordDetailWindow:initPartners()
	self.partners = {}
	local partners = self.data.partner_infos
	local power = 0

	for i = 1, #partners do
		local params = {
			isHeroBook = true,
			scale = 0.8055555555555556,
			isShowSelected = false,
			tableID = partners[i].table_id,
			lev = partners[i].lv,
			grade = partners[i].grade,
			equips = partners[i].equips
		}
		local partner = Partner.new()

		partner:populate(params)

		power = power + partner:getPower()

		function params.callback()
			xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
				partner = partner
			})
		end

		self["hero" .. partners[i].pos]:setInfo(params)
		self["hero" .. partners[i].pos]:SetActive(true)
		table.insert(self.partners, partner)
	end

	self.powerLabel_.text = power
end

function FairArenaRecordDetailWindow:initBuffs()
	local buffs = self.data.god_skills or {}

	for i = 1, #buffs do
		local icon = GroupBuffIcon.new(self["buffNode" .. i])

		icon:SetLocalScale(0.5714285714285714, 0.6, 1)
		icon:setInfo(buffs[i], true, xyd.GroupBuffIconType.FAIR_ARENA)

		UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(buffs[i], 200, true)
			else
				self:clearBuffTips()
			end
		end
	end

	if #self.partners < 6 then
		return
	end

	local actBuffID = 0
	local groupNum = {}
	local tNum = 0

	for _, p in ipairs(self.partners) do
		local group = p:getGroup()

		if not groupNum[group] then
			groupNum[group] = 0
		end

		groupNum[group] = groupNum[group] + 1
		tNum = tNum + 1
	end

	for i = 1, 6 do
		if not groupNum[i] then
			groupNum[i] = 0
		end
	end

	self.buffDataList = {}
	local buffIds = xyd.tables.groupBuffTable:getIds()

	for i, buffId in ipairs(buffIds) do
		table.insert(self.buffDataList, tonumber(buffId))
	end

	table.sort(self.buffDataList)

	for i = 1, #self.buffDataList do
		local buffId = self.buffDataList[i]
		local groupDataList = xyd.split(xyd.tables.groupBuffTable:getGroupConfig(buffId), "|")
		local type = xyd.tables.groupBuffTable:getType(buffId)
		local isNewAct = true

		if tonumber(type) == 1 then
			for _, gi in ipairs(groupDataList) do
				local giList = xyd.split(gi, "#")

				if tonumber(groupNum[tonumber(giList[1])]) ~= tonumber(giList[2]) then
					isNewAct = false

					break
				end
			end
		elseif tonumber(type) == 2 then
			local numCount = {}

			for num, _ in ipairs(groupNum) do
				if not numCount[groupNum[num]] then
					numCount[groupNum[num]] = 0
				end

				if tonumber(num) < 5 then
					numCount[groupNum[num]] = numCount[groupNum[num]] + 1
				end
			end

			if groupNum[5] + groupNum[6] == 3 and numCount[1] == 3 then
				isNewAct = true
			else
				isNewAct = false
			end
		end

		if isNewAct then
			actBuffID = buffId

			print(actBuffID)

			break
		end
	end

	if actBuffID > 0 then
		self.groupBuff = GroupBuffIcon.new(self.buffNode5)

		self.groupBuff:SetLocalScale(0.5714285714285714, 0.5714285714285714, 1)
		self.groupBuff:setInfo(actBuffID, true)

		UIEventListener.Get(self.groupBuff:getGameObject()).onPress = function (go, isPress)
			if isPress then
				local win = xyd.WindowManager.get():getWindow("group_buff_detail_window")

				if win then
					xyd.WindowManager.get():closeWindow("group_buff_detail_window", function ()
						XYDCo.WaitForTime(1, function ()
							local params = {
								buffID = actBuffID,
								contenty = 200
							}

							xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
						end, nil)
					end)
				else
					local params = {
						buffID = actBuffID,
						contenty = 200
					}

					xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
				end
			else
				xyd.WindowManager.get():closeWindow("group_buff_detail_window")
			end
		end
	end
end

function FairArenaRecordDetailWindow:onClcikBuffNode(buffID, contenty, isFairType)
	local params = {
		buffID = buffID,
		contenty = contenty
	}

	if isFairType then
		params.type = xyd.GroupBuffIconType.FAIR_ARENA
	end

	local win = xyd.getWindow("group_buff_detail_window")

	if win then
		win:update(params)
	else
		xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
	end
end

function FairArenaRecordDetailWindow:clearBuffTips()
	xyd.closeWindow("group_buff_detail_window")
end

return FairArenaRecordDetailWindow
