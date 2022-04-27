local ShrineHurdleChooseBuffWindow = class("ShrineHurdleChooseBuffWindow", import(".BaseWindow"))
local ShrineHurdleBuffItem = class("ShrineHurdleBuffItem", import("app.components.CopyComponent"))
local CardItemType = {
	REST = 4,
	SELECT = 1,
	BUY = 2,
	UPGREAD = 3
}

function ShrineHurdleBuffItem:ctor(go, parent)
	self.parent_ = parent
	self.isSelect_ = false

	ShrineHurdleBuffItem.super.ctor(self, go)
end

function ShrineHurdleBuffItem:initUI()
	self:getUIComponent()
	self:register()
end

function ShrineHurdleBuffItem:getUIComponent()
	local goTrans = self.go.transform
	self.selectImg_ = goTrans:NodeByName("selectImg").gameObject
	self.labelName_ = goTrans:ComponentByName("labelName", typeof(UILabel))
	self.labelDesc_ = goTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.costGroup_ = goTrans:NodeByName("costGroup").gameObject
	self.costLabel_ = goTrans:ComponentByName("costGroup/label", typeof(UILabel))
	self.labelbuy_ = goTrans:ComponentByName("labelBuy", typeof(UILabel))
	self.skillIcon_ = goTrans:ComponentByName("skillIcon", typeof(UISprite))
end

function ShrineHurdleBuffItem:setInfo(type, skill_id, index)
	self.skill_id_ = skill_id
	self.index_ = index
	self.type_ = type

	if type == CardItemType.REST then
		self.costGroup_:SetActive(false)
		self.labelbuy_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.skillIcon_, nil, "shrine_hurdle_case_img1")

		self.labelName_.text = xyd.tables.shrineHurdleRestoreTextTable:getTitle(index)
		self.labelDesc_.text = xyd.tables.shrineHurdleRestoreTextTable:getDesc(index)
	elseif type == CardItemType.UPGREAD then
		if not skill_id then
			self.go:SetActive(false)

			return
		else
			self.go:SetActive(true)
		end

		local skill_icon = xyd.tables.shrineHurdleBuffTable:getSkillIcon(skill_id)

		xyd.setUISpriteAsync(self.skillIcon_, nil, skill_icon)

		self.skill_lev = xyd.models.shrineHurdleModel:getSkillLv(skill_id)
		local skillNum, skillNumBefore = nil

		if self.skill_lev == 3 then
			skillNum = xyd.tables.shrineHurdleBuffTable:getSkillNum(skill_id)[self.skill_lev]
		else
			skillNumBefore = xyd.tables.shrineHurdleBuffTable:getSkillNum(skill_id)[self.skill_lev]
			skillNum = xyd.tables.shrineHurdleBuffTable:getSkillNum(skill_id)[self.skill_lev + 1]
		end

		local addLevText = ""

		if self.skill_lev == 3 then
			addLevText = "+" .. self.skill_lev - 1
			self.notSelect = true

			self.labelbuy_.gameObject:SetActive(true)
			self.costGroup_:SetActive(false)

			self.labelbuy_.text = __("SHRINE_HURDLE_TEXT36")
		else
			self.labelbuy_.gameObject:SetActive(false)
			self.costGroup_:SetActive(true)

			addLevText = "+" .. self.skill_lev

			if self.skill_lev == 1 then
				self.cost = xyd.tables.shrineHurdleBuffTable:getUpgrade1(skill_id)
			elseif self.skill_lev == 2 then
				self.cost = xyd.tables.shrineHurdleBuffTable:getUpgrade2(skill_id)
			end

			self.costLabel_.text = "x" .. self.cost[2]
		end

		if skillNumBefore and skillNumBefore > 0 then
			skillNum = "[c][34a883]" .. skillNumBefore .. "→" .. skillNum .. "[-][/c]"
		end

		self.labelDesc_.text = xyd.tables.shrineHurdleBuffTextTable:getDesc(skill_id, skillNum)
		self.labelName_.text = xyd.tables.shrineHurdleBuffTextTable:getTitle(skill_id) .. addLevText
	elseif type == CardItemType.BUY then
		if not skill_id then
			self.go:SetActive(false)

			return
		else
			self.go:SetActive(true)
		end

		local skill_icon = xyd.tables.shrineHurdleBuffTable:getSkillIcon(skill_id)

		xyd.setUISpriteAsync(self.skillIcon_, nil, skill_icon)

		self.skill_lev = xyd.models.shrineHurdleModel:getSkillLv(skill_id)
		local skillNum = xyd.tables.shrineHurdleBuffTable:getSkillNum(skill_id)[1]
		self.labelDesc_.text = xyd.tables.shrineHurdleBuffTextTable:getDesc(skill_id, skillNum)
		self.labelName_.text = xyd.tables.shrineHurdleBuffTextTable:getTitle(skill_id)

		if self.skill_lev and self.skill_lev > 0 then
			self.labelbuy_.gameObject:SetActive(true)
			self.costGroup_:SetActive(false)

			self.labelbuy_.text = __("SHRINE_HURDLE_TEXT21")
			self.cost = xyd.tables.shrineHurdleBuffTable:getCost(skill_id)
		else
			self.labelbuy_.gameObject:SetActive(false)
			self.costGroup_:SetActive(true)

			self.cost = xyd.tables.shrineHurdleBuffTable:getCost(skill_id)
			self.costLabel_.text = self.cost[2]
		end
	elseif type == CardItemType.SELECT then
		if not skill_id then
			self.go:SetActive(false)

			return
		end

		self.costGroup_:SetActive(false)
		self.labelbuy_.gameObject:SetActive(false)

		local skill_icon = xyd.tables.shrineHurdleBuffTable:getSkillIcon(skill_id)

		xyd.setUISpriteAsync(self.skillIcon_, nil, skill_icon)

		local skillNum = xyd.tables.shrineHurdleBuffTable:getSkillNum(skill_id)[1]
		self.labelDesc_.text = xyd.tables.shrineHurdleBuffTextTable:getDesc(skill_id, skillNum)
		self.labelName_.text = xyd.tables.shrineHurdleBuffTextTable:getTitle(skill_id)
	end
