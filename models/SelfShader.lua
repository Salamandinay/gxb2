local BaseModel = import(".BaseModel")
local SelfShader = class("SelfShader", BaseModel)

function SelfShader:ctor()
	SelfShader.super.ctor(self)
end

function SelfShader:onRegister()
	BaseModel:onRegister()
end

function SelfShader:changeSaturation(obj)
	if type(obj) == "table" then
		obj = obj:getGameObject()
	end

	XYDUtils.ChangeTextureShders(obj.gameObject, "UI/Tex Saturation", Color.New2(1291845887), false)
end

function SelfShader:clearSaturation(obj)
	if type(obj) == "table" then
		obj = obj:getGameObject()
	end

	XYDUtils.ResumeTextureShders(obj.gameObject, false)
end

return SelfShader
