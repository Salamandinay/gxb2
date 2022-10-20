local SoulLandSummonWindow = class("SoulLandSummonWindow", import(".BaseWindow"))
local SoulLandSummonItem = class("SoulLandSummonItem", import("app.components.CopyComponent"))
local SoulLandSummonState = {
	HIGH = 2,
	BASE = 1
}

function SoulLandSummonWindow:ctor(name, params)
	SoulLandSummonWindow.super.ctor(self, name, params)

	self.defaultIndex = 1
end

function SoulLandSummonWindow:initWindow()
	self:getUIComponent()
	SoulLandSummonWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function SoulLandSummonWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.logoCon = self.groupAction:NodeByName("logoCon").gameObject
	self.logoImg = self.logoCon:ComponentByName("logoImg", typeof(UISprite))
	self.levLabel = self.logoCon:ComponentByName("levLabel", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.arrowCon = self.groupAction:NodeByName("arrowCon").gameObject
	self.leftArrowBtn = self.arrowCon:NodeByName("leftArrowBtn").gameObject
	self.leftArrowBtnBoxCollider = self.arrowCon:ComponentByName("leftArrowBtn", typeof(UnityEngine.BoxCollider))
	self.rightArrowBtn = self.arrowCon:NodeByName("rightArrowBtn").gameObject
	self.rightArrowBtnBoxCollider = self.arrowCon:ComponentByName("rightArrowBtn", typeof(UnityEngine.BoxCollider))
	self.summonCon = self.groupAction:NodeByName("summonCon").gameObject

	for i = 1, 2 do
		self.con1 = self.summonCon:NodeByName("con1").gameObject
		self.con2 = self.summonCon:NodeByName("con2").gameObject
	end

	self.btnsCon = self.groupAction:NodeByName("btnsCon").gameObject
	self.helpBtn = self.btnsCon:NodeByName("helpBtn").gameObject
	self.viewBtn = self.btnsCon:NodeByName("viewBtn").gameObject
end

function SoulLandSummonWindow:reSize()
end

function SoulLandSummonWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateItemChange))
	self.eventProxy_:addEventListener(xyd.event.SOUL_LAND_SUMMON, handler(self, self.updateLvShow))

	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SOUL_LAND_SUMMON_HELP"
		})
	end)
	UIEventListener.Get(self.viewBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("soul_land_probability_window", {})
	end)
	UIEventListener.Get(self.leftArrowBtn.gameObject).onClick = handler(self, function ()
		self:tweenArrow("left")
	end)
	UIEventListener.Get(self.rightArrowBtn.gameObject).onClick = handler(self, function ()
		self:tweenArrow("right")
	end)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function SoulLandSummonWindow:layout()
	xyd.setUISpriteAsync(self.logoImg, nil, "soul_land_text_logo_ljjc_" .. xyd.Global.lang)

	self.baseItem = SoulLandSummonItem.new(self.con1.gameObject, {
		state = SoulLandSummonState.BASE
	}, self)
	self.highItem = SoulLandSummonItem.new(self.con2.gameObject, {
		state = SoulLandSummonState.HIGH
	}, self)

	self.leftArrowBtn:SetActive(false)
	self:updateArrow()
	self:updateLvShow()
	self:playPage()
end

function SoulLandSummonWindow:updateArrow()
	if self.defaultIndex == 1 then
		self.leftArrowBtnBoxCollider.enabled = false
		self.rightArrowBtnBoxCollider.enabled = true
	else
		self.leftArrowBtnBoxCollider.enabled = true
		self.rightArrowBtnBoxCollider.enabled = false
	end
end

function SoulLandSummonWindow:tweenArrow(state)
	local moveX = 0

	if self.isMoving then
		return
	end

	self:updateArrow()

	if state == "left" then
		moveX = 0
		self.defaultIndex = 1

		self.rightArrowBtn:SetActive(true)
		self.leftArrowBtn:SetActive(false)
	elseif state == "right" then
		moveX = -1000
		self.defaultIndex = 2

		self.rightArrowBtn:SetActive(false)
		self.leftArrowBtn:SetActive(true)
	end

	self.isMoving = true
	local sequence = self:getSequence()

	sequence:Append(self.summonCon.transform:DOLocalMoveX(moveX, 0.15))
	sequence:AppendCallback(function ()
		sequence:Kill(true)
		self:updateArrow()

		self.isMoving = false
	end)
end

function SoulLandSummonWindow:updateItemChange()
	self.baseItem:updateItemNumShow()
	self.highItem:updateItemNumShow()
end

function SoulLandSummonWindow:updateLvShow()
	local summonBaseInfo = xyd.models.soulLand:getSummonBaseInfo()
	local expLvMax = xyd.tables.soulLandEquip2DropboxTable:getExp(summonBaseInfo.lv)
	local maxShow = expLvMax

	if expLvMax == -1 then
		maxShow = "-"
	end

	local levText = "Lv."

	if xyd.Global.lang == "fr_fr" then
		levText = "Niv."
	end

	self.levLabel.text = levText .. summonBaseInfo.lv .. " (" .. summonBaseInfo.times .. "/" .. maxShow .. "）"
end