end

function ShrineHurdleBuffItem:getCost()
	return self.cost or {
		0,
		0
	}
end

function ShrineHurdleBuffItem:setSelect(state)
	self.isSelect_ = state

	self.selectImg_:SetActive(state)
end

function ShrineHurdleBuffItem:getSelect()
	return self.isSelect_
end

function ShrineHurdleBuffItem:register()
	UIEventListener.Get(self.go).onClick = function ()
		if self.isSelect_ then
			self.parent_:updateCardSelect(0)
		else
			self.parent_:updateCardSelect(self.index_, self.skill_id_, self.skill_lev, self.cost)
		end
	end
end

function ShrineHurdleChooseBuffWindow:ctor(name, params)
	ShrineHurdleChooseBuffWindow.super.ctor(self, name, params)

	self.wndType_ = params.window_type
	self.index_ = 1
	self.cardItemList_ = {}
	self.route_id_ = xyd.models.shrineHurdleModel:getRouteID()
end

function ShrineHurdleChooseBuffWindow:initWindow()
	self:getUIComponent()
	self:register()

	self.resItemLabel_.text = xyd.models.shrineHurdleModel:getGold()

	self:updateShopState()
	self:checkGuide()
	self:updateNav()
	self:updateCardItems()
end

function ShrineHurdleChooseBuffWindow:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHRINE_HURDLE_HELP"
		})
	end

	UIEventListener.Get(self.resItem_).onClick = function ()
		local params = {
			notShowGetWayBtn = true,
			showGetWays = false,
			itemID = 324,
			wndType = xyd.ItemTipsWndType.NORMAL
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

		if guideIndex then
			self.canClose_ = true
		end

		self:close()
	end

	UIEventListener.Get(self.partnerBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("shrine_hurdle_select_partner_window", {
			is_show = true
		})
	end

	UIEventListener.Get(self.recordBtn_).onClick = function ()
		xyd.models.shrineHurdleModel:reqShineHurdleRecords()
	end

	UIEventListener.Get(self.navBtn1).onClick = function ()
		self:onClickNav(1)
	end

	UIEventListener.Get(self.navBtn2).onClick = function ()
		local extra = xyd.models.shrineHurdleModel:getExtra()

		if not extra.upgrades or #extra.upgrades <= 0 then
			return
		end

		self:onClickNav(2)
	end

	UIEventListener.Get(self.destroyBtn_).onClick = function ()
		if self.wndType_ == 2 then
			xyd.alertYesNo(__("SHRINE_HURDLE_TEXT39"), function (yes_no)
				if yes_no then
					self.canClose_ = true

					xyd.models.shrineHurdleModel:challengeSelect(2, 0)
				end
			end)
		end
	end

	UIEventListener.Get(self.chooseBtn_).onClick = handler(self, self.onClickChoose)

	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_CHALLENGE, handler(self, self.onChallenge))
	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_GET_RECORDS, handler(self, self.onGetRecords))
