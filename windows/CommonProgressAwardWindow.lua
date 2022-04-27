local CommonProgressAwardWindow = class("CommonProgressAwardWindow", import(".BaseWindow"))
local CommonProgressAwardItem = class("CommonProgressAwardItem", import("app.components.CopyComponent"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function CommonProgressAwardWindow:ctor(name, params)
	CommonProgressAwardWindow.super.ctor(self, name, params)

	self.all_info = params.all_info
	self.click_callBack = params.click_callBack
	self.if_sort = params.if_sort
	self.title_text = params.title_text
	self.wnd_type = params.wnd_type
end

function CommonProgressAwardWindow:initWindow()
	self:getUIComponent()
	CommonProgressAwardWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function CommonProgressAwardWindow:getWndType()
	return self.wnd_type
end

function CommonProgressAwardWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.bg_UIWidget = self.groupAction:ComponentByName("bg", typeof(UIWidget))
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.gridDaily = self.scrollView:NodeByName("gridDaily").gameObject
	self.gridDaily_UIWrapContent = self.scrollView:ComponentByName("gridDaily", typeof(UIWrapContent))
	self.missionItem = self.groupAction:NodeByName("missionItem").gameObject
end

function CommonProgressAwardWindow:layout()
	if self.title_text then
		self:setTitle(self.title_text)
	else
		self:setTitle(__("MAIL_AWAED_TEXT"))
	end

	if self.if_sort then
		self.sortArr_1 = {}
		self.sortArr_2 = {}
		self.sortArr_3 = {}

		for i in pairs(self.all_info) do
			table.insert(self["sortArr_" .. self.all_info[i].state], self.all_info[i])
		end

		for i in pairs(self.sortArr_2) do
			table.insert(self.sortArr_1, self.sortArr_2[i])
		end

		for i in pairs(self.sortArr_3) do
			table.insert(self.sortArr_1, self.sortArr_3[i])
		end

		self.all_info = self.sortArr_1
	end

	self.itemsArr = {}

	if #self.all_info >= 7 then
		self.bg_UIWidget.height = 710
	end

	self:waitForFrame(1, function ()
		self.wrapContent = FixedWrapContent.new(self.scrollView, self.gridDaily_UIWrapContent, self.missionItem, CommonProgressAwardItem, self)

		self:waitForFrame(1, function ()
			self.wrapContent:setInfos(self.all_info, {})
			self.scrollView:ResetPosition()
		end)
	end)
end

function CommonProgressAwardWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function CommonProgressAwardWindow:updateItemState(id, state)
	for i in pairs(self.all_info) do
		if self.all_info[i].id == id then
			self.all_info[i].state = state

			break
		end
	end

	self.wrapContent:setInfos(self.all_info, {
		keepPosition = true
	})
end

function CommonProgressAwardItem:ctor(go, parent)
	self.parent = parent

	CommonProgressAwardItem.super.ctor(self, go)
end

function CommonProgressAwardItem:initUI()
	self.go_ = self.go
	local itemTrans = self.go.transform
	self.baseWi_ = itemTrans:GetComponent(typeof(UIWidget))
	self.progressBar_ = itemTrans:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.btnGo_ = itemTrans:ComponentByName("btnGo", typeof(UISprite))
	self.btnGoLabel_ = itemTrans:ComponentByName("btnGo/label", typeof(UILabel))
	self.btnAward_ = itemTrans:ComponentByName("btnAward", typeof(UISprite))
	self.btnAward_box_ = itemTrans:ComponentByName("btnAward", typeof(UnityEngine.BoxCollider))
	self.btnAwardLabel_ = itemTrans:ComponentByName("btnAward/label", typeof(UILabel))
	self.btnAwardMask_ = itemTrans:ComponentByName("btnAward/btnMask", typeof(UISprite))
	self.missionDesc_ = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.baseBg_ = itemTrans:ComponentByName("imgBg", typeof(UISprite))
	self.iconRoot_ = itemTrans:ComponentByName("itemRoot", typeof(UILayout))
	self.awardImg_ = itemTrans:ComponentByName("imgAward", typeof(UISprite))
	self.btnGoPointCon = itemTrans:NodeByName("btnGoPointCon").gameObject
	self.btnGoPointCon_layout = itemTrans:ComponentByName("btnGoPointCon", typeof(UILayout))
	self.btnGoPointIcon = self.btnGoPointCon:NodeByName("btnGoPointIcon").gameObject
	self.btnGoPointLabel = self.btnGoPointCon:ComponentByName("btnGoPointLabel", typeof(UILabel))

	self.btnGoPointCon:SetActive(false)
	xyd.setUISpriteAsync(self.awardImg_, nil, "mission_awarded_" .. xyd.Global.lang, nil, )

	self.btnAwardLabel_.text = __("GET2")
	self.btnGoLabel_.text = __("GO")
	UIEventListener.Get(self.btnAward_.gameObject).onClick = handler(self, self.onTouchGetAward)

	self.btnGo_:SetActive(false)
end

function CommonProgressAwardItem:onTouchGetAward()
	self.parent.click_callBack(self.little_info)
end

function CommonProgressAwardItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.id and self.state and info and self.id == info.id and self.state == info.state then
		return
	end

	self.little_info = info
	self.id = info.id
	self.state = info.state
	self.missionDesc_.text = self.little_info.name

	if not self.items_arr then
		self.items_arr = {}
	end

	for i, data in pairs(self.little_info.items) do
		if not self.items_arr[i] then
			break
		end

		local itemType = xyd.tables.itemTable:getType(data[1])
		local iconType = "hero_icon"

		if itemType ~= xyd.ItemType.HERO_DEBRIS and itemType ~= xyd.ItemType.HERO and itemType ~= xyd.ItemType.HERO_RANDOM_DEBRIS and itemType ~= xyd.ItemType.SKIN then
			iconType = "item_icon"
		end

		if iconType ~= self.items_arr[i]:getIconType() then
			NGUITools.DestroyChildren(self.iconRoot_.gameObject.transform)

			self.items_arr = {}

			break
		end
	end

	for i, data in pairs(self.little_info.items) do
		if not self.items_arr[i] then
			local item_params = {
				isAddUIDragScrollView = true,
				show_has_num = true,
				isShowSelected = false,
				itemID = data[1],
				num = data[2],
				scale = Vector3(0.7037037037037037, 0.7037037037037037, 1),
				uiRoot = self.iconRoot_.gameObject,
				wndType = xyd.ItemTipsWndType.NORMAL,
				isNew = self.little_info.isNew and self.little_info.isNew[i]
			}

			if data[1] == 285 then
				item_params.wndType = xyd.ItemTipsWndType.ACTIVITY
			end

			if data[1] == 7217 then
				item_params.wndType = xyd.ItemTipsWndType.ACTIVITY
				item_params.isNew = true
			end

			if data[1] == 7255 then
				item_params.wndType = xyd.ItemTipsWndType.ACTIVITY
			end

			if data[1] == 7259 then
				item_params.wndType = xyd.ItemTipsWndType.ACTIVITY
			end

			if data[1] == 331 or data[1] == 332 or data[1] == 333 or data[1] == 334 then
				item_params.wndType = xyd.ItemTipsWndType.ACTIVITY
			end

			local icon = xyd.getItemIcon(item_params)

			icon:setInfo(item_params)
			table.insert(self.items_arr, icon)
		else
			local item_params = {
				show_has_num = true,
				isShowSelected = false,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.NORMAL,
				isNew = self.little_info.isNew and self.little_info.isNew[i]
			}

			if data[1] == 285 then
				item_params.wndType = xyd.ItemTipsWndType.ACTIVITY
			end

			if data[1] == 331 or data[1] == 332 or data[1] == 333 or data[1] == 334 then
				item_params.wndType = xyd.ItemTipsWndType.ACTIVITY
			end

			self.items_arr[i]:SetActive(true)
			self.items_arr[i]:setInfo(item_params)
		end
	end

	if #self.little_info.items < #self.items_arr then
		for i = #self.little_info.items + 1, #self.items_arr do
			self.items_arr[i]:SetActive(false)
		end
	end

	self.iconRoot_:Reposition()
	self:updateState(self.state)
end

function CommonProgressAwardItem:updateState(state)
	self.activityData = self.parent.activityData
	self.btnAward_box_.enabled = true

	if state == 3 then
		self.btnAward_:SetActive(false)
		self.awardImg_:SetActive(true)
	elseif state == 2 then
		self.btnAward_:SetActive(true)
		self.awardImg_:SetActive(false)

		self.btnAward_box_.enabled = false

		xyd.applyChildrenGrey(self.btnAward_.gameObject)
	elseif state == 1 then
		self.btnAward_:SetActive(true)
		self.awardImg_:SetActive(false)

		self.btnAward_box_.enabled = true

		xyd.applyChildrenOrigin(self.btnAward_.gameObject)
	end

	self.progressDesc_.text = self.little_info.cur_value .. "/" .. self.little_info.max_value
	local pro_value = self.little_info.cur_value / self.little_info.max_value

	if pro_value > 1 then
		pro_value = 1
	end

	self.progressBar_.value = pro_value

	for i in pairs(self.items_arr) do
		if self.items_arr[i]:getGameObject().activeSelf then
			if state == 3 then
				self.items_arr[i]:setChoose(true)
			else
				self.items_arr[i]:setChoose(false)
			end
		end
	end
end

return CommonProgressAwardWindow
