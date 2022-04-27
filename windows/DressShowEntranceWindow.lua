local BaseWindow = import(".BaseWindow")
local DressShowEntranceWindow = class("DressShowEntranceWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")

function DressShowEntranceWindow:ctor(name, params)
	DressShowEntranceWindow.super.ctor(self, name, params)
end

function DressShowEntranceWindow:initWindow()
	DressShowEntranceWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
	self:initTopGroup()

	if xyd.models.dressShow:checkCanGetAward() then
		xyd.models.dressShow:reqGetAward()
	end
end

function DressShowEntranceWindow:initTopGroup()
	self.windowTop_ = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop_:setItem(items)
end

function DressShowEntranceWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.logoBg_ = winTrans:NodeByName("topGroup/logoBg").gameObject
	self.logoImg_ = winTrans:ComponentByName("topGroup/logoBg/logoImg", typeof(UISprite))
	self.helpBtn_ = winTrans:NodeByName("topGroup/helpBtn").gameObject
	self.shopBtn_ = winTrans:NodeByName("topGroup/shopBtn").gameObject
	self.shopBtnRed_ = winTrans:NodeByName("topGroup/shopBtn/redPoint").gameObject
	self.scoreGroup_ = winTrans:NodeByName("topGroup/scoreGroup").gameObject
	self.scoreLabel_ = self.scoreGroup_:ComponentByName("label", typeof(UILabel))
	self.labelDesc_ = winTrans:ComponentByName("topGroup/labelDesc", typeof(UILabel))

	for i = 1, 4 do
		self["entranceBtn" .. i] = winTrans:NodeByName("entranceGroup/entranceBtn" .. i).gameObject
		self["entranceState" .. i] = self["entranceBtn" .. i]:ComponentByName("stateImg", typeof(UISprite))
		self["entranceLockLabel" .. i] = self["entranceBtn" .. i]:ComponentByName("lockLabel", typeof(UILabel))
		self["mask" .. i] = self["entranceBtn" .. i]:NodeByName("mask").gameObject
		self["titleImg" .. i] = self["entranceBtn" .. i]:ComponentByName("titleGroup/img", typeof(UISprite))
		self["titleLabel" .. i] = self["entranceBtn" .. i]:ComponentByName("titleGroup/label", typeof(UILabel))

		UIEventListener.Get(self["entranceBtn" .. i]).onClick = function ()
			self:onClickShowCase(i)
		end

		xyd.setUISpriteAsync(self["titleImg" .. i], nil, "dress_show_text_" .. xyd.Global.lang)

		self["titleLabel" .. i].text = i
	end

	local realHeight = xyd.Global.getRealHeight()

	self.logoBg_.transform:Y((realHeight - 1280) / 178 * 80 - 40)
	self.helpBtn_.transform:Y((realHeight - 1280) / 178 * 80 - 20)
	self.labelDesc_.transform:Y((realHeight - 1280) / 178 * 40 - 135)
	self.shopBtn_.transform:Y((realHeight - 1280) / 178 * 40 - 145)
end

function DressShowEntranceWindow:register()
	DressShowEntranceWindow.super.register(self)

	UIEventListener.Get(self.scoreGroup_).onClick = function ()
		xyd.openWindow("dress_show_total_award_window")
	end

	UIEventListener.Get(self.shopBtn_).onClick = function ()
		self.shopBtnRed_:SetActive(false)
		xyd.db.misc:setValue({
			key = "dress_show_shop_time",
			value = xyd.getServerTime()
		})
		xyd.models.dressShow:updateRedMark()
		xyd.openWindow("dress_show_shop_window")
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHOW_WINDOW_HELP"
		})
	end

	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_GET_AWARD, handler(self, self.onGetAward))
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_EQUIP_ONE, handler(self, self.updateScore))
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_EQUIPS, handler(self, self.updateScore))
end

function DressShowEntranceWindow:onGetAward(event)
	local awardItems = {}
	local data = xyd.decodeProtoBuf(event.data)
	local results = data.results

	if results then
		for i = 1, #results do
			local items = results[i].items

			if items and #items > 0 then
				for j = 1, #items do
					table.insert(awardItems, items[j])
				end
			end
		end
	end

	xyd.itemFloat(awardItems)
end

function DressShowEntranceWindow:layout()
	self.scoreLabel_.text = xyd.models.dressShow:getTotalScore()
	self.labelDesc_.text = __("SHOW_WINDOW_TEXT01")

	xyd.setUISpriteAsync(self.logoImg_, nil, "dress_show_logo_" .. xyd.Global.lang, nil, , true)
	self.shopBtnRed_:SetActive(xyd.models.dressShow:checkShopUpdateRed())
	self:updateShowCase()
	self:updateTitleGroup()
end

function DressShowEntranceWindow:updateTitleGroup()
	local titleConfig = {
		zh_tw = {
			z = 8,
			x = -33,
			y = 8
		},
		de_de = {
			z = 8,
			x = -77,
			y = 3.5
		},
		en_en = {
			z = -8,
			x = 30,
			y = 8
		},
		fr_fr = {
			z = -16,
			x = 56,
			y = 4
		},
		ja_jp = {
			z = 16,
			x = -64.3,
			y = 1
		},
		ko_kr = {
			z = -10,
			x = 35.3,
			y = 7.6
		}
	}
	local data = titleConfig[xyd.Global.lang]

	for i = 1, 4 do
		self["titleLabel" .. i].transform:X(data.x)
		self["titleLabel" .. i].transform:Y(data.y)

		self["titleLabel" .. i].transform.localEulerAngles = Vector3(0, 0, data.z)
	end
end

function DressShowEntranceWindow:updateScore()
	self.scoreLabel_.text = xyd.models.dressShow:getTotalScore()

	self:updateShowCase()
end

function DressShowEntranceWindow:updateShowCase()
	for i = 1, 4 do
		local function_id = xyd.tables.dressShowWindowTable:getFunctionID(i)

		if not xyd.checkFunctionOpen(function_id, true) then
			self["mask" .. i]:SetActive(true)
			self["entranceLockLabel" .. i].gameObject:SetActive(true)

			self["entranceLockLabel" .. i].text = __("SHOW_WINDOW_TEXT03")

			xyd.setUISpriteAsync(self["entranceState" .. i], nil, "memory_list_lock", nil, , true)
		else
			self["mask" .. i]:SetActive(false)
			self["entranceLockLabel" .. i].gameObject:SetActive(false)

			local score = xyd.models.dressShow:getScore(i)
			local level = xyd.models.dressShow:getLevelByScore(score)

			xyd.setUISpriteAsync(self["entranceState" .. i], nil, "dress_show_level_" .. level, nil, , true)
		end
	end
end

function DressShowEntranceWindow:onClickShowCase(show_id)
	local function_id = xyd.tables.dressShowWindowTable:getFunctionID(show_id)

	if xyd.checkFunctionOpen(function_id, true) then
		xyd.WindowManager.get():openWindow("dress_show_main_window", {
			show_case_id = show_id
		})
	else
		local name = xyd.tables.functionTextTable:getName(function_id)

		xyd.alertTips(__("SHOW_WINDOW_TEXT04", name))
	end
end

return DressShowEntranceWindow
