local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local CollectCoralBranchData = class("CollectCoralBranchData", ActivityData, true)

function CollectCoralBranchData:ctor(params)
	CollectCoralBranchData.super.ctor(self, params)
end

function CollectCoralBranchData:getUpdateTime()
	return self:getEndTime()
end

function CollectCoralBranchData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	return false
end

return CollectCoralBranchData
