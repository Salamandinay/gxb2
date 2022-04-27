local ActivityCoinEmergency = import(".ActivityCoinEmergency")
local ActivityExpEmergency = class("ActivityExpEmergency", ActivityCoinEmergency)

function ActivityExpEmergency:ctor(go, params, parent)
	ActivityCoinEmergency.ctor(self, go, params, parent)
end

function ActivityExpEmergency:getPrefabPath()
	return "Prefabs/Components/exp_emergency"
end

function ActivityExpEmergency:layout()
	ActivityCoinEmergency.layout(self)
	xyd.setUITextureAsync(self.textImg, "Textures/activity_text_web/exp_emergency_text_" .. xyd.Global.lang)
end

return ActivityExpEmergency
