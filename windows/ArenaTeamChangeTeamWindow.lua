local BaseWindow = import(".BaseWindow")
local ArenaTeamChangeTeamWindow = class("ArenaTeamChangeTeamWindow", BaseWindow)
local ArenaTeamFormationItem2 = class("ArenaTeamFormationItem2", import("app.components.BaseComponent"))
local Partner = import("app.models.Partner")
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")

function ArenaTeamChangeTeamWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.teamIndex = {
		1,
		2,
		3
	}
	self.model_ = xyd.models.arenaTeam
end

function ArenaTeamChangeTeamWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaTeamChangeTeamWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	local topGroup = mainGroup:NodeByName("topGroup").gameObject
	self.backBtn = topGroup:NodeByName("backBtn").gameObject
	self.labelTitle = topGroup:ComponentByName("labelTitle", typeof(UILabel))
	local infoGroup = mainGroup:NodeByName("infoGroup").gameObject
	self.powerGroup = infoGroup:NodeByName("powerGroup").gameObject
	self.power = self.powerGroup:ComponentByName("power", typeof(UILabel))
	self.container = infoGroup:NodeByName("container").gameObject

	for i = 1, 3 do
		self["f" .. tostring(i)] = self.container:NodeByName("f" .. tostring(i)).gameObject
	end

	self.btnSave = infoGroup:NodeByName("btnSave").gameObject
	self.btnSaveLabelDisplay = self.btnSave:ComponentByName("button_label", typeof(UILabel))
end

function ArenaTeamChangeTeamWindow:layout()
	local teamInfo = self.model_:getMyTeamInfo()

	for i = 1, 3 do
		local info = teamInfo.players[i]
		local index = tonumber(i)
		local isCaptain = teamInfo.leader_id == info.player_id
		local item = ArenaTeamFormationItem2.new(self["f" .. tostring(index)])

		item:setInfo(info, index, isCaptain)

		self["btn" .. tostring(index)] = item:getTeamBtn()
		self["item" .. tostring(index)] = item
	end

	self.power.text = tostring(self.model_:getPower())
	self.btnSaveLabelDisplay.text = __("SAVE_FORMATION")
	self.labelTitle.text = __("RESET_TEAM")
end

function ArenaTeamChangeTeamWindow:registerEvent()
	for i = 1, 3 do
		xyd.setDarkenBtnBehavior(self["btn" .. tostring(i)], self, function ()
			self:onTouchBtn(i)
		end)
	end

	xyd.setDarkenBtnBehavior(self.btnSave, self, self.onClickSave)

	UIEventListener.Get(self.backBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)

	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_CHANGE_TEAM, handler(self, self.onSave))
end

function ArenaTeamChangeTeamWindow:onSave()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ArenaTeamChangeTeamWindow:onClickSave(event)
	local teamInfo = self.model_:getMyTeamInfo()
	local ids = {}

	for i = 1, #self.teamIndex do
		local id = teamInfo.players[self.teamIndex[i]].player_id

		table.insert(ids, id)
	end

	self.model_:changeTeam(ids)
end

function ArenaTeamChangeTeamWindow:onTouchBtn(index)
	local choseFlag, switchFlag = nil
	local item = self["item" .. tostring(index)]
	local cur_state = item:getCurrentState()
	choseFlag = cur_state == "chosen" and true or false
	switchFlag = cur_state == "switch" and true or false

	if not switchFlag then
		for i = 1, 3 do
			if self.teamIndex[i] == index then
				if choseFlag then
					self["item" .. tostring(self.teamIndex[i])]:setCurrentState("unchosen")
					self:removeMask()
				else
					self["item" .. tostring(self.teamIndex[i])]:setCurrentState("chosen")
					self:setMask(index)
				end
			elseif choseFlag then
				self["item" .. tostring(self.teamIndex[i])]:setCurrentState("unchosen")
			else
				self["item" .. tostring(self.teamIndex[i])]:setCurrentState("switch")
			end
		end
	else
		local chosenIndex = 0

		for i = 1, 3 do
			if self["item" .. tostring(i)]:getCurrentState() == "chosen" then
				chosenIndex = i

				break
			end
		end

		if chosenIndex == 0 then
			for i = 1, 3 do
				self["item" .. tostring(i)]:setCurrentState("unchosen")
			end

			return
		end

		self:switchTeam(index, chosenIndex)

		for i = 1, 3 do
			self["item" .. tostring(i)]:setCurrentState("unchosen")
		end

		self:removeMask()
	end
end

function ArenaTeamChangeTeamWindow:setMask(index)
	local i = 1

	while i <= 3 do
		if i ~= index then
			self["item" .. tostring(i)]:setMask()
		end

		i = i + 1
	end

	xyd.setTouchEnable(self.btnSave, false)
end

function ArenaTeamChangeTeamWindow:removeMask()
	local i = 1

	while i <= 3 do
		self["item" .. tostring(i)]:removeMask()

		i = i + 1
	end

	xyd.setTouchEnable(self.btnSave, true)
end

