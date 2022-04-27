local ActivityContent = import(".ActivityContent")
local NewYearNewSignIn = class("NewYearNewSignIn", ActivityContent)
local NewYearNewSignInItem = class("NewYearNewSignInItem", import("app.components.CopyComponent"))
local ActivityFestivalLoginTable = xyd.tables.activityFestivalLoginTable
local json = require("cjson")

function NewYearNewSignIn:ctor(parentGO, params, parent)
	self.items_ = {}
	self.total_days_ = ActivityFestivalLoginTable:getDays()

	ActivityContent.ctor(self, parentGO, params, parent)
end

function NewYearNewSignIn:getPrefabPath()
	return "Prefabs/Windows/activity/new_year_new_signin"
end

function NewYearNewSignIn:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:setItems()
	self:updateStatus()
end

function NewYearNewSignIn:getUIComponent()
	local go = self.go:NodeByName("allGroup").gameObject
	self.textImg = go:ComponentByName("textImg", typeof(UITexture))
	self.big_bg = go:NodeByName("imgBg").gameObject
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.explainLabel = self.contentGroup:ComponentByName("explainLabel", typeof(UILabel))
	self.scroller = self.contentGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.itemGroup_UILayout = self.scroller:ComponentByName("itemGroup", typeof(UILayout))
	self.sign_item = self.contentGroup:NodeByName("new_year_signin_item").gameObject
	self.signTextLabel = self.go:ComponentByName("downGroup/textGroup/signTextLabel", typeof(UILabel))
	self.signCountLabel = self.go:ComponentByName("downGroup/textGroup/signCountLabel", typeof(UILabel))
	self.textGroup_UILayout = self.go:ComponentByName("downGroup/textGroup", typeof(UILayout))
	self.downGroup = self.go:NodeByName("downGroup").gameObject
end

function NewYearNewSignIn:initUIComponent()
	self.signTextLabel.text = __("NEWYEAR_TEXT02")
	self.explainLabel.text = __("NEWYEAR_TEXT01")

	xyd.setUITextureByNameAsync(self.textImg, "newyear_new_signin_text_" .. xyd.Global.lang, true)

	if xyd.Global.lang == "de_de" then
		self.explainLabel.height = 74
		self.explainLabel:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Left

		self.explainLabel:X(-146)
	end
end

function NewYearNewSignIn:resizeToParent()
	NewYearNewSignIn.super.resizeToParent(self)
	self.big_bg:Y(37 + -37 * self.scale_num_contrary)
	self.textImg:Y(-138.8 + -57.19999999999999 * self.scale_num_contrary)
	self.contentGroup:Y(-550 + -87.39999999999998 * self.scale_num_contrary)
	self.contentGroup:Y(-550 + -87.39999999999998 * self.scale_num_contrary)
	self.downGroup:Y(0 + -87.4 * self.scale_num_contrary)
end

function NewYearNewSignIn:setItems()
	self.items_ = {}
	local ids = ActivityFestivalLoginTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])
		local info = {
			id = id,
			is_completed = self:getStatus(id)
		}
		local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.sign_item.gameObject)
		local item = NewYearNewSignInItem.new(tmp, info, self)

		table.insert(self.items_, item)
	end

	self:waitForFrame(1, function ()
		self.itemGroup_UILayout:Reposition()
		self.scroller:ResetPosition()

		if self.activityData.detail.day > 1 then
			self:jumpToInfo(math.min(self.activityData.detail.day, self.total_days_))
		end
	end)
end

function NewYearNewSignIn:updateStatus()
	local numYet = 0

	for i, v in pairs(self.activityData.detail.awarded) do
		if v == 1 then
			numYet = numYet + 1
		end
	end

	self.signCountLabel.text = numYet .. "/" .. self.total_days_

	self.textGroup_UILayout:Reposition()
end

function NewYearNewSignIn:onRegister()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function NewYearNewSignIn:onTouchSign()
end

function NewYearNewSignIn:onGetAward(event)
	self.activityData = xyd.models.activity:getActivity(self.id)

	self:updateStatus()

	local awardid = -1

	for i in pairs(self.items_) do
		local backNum = self.items_[i]:updateLayout("award_back")

		if backNum ~= -1 then
			awardid = backNum
		end
	end

	if awardid ~= -1 then
		local items = {}
		local data = ActivityFestivalLoginTable:getAwards(awardid)

		for i = 1, #data do
			table.insert(items, {
				item_id = data[i][1],
				item_num = data[i][2]
			})
		end

		xyd.itemFloat(items, nil, , 6500)
	end
end

function NewYearNewSignIn:getStatus(id)
	return self.activityData.detail.awarded[id] == 1
end

function NewYearNewSignIn:checkCanSign()
end