end

function ShrineHurdleChooseBuffWindow:close(callback, skipAnimation)
	local floor_id = xyd.models.shrineHurdleModel:getFloorInfo()
	local close_floor = xyd.db.misc:getValue("shrine_hurdle_close_floor") or 0

	if self.wndType_ == 3 and tonumber(close_floor) < floor_id and not self.canClose_ then
		xyd.alertYesNo(__("SHRINE_HURDLE_TEXT22"), function (yes_no)
			if yes_no then
				if skipAnimation == nil then
					skipAnimation = false
				end

				xyd.db.misc:setValue({
					key = "shrine_hurdle_close_floor",
					value = floor_id
				})
				xyd.WindowManager.get():closeWindow(self.name_, callback, skipAnimation)
				self:cleanDefaultBgClick()
			end
		end)
	elseif (self.wndType_ == 2 or self.wndType_ == 4) and not self.canClose_ then
		xyd.alertTips(__("SHRINE_HURDLE_TEXT30"))

		return
	else
		xyd.db.misc:setValue({
			key = "shrine_hurdle_close_floor",
			value = floor_id
		})

		if skipAnimation == nil then
			skipAnimation = false
		end

		xyd.WindowManager.get():closeWindow(self.name_, callback, skipAnimation)
		self:cleanDefaultBgClick()
	end
end

function ShrineHurdleChooseBuffWindow:onClickChoose()
	if not self.selectIndex_ or self.selectIndex_ <= 0 then
		xyd.alertTips(__("SHRINE_HURDLE_TEXT30"))

		return
	end

	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if self.wndType_ == 2 then
		self.canClose_ = true

		if guideIndex and guideIndex == 2 then
			xyd.models.shrineHurdleModel:setFlag(nil, 2)

			local win = xyd.WindowManager.get():getWindow("shrine_hurdle_window")

			if win then
				win:onGuideUpdate()
			end

			self:close()
		else
			xyd.models.shrineHurdleModel:challengeSelect(1, self.selectIndex_)
		end
	elseif self.wndType_ == 3 then
		if self.index_ == 1 and self.skill_lev_ > 0 then
			xyd.alertTips(__("SHRINE_HURDLE_TEXT21"))

			return
		elseif self.index_ == 2 and self.skill_lev_ >= 3 then
			xyd.alertTips(__("SHRINE_HURDLE_TEXT28"))

			return
		end

		if self.costNum_ and xyd.models.shrineHurdleModel:getGold() < self.costNum_ then
			xyd.alertTips(__("SHRINE_HURDLE_TEXT29"))

			return
		end

		xyd.models.shrineHurdleModel:challengeSelect(self.index_, self.selectIndex_)
	elseif self.wndType_ == 4 then
		if guideIndex and guideIndex == 7 then
			xyd.models.shrineHurdleModel:setFlag(nil, 7)

			local win = xyd.WindowManager.get():getWindow("shrine_hurdle_window")

			if win then
				win:onGuideUpdate()
			end

			self.canClose_ = true

			self:close()

			return
		end

		if self.selectIndex_ == 3 then
			xyd.WindowManager.get():openWindow("shrine_hurdle_select_partner_window", {})
		else
			self.canClose_ = true

			xyd.models.shrineHurdleModel:challengeSelect(self.selectIndex_, 0)
		end
	end
