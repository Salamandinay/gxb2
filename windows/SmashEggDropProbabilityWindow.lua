local BaseWindow = import(".BaseWindow")
local SmashEggDropProbabilityWindow = class("SmashEggDropProbabilityWindow", BaseWindow)
local ProbabilityRender = class("ProbabilityRender", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local DropboxShowTable = xyd.tables.dropboxShowTable

function SmashEggDropProbabilityWindow:ctor(name, params)
	SmashEggDropProbabilityWindow.super.ctor(self, name, params)

	self.params = params
	local box_id_ = xyd.tables.activitySmashEggTable:getDropBoxIDs()
	self.box_id_ = {
		box_id_[1],
		box_id_[3],
		box_id_[2]
	}
	self.cur_select_ = 1
	self.collect_ = {}
	self.labelSelect_summon = {
		3,
		5,
		4
	}
	self.prefix = "DRIFT_BOTTLE_TEXT_0"
	self.title = __("DROP_PROBABILITY_WINDOW_TITLE")
	self.type = 1

	if params.type and params.type == 2 then
		self.type = 3
	elseif params.type and params.type == 3 then
		self.type = 2
	end
end

function SmashEggDropProbabilityWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle = winTrans:ComponentByName("groupAction/labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.dropItem = winTrans:NodeByName("dropItem").gameObject
	self.scrollView = winTrans:ComponentByName("groupAction/scroller", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("groupAction/scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.dropItem, ProbabilityRender, self)

	for i = 1, 3 do
		self["nav" .. tostring(i)] = winTrans:NodeByName("groupAction/topBtns_/nav" .. tostring(i)).gameObject
	end
end

function SmashEggDropProbabilityWindow:initWindow()
	SmashEggDropProbabilityWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayOut()
	self:register()
	self:updateTopButton()
end

function SmashEggDropProbabilityWindow:initLayOut()
	local prefix = self.prefix
	self.labelTitle.text = self.title

	for i = 1, 3 do
		local nav = self["nav" .. i]
		local navLabel = nav:ComponentByName("navLabel", typeof(UILabel))
		navLabel.text = __(prefix .. tostring(self.labelSelect_summon[i]))

		UIEventListener.Get(nav).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.TAB)
			self:updateLayout(i)
			self:updateTopButton()
		end

		if xyd.Global.lang == "de_de" then
			navLabel.width = 220
		end

		if i == 1 and xyd.Global.lang == "fr_fr" then
			navLabel.fontSize = 20
		end
	end

	self:updateLayout(self.type)
end

function SmashEggDropProbabilityWindow:updateLayout(i)
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

	self.wrapContent:setInfos(self.collect_, {})
end

function SmashEggDropProbabilityWindow:updateTopButton()
	for i = 1, 3 do
		local nav = self["nav" .. tostring(i)]
		local btn = nav:GetComponent(typeof(UIButton))
		local label = nav:ComponentByName("navLabel", typeof(UILabel))

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

function SmashEggDropProbabilityWindow:iosTestChangeUI()
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

	NGUITools.DestroyChildren(self.groupIcon.transform)
	xyd.getItemIcon({
		noWays = true,
		scale = 1,
		uiRoot = self.groupIcon,
		itemID = self.itemID,
		num = self.num,
		dragScrollView = self.parent.scrollView
	})
end

return SmashEggDropProbabilityWindow