function ArenaTeamChangeTeamWindow:switchTeam(index1, index2)
	local teamGroup1 = self["f" .. tostring(index1)]
	local teamGroup2 = self["f" .. tostring(index2)]
	local pos1 = teamGroup1.transform.localPosition
	local pos2 = teamGroup2.transform.localPosition

	teamGroup1:SetLocalPosition(pos2.x, pos2.y, pos2.z)
	teamGroup2:SetLocalPosition(pos1.x, pos1.y, pos1.z)

	local src = self["item" .. tostring(index1)]:getTeamIndex()

	self["item" .. tostring(index1)]:setTeamIndex(self["item" .. tostring(index2)]:getTeamIndex())
	self["item" .. tostring(index2)]:setTeamIndex(src)

	local arrID1 = -1
	local arrID2 = -1
	local i = 0

	while i < #self.teamIndex do
		if self.teamIndex[i + 1] == index1 then
			arrID1 = i
		end

		if self.teamIndex[i + 1] == index2 then
			arrID2 = i
		end

		i = i + 1
	end

	if arrID1 >= 0 and arrID2 >= 0 then
		self.teamIndex[arrID1 + 1] = index2
		self.teamIndex[arrID2 + 1] = index1
	end
end

function ArenaTeamFormationItem2:ctor(parentGO)
	ArenaTeamFormationItem2.super.ctor(self, parentGO)

	self.currentState = "unchosen"
end

function ArenaTeamFormationItem2:getTeamIndex()
	return self.teamImg.spriteName
end

function ArenaTeamFormationItem2:setTeamIndex(src)
	xyd.setUISpriteAsync(self.teamImg, nil, src, function ()
	end)
end

function ArenaTeamFormationItem2:getPrefabPath()
	return "Prefabs/Components/arena_team_formation_item2"
end

function ArenaTeamFormationItem2:initUI()
	ArenaTeamFormationItem2.super.initUI(self)

	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.teamImg = go:ComponentByName("teamImg", typeof(UISprite))
	self.pIconGroup = go:NodeByName("pIconGroup").gameObject
	self.pIcon = PlayerIcon.new(self.pIconGroup)
	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	self.powerGroup = go:NodeByName("powerGroup").gameObject
	self.power = self.powerGroup:ComponentByName("power", typeof(UILabel))
	self.teamBtn = go:NodeByName("teamBtn").gameObject
	self.teamBtnIcon = self.teamBtn:ComponentByName("icon", typeof(UISprite))
	local heroGroup = go:NodeByName("heroGroup").gameObject
	local heroGroup1 = heroGroup:NodeByName("heroGroup1").gameObject
	local heroGroup2 = heroGroup:NodeByName("heroGroup2").gameObject

	for i = 1, 2 do
		local group = heroGroup1:NodeByName("heroIcon" .. tostring(i)).gameObject
		self["heroMask" .. tostring(i)] = group:ComponentByName("heroMask", typeof(UISprite))
		self["hero" .. tostring(i)] = HeroIcon.new(group)

		self["hero" .. tostring(i)]:SetActive(false)
	end

	for i = 3, 6 do
		local group = heroGroup2:NodeByName("heroIcon" .. tostring(i)).gameObject
		self["heroMask" .. tostring(i)] = group:ComponentByName("heroMask", typeof(UISprite))
		self["hero" .. tostring(i)] = HeroIcon.new(group)

		self["hero" .. tostring(i)]:SetActive(false)
	end
end

function ArenaTeamFormationItem2:setInfo(params, index, isCaptain)
	self.data = params
	self.playerName.text = params.player_name

	xyd.setUISpriteAsync(self.teamImg, nil, "arena_3v3_t" .. tostring(index), function ()
	end)
	self.pIcon:setInfo({
		avatarID = params.avatar_id,
		lev = params.lev
	})

	local petID = 0

	if params and params.pet then
		petID = params.pet.pet_id
	end

	if isCaptain then
		self.pIcon:setCaptain(true)
	end

	local i = 0

	while i < #params.partners do
		local index = i + 1
		local np = Partner.new()

		np:populate(params.partners[i + 1])
		self["hero" .. tostring(index)]:setInfo(np:getInfo(), petID)
		self["hero" .. tostring(index)]:SetActive(true)

		i = i + 1
	end

	self.power.text = params.power
end

function ArenaTeamFormationItem2:setMask()
	for i = 1, 6 do
		local img = self["heroMask" .. tostring(i)]

		img:SetActive(true)
	end
end

function ArenaTeamFormationItem2:removeMask()
	for i = 1, 6 do
		local img = self["heroMask" .. tostring(i)]

		img:SetActive(false)
	end
end

function ArenaTeamFormationItem2:getTeamBtn()
	return self.teamBtn
end

function ArenaTeamFormationItem2:getCurrentState()
	return self.currentState
end

function ArenaTeamFormationItem2:setCurrentState(state)
	local img = self.teamBtn:GetComponent(typeof(UISprite))
	local img_src = ""
	local icon_src = ""

	if state == "chosen" then
		img_src = "white_btn_65_65"
		icon_src = "arena_3v3_cancel"
	elseif state == "unchosen" then
		img_src = "white_btn_65_65"
		icon_src = "arena_3v3_exchange_team"
	elseif state == "switch" then
		img_src = "blue_btn_65_65"
		icon_src = "arena_3v3_move_team"
	end

	xyd.setUISpriteAsync(img, nil, img_src, function ()
	end)
	xyd.setUISpriteAsync(self.teamBtnIcon, nil, icon_src, function ()
	end)

	self.currentState = state
end

return ArenaTeamChangeTeamWindow