end

function ShrineHurdleChooseBuffWindow:onChallenge(event)
	if self.wndType_ == 2 and event.data.choice == 1 then
		xyd.alertTips(__("SHRINE_HURDLE_TEXT31"))
		self:close()
	elseif self.wndType_ == 2 and event.data.choice == 2 then
		xyd.alertTips(__("SHRINE_HURDLE_TEXT35"))
		self:close()
	elseif self.wndType_ == 3 then
		if self.index_ == 1 then
			xyd.alertTips(__("SHRINE_HURDLE_TEXT32"))
		else
			xyd.alertTips(__("SHRINE_HURDLE_TEXT33"))
		end

		self:updateCardSelect(0)
		self:updateCardItems()
	elseif self.wndType_ == 4 then
		xyd.alertTips(__("SHRINE_HURDLE_TEXT34"))
		self:close()
	end
end

function ShrineHurdleChooseBuffWindow:showGoldChange(changeNum)
	if changeNum > 0 then
		self.resItemChangeLabel_.color = Color.New2(915996927)
		self.resItemChangeLabel_.text = "+ " .. changeNum
	else
		self.resItemChangeLabel_.color = Color.New2(2751463679.0)
		self.resItemChangeLabel_.text = changeNum
	end

	self.resItemLabel_.text = xyd.models.shrineHurdleModel:getGold()

	self.resItemChangeLabel_:SetActive(true)

	local function setter(value)
		self.resItemChangeLabel_.alpha = value
	end

	local seq = self:getSequence(function ()
		if self.window_ and not tolua.isnull(self.window_) then
			self.resItemChangeLabel_:SetActive(false)
		end
	end)

	seq:AppendInterval(3)
	seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.5))
end

function ShrineHurdleChooseBuffWindow:updateNav()
	for i = 1, 2 do
		self["navShowImg" .. i]:SetActive(i == self.index_)
	end
end