function NewYearNewSignIn:jumpToInfo(curid)
	local currIndex = curid

	if not currIndex then
		return
	end

	if curid == 1 then
		return
	end

	local panel = self.scroller.gameObject:GetComponent(typeof(UIPanel))
	local height = panel.baseClipRegion.w
	local width = panel.baseClipRegion.z
	local itemSize = 134
	local allHeight = curid * 190 + 130 * (self.total_days_ - curid) + 5 * self.total_days_
	local maxDeltaY = allHeight - height
	local deltaY = (curid - 1) * 190 + 5 * (curid - 1) - 60
	deltaY = math.min(deltaY, maxDeltaY)

	self.scroller:MoveRelative(Vector3(0, deltaY, 0))
end

function NewYearNewSignInItem:ctor(go, itemData, parent)
	self.data = itemData
	self.is_completed_ = false
	self.parent = parent

	NewYearNewSignInItem.super.ctor(self, go, parent)
end

function NewYearNewSignInItem:initUI()
	self.itemGroup = self.go:NodeByName("group/itemGroup").gameObject
	self.group = self.go:NodeByName("group").gameObject
	self.timeLabel = self.go:ComponentByName("group/timeLabel", typeof(UILabel))
	self.bg_ = self.go:ComponentByName("group/bg_", typeof(UITexture))
	self.go_UIWidget = self.go:GetComponent(typeof(UIWidget))
	self.signBtn = self.group:NodeByName("signBtn").gameObject
	self.signBtnText = self.signBtn:ComponentByName("signBtnText", typeof(UILabel))

	self:updateInfo()

	UIEventListener.Get(self.signBtn.gameObject).onClick = handler(self, self.onTouch)
end

function NewYearNewSignInItem:updateInfo()
	self.id_ = self.data.id
	self.timeLabel.text = __("ACTIVITY_WEEK_DATE", self.id_)
	local awards = ActivityFestivalLoginTable:getAwards(self.id_)
	self.state = self.parent.activityData.detail.awarded[self.id_]
	self.items_ = {}

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #awards do
		local data = awards[i]
		local item = xyd.getItemIcon({
			show_has_num = true,
			hideText = true,
			scale = 0.7,
			uiRoot = self.itemGroup,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scroller
		})

		table.insert(self.items_, item)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	self:updateLayout()
end

function NewYearNewSignInItem:updateLayout(type)
	if type and type == "award_back" then
		if self.parent.activityData.detail.day < self.id_ then
			return -1
		end

		if self.state == self.parent.activityData.detail.awarded[self.id_] then
			return -1
		end
	end

	self.state = self.parent.activityData.detail.awarded[self.id_]
	self.is_completed_ = false

	if self.parent.activityData.detail.day < self.id_ then
		xyd.setUITextureByNameAsync(self.bg_, "new_year_new_signin_item_bg3", true)

		self.go_UIWidget.height = 130

		self.signBtn:SetActive(false)
		xyd.setTouchEnable(self.signBtn, false)
	else
		self.signBtn:SetActive(true)

		if self.parent.activityData.detail.awarded[self.id_] == 0 then
			xyd.setUITextureByNameAsync(self.bg_, "new_year_new_signin_item_bg2", true)
			xyd.applyChildrenOrigin(self.signBtn)
			xyd.setTouchEnable(self.signBtn, true)

			if tonumber(self.id_) < tonumber(self.parent.activityData.detail.day) then
				self.signBtnText.text = __("RE_CHECKIN")
			else
				self.signBtnText.text = __("CHECKIN_TEXT04")
			end
		else
			xyd.setUITextureByNameAsync(self.bg_, "new_year_new_signin_item_bg4", true)
			xyd.applyChildrenGrey(self.signBtn)

			self.signBtnText.text = __("ALREADY_GET_PRIZE")
			self.is_completed_ = true

			xyd.setTouchEnable(self.signBtn, false)
		end

		self.go_UIWidget.height = 190
	end

	if self.is_completed_ then
		self:setStatus(true)
	end

	return self.id_
end

function NewYearNewSignInItem:setStatus(flag)
	if #self.items_ == 0 then
		return
	end

	for i = 1, #self.items_ do
		self.items_[i]:setChoose(flag)
	end
end

function NewYearNewSignInItem:onTouch()
	if self.id_ <= self.parent.activityData.detail.day and self.parent.activityData.detail.awarded[self.id_] == 0 then
		if tonumber(self.id_) < tonumber(self.parent.activityData.detail.day) then
			local diamondNum = tonumber(ActivityFestivalLoginTable:getCost(self.id_)[2])
			local hasDiamond = xyd.models.backpack:getCrystal()

			if hasDiamond < diamondNum then
				xyd.showToast(__("NOT_ENOUGH_CRYSTAL"))

				return
			end

			xyd.alert(xyd.AlertType.YES_NO, __("RE_CHECKIN_TIPS", diamondNum), function (yes)
				if yes then
					self:sendAward()
				end
			end, __("BUY"))
		else
			self:sendAward()
		end
	end
end

function NewYearNewSignInItem:sendAward()
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.NEWYEAR_NEW_SIGNIN
	local params = {
		award_id = self.id_
	}
	msg.params = json.encode(params)

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function NewYearNewSignInItem:getDay()
	return self.id_
end

return NewYearNewSignIn
