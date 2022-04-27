local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestEnemyWindow = class("ActivityEntranceTestEnemyWindow", BaseWindow)
local PlayerIcon = require("app.components.PlayerIcon")

function ActivityEntranceTestEnemyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ActivityEntranceTestEnemyWindowSkin"
	self.matchInfo = params.matchInfo
	self.noBtn_ = params.noBtn
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	local a = 0
end

function ActivityEntranceTestEnemyWindow:initWindow()
	self:getUIConponent()
	BaseWindow.initWindow(self)
	self:layout()
	self:registerEvent()
end

function ActivityEntranceTestEnemyWindow:getUIConponent()
	local trans = self.window_.transform
	local allgroup = trans:NodeByName("groupAction").gameObject
	self.bg_ = allgroup:ComponentByName("e:Image", typeof(UIWidget))
	self.scoreWords = allgroup:ComponentByName("scoreWords", typeof(UILabel))
	self.scoreText = allgroup:ComponentByName("scoreText", typeof(UILabel))
	self.ns1 = allgroup:ComponentByName("ns1:MultiLabel", typeof(UILabel))
	self.labelId = allgroup:ComponentByName("labelId", typeof(UILabel))
	self.labelWinTitle_ = allgroup:ComponentByName("upGroup/labelWinTitle", typeof(UILabel))
	self.closeBtn = allgroup:NodeByName("upGroup/closeBtn").gameObject
	self.pIconGroup = allgroup:NodeByName("pIcon").gameObject
	self.playerName = allgroup:ComponentByName("playerGroup/playerName", typeof(UILabel))
	self.serverGroup = allgroup:NodeByName("playerGroup/serverGroup").gameObject
	self.labelServer = self.serverGroup:ComponentByName("labelServer", typeof(UILabel))
	self.labelFormation = allgroup:ComponentByName("labelFormation", typeof(UILabel))
	self.power = allgroup:ComponentByName("powerGroup/power", typeof(UILabel))

	for i = 1, 2 do
		self["hero" .. i] = allgroup:NodeByName("group3/hero" .. i).gameObject
	end

	for i = 3, 6 do
		self["hero" .. i] = allgroup:NodeByName("group4/hero" .. i).gameObject
	end

	self.fightBtn = allgroup:NodeByName("fightBtn").gameObject
	self.fightBtn_label = self.fightBtn:ComponentByName("button_label", typeof(UILabel))
	self.iconImg = self.fightBtn:NodeByName("iconImg")
	self.iconNum = self.fightBtn:ComponentByName("iconImg/iconNum", typeof(UILabel))
end

function ActivityEntranceTestEnemyWindow:layout()
	self.labelFormation.text = __("DEFFORMATION")
	self.fightBtn_label.text = __("FIGHT2")
	self.scoreWords.text = __("SCORE")
	local isRobot = self.matchInfo.is_robot

	if isRobot and isRobot == 1 then
		local allInfo = xyd.tables.activityEntranceTestRobotTable:getAllInfo(self.matchInfo.player_id)
		self.matchInfo.show_id = allInfo.showID
		self.matchInfo.lev = allInfo.lv
		self.matchInfo.avatar_id = allInfo.avatar
		self.matchInfo.server_id = allInfo.server
		self.matchInfo.player_name = allInfo.name
	end

	self.pIcon = PlayerIcon.new(self.pIconGroup)

	self.pIcon:setInfo({
		avatarID = self.matchInfo.avatar_id,
		lev = self.matchInfo.lev,
		avatar_frame_id = self.matchInfo.avatar_frame_id
	})

	self.playerName.text = self.matchInfo.player_name
	self.power.text = self.matchInfo.power
	self.labelServer.text = xyd.getServerNumber(self.matchInfo.server_id)

	if self.matchInfo.show_id then
		self.labelId.text = self.matchInfo.show_id
	else
		self.labelId.text = self.matchInfo.player_id
	end

	self.scoreText.text = self.matchInfo.score
	local petID = 0

	if self.matchInfo and self.matchInfo.pet_info then
		petID = self.matchInfo.pet_info.pet_id
	elseif self.matchInfo and self.matchInfo.pet_id then
		petID = self.matchInfo.pet_id
	end

	if not self.matchInfo.partners then
		self.matchInfo.partners = {}
	end

	self.partnerList_ = {}

	for i, _ in ipairs(self.matchInfo.partners) do
		local Partner = import("app.models.Partner")
		local p = Partner.new()

		if not self.matchInfo.partners[i] then
			return
		end

		self.matchInfo.partners[i].isEntrance = true

		p:populate(self.matchInfo.partners[i])
		table.insert(self.partnerList_, p)

		local params = {
			isEntrance = true,
			noClickSelected = true,
			scale = 0.75,
			tableID = self.matchInfo.partners[i].table_id,
			lev = self.matchInfo.partners[i].lv,
			awake = self.matchInfo.partners[i].awake,
			grade = self.matchInfo.partners[i].grade,
			star = self.matchInfo.partners[i].star
		}
		params.star = xyd.tables.partnerTable:getStar(params.tableID) + params.awake
		local HeroIcon = import("app.components.HeroIcon")
		local heroIcon = HeroIcon.new(self["hero" .. tostring(self.matchInfo.partners[i].pos)])

		heroIcon:setInfo(params, petID, p)
	end

	if self.noBtn_ then
		self.fightBtn:SetActive(false)

		self.bg_.height = 380
		self.labelWinTitle_.text = __("DEFFORMATION")
	else
		self.labelWinTitle_.text = __(self:winName())
		self.bg_.height = 469
	end
