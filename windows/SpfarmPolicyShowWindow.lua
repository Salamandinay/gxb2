local SpfarmPolicyShowWindow = class("SpfarmPolicyShowWindow", import(".BaseWindow"))
local SettingUpInfoItem = class("SettingUpInfoItem", import("app.components.CopyComponent"))
local policyBuildNameList = {
	__("ACTIVITY_SPFARM_TEXT44"),
	__("ACTIVITY_SPFARM_TEXT45"),
	__("ACTIVITY_SPFARM_TEXT46"),
	__("ACTIVITY_SPFARM_TEXT47")
}

function SettingUpInfoItem:ctor(go, parent)
	self.parent_ = parent

	SettingUpInfoItem.super.ctor(self, go)
end

function SettingUpInfoItem:initUI()
	local itemTrans = self.go.transform
	self.groupTitleBg_ = itemTrans:NodeByName("groupTitle/img").gameObject
	self.dragBg_ = self.groupTitleBg_:GetComponent(typeof(UIDragScrollView))
	self.groupDialog_ = itemTrans:NodeByName("groupDialog").gameObject
	self.labelTitle_ = itemTrans:ComponentByName("groupTitle/labelTitle", typeof(UILabel))
	self.imgArr_ = itemTrans:ComponentByName("groupTitle/imgArr", typeof(UISprite))
	self.titleIcon_ = itemTrans:ComponentByName("groupTitle/icon", typeof(UISprite))
	self.dialogImg_ = itemTrans:ComponentByName("groupDialog/img", typeof(UISprite))
	self.dialogGrid_ = itemTrans:NodeByName("groupDialog/img/scrollView/grid")
	self.lineItem_ = itemTrans:NodeByName("groupDialog/img/lineItem").gameObject

	self.lineItem_:SetActive(false)
end

function SettingUpInfoItem:setInfos(params)
	self.ids_ = params.ids
	self.index_ = params.lev + 1
	self.obj_ = self.parent_
	self.table_ = params.table
	self.scrollView_ = params.scrollView
	self.dragBg_.scrollView = params.scrollView
	self.long_ = params.long

	self:layout()
	self:registerEvent()
end

function SettingUpInfoItem:layout()
	self.labelTitle_.text = __("ACTIVITY_SPFARM_TEXT51") .. self.index_ - 1
	self.dialogImg_.transform.localScale = Vector3(1, 0, 1)
end

function SettingUpInfoItem:createDialog()
	self.totalHeight = 0

	for index, id in ipairs(self.ids_) do
		self:initText(id)
	end

	self.dialogImg_.height = self.totalHeight + 40
	self.all = self.long_ * 92 + self.totalHeight + 40 - 546
	self.dialogImg_.transform.localScale = Vector3(1, 0, 1)
end

function SettingUpInfoItem:destroyDialog()
	NGUITools.DestroyChildren(self.dialogGrid_.transform)
end

function SettingUpInfoItem:initText(id)
	local num = xyd.tables.activitySpfarmPolicyTable:getNum(id)
	local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
	local params = xyd.tables.activitySpfarmPolicyTable:getParams(id)
	local desc = nil
	local title = xyd.tables.activitySpfarmPolicyTextTable:getTitle(type)

	if type == 1 then
		desc = xyd.tables.activitySpfarmPolicyTextTable:getDesc(type, policyBuildNameList[params], num)
	elseif type == 2 then
		desc = xyd.tables.activitySpfarmPolicyTextTable:getDesc(type, policyBuildNameList[params], num)
	else
		desc = xyd.tables.activitySpfarmPolicyTextTable:getDesc(type, num)
	end

	local itemNew = NGUITools.AddChild(self.dialogGrid_.gameObject, self.lineItem_)

	itemNew:SetActive(true)

	itemNew.transform.localPosition = Vector3(0, -self.totalHeight, 0)
	local label = itemNew:ComponentByName("lable", typeof(UILabel))
	local imgIcon = itemNew:ComponentByName("imgIcon", typeof(UISprite))

	imgIcon.gameObject:SetActive(false)
	self:setLabelInfo(label, {
		c = 1549556991,
		s = 20,
		x = 16,
		t = desc
	})

	label.width = 604
	label.transform.localPosition = Vector3(-284, 0, 0)
	self.totalHeight = self.totalHeight + label.height + 10
	local goLine1 = NGUITools.AddChild(itemNew, imgIcon.gameObject)
	local goLine1Img = goLine1:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(goLine1Img, nil, "setting_up_help_icon_2", nil, )

	goLine1Img.transform.localScale = Vector3(0.5, 0.5, 0.5)

	goLine1:SetLocalPosition(-300, -10, 0)

	self.totalHeight = self.totalHeight + 10
end

