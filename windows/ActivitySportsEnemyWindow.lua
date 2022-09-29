local BaseWindow = import(".BaseWindow")
local ActivitySportsEnemyWindow = class("ActivitySportsEnemyWindow", BaseWindow)
local PlayerIcon = require("app.components.PlayerIcon")

function ActivitySportsEnemyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.matchInfo = params.matchInfo
	self.title_name = params.title_name
end

function ActivitySportsEnemyWindow:initWindow()
	self:getUIConponent()
	BaseWindow.initWindow(self)
	self:layout()
	self:registerEvent()
end

function ActivitySportsEnemyWindow:getUIConponent()
	local trans = self.window_.transform
	local allgroup = trans:NodeByName("groupAction").gameObject
	self.scoreWords = allgroup:ComponentByName("scoreWords", typeof(UILabel))
	self.scoreText = allgroup:ComponentByName("scoreText", typeof(UILabel))
	self.ns1 = allgroup:ComponentByName("ns1:MultiLabel", typeof(UILabel))
	self.labelId = allgroup:ComponentByName("labelId", typeof(UILabel))
	self.labelWinTitle = allgroup:ComponentByName("upGroup/labelWinTitle", typeof(UILabel))
	self.closeBtn = allgroup:NodeByName("upGroup/closeBtn").gameObject
	self.pIconGroup = allgroup:NodeByName("pIcon").gameObject
	self.playerName = allgroup:ComponentByName("playerGroup/playerName", typeof(UILabel))
	self.serverGroup = allgroup:NodeByName("serverGroup").gameObject
	self.labelServer = self.serverGroup:ComponentByName("labelServer", typeof(UILabel))
	self.labelFormation = allgroup:ComponentByName("labelFormation", typeof(UILabel))
	self.power = allgroup:ComponentByName("powerGroup/power", typeof(UILabel))
	self.powerGroup_layout = allgroup:ComponentByName("powerGroup", typeof(UILayout))
	self.groupIcon = allgroup:ComponentByName("groupIcon", typeof(UISprite))

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
	self.personCon = allgroup:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
end

function ActivitySportsEnemyWindow:layout()
	self.labelFormation.text = __("DEFFORMATION")
	self.fightBtn_label.text = __("FIGHT2")
	self.scoreWords.text = __("SCORE")
	self.pIcon = PlayerIcon.new(self.pIconGroup)

	self.pIcon:setInfo({
		avatarID = self.matchInfo.avatar_id,
		lev = self.matchInfo.lev,
		avatar_frame_id = self.matchInfo.avatar_frame_id
	})

	self.playerName.text = self.matchInfo.player_name
	self.power.text = self.matchInfo.power

	self.powerGroup_layout:Reposition()

	self.labelServer.text = xyd.getServerNumber(self.matchInfo.server_id)
	self.labelId.text = self.matchInfo.player_id
	self.scoreText.text = self.matchInfo.score
	self.matchInfo = xyd.decodeProtoBuf(self.matchInfo)

	if not self.matchInfo.server_id then
		self.labelServer.text = "S999"
	end

	if self.matchInfo.partners and #self.matchInfo.partners > 0 then
		for i in pairs(self.matchInfo.partners) do
			local params = {
				noClick = true,
				scale = 0.75,
				tableID = self.matchInfo.partners[i].table_id,
				lev = self.matchInfo.partners[i].lv,
				awake = self.matchInfo.partners[i].awake,
				grade = self.matchInfo.partners[i].grade,
				star = self.matchInfo.partners[i].star,
				star_origin = self.matchInfo.partners[i].star_origin
			}

			if params.awake then
				params.star = xyd.tables.partnerTable:getStar(params.tableID) + params.awake
			else
				params.star = xyd.tables.partnerTable:getStar(params.tableID)
			end

			local HeroIcon = import("app.components.HeroIcon")
			local heroIcon = HeroIcon.new(self["hero" .. tostring(self.matchInfo.partners[i].pos)])

			heroIcon:setInfo(params)
		end
	end

	self.normalModel_ = import("app.components.SenpaiModel").new(self.personEffect)

	if self.matchInfo.is_robot and self.matchInfo.is_robot == 1 or not self.matchInfo.dress_style then
		local styles = xyd.tables.miscTable:split2num("robot_dress_unit", "value", "|")

		self.normalModel_:setModelInfo({
			ids = styles
		})
	else
		self.normalModel_:setModelInfo({
			ids = self.matchInfo.dress_style
		})
	end

	if self.matchInfo.group then
		xyd.setUISpriteAsync(self.groupIcon, nil, "img_group" .. self.matchInfo.group, function ()
		end, nil, )
	end
end

function ActivitySportsEnemyWindow:addTitle()
	ActivitySportsEnemyWindow.super.addTitle(self)

	if self.title_name then
		self.labelWinTitle.text = self.title_name
	end
end

function ActivitySportsEnemyWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

return ActivitySportsEnemyWindow
