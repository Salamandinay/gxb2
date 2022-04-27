local HeroChallengeMemoryWindow = class("HeroChallengeMemoryWindow", import(".StoryMemoryWindow"))
local BaseWindow = import(".BaseWindow")
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	if not self.heroChallengeItem then
		local itemClass = self.parent.itemClass
		self.heroChallengeItem = itemClass.new(self.go)

		self.heroChallengeItem:setDragScrollView(self.parent.scrollView_)
	end

	self.heroChallengeItem.data = info

	self.go:SetActive(true)
	self.heroChallengeItem:update()
end

function ItemRender:getGameObject()
	return self.go
end

local HeroChallengeDetailItem = import(".HeroChallengeDetailWindow").getHeroChallengeDetailItem()
local HeroChallengeMemoryWindowItem = class("HeroChallengeMemoryWindowItem", HeroChallengeDetailItem)

function HeroChallengeMemoryWindowItem:ctor(parentGo)
	HeroChallengeMemoryWindowItem.super.ctor(self, parentGo)
end

function HeroChallengeMemoryWindowItem:createChildren()
	HeroChallengeMemoryWindowItem.super.createChildren(self)
	self.groupItem:SetActive(false)
end

function HeroChallengeMemoryWindowItem:onClickFortItem()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.isLocked then
		local params = {
			alertType = xyd.AlertType.YES_NO,
			message = __("HERO_CHALLENGE_TIPS40"),
			callback = function (yes)
				if yes then
					xyd.WindowManager.get():openWindow("hero_challenge_detail_window", {
						fort_id = self.fortId
					})
				end
			end
		}

		xyd.WindowManager.get():openWindow("alert_window", params)

		return
	end

	xyd.WindowManager.get():openWindow("story_window", {
		is_back = true,
		story_type = xyd.StoryType.PARTNER,
		story_list = self.table_:memoryPlotId(self.id)
	})
end

function HeroChallengeMemoryWindowItem:update()
	self.max_stage_ = self.data.max_stage

	HeroChallengeMemoryWindowItem.super.update(self)

	if xyd.tables.partnerChallengeChessTable:getFortType(self.data.fort_id) == xyd.HeroChallengeFort.CHESS then
		self.table_ = xyd.tables.partnerChallengeChessTable
	else
		self.table_ = xyd.tables.partnerChallengeTable
	end
end

function HeroChallengeMemoryWindowItem:checkLock()
	if self.max_stage_ < self.id then
		self:lock()
	else
		self:unlock()
	end
end

function HeroChallengeMemoryWindowItem:lock()
	HeroChallengeMemoryWindowItem.super.lock(self)
	self.imgAsk.gameObject:SetActive(false)
end

function HeroChallengeMemoryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.stage_id_ = params.stage_id
	self.fort_id_ = params.fort_id
	self.max_stage_id_ = params.max_stage

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fort_id_) == xyd.HeroChallengeFort.CHESS then
		self.table_ = xyd.tables.partnerChallengeChessTable
	else
		self.table_ = xyd.tables.partnerChallengeTable
	end
end

function HeroChallengeMemoryWindow:initWindow()
	BaseWindow.initWindow(self)

	self.windowTop = import("app.components.WindowTop").new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupMain_").gameObject
	self.scrollView_ = groupMain:ComponentByName("scroller_", typeof(UIScrollView))
	self.wrapContent_ = groupMain:ComponentByName("scroller_/itemGroup", typeof(UIWrapContent))
	self.titleLable_ = groupMain:ComponentByName("topGroup/labelTitle_", typeof(UILabel))
	self.itemClass = HeroChallengeMemoryWindowItem
	local wrapContent = self.scrollView_:ComponentByName("itemGroup", typeof(UIWrapContent))
	local itemContainer = self.scrollView_:NodeByName("itemContainer").gameObject
	self.wrapContent = import("app.common.ui.FixedWrapContent").new(self.scrollView_, wrapContent, itemContainer, ItemRender, self)

	self:initSource()

	self.titleLable_.text = __(self.table_:fortName2(self.table_:getIdsByFort(self.fort_id_)[1]))

	XYDCo.WaitForFrame(1, function ()
		self:updateList()
	end, nil)
end

function HeroChallengeMemoryWindow:initSource()
	local ids = self.table_:getIdsByFort(self.fort_id_)
	local data = {}

	dump(ids)

	for i = 1, #ids do
		local id = ids[i]
		local list = self.table_:memoryPlotId(id)

		if list and #list > 0 then
			table.insert(data, {
				id = ids[i],
				index = i,
				fort_id = self.fort_id_,
				max_stage = self.max_stage_id_
			})
		end
	end

	dump(data)

	self.source_list_ = data
end

function HeroChallengeMemoryWindow:updateList()
	self.wrapContent:setInfos(self.source_list_, {})
	self.wrapContent:resetPosition()
end

return HeroChallengeMemoryWindow