function SettingUpInfoItem:setLabelInfo(label, params)
	if params.w then
		label.width = params.w
	end

	if params.h then
		label.height = params.h
	end

	if params.s then
		label.fontSize = params.s
	end

	if params.c then
		label.color = Color.New2(params.c)
	end

	if params.t then
		label.text = params.t
	end

	if params.b then
		label.fontStyle = UnityEngine.FontStyle.Bold
	else
		label.fontStyle = UnityEngine.FontStyle.Normal
	end

	if params.p then
		label.pivot = UIWidget.Pivot[params.p]
	end

	if params.ec then
		label.effectStyle = UILabel.Effect.Outline
		label.effectDistance = Vector2(1, 1)
		label.effectColor = Color.New2(params.ec)
	end
end

function SettingUpInfoItem:registerEvent()
	UIEventListener.Get(self.groupTitleBg_.gameObject).onClick = handler(self, self.onClick)
end

function SettingUpInfoItem:onClick()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.isShow_ then
		self:playHide()
	else
		self.obj_:playHideItem()
		self:createDialog()

		self.isShow_ = true

		self.dialogImg_:SetLocalScale(1, 1, 1)

		self.dialogImg_.alpha = 0

		self.dialogImg_:SetActive(true)
		self.table_:Reposition()
		self.dialogImg_:SetLocalScale(1, 0, 1)

		self.dialogImg_.alpha = 1
		local action = DG.Tweening.DOTween.Sequence()
		self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 0)

		if tonumber(self.id_) == xyd.HELP_SETTING_UP_ID.GROUP_BUFF then
			for i = 1, #self.buffItems do
				self.buffItems[i]:reposition()
			end
		end

		action:Insert(0, self.dialogImg_.transform:DOScale(Vector3(1, 1, 1), 0.1))
		action:AppendCallback(function ()
			self.table_:Reposition()
			XYDCo.WaitForFrame(1, function ()
				self.scrollView_:SetDragAmount(0, math.min(1, (self.index_ - 1) * 92 / self.all), false)
			end, nil)
		end)
	end
end

function SettingUpInfoItem:isShow()
	return self.isShow_
end

function SettingUpInfoItem:playHide(noAction, callback)
	if not self.isShow_ then
		return
	end

	self:destroyDialog()

	self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 90)

	if noAction then
		self.isShow_ = false
		self.dialogImg_.transform.localScale = Vector3(1, 0, 1)

		self.table_:Reposition()
	else
		local action = DG.Tweening.DOTween.Sequence()

		action:Insert(0, self.dialogImg_.transform:DOScale(Vector3(1, 0, 1), 0.1))
		action:AppendCallback(function ()
			self.dialogImg_:SetActive(false)

			self.isShow_ = false

			XYDCo.WaitForFrame(1, function ()
				self.table_:Reposition()

				if callback then
					callback()
				end
			end, nil)
		end)
	end
end

function SpfarmPolicyShowWindow:ctor(name, params)
	SpfarmPolicyShowWindow.super.ctor(self, name, params)

	self.levelNum_ = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM):getFamousNum()
	self.Items_ = {}
end

function SpfarmPolicyShowWindow:initWindow()
	self:getUIComponent()
	self:layoutList()
end

function SpfarmPolicyShowWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.scrollViewPolicy_ = winTrans:ComponentByName("scrollViewPolicy", typeof(UIScrollView))
	self.listTable_ = winTrans:ComponentByName("scrollViewPolicy/listTable", typeof(UITable))
	self.policyItem_ = winTrans:NodeByName("scrollViewPolicy/policyItem").gameObject
	self.titleLabel_.text = __("ACTIVITY_SPFARM_TEXT50")
end

function SpfarmPolicyShowWindow:layoutList()
	local policyIds = xyd.tables.activitySpfarmPolicyTable:getFamousWithIds()
	local widget = self.listTable_:GetComponent(typeof(UIWidget))
	widget.alpha = 0

	for i = 0, 15 do
		local lev = i
		local ids = policyIds[i]

		if not self.Items_[lev] then
			local newItemRoot = NGUITools.AddChild(self.listTable_.gameObject, self.policyItem_)
			local item = SettingUpInfoItem.new(newItemRoot, self)

			item:setInfos({
				ids = ids,
				lev = lev,
				table = self.listTable_,
				scrollView = self.scrollViewPolicy_,
				long = #policyIds
			})

			self.Items_[lev] = item
		end
	end

	widget.alpha = 1

	XYDCo.WaitForFrame(1, function ()
		if self.listTable_ == nil then
			return
		end

		self.listTable_:Reposition()
		self.scrollViewPolicy_:ResetPosition()

		self.scrollPos_ = self.scrollViewPolicy_.transform.localPosition

		if self.Items_[self.levelNum_] then
			self.Items_[self.levelNum_]:onClick()
		end
	end, nil)
end

function SpfarmPolicyShowWindow:playHideItem()
	for idx, item in pairs(self.Items_) do
		if item:isShow() then
			item:playHide(true)
		end
	end
end

return SpfarmPolicyShowWindow
