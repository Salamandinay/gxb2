local BaseModel = class("BaseModel")
local handlers_ = {}
local innerHandlers_ = {}

function BaseModel:ctor()
	self:onRegister()
end

function BaseModel:onRegister()
end

function BaseModel:disposeAll()
	self:removeEvents()
end

function BaseModel:registerEvent(eventName, callback, this)
	if this then
		callback = handler(this, callback)
	end

	local tmpHandler = xyd.EventDispatcher.outer():addEventListener(eventName, callback)

	table.insert(handlers_, tmpHandler)

	return tmpHandler
end

function BaseModel:registerEventInner(eventName, callback, this)
	if this then
		callback = handler(this, callback)
	end

	local tmpHandler = xyd.EventDispatcher.inner():addEventListener(eventName, callback)

	table.insert(innerHandlers_, tmpHandler)

	return tmpHandler
end

function BaseModel:removeEvents()
	for i = 1, #handlers_ do
		xyd.EventDispatcher.outer():removeEventListener(handlers_[i])
	end

	for i = 1, #innerHandlers_ do
		xyd.EventDispatcher.inner():removeEventListener(innerHandlers_[i])
	end

	innerHandlers_ = {}
	handlers_ = {}
end

return BaseModel
