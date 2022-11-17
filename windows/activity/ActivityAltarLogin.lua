local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityAltarLogin = class("ActivityAltarLogin", ActivityContent)
local LoginItem = class("LoginItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function ActivityAltarLogin:ctor(parentGO, params)
	ActivityAltarLogin.super.ctor(self, parentGO, params)
end

function ActivityAltarLogin:getPrefabPath()
	return "Prefabs/Windows/activity/activity_star_altar_login"
end

function ActivityAltarLogin:initUI()
	ActivityAltarLogin.super.initUI(self)

	self.itemList_ = {}

	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityAltarLogin:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("logo", typeof(UISprite))
	self.timeGroup_ = goTrans:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.labelTips_ = goTrans:ComponentByName("labelTips", typeof(UILabel))
	self.cardGroup_ = goTrans:ComponentByName("cardGroup", typeof(UIGrid))
	self.cardGroup2_ = goTrans:ComponentByName("cardGroup2", typeof(UIGrid))
	self.cardItem_ = goTrans:NodeByName("cardItem").gameObject
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject

	self:resizePosY(self.logoImg_.gameObject, 45, -27)
	self:resizePosY(self.timeGroup_.gameObject, -250, -322)
	self:resizePosY(self.labelTips_.gameObject, -280, -383)
	self:resizePosY(self.cardGroup_.gameObject, -298, -405)
	self:resizePosY(self.cardGroup2_.gameObject, -586, -711)
end

function ActivityAltarLogin:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_STAR_ALTAR_LOGIN_HELP"
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityAltarLogin:onGetAward(event)
	if event.data.activity_id == xyd.ActivityID.ACTIVITY_START_ALTAR_LOGIN then
		self:updateList()

		local details = require("cjson").decode(event.data.detail)
		local items = details.items

		xyd.itemFloat(items)

		local num = self.activityData:getLoginNum()
		self.labelTips_.text = __("ACTIVITY_STAR_ALTAR_LOGIN_TEXT01", num)
	end
end

function ActivityAltarLogin:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_star_altar_giftbag_logo_" .. xyd.Global.lang)

	local num = self.activityData:getLoginNum()
	self.labelTips_.text = __("ACTIVITY_STAR_ALTAR_LOGIN_TEXT01", num)

	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)
	end

	self.timeGroup_:Reposition()
	self:updateList()
end

function ActivityAltarLogin:updateList()
	local ids = xyd.tables.activityStarAltarLoginTable:getIDs()

	for index, id in ipairs(ids) do
		if not self.itemList_[index] then
			local itemRoot = nil

			if index <= 4 then
				itemRoot = NGUITools.AddChild(self.cardGroup_.gameObject, self.cardItem_)
			else
				itemRoot = NGUITools.AddChild(self.cardGroup2_.gameObject, self.cardItem_)
			end

			itemRoot:SetActive(true)

			self.itemList_[index] = LoginItem.new(itemRoot, self)
		end

		local is_finish = self.activityData.detail.awards[index] == 1

		self.itemList_[index]:setInfo(id, is_finish)
	end

	self:waitForFrame(1, function ()
		self.cardGroup_:Reposition()
		self.cardGroup2_:Reposition()
	end)
end

function LoginItem:ctor(go, parent)
	self.parent_ = parent
	self.itemList_ = {}

	LoginItem.super.ctor(self, go)
end

function LoginItem:initUI()
	LoginItem.super.initUI(self)
	self:getUIComponent()
end

function LoginItem:getUIComponent()
	local goTrans = self.go.transform
	self.awardBtn_ = goTrans:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = goTrans:ComponentByName("awardBtn/label", typeof(UILabel))
	self.itemGrid_ = goTrans:ComponentByName("itemGrid", typeof(UIGrid))
	self.title_ = goTrans:ComponentByName("title", typeof(UILabel))
	self.finishImg_ = goTrans:NodeByName("finishImg").gameObject
	UIEventListener.Get(self.awardBtn_).onClick = handler(self, self.onClickAward)
end

function LoginItem:setInfo(id, is_finish)
	self.is_finish = is_finish
	self.id_ = id
	self.title_.text = __("ACTIVITY_STAR_ALTAR_LOGIN_TEXT02", self.id_)
	local nowDay = self.parent_.activityData:getNowDay()

	if self.id_ <= nowDay then
		self.finishImg_:SetActive(true)

		if self.is_finish then
			self.awardBtn_:SetActive(false)
		else
			if nowDay == self.id_ then
				self.awardBtnLabel_.text = __("ACTIVITY_STAR_ALTAR_LOGIN_TEXT03")
			else
				self.awardBtnLabel_.text = __("ACTIVITY_STAR_ALTAR_LOGIN_TEXT04")
			end

			self.awardBtn_:SetActive(true)
		end
	else
		self.finishImg_:SetActive(false)
		self.awardBtn_:SetActive(false)
	end

	local awards = xyd.tables.activityStarAltarLoginTable:getAward(self.id_)

	for index, award in ipairs(awards) do
		if not self.itemList_[index] then
			self.itemList_[index] = xyd.getItemIcon({
				scale = 0.7037037037037037,
				uiRoot = self.itemGrid_.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end

		self.itemList_[index]:setChoose(self.is_finish)
	end
end

function LoginItem:onClickAward()
	if self.is_finish then
		return
	end

	local nowDay = self.parent_.activityData:getNowDay()

	if nowDay == self.id_ then
		self:sendAward()
	elseif self.id_ < nowDay then
		local diamondNum = tonumber(xyd.tables.miscTable:split2Cost("activity_star_altar_login_cost", "value", "#")[2])
		local hasDiamond = xyd.models.backpack:getCrystal()

		if hasDiamond < diamondNum then
			xyd.showToast(__("NOT_ENOUGH_CRYSTAL"))

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("RE_CHECKIN_TIPS", diamondNum), function (yes)
			if yes then
				self:sendAward()
			end
		end, __("ACTIVITY_STAR_ALTAR_LOGIN_TEXT04"))
	end
end

function LoginItem:sendAward()
	if self.is_finish then
		return
	end

	local params = cjson.encode({
		id = tonumber(self.id_)
	})

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_START_ALTAR_LOGIN, params)
end

return ActivityAltarLogin