function SoulLandSummonWindow:playPage()
	local positionLeft = -317
	local positionRight = 317

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	function self.playAni2_()
		self.sequence2_ = self:getSequence()

		self.sequence2_:Insert(0, self.leftArrowBtn.transform:DOLocalMoveX(positionLeft - 10, 1))
		self.sequence2_:Insert(1, self.leftArrowBtn.transform:DOLocalMoveX(positionLeft + 10, 1))
		self.sequence2_:Insert(0, self.rightArrowBtn.transform:DOLocalMoveX(positionRight + 10, 1))
		self.sequence2_:Insert(1, self.rightArrowBtn.transform:DOLocalMoveX(positionRight - 10, 1))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = self:getSequence()

		self.sequence1_:Insert(0, self.leftArrowBtn.transform:DOLocalMoveX(positionLeft - 10, 1))
		self.sequence1_:Insert(1, self.leftArrowBtn.transform:DOLocalMoveX(positionLeft + 10, 1))
		self.sequence1_:Insert(0, self.rightArrowBtn.transform:DOLocalMoveX(positionRight + 10, 1))
		self.sequence1_:Insert(1, self.rightArrowBtn.transform:DOLocalMoveX(positionRight - 10, 1))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

function SoulLandSummonItem:ctor(goItem, data, parent)
	self.state = data.state
	self.parent = parent

	SoulLandSummonItem.super.ctor(self, goItem)
end

function SoulLandSummonItem:initUI()
	self:getUIComponent()
	SoulLandSummonItem.super.initUI(self)
	self:register()
	self:layout()
end

function SoulLandSummonItem:getUIComponent()
	self.con = self.go.gameObject
	self.baseConBg = self.con:ComponentByName("baseConBg", typeof(UITexture))
	self.oneBtn = self.con:NodeByName("oneBtn").gameObject
	self.oneBtnUISprite = self.con:ComponentByName("oneBtn", typeof(UISprite))
	self.oneBtnTimesShow = self.oneBtn:ComponentByName("oneBtnTimesShow", typeof(UILabel))
	self.oneBtnIcon = self.oneBtn:ComponentByName("oneBtnIcon", typeof(UISprite))
	self.oneBtnLabel = self.oneBtn:ComponentByName("oneBtnLabel", typeof(UILabel))
	self.tenBtn = self.con:NodeByName("tenBtn").gameObject
	self.tenBtnUISprite = self.con:ComponentByName("tenBtn", typeof(UISprite))
	self.tenBtnTimesShow = self.tenBtn:ComponentByName("tenBtnTimesShow", typeof(UILabel))
	self.tenBtnIcon = self.tenBtn:ComponentByName("tenBtnIcon", typeof(UISprite))
	self.tenBtnLabel = self.tenBtn:ComponentByName("tenBtnLabel", typeof(UILabel))
	self.numCon = self.con:NodeByName("numCon").gameObject
	self.numConBg = self.numCon:ComponentByName("numConBg", typeof(UISprite))
	self.numIcon = self.numCon:ComponentByName("numIcon", typeof(UISprite))
	self.numAddBtn = self.numCon:ComponentByName("numAddBtn", typeof(UISprite))
	self.numLabel = self.numCon:ComponentByName("numLabel", typeof(UILabel))
end

function SoulLandSummonItem:register()
	UIEventListener.Get(self.oneBtn.gameObject).onClick = handler(self, function ()
		xyd.models.soulLand:reqSummon(self.state, 1)
	end)
	UIEventListener.Get(self.tenBtn.gameObject).onClick = handler(self, function ()
		xyd.models.soulLand:reqSummon(self.state, 10)
	end)
	UIEventListener.Get(self.numAddBtn.gameObject).onClick = handler(self, function ()
		local cost = xyd.tables.soulLandEquip2GachaTable:getCost(self.state)

		xyd.WindowManager.get():openWindow("item_tips_window", {
			notShowGetWayBtn = false,
			itemID = cost[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end)
	UIEventListener.Get(self.numConBg.gameObject).onClick = handler(self, function ()
		local cost = xyd.tables.soulLandEquip2GachaTable:getCost(self.state)

		xyd.WindowManager.get():openWindow("item_tips_window", {
			notShowGetWayBtn = false,
			itemID = cost[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end)
end

function SoulLandSummonItem:layout()
	local costIconName = "soul_land_icon_db_a_1"
	local costAddIconName = "soul_land_btn_add_1"
	local btnImgName = "soul_land_btn_ck_1"
	local numConBgName = "soul_land_bg_js_1"
	local cost = xyd.tables.soulLandEquip2GachaTable:getCost(self.state)

	if self.state == SoulLandSummonState.BASE then
		-- Nothing
	elseif self.state == SoulLandSummonState.HIGH then
		costIconName = "soul_land_icon_db_b_1"
		costAddIconName = "soul_land_btn_add_2"
		btnImgName = "soul_land_btn_ck_2"
		numConBgName = "soul_land_bg_js_2"
	end

	xyd.setUISpriteAsync(self.numIcon, nil, costIconName)
	xyd.setUISpriteAsync(self.numAddBtn, nil, costAddIconName)
	xyd.setUISpriteAsync(self.oneBtnUISprite, nil, btnImgName)
	xyd.setUISpriteAsync(self.tenBtnUISprite, nil, btnImgName)
	xyd.setUISpriteAsync(self.numConBg, nil, numConBgName)

	local btnIconName = "icon_" .. cost[1] .. "_small"

	xyd.setUISpriteAsync(self.oneBtnIcon, nil, btnIconName)
	xyd.setUISpriteAsync(self.tenBtnIcon, nil, btnIconName)

	self.oneBtnTimesShow.text = __("SOUL_LAND_TEXT11")
	self.tenBtnTimesShow.text = __("SOUL_LAND_TEXT12")
	self.oneBtnLabel.text = cost[2] * 1
	self.tenBtnLabel.text = cost[2] * 10

	self:updateItemNumShow()
end

function SoulLandSummonItem:updateItemNumShow()
	local cost = xyd.tables.soulLandEquip2GachaTable:getCost(self.state)
	self.numLabel.text = tostring(xyd.models.backpack:getItemNumByID(cost[1]))
end

return SoulLandSummonWindow
