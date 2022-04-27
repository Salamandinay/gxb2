local CommingSoonWindow = class("CommingSoonWindow", import(".BaseWindow"))

function CommingSoonWindow:ctor(name, params)
	CommingSoonWindow.super.ctor(self, name, params)
end

function CommingSoonWindow:initWindow()
	CommingSoonWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function CommingSoonWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.group_bg = winTrans:NodeByName("e:Skin/group_bg").gameObject
	self.effect_gp = winTrans:NodeByName("e:Skin/group_bg/effect_gp").gameObject
	self.group_desc = winTrans:NodeByName("e:Skin/group_bg/group_desc").gameObject
	self.skip_btn = winTrans:NodeByName("e:Skin/group_bg/skip_btn").gameObject
end

function CommingSoonWindow:initUIComponent()
	xyd.setNormalBtnBehavior(self.skip_btn, self, self.close)
	xyd.AssetsLoader.get():loadPrefabAsync("Effects/Commingsoon_web/comingsoon", function (prefab)
		if tolua.isnull(self.group_bg) or tolua.isnull(prefab) then
			return
		end

		self.snowMan_ = NGUITools.AddChild(self.group_bg.gameObject, prefab)
		self.snowMan_.transform.localScale = Vector3(89, 89, 89)
		self.snowMan_.transform.localPosition = Vector3(-50, -450, 0)
		local snowManAnimation = self.snowMan_:GetComponent(typeof(DragonBones.UnityArmatureComponent)).animation
		self.snowMan_:GetComponent(typeof(DragonBones.UnityArmatureComponent)).sortingOrder = self.group_bg:GetComponent(typeof(UIWidget)).depth + 1

		snowManAnimation:Play("texiao01", 1)
	end)
end

return CommingSoonWindow
