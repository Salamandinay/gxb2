local ActivityContent = import(".ActivityContent")
local ActivityNewTrial = class("ActivityNewTrial", ActivityContent)

function ActivityNewTrial:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
	self:getUIComponent()
	self:initUIComponet()
	self:onRegisterEvent()
end

return ActivityNewTrial
