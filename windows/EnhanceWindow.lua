local BaseWindow = import(".BaseWindow")
local BaseComponent = import("app.components.BaseComponent")
local EnhanceWindow = class("EnhanceWindow", BaseWindow)
local EnhanceItem = class("EnhanceItem", BaseComponent)
local EnhanceContentItem = class("EnhanceContentItem", BaseComponent)

function EnhanceWindow:ctor(name, params)
	EnhanceWindow.super.ctor(self, name, params)

	self.enhanceItemList_ = {}
end

function EnhanceWindow:initWindow()
	EnhanceWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("groupAction/groupTop/labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:ComponentByName("groupAction/groupTop/closeBtn", typeof(UISprite)).gameObject
	self.scrollView_ = winTrans:ComponentByName("groupAction/scrollView", typeof(UIScrollView))
	self.table_ = winTrans:ComponentByName("groupAction/scrollView/listTable", typeof(UITable))

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.labelTitle_.text = __(self:winName())
end

function EnhanceWindow:playOpenAnimation()
	EnhanceWindow.super.playOpenAnimation(self, function ()
		self:layout()
	end)
end

function EnhanceWindow:layout()
	self:registerEvent()
	self:setLayout()
end

function EnhanceWindow:registerEvent()
end

function EnhanceWindow:setLayout()
	local ids = xyd.tables.enhanceTable:getIDs()

	for idx, id in ipairs(ids) do
		XYDCo.WaitForFrame(idx, function ()
			if not tolua.isnull(self.table_) and not tolua.isnull(self.table_.gameObject) then
				local enhanceItem = EnhanceItem.new(self.table_.gameObject)

				enhanceItem:SetInfo({
					id = id,
					scrollView = self.scrollView_,
					parent = self
				})
				table.insert(self.enhanceItemList_, enhanceItem)
				self.table_:Reposition()

				if idx == 1 or idx == #ids then
					self.scrollView_:ResetPosition()
				end
			end
		end, nil)
	end
end

function EnhanceWindow:setCurrent(item, isOpen)
	if not isOpen then
		self.currentItem_ = nil

		return
	end

	if self.currentItem_ then
		self.currentItem_:closeContent()
	end

	self.currentItem_ = item
end

function EnhanceWindow:willClose(params, skipAnimation, force)
	EnhanceWindow.super.willClose(self, params, skipAnimation, force)
end

function EnhanceItem:ctor(parentGo)
	EnhanceItem.super.ctor(self, parentGo)

	local itemTrans = self.go.transform
	self.contentList_ = {}
	self.labelTitle_ = itemTrans:ComponentByName("groupTitle/labelTitle", typeof(UILabel))
	self.imgArr_ = itemTrans:ComponentByName("groupTitle/imgArr", typeof(UISprite))
	self.groupTitleBg_ = itemTrans:NodeByName("groupTitle/img").gameObject
	self.dragBg_ = self.groupTitleBg_:GetComponent(typeof(UIDragScrollView))
	self.titleIcon_ = itemTrans:ComponentByName("groupTitle/icon", typeof(UISprite))
	self.dialogImg_ = itemTrans:ComponentByName("groupDialog/img", typeof(UISprite))
	self.dialogGrid_ = itemTrans:ComponentByName("groupDialog/img/itemGrid", typeof(UIGrid))
end

function EnhanceItem.getPrefabPath()
	return "Prefabs/Components/enhance_item"
end

function EnhanceItem:SetInfo(params)
	self.id_ = params.id
	self.scrollView_ = params.scrollView
	self.parent_ = params.parent
	self.dragBg_.scrollView = params.scrollView
	self.labelTitle_.text = xyd.tables.enhanceTextTable:getTitle(self.id_)

	xyd.setUISpriteAsync(self.titleIcon_, nil, xyd.tables.enhanceTable:getIcon(self.id_), nil, )
	self:createContent()
	self:setTouchEvent()
end

function EnhanceItem:createContent()
	local texts = xyd.tables.enhanceTextTable:getText(self.id_)

	for idx, _ in ipairs(texts) do
		local content = EnhanceContentItem.new(self.dialogGrid_.gameObject)

		content:setInfos(self.id_, idx)
		table.insert(self.contentList_, content)
	end

	self.dialogGrid_:Reposition()

	self.dialogImg_.height = #texts * 74 - 2
	self.openHeight = #texts * 74 - 2
	self.dialogImg_.transform.localScale = Vector3(1, 0, 1)
	self.showContent = -1
	self.height = 80
end

function EnhanceItem:setTouchEvent()
	UIEventListener.Get(self.groupTitleBg_.gameObject).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if self.showContent == 0 then
			return
		elseif self.showContent == -1 then
			self:openContent()

			local wnd = xyd.WindowManager.get():getWindow("enhance_window")

			if wnd then
				wnd:setCurrent(self, true)
			end
		elseif self.showContent == 1 then
			self:closeContent(function ()
				local wnd = xyd.WindowManager:get():getWindow("enhance_window")

				if wnd then
					wnd:setCurrent(self, false)
				end
			end)
		end
	end
end

function EnhanceItem:closeContent(callback)
	self.showContent = 0
	self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 90)
	local action = DG.Tweening.DOTween.Sequence()
	self.dialogImg_.alpha = 0

	for i = 0, 5 do
		action:Insert(0.033 * i, self.dialogImg_.transform:DOScale(Vector3(1, 1 - 0.16666666666666666 * (i + 1), 1), 0.033))
		action:InsertCallback(0.033 * (i + 1), function ()
			self.parent_.table_:Reposition()
		end)
	end

	action:AppendCallback(function ()
		XYDCo.WaitForFrame(1, function ()
			self.parent_.table_:Reposition()
		end, nil)

		self.showContent = -1

		if callback then
			callback()
		end
	end)
