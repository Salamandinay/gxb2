local DBResManager = xyd.DBResManager
local EffectConstants = xyd.EffectConstants
local AreaFinishWindow = class("AreaFinishWindow", import(".BaseWindow"))
local MappingData = xyd.MappingData

function AreaFinishWindow:ctor(name, params)
	AreaFinishWindow.super.ctor(self, name, params)
end

function AreaFinishWindow:initWindow()
	AreaFinishWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:playPopupEffect()
end

function AreaFinishWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.finish_img = winTrans:ComponentByName("group_all/group_finish/finish_img", typeof(UISprite))
	self.finish_banner = winTrans:ComponentByName("group_all/group_finish/finish_banner", typeof(UISprite))
	self.char_img = winTrans:ComponentByName("group_all/group_finish/char_img", typeof(UISprite))
	self.finish_label1 = winTrans:ComponentByName("group_all/group_finish/finish_label1", typeof(UILabel))
	self.close_btn_go = winTrans:NodeByName("group_all/close_btn").gameObject
	self.start_btn_go = winTrans:NodeByName("group_all/start_btn").gameObject
	self.group_finish_go = winTrans:NodeByName("group_all/group_finish").gameObject
	self.group_finish = winTrans:ComponentByName("group_all/group_finish", typeof(UIWidget))
end

function AreaFinishWindow:initUIComponent()
	xyd.setNormalBtnBehavior(self.close_btn_go, self, self.close)
	xyd.setNormalBtnBehavior(self.start_btn_go, self, self.close)

	local finish_bg_img_name = self.params_.bg_img
	local area_label_key = self.params_.area_label_key
	local finish_banner_img_name = "mingpai"
	local char_img_name = "half_anna"

	xyd.setUISpriteAsync(self.finish_img, MappingData[finish_bg_img_name], finish_bg_img_name)
	xyd.setUISpriteAsync(self.finish_banner, MappingData[finish_banner_img_name], finish_banner_img_name)
	xyd.setUISpriteAsync(self.char_img, MappingData[char_img_name], char_img_name)

	self.finish_label1.text = __(area_label_key)
end

function AreaFinishWindow:playPopupEffect()
	DBResManager.get():newEffect(self.group_finish_go, EffectConstants.AREA_FINISH_POPUP, function (success, eff)
		if success then
			eff.transform.localScale = Vector3(100, 100, 100)
			local animComponent = eff:GetComponent(typeof(DragonBones.UnityArmatureComponent))
			animComponent.renderTarget = self.char_img
			local effAnimation = animComponent.animation

			effAnimation:Play("texiao01", 1)

			local onComplete = nil

			local function remove()
				animComponent:RemoveDBEventListener("complete", onComplete)
				UnityEngine.Object.Destroy(eff)
			end

			function onComplete()
				remove()
			end

			animComponent:AddDBEventListener("complete", onComplete)
		end
	end)
end

return AreaFinishWindow
