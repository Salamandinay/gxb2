local Player = class("Player", import("app.models.BaseModel"))

function Player:ctor(...)
	Player.super.ctor(self, ...)
end

function Player:onRegister()
	Player.super.onRegister(self)
	self:registerEvent(xyd.event.PLAYER_INFO, handler(self, self.onPlayerInfo_))
end

function Player:onPlayerInfo_(event)
	local params = event.data

	if self.playerID_ ~= nil and self.playerID_ ~= params.player_id then
		return
	end

	self:populate(params)
end

function Player:populate(params)
	self.playerID_ = params.player_id
	self.playerName_ = params.player_name
	self.level_ = params.level
end

function Player:getPlayerID()
	return self.playerID_
end

function Player:getPlayerName()
	return self.playerName_
end

function Player:getLevel()
	return self.level_
end

return Player
