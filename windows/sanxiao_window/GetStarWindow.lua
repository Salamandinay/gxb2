local GetStarWindow = class("GetStarWindow", import(".BaseWindow"))
local MappingData = xyd.MappingData

function GetStarWindow:ctor(name, params)
	GetStarWindow.super.ctor(self, name, params)
end

function GetStarWindow:initWindow()
	GetStarWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function GetStarWindow:getUIComponent()
	local winTrans = self.window_.transform
	self._closeBtn = winTrans:NodeByName("e:Skin/group_bg/_closeBtn").gameObject
	self._nextBtn = winTrans:NodeByName("e:Skin/group_bg/_nextBtn").gameObject
	self._explainImg = winTrans:ComponentByName("e:Skin/group_bg/explainImg", typeof(UISprite))
	self.tileText = winTrans:ComponentByName("e:Skin/group_bg/_title", typeof(UILabel))
	self.tipsText = winTrans:ComponentByName("e:Skin/group_bg/_tips", typeof(UILabel))
	self.btnText = winTrans:ComponentByName("e:Skin/group_bg/_nextBtn/_btn_text", typeof(UILabel))
end

function GetStarWindow:initUIComponent()
	xyd.setNormalBtnBehavior(self._nextBtn, self, self._onNextBtn)
	xyd.setNormalBtnBehavior(self._closeBtn, self, self._onCloseBtn)
	self:setDefaultBgClick(function ()
		self:_onCloseBtn()
	end)

	local tipImgName = "get_star_tips"
	local tipImgAtlas = MappingData[tipImgName]

	xyd.setUISpriteAsync(self._explainImg, tipImgAtlas, tipImgName)

	self.btnText.text = __("PLAY_A_LEVEL")
	self.tipsText.text = __("GET_STAR_TIPS")
	self.tileText.text = __("GET_STAR_TITLE")
end

function GetStarWindow:_onNextBtn()
	self:disableBtns()
	self:close(function ()
		local playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)

		if playerInfoModel:hasStamina() then
			xyd.WindowManager.get():openWindow("pre_game_window", {
				totalLevel = xyd.SelfInfo.get():getCurrentLevel()
			})
		else
			xyd.WindowManager.get():openWindow("stamina_window")
		end
	end)
end

function GetStarWindow:_onCloseBtn()
	self:disableBtns()
	self:close(function ()
		XYDCo.WaitForTime(5 * xyd.TweenDeltaTime, function ()
			xyd.EventDispatcher:inner():dispatchEvent({
				name = xyd.event.CHECK_UI_DISPLAY
			})
		end, nil)
	end)
end

function GetStarWindow:disableBtns()
	self:setDefaultBgClick(nil)

	self._nextBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self._closeBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

return GetStarWindow