function ShrineHurdleChooseBuffWindow:onClickNav(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	self.index_ = index

	self:updateCardItems()
	self:updateNav()
end

function ShrineHurdleChooseBuffWindow:updateShopState()
	if self.wndType_ == 3 then
		self.navGroup_:SetActive(true)
	else
		self.navGroup_:SetActive(false)
	end

	if self.wndType_ == 2 then
		self.closeBtn_:SetActive(false)
		self.chooseBtn_.transform:X(150)
		self.destroyBtn_:SetActive(true)
	else
		self.chooseBtn_.transform:X(0)
		self.destroyBtn_:SetActive(false)
	end

	if self.wndType_ == 4 then
		self.closeBtn_:SetActive(false)
	end

	if self.wndType_ == 2 then
		local cost = xyd.tables.shrineHurdleBuffTable:getCost(1) or {}
		self.destroyNum_.text = "+" .. cost[2]
	end
end

function ShrineHurdleChooseBuffWindow:updateCardItems()
	local extra = xyd.models.shrineHurdleModel:getExtra()

	for i = 1, 3 do
		if not self.cardItemList_[i] then
			self.cardItemList_[i] = ShrineHurdleBuffItem.new(self["cardItem" .. i], self)
		end

		if self.wndType_ == 4 then
			self.cardItemList_[i]:setInfo(CardItemType.REST, nil, i)

			self.chooseBtnLabel_.text = __("SHRINE_HURDLE_TEXT17")
		elseif self.wndType_ == 3 then
			if self.index_ == 2 then
				self.cardItemList_[i]:setInfo(CardItemType.UPGREAD, extra.upgrades[i], i)

				self.chooseBtnLabel_.text = __("SHRINE_HURDLE_TEXT20")
			else
				self.cardItemList_[i]:setInfo(CardItemType.BUY, extra.buys[i], i)

				self.chooseBtnLabel_.text = __("SHRINE_HURDLE_TEXT19")
			end
		elseif self.wndType_ == 2 then
			self.cardItemList_[i]:setInfo(CardItemType.SELECT, extra.skills[i], i)

			self.chooseBtnLabel_.text = __("SHRINE_HURDLE_TEXT17")
		end
	end

	self.cardGroup_:Reposition()
end

function ShrineHurdleChooseBuffWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.chooseBtn_ = winTrans:NodeByName("chooseBtn").gameObject
	self.chooseBtnLabel_ = winTrans:ComponentByName("chooseBtn/label", typeof(UILabel))
	self.destroyBtn_ = winTrans:NodeByName("destroyBtn").gameObject
	self.destroyBtnLabel_ = winTrans:ComponentByName("destroyBtn/label", typeof(UILabel))
	self.destroyNum_ = winTrans:ComponentByName("destroyBtn/labelNum", typeof(UILabel))
	self.navGroup_ = winTrans:NodeByName("navGroup").gameObject

	for i = 1, 2 do
		self["navBtn" .. i] = self.navGroup_:NodeByName("navBtn" .. i).gameObject
		self["navBtnLabel" .. i] = self["navBtn" .. i]:ComponentByName("label", typeof(UILabel))
		self["navShowImg" .. i] = self["navBtn" .. i]:NodeByName("showImg").gameObject
	end

	self.cardGroup_ = winTrans:ComponentByName("cardGroup", typeof(UILayout))

	for i = 1, 3 do
		self["cardItem" .. i] = winTrans:NodeByName("cardGroup/cardItem" .. i).gameObject
	end

	local infoGroup = self.window_:NodeByName("infoGroup").gameObject
	self.helpBtn_ = infoGroup:NodeByName("btnGroup/helpBtn").gameObject
	self.recordBtn_ = infoGroup:NodeByName("btnGroup/recordBtn").gameObject
	self.partnerBtn_ = infoGroup:NodeByName("btnGroup/partnerBtn").gameObject
	self.topLabelName_ = infoGroup:ComponentByName("topLabelName", typeof(UILabel))
	self.topLabel_ = infoGroup:ComponentByName("topLabel", typeof(UILabel))
	self.resItem_ = infoGroup:NodeByName("res_item").gameObject
	self.resItemLabel_ = infoGroup:ComponentByName("res_item/res_num_label", typeof(UILabel))
	self.resItemChangeLabel_ = infoGroup:ComponentByName("res_item/changeLabel", typeof(UILabel))
	self.navBtnLabel1.text = __("SHRINE_HURDLE_SHOP_TAB1")
	self.navBtnLabel2.text = __("SHRINE_HURDLE_SHOP_TAB2")
	self.chooseBtnLabel_.text = __("SHRINE_HURDLE_TEXT17")
	self.destroyBtnLabel_.text = __("SHRINE_HURDLE_TEXT18")
end

function ShrineHurdleChooseBuffWindow:updateCardSelect(card_index, skill_id, skill_lev, cost)
	self.selectIndex_ = card_index
	self.skill_id_ = skill_id or 0
	self.skill_lev_ = skill_lev or 0

	if cost then
		self.costNum_ = cost[2] or 0
	else
		self.costNum_ = 0
	end

	for i = 1, 3 do
		if i == self.selectIndex_ then
			self.cardItemList_[i]:setSelect(true)
		else
			self.cardItemList_[i]:setSelect(false)
		end
	end
end

function ShrineHurdleChooseBuffWindow:onGetRecords(event)
	local records = event.data.records
	local data = xyd.decodeProtoBuf(event.data)

	xyd.WindowManager.get():openWindow("shrine_hurdle_record_window", {
		records = data.records
	})
end

function ShrineHurdleChooseBuffWindow:checkGuide()
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex and guideIndex == 2 then
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_2
		})
	elseif guideIndex and guideIndex == 6 then
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_5
		})

		local win = xyd.WindowManager.get():getWindow("shrine_hurdle_window")

		if win then
			win:ShowNextClickBox()
		end
	elseif guideIndex and guideIndex == 7 then
		local win = xyd.WindowManager.get():getWindow("shrine_hurdle_window")

		if win then
			win:ShowNextClickBox()
		end

		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_6
		})
	end
end

return ShrineHurdleChooseBuffWindow
