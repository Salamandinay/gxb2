local FunctionOpen = class("FunctionOpen", import("app.models.BaseModel"))
local PlayerPrefs = UnityEngine.PlayerPrefs

function FunctionOpen:ctor(...)
	FunctionOpen.super.ctor(self, ...)

	self.openFuncsIndex = {}
end

function FunctionOpen:onRegister()
	FunctionOpen.super.onRegister(self)
	self:registerEvent(xyd.event.LEV_CHANGE, handler(self, self.onFunctionStageChange))
end

function FunctionOpen:getOpenFunctions()
	return xyd.tables.functionTable:getFuncIDsByLev()
end

function FunctionOpen:getOpenFuncIndex()
	return self.openFuncsIndex
end

function FunctionOpen:initData()
	local openFuncs = self:getOpenFunctions()

	for k, v in pairs(openFuncs) do
		self.openFuncsIndex[tostring(v)] = true
	end
end

function FunctionOpen:onFunctionStageChange(event)
	self:initData()

	local oldIDs = {}
	local oldIDs_ = xyd.models.selfPlayer:getOpenedFuncs()

	for key, value in pairs(oldIDs_) do
		table.insert(oldIDs, tonumber(key))
	end

	local newIDs = xyd.tables.functionTable:getFuncIDsByLev()

	table.sort(oldIDs, function (a, b)
		return b < a and true or false
	end)
	table.sort(newIDs, function (a, b)
		return b < a and true or false
	end)

	while #newIDs > 0 do
		if oldIDs[#oldIDs] == newIDs[#newIDs] then
			table.remove(oldIDs, #oldIDs)
			table.remove(newIDs, #newIDs)
		else
			local id = table.remove(newIDs, #newIDs)

			if xyd.Global.isReview ~= 1 or xyd.tables.functionTable:openInReview(id) then
				local params = {
					name = xyd.event.FUNCTION_OPEN,
					data = {
						functionID = id
					}
				}

				xyd.EventDispatcher.outer():dispatchEvent(params)
				xyd.EventDispatcher.inner():dispatchEvent(params)

				oldIDs_[id] = 1
			end
		end
	end
end

function FunctionOpen:onWindowClose()
	self:onFunctionStageChange()
end

return FunctionOpen
