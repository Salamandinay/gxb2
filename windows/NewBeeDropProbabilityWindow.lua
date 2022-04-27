local BaseWindow = import(".BaseWindow")
local NewBeeDropProbabilityWindow = class("NewBeeDropProbabilityWindow", BaseWindow)
local ProbabilityRender = class("ProbabilityRender", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local DropboxShowTable = xyd.tables.dropboxShowTable

function NewBeeDropProbabilityWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.box_id_ = xyd.tables.miscTable:split2num("newbee_10gacha_dropbox", "value", "|")
	self.cur_select_ = 1
	self.collect_ = {}
	self.bgSelect = {
		"left",
		"right",
		"mid"
	}
	self.box_id_ = self.box_id_
	self.prefix = "NEWBEE_10GACHA_TEXT"
	self.title = __("DROP_PROBABILITY_WINDOW_TITLE")
	self.type = 1

	if params then
		self.stage_ = params.stage
	end
end

function NewBeeDropProbabilityWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle = winTrans:ComponentByName("groupAction/labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.dropItem = winTrans:NodeByName("dropItem").gameObject
	self.scroller = winTrans:ComponentByName("groupAction/scroller", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("groupAction/scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, self.dropItem, ProbabilityRender, self)

	if self.stage_ < 3 then
		self["nav" .. tostring(1)] = winTrans:NodeByName("groupAction/topBtns_/nav" .. tostring(1)).gameObject
		self["nav" .. tostring(2)] = winTrans:NodeByName("groupAction/topBtns_/nav" .. tostring(3)).gameObject
		self["nav" .. tostring(3)] = winTrans:NodeByName("groupAction/topBtns_/nav" .. tostring(2)).gameObject
	else
		for i = 1, 3 do
			self["nav" .. tostring(i)] = winTrans:NodeByName("groupAction/topBtns_/nav" .. tostring(i)).gameObject
		end

		self.nav3:SetActive(false)

		local nav1Sprite = self.nav1:GetComponent(typeof(UISprite))
		local nav2Sprite = self.nav2:GetComponent(typeof(UISprite))
		nav1Sprite.width = 325
		nav2Sprite.width = 325

		self.nav1.transform:X(-162.5)
		self.nav2.transform:X(162.5)
	end
end

function NewBeeDropProbabilityWindow:initWindow()
	NewBeeDropProbabilityWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayOut()
	self:register()
	self:updateTopButton()
end

function NewBeeDropProbabilityWindow:initLayOut()
	local prefix = self.prefix
	self.labelTitle.text = self.title

	for i = 1, 3 do
		local nav = self["nav" .. tostring(i)]
		local navLabel = nav:ComponentByName("navLabel", typeof(UILabel))
		navLabel.text = __(prefix .. i - 1)

		UIEventListener.Get(nav).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
			self:updateLayout(i)
			self:updateTopButton()
		end
	end

	self:updateLayout(self.type)
end

function NewBeeDropProbabilityWindow:updateLayout(i)
	self.cur_select_ = i
	local info = DropboxShowTable:getIdsByBoxId(self.box_id_[i])
	local all_proba = info.all_weight
	local list = info.list
	local sort_func = nil

	if self.params then
		sort_func = self.params.sort_func
	end

	DropboxShowTable:sort(list, sort_func)

	local collect = {}

	for i = 1, #list do
		local table_id = list[i]
		local weight = DropboxShowTable:getWeight(table_id)

		if weight then
			table.insert(collect, {
				table_id = table_id,
				all_proba = all_proba
			})
		end
	end

	self.collect_ = collect

	table.sort(self.collect_, function (a, b)
		return tonumber(a.table_id) < tonumber(b.table_id)
	end)
	self.wrapContent:setInfos(self.collect_, {})
end

function NewBeeDropProbabilityWindow:updateTopButton()
	for i = 1, 3 do
		local nav = self["nav" .. tostring(i)]
		local btn = nav:GetComponent(typeof(UIButton))
		local label = nav:ComponentByName("navLabel", typeof(UILabel))

		if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
			label.fontSize = 20
		end

		if i == self.cur_select_ then
			btn:SetEnabled(false)

			label.color = Color.New2(4294967295.0)
			label.effectStyle = UILabel.Effect.Outline
			label.effectColor = Color.New2(1012112383)
		else
			btn:SetEnabled(true)

			label.color = Color.New2(960513791)
			label.effectStyle = UILabel.Effect.None
		end
	end
end

function NewBeeDropProbabilityWindow:iosTestChangeUI()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	local allChildren = groupAction:GetComponentsInChildren(typeof(UISprite), true)

	for i = 0, allChildren.Length - 1 do
		local sprite = allChildren[i]

		xyd.setUISprite(sprite, nil, sprite.spriteName .. "_ios_test")
	end

	self.nav1:GetComponent(typeof(UIButton)).normalSprite = "nav_btn_white_left_ios_test"
	self.nav2:GetComponent(typeof(UIButton)).normalSprite = "nav_btn_white_right_ios_test"
	self.nav3:GetComponent(typeof(UIButton)).normalSprite = "nav_btn_white_mid_ios_test"
end

function ProbabilityRender:ctor(go, parent)
	ProbabilityRender.super.ctor(self, go, parent)
end

function ProbabilityRender:initUI()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.label = go:ComponentByName("label", typeof(UILabel))
	local HeroIcon = import("app.components.HeroIcon")
	local icon = HeroIcon.new(self.groupIcon)

	icon:setDragScrollView(self.scroller)

	self.icon_ = icon
end

function ProbabilityRender:updateInfo()
	self.table_id_ = self.data.table_id
	self.all_proba_ = self.data.all_proba
	local data = DropboxShowTable:getItem(self.table_id_)
	self.itemID = data[1]
	self.num = data[2]
	local proba = DropboxShowTable:getWeight(self.table_id_)
	local show_proba = math.ceil(proba * 1000000 / self.all_proba_)
	show_proba = show_proba / 10000
	self.label.text = tostring(show_proba) .. "%"

	self.icon_:setInfo({
		scale = 1.1,
		notShowGetWayBtn = true,
		noWays = true,
		not_show_ways = true,
		uiRoot = self.groupIcon,
		itemID = self.itemID,
		num = self.num
	})
end

return NewBeeDropProbabilityWindow
