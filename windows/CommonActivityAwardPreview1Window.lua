local BaseWindow = import(".BaseWindow")
local CommonActivityAwardPreview1Window = class("CommonActivityAwardPreview1Window", BaseWindow)

function CommonActivityAwardPreview1Window:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.winTitleText = params.winTitleText
	self.groupTitleText1 = params.groupTitleText1
	self.groupTitleText2 = params.groupTitleText2
	self.awardData1 = params.awardData1 or {}
	self.awardData2 = params.awardData2 or {}
	self.setChoose1 = params.setChoose1 or {}
	self.setChoose2 = params.setChoose2 or {}
	self.iconName1 = params.iconName1
	self.iconName2 = params.iconName2
end

function CommonActivityAwardPreview1Window:initWindow()
	self:getUIComponent()
	CommonActivityAwardPreview1Window.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function CommonActivityAwardPreview1Window:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:ComponentByName("groupAction", typeof(UIWidget))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.mainGroup = self.groupAction:NodeByName("mainGroup").gameObject
	self.scrollView = self.mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.mainLayout = self.scrollView:ComponentByName("layout", typeof(UILayout))
	self.awardGroup1 = self.mainLayout:NodeByName("awardGroup1").gameObject
	self.titleLabel1 = self.awardGroup1:ComponentByName("label1", typeof(UILabel))
	self.icon1 = self.titleLabel1:ComponentByName("icon1", typeof(UISprite))
	self.itemGroup1 = self.awardGroup1:NodeByName("itemGroup1").gameObject
	self.awardGroup2 = self.mainLayout:NodeByName("awardGroup2").gameObject
	self.titleLabel2 = self.awardGroup2:ComponentByName("label2", typeof(UILabel))
	self.icon2 = self.titleLabel2:ComponentByName("icon2", typeof(UISprite))
	self.itemGroup2 = self.awardGroup2:NodeByName("itemGroup2").gameObject
end

function CommonActivityAwardPreview1Window:initUIComponent()
	self.labelTitle.text = self.winTitleText
	self.titleLabel1.text = self.groupTitleText1
	self.titleLabel2.text = self.groupTitleText2

	for i = 1, #self.awardData1 do
		local award = self.awardData1[i]
		local item = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7962962962962963,
			notShowGetWayBtn = true,
			uiRoot = self.itemGroup1,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.scrollView
		})

		item:setChoose(self.setChoose1[i] == 1 or self.setChoose1[i] == true)
	end

	for i = 1, #self.awardData2 do
		local award = self.awardData2[i]
		local item = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7962962962962963,
			notShowGetWayBtn = true,
			uiRoot = self.itemGroup2,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.scrollView
		})

		item:setChoose(self.setChoose2[i] == 1 or self.setChoose2[i] == true)
	end

	if #self.awardData1 < 6 then
		self.itemGroup1:X(0)

		self.itemGroup1:GetComponent(typeof(UIGrid)).pivot = UIWidget.Pivot.Center
	else
		self.awardGroup1:GetComponent(typeof(UIWidget)).height = 100 * math.ceil(#self.awardData1 / 6) + 40
	end

	if #self.awardData2 < 6 then
		self.itemGroup2:X(0)

		self.itemGroup2:GetComponent(typeof(UIGrid)).pivot = UIWidget.Pivot.Center
	else
		self.awardGroup2:GetComponent(typeof(UIWidget)).height = 100 * math.ceil(#self.awardData2 / 6) + 40
	end

	local heightOffset = 100 * math.ceil(#self.awardData1 / 6) + 100 * math.ceil(#self.awardData2 / 6) - 300

	if heightOffset > 0 then
		self.groupAction:GetComponent(typeof(UIWidget)).height = 492 + heightOffset
	else
		self.groupAction:GetComponent(typeof(UIWidget)).height = 492
	end

	if #self.awardData2 == 0 then
		self.groupAction.height = 343

		self.awardGroup2:SetActive(false)
		self.labelTitle:Y(149)
		self.closeBtn:Y(149)
		self.awardGroup1:Y(117)
	end

	if self.iconName1 then
		xyd.setUISpriteAsync(self.icon1, nil, self.iconName1)

		self.titleLabel1.text = "    " .. self.titleLabel1.text
	end

	if self.iconName2 then
		xyd.setUISpriteAsync(self.icon2, nil, self.iconName2)

		self.titleLabel2.text = "    " .. self.titleLabel2.text
	end

	self.itemGroup1:GetComponent(typeof(UIGrid)):Reposition()
	self.itemGroup2:GetComponent(typeof(UIGrid)):Reposition()
	self.scrollView:ResetPosition()
	self.mainLayout:Reposition()
	self:waitForFrame(2, function ()
		self.scrollView:ResetPosition()
	end)
end

function CommonActivityAwardPreview1Window:register()
	CommonActivityAwardPreview1Window.super.register(self)
end

return CommonActivityAwardPreview1Window