end

function ActivityEntranceTestEnemyWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= xyd.ActivityID.ENTRANCE_TEST then
			return
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end)

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.fightBtn.gameObject).onClick = handler(self, function ()
		local dbVal = xyd.db.formation:getValue(xyd.BattleType.ENTRANCE_TEST)
		local hasPartners = true

		if not dbVal then
			hasPartners = false
		else
			local data = require("cjson").decode(dbVal)

			if not data.partners then
				hasPartners = false
			end
		end

		if not hasPartners then
			xyd.alertYesNo(__("ENTRANCE_TEST_NO_FIGHT_PARTNERS"), function (yes_no)
				if yes_no then
					local pet_id = 0

					if self.activityData.detail.pet_info then
						pet_id = self.activityData.detail.pet_info.pet_id or 0
					end

					local dbVal_def = xyd.db.formation:getValue(xyd.BattleType.ENTRANCE_TEST_DEF)

					if pet_id == 0 and dbVal_def then
						local data_def = require("cjson").decode(dbVal_def)
						pet_id = data_def.pet_id or 0
					end

					self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

					xyd.WindowManager:get():openWindow("battle_formation_window", {
						showSkip = true,
						battleType = xyd.BattleType.ENTRANCE_TEST,
						mapType = xyd.MapType.ENTRANCE_TEST,
						enemy_id = self.matchInfo.player_id,
						formation = self.activityData.detail.partners,
						pet = pet_id,
						skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("entrance_test_skip_report")) == 1, true, false),
						btnSkipCallback = function (flag)
							local valuedata = xyd.checkCondition(flag, 1, 0)

							xyd.db.misc:setValue({
								key = "entrance_test_skip_report",
								value = valuedata
							})
						end
					})
				else
					xyd.WindowManager:get():openWindow("battle_formation_window", {
						showSkip = true,
						battleType = xyd.BattleType.ENTRANCE_TEST,
						mapType = xyd.MapType.ENTRANCE_TEST,
						enemy_id = self.matchInfo.player_id,
						skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("entrance_test_skip_report")) == 1, true, false),
						btnSkipCallback = function (flag)
							local valuedata = xyd.checkCondition(flag, 1, 0)

							xyd.db.misc:setValue({
								key = "entrance_test_skip_report",
								value = valuedata
							})
						end
					})
				end
			end)
		else
			xyd.WindowManager:get():openWindow("battle_formation_window", {
				showSkip = true,
				battleType = xyd.BattleType.ENTRANCE_TEST,
				mapType = xyd.MapType.ENTRANCE_TEST,
				enemy_id = self.matchInfo.player_id,
				skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("entrance_test_skip_report")) == 1, true, false),
				btnSkipCallback = function (flag)
					local valuedata = xyd.checkCondition(flag, 1, 0)

					xyd.db.misc:setValue({
						key = "entrance_test_skip_report",
						value = valuedata
					})
				end
			})
		end
	end)
end

function ActivityEntranceTestEnemyWindow:willClose(params)
	BaseWindow.willClose(self, params)

	self.activityData.matchIndex = self.activityData.matchIndex + 1
end

return ActivityEntranceTestEnemyWindow
