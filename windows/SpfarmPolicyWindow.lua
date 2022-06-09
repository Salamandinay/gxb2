local SpfarmPolicyWindow = class("SpfarmPolicyWindow", import(".BaseWindow"))
local PolicyItem = class("PolicyItem", import("app.components.CopyComponent"))
local json = require("cjson")
local policyBuildNameList = {
	__("ACTIVITY_SPFARM_TEXT44"),
	__("ACTIVITY_SPFARM_TEXT45"),
	__("ACTIVITY_SPFARM_TEXT46"),
	__("ACTIVITY_SPFARM_TEXT47")
}

function PolicyItem:ctor(go, parent)
	self.parent_ = parent

	PolicyItem.super.ctor(self, go)
end

function PolicyItem:initUI()
	self:getUIComponent()
	self:onRegister()
end

function PolicyItem:getUIComponent()
	local goTrans = self.go.transform
	self.avatarImg = goTrans:ComponentByName("avatar_img", typeof(UISprite))
	self.labelName = goTrans:ComponentByName("labelName", typeof(UILabel))
	self.labelDesc = goTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.sureBtn = goTrans:NodeByName("sureBtn").gameObject
	self.sureBtnLabel = goTrans:ComponentByName("sureBtn/label", typeof(UILabel))
	self.sureNumLabel = goTrans:ComponentByName("sureBtn/num", typeof(UILabel))
	self.finishImg = goTrans:NodeByName("finishImg").gameObject
	self.sureBtnLabel.text = __("ACTIVITY_SPFARM_TEXT48")
end

function PolicyItem:update(params)
	self.id_ = params.policy_id
	self.level_ = params.level or 0

	if self.level_ and self.level_ > 0 then
		self.finishImg:SetActive(true)
		self.sureBtn:SetActive(false)
	else
		self.finishImg:SetActive(false)
		self.sureBtn:SetActive(true)
	end

	self.cost_ = xyd.tables.activitySpfarmPolicyTable:getCost(self.id_)
	self.type_ = xyd.tables.activitySpfarmPolicyTable:getType(self.id_)
	local numNow = 0
	self.num_ = xyd.tables.activitySpfarmPolicyTable:getNum(self.id_)
	self.params_ = xyd.tables.activitySpfarmPolicyTable:getParams(self.id_) or 0
	self.index_ = params.index

	if self.type_ == 1 then
		numNow = self.parent_.activityData:getTypeBuildLimitLevUp(self.params_)

		if self.level_ and self.level_ > 0 then
			self.labelDesc.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(self.type_, policyBuildNameList[self.params_], self.num_)
		else
			self.labelDesc.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(self.type_, policyBuildNameList[self.params_], numNow .. "->" .. self.num_)
		end
	elseif self.type_ == 2 then
		numNow = self.parent_.activityData:getTypeBuildLimitNumUp(self.params_)

		if self.level_ and self.level_ > 0 then
			self.labelDesc.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(self.type_, policyBuildNameList[self.params_], self.num_)
		else
			self.labelDesc.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(self.type_, policyBuildNameList[self.params_], numNow .. "->" .. self.num_)
		end
	elseif self.type_ == 6 then
		self.labelDesc.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(self.type_, self.num_)
	else
		numNow = self.parent_.activityData:getTypeBuildLimitNum(self.type_)

		if self.level_ and self.level_ > 0 then
			self.labelDesc.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(self.type_, self.num_)
		else
			self.labelDesc.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(self.type_, numNow .. "->" .. self.num_)
		end
	end

	self.labelName.text = xyd.tables.activitySpfarmPolicyTextTable:getTitle(self.type_)
	self.sureNumLabel.text = self.cost_[2]
	local img = xyd.tables.activitySpfarmPolicyTable:getImage(self.id_)

	xyd.setUISpriteAsync(self.avatarImg, nil, img)
end

function PolicyItem:onRegister()
	UIEventListener.Get(self.sureBtn).onClick = function ()
		if xyd.models.backpack:getItemNumByID(self.cost_[1]) < self.cost_[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.cost_[1])))

			return
		end

		local timeStamp = xyd.db.misc:getValue("spfarm_policy_levelup_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "spfarm_policy_levelup",
				text = __("ACTIVITY_SPFARM_TEXT49", self.cost_[2]),
				callback = function (yes)
					self.parent_.changeIndex = self.index_

					self.parent_.activityData:reqPolicy(self.id_)
				end
			})
		else
			self.parent_.changeIndex = self.index_

			self.parent_.activityData:reqPolicy(self.id_)
		end
	end
end

function SpfarmPolicyWindow:ctor(name, params)
	SpfarmPolicyWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
	self.historyLabelList_ = {}
	self.labelItemList_ = {}
	self.policyItemList_ = {}
end

function SpfarmPolicyWindow:initWindow()
	self:getUIComponent()
	self:updateLevLabel()
	self:initLabel()
	self:updateHistoryLabel()
	self:updatePolicyItem()
	self:register()
end

function SpfarmPolicyWindow:register()
	UIEventListener.Get(self.detailBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("spfarm_policy_show_window", {})
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onSetPolicy))
end

function SpfarmPolicyWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.labelLev_ = winTrans:ComponentByName("labelLev", typeof(UILabel))
	self.labelTips_ = winTrans:ComponentByName("labelTips", typeof(UILabel))
	self.labelTips2_ = winTrans:ComponentByName("labelTips2", typeof(UILabel))
	self.labelTips3_ = winTrans:ComponentByName("labelTips3", typeof(UILabel))
	self.detailBtn_ = winTrans:NodeByName("detailBtn").gameObject
	self.scrollViewHistory_ = winTrans:ComponentByName("scrollViewHistory", typeof(UIScrollView))
	self.historyGrid_ = winTrans:ComponentByName("scrollViewHistory/grid", typeof(UILayout))
	self.singleLabel_ = winTrans:NodeByName("scrollViewHistory/singleLabel").gameObject
	self.gridPolicy_ = winTrans:ComponentByName("gridPolicy", typeof(UIGrid))
	self.policyWidgt_ = winTrans:ComponentByName("gridPolicy", typeof(UIWidget))
	self.policyItemRoot_ = winTrans:NodeByName("policyItem").gameObject
	self.effectRoot_ = winTrans:NodeByName("effectRoot").gameObject
end

function SpfarmPolicyWindow:updateLevLabel()
	self.levNum_ = self.activityData:getFamousNum()
	self.labelLev_.text = self.levNum_
end

function SpfarmPolicyWindow:initLabel()
	self.labelTips_.text = __("ACTIVITY_SPFARM_TEXT41")

	if self.levNum_ == 15 then
		self.labelTips2_.text = __("ACTIVITY_SPFARM_TEXT107")
	else
		self.labelTips2_.text = __("ACTIVITY_SPFARM_TEXT42")
	end

	self.labelTips3_.text = __("ACTIVITY_SPFARM_TEXT43")
end

function SpfarmPolicyWindow:updateHistoryLabel()
	local policyData = self.activityData.detail.policys
	self.historyLabelList_ = {}

	for id, num in ipairs(policyData) do
		if num and tonumber(num) and tonumber(num) > 0 then
			local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
			local params = xyd.tables.activitySpfarmPolicyTable:getParams(id) or 0

			if not self.historyLabelList_[type] then
				self.historyLabelList_[type] = {}
			end

			self.historyLabelList_[type][params] = id
		end
	end

	NGUITools.DestroyChildren(self.historyGrid_.transform)

	for i = 1, 5 do
		for j = 0, 4 do
			if self.historyLabelList_[i] and self.historyLabelList_[i][j] and self.historyLabelList_[i][j] > 0 then
				local id = self.historyLabelList_[i][j]
				local newItem = NGUITools.AddChild(self.historyGrid_.gameObject, self.singleLabel_)

				newItem:SetActive(true)

				local label = newItem:GetComponent(typeof(UILabel))
				local num = xyd.tables.activitySpfarmPolicyTable:getNum(id)
				local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
				local params = xyd.tables.activitySpfarmPolicyTable:getParams(id)

				if type == 1 then
					label.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(type, policyBuildNameList[params], num)
				elseif type == 2 then
					label.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(type, policyBuildNameList[params], num)
				else
					label.text = xyd.tables.activitySpfarmPolicyTextTable:getDesc(type, num)
				end
			end
		end
	end

	self.historyGrid_:Reposition()
	self.scrollViewHistory_:ResetPosition()
end

function SpfarmPolicyWindow:updatePolicyItem()
	local policy_level = nil

	if self.levNum_ >= 15 then
		policy_level = self.levNum_
	else
		policy_level = self.levNum_ + 1
	end

	local policyIds = xyd.tables.activitySpfarmPolicyTable:getFamousWithIds()[policy_level]
	local policyData = self.activityData.detail.policys

	for i = 1, 3 do
		local params = {}
		local policy_id = policyIds[i]
		params.policy_id = policy_id
		params.level = policyData[policy_id]
		params.index = i

		if not self.policyItemList_[i] then
			local newItemRoot = NGUITools.AddChild(self.gridPolicy_.gameObject, self.policyItemRoot_)

			newItemRoot:SetActive(true)

			self.policyItemList_[i] = PolicyItem.new(newItemRoot, self)
		end

		self.policyItemList_[i]:update(params)
	end

	self.gridPolicy_:Reposition()
end

function SpfarmPolicyWindow:playUpgradeAnimation()
	local changeIndex = self.changeIndex or 2

	if not self.effect_ then
		self.effect_ = xyd.Spine.new(self.effectRoot_)

		self.effect_:setInfo("fx_spfarm_lvlup", function ()
			self.effect_:play("texiao0" .. changeIndex, 1, 1)
		end)
	else
		self.effect_:play("texiao0" .. changeIndex, 1, 1)
	end

	local seq = self:getSequence()

	local function setter(value)
		self.policyWidgt_.alpha = value
	end

	self:waitForTime(0.6, function ()
		self:updatePolicyItem()
		self:updateHistoryLabel()
	end)
	seq:Insert(0.5, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.25))
	seq:Insert(0.75, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.25))
end

function SpfarmPolicyWindow:onSetPolicy(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local info = json.decode(event.data.detail)
	local type = info.type

	if type == xyd.ActivitySpfarmType.POLICY then
		if not self.levNum_ then
			self.levNum_ = self.activityData:getFamousNum()

			self:updatePolicyItem()
			self:updateHistoryLabel()

			if self.levNum_ == 15 then
				self.labelTips2_.text = __("ACTIVITY_SPFARM_TEXT107")
			else
				self.labelTips2_.text = __("ACTIVITY_SPFARM_TEXT42")
			end
		else
			local levNow = self.activityData:getFamousNum()

			if self.levNum_ < levNow then
				self:playUpgradeAnimation()
			else
				self:updatePolicyItem()
				self:updateHistoryLabel()
			end

			self.levNum_ = levNow
			self.labelLev_.text = self.levNum_

			if self.levNum_ == 15 then
				self.labelTips2_.text = __("ACTIVITY_SPFARM_TEXT107")
			else
				self.labelTips2_.text = __("ACTIVITY_SPFARM_TEXT42")
			end
		end
	end
end

return SpfarmPolicyWindow
