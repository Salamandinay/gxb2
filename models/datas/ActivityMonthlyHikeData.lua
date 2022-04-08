local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityMonthlyHikeData = class("ActivityMonthlyHikeData", ActivityData, true)

function ActivityMonthlyHikeData:getBossHp()
	local enemies = self.detail_.boss_info[1].enemies
	local totalHp = 0
	local nowHp = 0

	for _, enemyData in ipairs(enemies) do
		local hp = xyd.tables.monsterTable:getHp(enemyData.table_id)
		totalHp = totalHp + hp
		local progress = enemyData.status.hp
		nowHp = nowHp + hp * progress / 100
	end

	return nowHp / totalHp
end

function ActivityMonthlyHikeData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityMonthlyHikeData:getActivityInfo()
	return self.detail_.skill_levs
end

function ActivityMonthlyHikeData:updateBossInfo(boss_info)
	self.detail_.boss_info[1] = boss_info
end

function ActivityMonthlyHikeData:getCanFreeReset()
	return self.detail_.reset == 0
end

function ActivityMonthlyHikeData:setTempSweepInfo(params)
	self.tempSweepInfo_ = params
end

function ActivityMonthlyHikeData:clearTempSweepInfo()
	self.tempSweepInfo_ = nil
end

function ActivityMonthlyHikeData:getTempSweepInfo()
	return self.tempSweepInfo_
end

function ActivityMonthlyHikeData:register()
	self:registerEvent(xyd.event.BOSS_NEW_ADD_SKILLS, self.onChangeSkill, self)
	self:registerEvent(xyd.event.BOSS_NEW_RESET_SKILLS, self.onResetSkill, self)
end

function ActivityMonthlyHikeData:onChangeSkill(event)
	local data = event.data
	self.detail_.reset = data.reset
	self.detail_.skill_point = data.skill_point
	self.detail_.skill_levs = data.skill_levs
end

function ActivityMonthlyHikeData:onResetSkill(event)
	local total_point = 0

	for i = 1, #self.detail_.skill_levs do
		total_point = total_point + self.detail_.skill_levs[i]
		self.detail_.skill_levs[i] = 0
	end

	self.detail_.skill_point = self.detail_.skill_point + total_point
	self.detail_.reset = 1
end

return ActivityMonthlyHikeData
