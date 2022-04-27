local ActivityContent = import(".ActivityContent")
local NewbieCampWindow = class("NewbieCampWindow", ActivityContent)
local NewbieCampWindowItem = class("NewbieCampWindowItem", import("app.components.BaseComponent"))
local WindowTop = import("app.components.WindowTop")

function NewbieCampWindow:ctor(name, params)
	NewbieCampWindow.super.ctor(self, name, params)

	self.itemList_ = {}
	self.constructor_complete_ = false

	self.eventProxyInner_:addEventListener(xyd.event.GET_ROOKIE_MISSION_LIST, function ()
		self:updateLayout()
		xyd.models.newbieCamp:reqLostAward()
	end)
	self.eventProxyInner_:addEventListener(xyd.event.GET_ROOKIE_MISSION_AWARD, function ()
		self:updateLayout()
	end)
	self:initWindow()
end

function NewbieCampWindow:getPrefabPath()
	return "Prefabs/Windows/activity/newbie_camp_window"
end

function NewbieCampWindow:initWindow()
	local content = self.go:NodeByName("content")
	local mainTrans = self.go:NodeByName("content/groupMain")
	self.textImg_ = mainTrans:ComponentByName("textImg", typeof(UITexture))
	self.helpBtn_ = mainTrans:NodeByName("helpBtn").gameObject
	self.itemRoot1 = mainTrans:NodeByName("groupBottom/itemRoot1").gameObject
	self.itemRoot2 = mainTrans:NodeByName("groupBottom/itemRoot2").gameObject
	self.itemRoot3 = mainTrans:NodeByName("groupBottom/itemRoot3").gameObject
	self.content = content
	self.effectCon = mainTrans:ComponentByName("effectCon", typeof(UITexture))

	xyd.setUITextureAsync(self.textImg_, "Textures/newbie_camp_web/newbie_camp_text01_" .. xyd.Global.lang)
	xyd.setUITextureByNameAsync(self.textImg_, "newbie_camp_text01_" .. xyd.Global.lang, true)
	xyd.models.newbieCamp:reqData()

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "NEWBIE_CAMP_WINDOW" .. "_HELP"
		})
	end

	self.effect_ = xyd.Spine.new(self.effectCon.gameObject)

	self.effect_:setInfo("guanggao1_lihui01", function ()
		self.effect_:setRenderTarget(self.effectCon, 1)
		self.effect_:play("animation", 0)
		self.effect_:SetLocalScale(-1, 1, 1)
		self.effect_:SetLocalPosition(-94, -897, 1)
	end)
end

function NewbieCampWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function NewbieCampWindow:updateLayout()
	if not self.constructor_complete_ then
		for i = 1, 3 do
			local group = self["itemRoot" .. i]
			local item = NewbieCampWindowItem.new(group)

			item:setInfo({
				id = i,
				is_unlock = not xyd.models.newbieCamp:checkLockByPhase(i),
				count = xyd.models.newbieCamp:getCountByPhase(i)
			})

			self.itemList_[i] = item
		end

		self.constructor_complete_ = true
	else
		for i = 1, 3 do
			local item = self.itemList_[i]

			if item then
				item:setInfo({
					id = i,
					is_unlock = not xyd.models.newbieCamp:checkLockByPhase(i),
					count = xyd.models.newbieCamp:getCountByPhase(i)
				})
			end
		end
	end
end

function NewbieCampWindowItem:ctor(parentGo)
	NewbieCampWindowItem.super.ctor(self, parentGo)
end

function NewbieCampWindowItem:getPrefabPath()
	return "Prefabs/Components/newbie_camp_item"
end

function NewbieCampWindowItem:initUI()
	NewbieCampWindowItem.super.initUI(self)

	local goTrans = self.go.transform
	self.iconImg = goTrans:ComponentByName("iconImg", typeof(UISprite))
	local bg = goTrans:ComponentByName("bg", typeof(UISprite))

	xyd.setUISpriteAsync(bg, nil, "newbie_camp_bg02")

	self.label = goTrans:ComponentByName("label", typeof(UILabel))
	self.redPoint = goTrans:NodeByName("redPoint").gameObject
	self.chooseImg = goTrans:ComponentByName("chooseImg", typeof(UISprite))

	xyd.setUISpriteAsync(self.chooseImg, nil, "newbie_camp_choose_icon")

	UIEventListener.Get(self.go).onClick = function ()
		if not self.is_unlock_ then
			local limit_lev = xyd.tables.newbieCampBoardTable:getUnlockLev(self.id_)

			xyd.showToast(__("BEGINNER_QUEST_TIPS", limit_lev))

			return
		end

		xyd.WindowManager.get():openWindow("newbie_camp_list_window", {
			phase_id = self.id_
		})
		self:updateLayout()
	end
end

function NewbieCampWindowItem:setInfo(info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id_ = info.id
	self.is_unlock_ = info.is_unlock
	self.count_ = info.count

	self:updateLayout()
end

function NewbieCampWindowItem:updateLayout()
	if self.is_unlock_ then
		self.label.text = __("NEWBIE_CAMP_UNLOCK", self.count_, xyd.tables.newbieCampTable:getCountByPhase(self.id_))
	else
		self.label.text = __("BEGINNER_QUEST_LOCKED")
	end

	if self.is_unlock_ then
		if xyd.models.newbieCamp:checkAllAwardByPhase(self.id_) then
			xyd.setUISpriteAsync(self.iconImg, nil, "newbie_camp_icon" .. self.id_ .. "_2")
			self.chooseImg:SetActive(true)
		else
			xyd.setUISpriteAsync(self.iconImg, nil, "newbie_camp_icon" .. self.id_ .. "_1")
			self.chooseImg:SetActive(false)
		end
	else
		xyd.setUISpriteAsync(self.iconImg, nil, "newbie_camp_icon" .. self.id_ .. "_0")
		self.chooseImg:SetActive(false)
	end

	local list = xyd.models.newbieCamp:getStructureDataByPhase(self.id_)

	self.redPoint:SetActive(false)

	for i = 1, #list do
		local data = list[i]

		if data.status == 1 then
			self.redPoint:SetActive(true)

			break
		end
	end
end

return NewbieCampWindow