end

function EnhanceItem:openContent()
	self.showContent = 0
	self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 0)
	self.dialogImg_.alpha = 1
	local action = DG.Tweening.DOTween.Sequence()
	local singleHeight = 98
	local scrollerV = singleHeight * (self.id_ - 1)
	local all = #xyd.tables.enhanceTable:getIDs() * singleHeight + self.openHeight - 653

	for i = 0, 5 do
		action:Insert(0.033 * i, self.dialogImg_.transform:DOScale(Vector3(1, 0.16666666666666666 * (i + 1), 1), 0.033))
		action:InsertCallback(0.033 * (i + 1), function ()
			self.parent_.table_:Reposition()
		end)
	end

	action:AppendCallback(function ()
		self.showContent = 1

		XYDCo.WaitForFrame(1, function ()
			self.parent_.scrollView_:SetDragAmount(0, math.min(1, scrollerV / all), false)
		end, nil)
	end)
end

function EnhanceContentItem:ctor(parentGo)
	EnhanceContentItem.super.ctor(self, parentGo)

	local itemTrans = self.go.transform
	self.labelContent_ = itemTrans:ComponentByName("labelContent", typeof(UILabel))
	self.imgIcon_ = itemTrans:ComponentByName("imgIcon", typeof(UISprite))
	self.btnLable_ = itemTrans:ComponentByName("btnApply/label", typeof(UILabel))
	self.btn_ = itemTrans:ComponentByName("btnApply", typeof(UISprite))
	self.rectSplit_ = itemTrans:ComponentByName("e:rect", typeof(UISprite))
	self.mask_ = itemTrans:ComponentByName("btnApply/mask", typeof(UISprite))

	self.mask_.gameObject:SetActive(false)
end

function EnhanceContentItem.getPrefabPath()
	return "Prefabs/Components/enhance_content_item"
end

function EnhanceContentItem:setInfos(id, idx)
	self.id_ = id
	self.index_ = idx
	local texts = xyd.tables.enhanceTextTable:getText(self.id_)
	self.labelContent_.text = texts[self.index_]
	local isGoto = xyd.tables.enhanceTable:isGoto(self.id_)

	self.btn_.gameObject:SetActive(isGoto[self.index_] ~= 0)

	if isGoto[self.index_] then
		self:setBtn(isGoto[self.index_])
	end

	self.rectSplit_.gameObject:SetActive(self.index_ ~= #texts)
end

function EnhanceContentItem:setBtn(getWayID)
	self.btnLable_.text = __("GOTO")
	local function_id = xyd.tables.getWayTable:getFunctionId(getWayID)

	if not xyd.checkFunctionOpen(function_id, true) then
		self.mask_.gameObject:SetActive(true)
	end

	UIEventListener.Get(self.btn_.gameObject).onClick = function ()
		local windows = xyd.tables.getWayTable:getGoWindow(getWayID)
		local params = xyd.tables.getWayTable:getGoParam(getWayID)

		if not xyd.checkFunctionOpen(function_id) then
			return
		end

		if getWayID == xyd.getWays.OLD_SCHOOL then
			xyd.models.oldSchool:openOldSchoolMainWindow()
		else
			xyd.WindowManager.get():closeWindow("enhance_window")
			xyd.WindowManager.get():closeWindow("setting_up_window")

			for i = 1, #windows do
				local windowName = windows[i]

				if windowName == "trial_enter_window" and xyd.models.trial:checkClose() then
					xyd.alertTips(__("NEW_TRIAL_RESET_TEXT01"))

					return
				end

				xyd.WindowManager.get():openWindow(windowName, params[i])
			end
		end
	end
end

return EnhanceWindow
