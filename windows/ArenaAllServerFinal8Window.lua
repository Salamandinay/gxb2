local ArenaAllServerFinal8Window = class("ArenaAllServerFinal8Window", import(".BaseWindow"))
local AllServerPlayerIcon = import("app.components.AllServerPlayerIcon")

function ArenaAllServerFinal8Window:ctor(name, params)
	ArenaAllServerFinal8Window.super.ctor(self, name, params)

	self.data_ = params
end

function ArenaAllServerFinal8Window:initWindow()
	ArenaAllServerFinal8Window.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaAllServerFinal8Window:getUIComponent()
	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("main").gameObject
	self.labelTitle_ = main:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelTime_ = main:ComponentByName("labelTime_", typeof(UILabel))
	self.closeBtn = main:NodeByName("closeBtn").gameObject
	self.labelTip1 = main:ComponentByName("group1/groupTips1/labelTip1", typeof(UILabel))
	self.labelTip2 = main:ComponentByName("group2/groupTips2/labelTip2", typeof(UILabel))
	self.labelTip3 = main:ComponentByName("group3/groupTips3/labelTip3", typeof(UILabel))
	self.player1 = main:NodeByName("group1/player1").gameObject

	for i = 2, 4 do
		self["player" .. i] = main:NodeByName("group2/player" .. i).gameObject
	end

	for i = 5, 8 do
		self["player" .. i] = main:NodeByName("group3/player" .. i).gameObject
	end
end

function ArenaAllServerFinal8Window:layout()
	self.labelTitle_.text = __("ARENA_ALL_SERVER_TEXT_20", self.data_.index)
	self.labelTip1.text = __("ARENA_ALL_SERVER_TEXT_17")
	self.labelTip2.text = __("ARENA_ALL_SERVER_TEXT_18")
	self.labelTip3.text = __("ARENA_ALL_SERVER_TEXT_19")
	self.labelTime_.text = xyd.models.arenaAllServer:getTimeStr(self.data_.index, true)

	self:initPlayer()
end

function ArenaAllServerFinal8Window:registerEvent()
	self:register()
end

function ArenaAllServerFinal8Window:initPlayer()
	local playerInfos = self.data_.player_infos or {}

	for i = 1, #playerInfos do
		local prentNode = self["player" .. i]
		local item = AllServerPlayerIcon.new(prentNode)

		item:setInfo(playerInfos[i])

		if i ~= 1 then
			item:setType("arena_all_server_final_small")
		end

		item:setNoClick(true)
	end
end

return ArenaAllServerFinal8Window
