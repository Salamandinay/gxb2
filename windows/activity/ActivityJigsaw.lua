local ActivityContent = import(".ActivityContent")
local ActivityJigsaw = class("ActivityJigsaw", ActivityContent)
local CountDown = import("app.components.CountDown")
local ActivityJigsawCard = class("ActivityJigsawCard", import("app.components.BaseComponent"))
local ActivityJigsawItem = class("ActivityJigsawItem", import("app.components.BaseComponent"))
local ActivityJigsawItemPiece = class("ActivityJigsawItemPiece", import("app.components.BaseComponent"))
local cjson = require("cjson")
ActivityJigsaw.cost_type = 2
ActivityJigsaw.buy_type = 40
ActivityJigsaw.groupChooseX = -240
ActivityJigsaw.groupActionX = 0
ActivityJigsaw.groupAwardChooseX = 0

function ActivityJigsaw:ctor(parentGO, params)
	self.cardList_ = {}
	self.sequenceList_ = {}

	ActivityJigsaw.super.ctor(self, parentGO, params)
	self:registerEvent()
end

function ActivityJigsaw:getPrefabPath()
	return "Prefabs/Windows/activity/activity_jigsaw"
end

function ActivityJigsaw:initUI()
	ActivityJigsaw.super.initUI(self)
	self:getUIComponent()
	self:initCards()
	self:setBtnText()
	self:setLabelText()
	self:updateEnergy()
	self:updateProgress()
	self:setCountDown()
end

function ActivityJigsaw:getUIComponent()
	local goTrans = self.go.transform
	self.textImg_ = goTrans:ComponentByName("textImg", typeof(UITexture))
	self.countTextLabel_ = goTrans:ComponentByName("groupCount/countTextLabel", typeof(UILabel))
	self.countLabel_ = goTrans:ComponentByName("groupCount/countLabel", typeof(UILabel))
	self.leftTimeLabel_ = goTrans:ComponentByName("groupTime/leftTimeLabel", typeof(UILabel))
	self.timeLabel_ = goTrans:ComponentByName("groupTime/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("groupTime/endLabel", typeof(UILabel))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.helpBtnLabel_ = goTrans:ComponentByName("helpBtn/label", typeof(UILabel))
	self.returnBtn_ = goTrans:NodeByName("returnBtn").gameObject
	self.returnBtnLabel_ = goTrans:ComponentByName("returnBtn/label", typeof(UILabel))
	self.purchaseBtn_ = goTrans:NodeByName("purchaseBtn").gameObject
	self.purchaseBtnLabel_ = goTrans:ComponentByName("purchaseBtn/label", typeof(UILabel))
	self.scrollView_ = goTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = goTrans:ComponentByName("scrollView/itemGroup", typeof(UIGrid))
	self.groupChoose_ = self.grid_:GetComponent(typeof(UIWidget))
	self.itemCardRoot_ = goTrans:NodeByName("scrollView/itemRoot").gameObject

	self.itemCardRoot_:SetActive(false)

	self.actionScroller_ = goTrans:ComponentByName("scrollAction", typeof(UIPanel))
	self.groupAction_ = goTrans:ComponentByName("scrollAction/groupAction", typeof(UIWidget))
	self.awardScorll_ = goTrans:ComponentByName("scorllAward", typeof(UIPanel))
	self.groupAward_ = goTrans:ComponentByName("scorllAward/groupAward", typeof(UIWidget))
	self.progressBar_ = goTrans:ComponentByName("scorllAward/groupAward/progressBar", typeof(UIProgressBar))
	self.sumTextLabel_ = goTrans:ComponentByName("scorllAward/groupAward/groupLabel/label", typeof(UILabel))
	local boxIds = xyd.tables.activityJigsawAwardTable:getIds()

	for i = 1, 6 do
		local id = tonumber(boxIds[i])
		local awardBag = goTrans:ComponentByName("scorllAward/groupAward/awardBags/awardBag" .. i, typeof(UIWidget))
		local awardImg = awardBag.gameObject:ComponentByName("bagImg", typeof(UISprite))
		self["boxImg" .. id] = awardImg
		self["boxLabel" .. id] = awardBag.gameObject:ComponentByName("label", typeof(UILabel))
	end

	for i = 1, #boxIds do
		local id = boxIds[i]
		local img = self["boxImg" .. id]

		UIEventListener.Get(img.gameObject).onClick = function ()
			xyd.WindowManager.get():openWindow("activity_award_preview_window", {
				awards = xyd.tables.activityJigsawAwardTable:getAwards(id)
			})
		end
	end

	UIEventListener.Get(self.purchaseBtn_).onClick = function ()
		if self:getBuyTime() <= 0 then
			xyd.showToast(__("ACTIVITY_JIGSAW_LIMIT"))

			return
		end

		xyd.WindowManager.get():openWindow("activity_jigsaw_purchase_window", {
			limitKey = "ACTIVITY_JIGSAW_LIMIT",
			needTips = true,
			buyNum = 1,
			titleKey = "ACTIVITY_JIGSAW_BUY_TITLE",
			buyType = self.buy_type,
			costType = self.cost_type,
			purchaseCallback = function (_, num)
				local msg = messages_pb.boss_buy_req()
				msg.activity_id = self.id
				msg.num = num

				xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
			end,
			limitNum = self:getBuyTime(),
			maxNum = self:getMaxBuyNum(),
			eventType = xyd.event.BOSS_BUY,
			costNum = xyd.tables.activityJigsawBuyTable:getPresum(self:getHasBoughtTime()),
			calPriceCallback = function (num)
				local price = xyd.tables.activityJigsawBuyTable:getPresum(self:getHasBoughtTime() + num) - xyd.tables.activityJigsawBuyTable:getPresum(self:getHasBoughtTime())

				return price
			end,
			textArray = {
				__("ACTIVITY_JIGSAW_BUY_TEXT1"),
				__("ACTIVITY_JIGSAW_BUY_TEXT2")
			}
		})
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		local params = {
			key = "ACTIVITY_JIGSAW_HELP",
			title = __("ACTIVITY_JIGSAW_RULE")
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end

	UIEventListener.Get(self.returnBtn_).onClick = function ()
		self:playReturn()
		self.curItem:destorySelf()

		self.curItem = nil
	end

	self.returnBtn_.gameObject:SetActive(false)
	xyd.setUITextureAsync(self.textImg_, "Textures/activity_text_web/activity_jigsaw_text01_" .. xyd.Global.lang)
end

function ActivityJigsaw:getMaxBuyNum()
	local costHasNum = xyd.models.backpack:getItemNumByID(self.cost_type)

	for i = self:getHasBoughtTime(), xyd.tables.miscTable:getNumber("activity_jigsaw_buy_limit", "value") do
		local costNum = xyd.tables.activityJigsawBuyTable:getPresum(i)

		if costHasNum < costNum then
			return i - 1
		elseif costNum == costHasNum then
			return i
		end
	end
end

function ActivityJigsaw:registerEvent()
	self.eventProxyInner_:addEventListener(xyd.event.BOSS_BUY, handler(self, self.onBuyEnergy))
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetActivityAward))
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityJigsaw:onBuyEnergy(event)
	local data = event.data

	if data.activity_id ~= self.id then
		return
	end

	self.activityData.detail_.buy_times = event.data.buy_times

	self:updateEnergy()
end

function ActivityJigsaw:onGetActivityAward(event)
	local data = event.data
	local real_data = cjson.decode(data.detail)

	if self.id ~= data.activity_id then
		return
	end

	local pic_id = real_data.picture_id
	local card = self.cardList_[pic_id]

	if self.curItem then
		local succ = self.curItem:swap()

		card:updateStatus(succ)
	end

	self:updateEnergy()
	self:updateProgress()
end

function ActivityJigsaw:onItemChange(event)
	local data = event.data

	for i = 1, #data.items do
		if data.items[i].item_id == self.buy_type then
			self:updateEnergy()

			break
		end
	end
end

function ActivityJigsaw:getBuyTime()
	return xyd.tables.miscTable:getNumber("activity_jigsaw_buy_limit", "value") - self:getHasBoughtTime()
end

function ActivityJigsaw:getHasBoughtTime()
	return self.activityData.detail_.buy_times
end

function ActivityJigsaw:initCards()
	local ids = xyd.tables.activityJigsawPicTable:getIds()
	local datas = {}

	for i = 1, #ids do
		local id = ids[i]
		local data = {
			id = id,
			pieces = self.activityData.detail_["picture_" .. id],
			is_awarded = self.activityData.detail_["is_awarded_" .. id]
		}

		table.insert(datas, data)
	end

	table.sort(datas, function (a, b)
		return tonumber(a.id) < tonumber(b.id)
	end)

	for i = 1, #ids do
		local newRoot = NGUITools.AddChild(self.grid_.gameObject, self.itemCardRoot_)

		newRoot:SetActive(true)

		local card = ActivityJigsawCard.new(newRoot, self)

		card:setInfo(datas[i])

		self.cardList_[datas[i].id] = card

		card:setTouchEvent(function ()
			NGUITools.DestroyChildren(self.groupAction_.transform)

			if self.curItem then
				self.curItem:onRemove()
			end

			local item = ActivityJigsawItem.new(self.groupAction_.gameObject, self)

			item:setInfo(datas[i])
			self:playEnter()

			self.curItem = item
		end)
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

function ActivityJigsaw:setBtnText()
	self.helpBtnLabel_.text = __("ACTIVITY_JIGSAW_RULE")
	self.returnBtnLabel_.text = __("ACTIVITY_JIGSAW_BACK")
	self.purchaseBtnLabel_.text = __("ACTIVITY_JIGSAW_BTN_ENERGY")
end

function ActivityJigsaw:setLabelText()
	self.endLabel_.text = __("TEXT_END")
	self.countTextLabel_.text = __("ACTIVITY_JIGSAW_ENERGY")
	self.sumTextLabel_.text = __("ACTIVITY_JIGSAW_TOTAL")
end

function ActivityJigsaw:updateEnergy()
	self.countLabel_.text = tostring(xyd.models.backpack:getItemNumByID(self.buy_type))
end

function ActivityJigsaw:setCountDown()
	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local params = {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		}

		if not self.refreshCount_ then
			self.refreshCount_ = CountDown.new(self.timeLabel_, params)
		else
			self.refreshCount_:setInfo(params)
		end
	else
		self.endLabel_.gameObject:SetActive(false)
		self.timeLabel_.gameObject:SetActive(false)
		self.leftTimeLabel_.gameObject:SetActive(false)
	end
end

function ActivityJigsaw:updateProgress()
	local ids = xyd.tables.activityJigsawAwardTable:getIds()
	local cur_cnt = self.activityData.detail_.complete_num
	local maxNum = #xyd.tables.activityJigsawPicTable:getIds()
	self.progressBar_.value = tonumber(cur_cnt) / tonumber(maxNum)

	for i = 1, maxNum do
		local id = tonumber(ids[i])

		if id then
			local label = self["boxLabel" .. id]
			local img = self["boxImg" .. id]
			local tar_cnt = tonumber(xyd.tables.activityJigsawAwardTable:getComplete(id))
			label.text = tostring(tar_cnt)
			local source = ""

			if tar_cnt <= tonumber(cur_cnt) then
				if id <= 3 then
					source = "activity_jigsaw_icon01_1"
				elseif id <= 4 then
					source = "activity_jigsaw_icon02_1"
				else
					source = "activity_jigsaw_open_icon"
				end
			elseif id <= 3 then
				source = "activity_jigsaw_icon01_0"
			elseif id <= 4 then
				source = "activity_jigsaw_icon02_0"
			else
				source = "trial_icon04"
			end

			xyd.setUISpriteAsync(img, nil, source)
		end
	end
end

function ActivityJigsaw:playReturn()
	self:initSeq()
	self.returnBtn_.gameObject:SetActive(false)

	self.groupChoose_.alpha = 0.5

	self.groupChoose_.gameObject:SetActive(true)

	local function settergroupChoose(value)
		self.groupChoose_.alpha = value
	end

	local groupChooseTouchMask = self.scrollView_.transform:NodeByName("noTouchMask").gameObject

	groupChooseTouchMask:SetActive(true)
	self.groupChooseAction:Insert(0, self.groupChoose_.transform:DOLocalMove(Vector3(self.groupChooseX, 0, 0), 0.5))
	self.groupChooseAction:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(settergroupChoose), 0.5, 1, 0.5))
	self.groupChooseAction:InsertCallback(0.5, function ()
		groupChooseTouchMask:SetActive(false)
		self.groupChooseAction:Kill(true)
	end)
	self.groupAward_.gameObject:SetActive(true)

	local groupAwardTouchMask = self.groupAward_.transform:NodeByName("noTouchMask").gameObject

	groupAwardTouchMask:SetActive(true)

	local function settergroupAward(value)
		self.groupAward_.alpha = value
	end

	self.groupAward_.alpha = 0.5

	self.groupAwardAction:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(settergroupAward), 0.5, 1, 0.5))
	self.groupAwardAction:Insert(0, self.groupAward_.transform:DOLocalMove(Vector3(self.groupAwardChooseX, 0, 0), 0.5))
	self.groupAwardAction:InsertCallback(0.5, function ()
		groupAwardTouchMask:SetActive(false)
		self.groupAwardAction:Kill(true)
	end)
	self.groupAction_.gameObject:SetActive(false)

	local function settergroupAction(value)
		if not UNITY_IOS then
			self.groupAction_.alpha = value
		end
	end

	local groupActionTouchMask = self.actionScroller_.transform:NodeByName("noTouchMask").gameObject

	groupActionTouchMask:SetActive(true)
	self.groupActionAction:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(settergroupAction), 1, 0.5, 0.5))
	self.groupActionAction:Insert(0, self.groupAction_.transform:DOLocalMove(Vector3(self.groupActionX + 756, -30, 0), 0.5))
	self.groupActionAction:InsertCallback(0.5, function ()
		self.actionScroller_.gameObject:SetActive(false)
		self.groupAction_.gameObject:SetActive(false)
		groupActionTouchMask:SetActive(false)
		self.groupActionAction:Kill(true)
	end)
end

function ActivityJigsaw:playEnter()
	self:initSeq()
	self.groupAction_.gameObject:SetActive(true)
	self.actionScroller_.gameObject:SetActive(true)

	local groupChooseTouchMask = self.scrollView_.transform:NodeByName("noTouchMask").gameObject

	groupChooseTouchMask:SetActive(true)

	local function settergroupChoose(value)
		self.groupChoose_.alpha = value
	end

	self.groupChooseAction:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(settergroupChoose), 1, 0.01, 0.5))
	self.groupChooseAction:Insert(0, self.groupAward_.transform:DOLocalMove(Vector3(self.groupChooseX - 640, 0, 0), 0.5))
	self.groupChooseAction:InsertCallback(0.5, function ()
		groupChooseTouchMask:SetActive(false)
		self.returnBtn_:SetActive(true)
		self.groupAward_.gameObject:SetActive(false)
		self.groupChooseAction:Kill(true)
	end)

	local groupAwardTouchMask = self.groupAward_.transform:NodeByName("noTouchMask").gameObject

	groupAwardTouchMask:SetActive(true)

	local function settergroupAward(value)
		self.groupAward_.alpha = value
	end

	self.groupAwardAction:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(settergroupAward), 1, 0.01, 0.5))
	self.groupAwardAction:Insert(0, self.groupAward_.transform:DOLocalMove(Vector3(self.groupAwardChooseX - 644, 0, 0), 0.5))
	self.groupChooseAction:InsertCallback(0.5, function ()
		groupAwardTouchMask:SetActive(false)
		self.groupChooseAction:Kill(true)
	end)
	self.groupAction_.gameObject:SetLocalPosition(self.groupActionX + 756, -30, 0)

	local groupActionTouchMask = self.actionScroller_.gameObject:NodeByName("noTouchMask")
	groupActionTouchMask = groupActionTouchMask.gameObject

	groupActionTouchMask:SetActive(true)

	local function settergroupAction(value)
		self.groupAction_.alpha = value
	end

	self.groupAction_.gameObject:SetActive(true)

	if not UNITY_IOS then
		self.groupAction_.alpha = 0.5

		self.groupActionAction:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(settergroupAction), 0.5, 1, 0.5))
	end

	self.groupActionAction:Insert(0, self.groupAction_.transform:DOLocalMove(Vector3(self.groupActionX, -30, 0), 0.5))
	self.groupActionAction:InsertCallback(0.5, function ()
		groupActionTouchMask:SetActive(false)
		self.groupActionAction:Kill(true)
	end)
end

function ActivityJigsaw:initSeq()
	if self.groupChooseAction then
		self.groupChooseAction:Kill(false)

		self.groupChooseAction = nil
	end

	self.groupChooseAction = self:getSequence()

	if self.groupAwardAction then
		self.groupAwardAction:Kill(false)

		self.groupAwardAction = nil
	end

	self.groupAwardAction = self:getSequence()

	if self.groupActionAction then
		self.groupActionAction:Kill(false)

		self.groupActionAction = nil
	end

	self.groupActionAction = self:getSequence()
end

function ActivityJigsaw:onRemove()
	if self.groupChooseAction then
		self.groupChooseAction:Kill(false)

		self.groupChooseAction = nil
	end

	if self.groupAwardAction then
		self.groupAwardAction:Kill(false)

		self.groupAwardAction = nil
	end

	if self.groupActionAction then
		self.groupActionAction:Kill(false)

		self.groupActionAction = nil
	end

	for _, seq in ipairs(self.sequenceList_) do
		seq:Kill(true)
	end
end

function ActivityJigsawCard:ctor(parentGO, parent)
	self.parent_ = parent

	ActivityJigsawCard.super.ctor(self, parentGO)
end

function ActivityJigsawCard:initUI()
	ActivityJigsawCard.super.initUI(self)
	self:getComponent()
end

function ActivityJigsawCard:getComponent()
	local goTrans = self.go.transform
	self.nameLabel_ = goTrans:ComponentByName("nameLabel", typeof(UILabel))
	self.avatorImg_ = goTrans:ComponentByName("avatorImg", typeof(UISprite))
	self.finishImg_ = goTrans:ComponentByName("finishImg", typeof(UITexture))

	self.finishImg_.gameObject:SetActive(false)

	local drag = self.go:AddComponent(typeof(UIDragScrollView))
	drag.scrollView = self.parent_.scrollView_
end

function ActivityJigsawCard:setInfo(params)
	self.data_ = params
	self.id_ = params.id

	self:initCard()
end

function ActivityJigsawCard:initCard()
	self.nameLabel_.text = xyd.tables.activityJigsawPicTextTable:getName(self.id_)

	xyd.setUITextureAsync(self.finishImg_, "Textures/activity_text_web/activity_jigsaw_finish_icon_" .. xyd.Global.lang)

	local iconName = xyd.tables.activityJigsawPicTable:getAvatarSrc(self.id_)

	xyd.setUISpriteAsync(self.avatorImg_, nil, iconName)

	if self.data_.is_awarded and self.data_.is_awarded == 1 then
		self.finishImg_.gameObject:SetActive(true)
	end
end

function ActivityJigsawCard:getData()
	return self.data_
end

function ActivityJigsawCard:updateStatus(finish)
	self.data_.is_awarded = xyd.checkCondition(finish, 1, 0)

	self.finishImg_.gameObject:SetActive(finish)
end

function ActivityJigsawCard:getPrefabPath()
	return "Prefabs/Components/jigsaw_card_item"
end

function ActivityJigsawCard:setTouchEvent(callback)
	UIEventListener.Get(self.go).onClick = function ()
		callback()
	end
end

function ActivityJigsawItem:ctor(parentGO, parent, card)
	self.parent_ = parent
	self.card_ = card
	self.deltaX = 110
	self.deltaY = -160
	self.col = 3
	self.itemsList_ = {}
	self.pieces_ = {}
	self.select_queue = {}

	ActivityJigsawItem.super.ctor(self, parentGO)
end

function ActivityJigsawItem:initUI()
	ActivityJigsawItem.super.initUI(self)
	self:getComponent()

	UIEventListener.Get(self.bgTouch_).onClick = function ()
		self:clearSelectQueue()
	end
end

function ActivityJigsawItem:getComponent()
	local goTrans = self.go.transform
	self.nameLabel_ = goTrans:ComponentByName("nameLabel", typeof(UILabel))
	self.bgTouch_ = goTrans:NodeByName("touchBg").gameObject
	self.groupAwards_ = goTrans:ComponentByName("groupAwards", typeof(UIGrid))
	self.finishImg_ = goTrans:ComponentByName("finishiImg", typeof(UITexture))
	self.piecesGroup_ = goTrans:NodeByName("piecesGroup").gameObject

	self.finishImg_.gameObject:SetActive(false)
end

function ActivityJigsawItem:getPrefabPath()
	return "Prefabs/Components/jigsaw_item"
end

function ActivityJigsawItem:setInfo(params)
	self.pieces_ = params.pieces
	self.item_id_ = params.id
	self.is_awarded_ = params.is_awarded

	self:initItem()
end

function ActivityJigsawItem:initItem()
	self:initPieces()
	self:initAward()
	xyd.setUITextureAsync(self.finishImg_, "Textures/activity_text_web/activity_jigsaw_finish_icon_" .. xyd.Global.lang)

	self.nameLabel_.text = xyd.tables.activityJigsawPicTextTable:getName(self.item_id_)

	if self.is_awarded_ == 1 then
		self.finishImg_.gameObject:SetActive(true)
	end
end

function ActivityJigsawItem:initAward()
	local awards = xyd.tables.activityJigsawPicTable:getAwards(self.item_id_)

	for i = 1, #awards do
		local data = awards[i]
		local params = {
			scale = 0.8,
			itemID = data[1],
			num = data[2],
			attach_callback = function ()
				self:clearSelectQueue()
			end,
			uiRoot = self.groupAwards_.gameObject
		}

		xyd.getItemIcon(params)
	end
end

function ActivityJigsawItem:initPieces()
	local x = -110
	local y = 160

	for i = 1, 9 do
		local params = {
			item_id = self.item_id_,
			pic_id = i,
			fa = self
		}
		local piece = ActivityJigsawItemPiece.new(self.piecesGroup_.gameObject)

		piece:setInfo(params)
		table.insert(self.itemsList_, piece)
	end

	for i = 1, 9 do
		local item = self:getPieceByPicId(self:getPicIdByPosId(i))

		item:setPosId(i)
		item:setPosition(x, y)

		if i % self.col == 0 then
			x = -110
			y = y + self.deltaY
		else
			x = x + self.deltaX
		end
	end
end

function ActivityJigsawItem:getPieceByPicId(pic_id)
	return self.itemsList_[pic_id]
end

function ActivityJigsawItem:getPicIdByPosId(pos_id)
	return self.pieces_[pos_id]
end

function ActivityJigsawItem:setSelect(pos_id)
	if self.is_awarded_ == 1 then
		return
	end

	if not self:checkSwap() then
		return
	end

	if #self.select_queue > 2 then
		return
	end

	local item = self:getPieceByPicId(self:getPicIdByPosId(pos_id))
	local index = xyd.arrayIndexOf(self.select_queue, pos_id)
	self.hasSwapOver_ = false

	if index ~= -1 then
		table.remove(self.select_queue, index)
		item.effect:SetActive(false)

		return
	end

	table.insert(self.select_queue, pos_id)

	index = #self.select_queue

	if not item.effect then
		local effectRoot = item:getSprite().gameObject
		local effect = xyd.Spine.new(effectRoot, true)

		item:setEffect(effect)
		item.effect:setInfo("act_jigsaw_pick", function ()
			if tolua.isnull(self.go) then
				return
			end

			effect:SetLocalPosition(0, 0, 0)
			effect:SetLocalScale(1, 1, 1)
			effect:setRenderTarget(item:getSprite(), 1)

			if self.hasSwapOver_ then
				return
			end

			effect:play("texiao01", 0, 1)
		end)
	else
		item.effect:SetActive(true)
		item.effect:play("texiao01", 0, 1)
	end

	if #self.select_queue == 2 then
		self:reqSwap()
	end
end

function ActivityJigsawItem:reqSwap()
	if #self.select_queue < 2 then
		return
	end

	local param = {
		picture_id = self.item_id_,
		index_a = self.select_queue[1],
		index_b = self.select_queue[2]
	}
	local param2 = cjson.encode(param)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_JIGSAW
	msg.params = param2

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityJigsawItem:testMatch()
	for i = 1, 9 do
		if self.pieces_[i] ~= i then
			return false
		end
	end

	self.is_awarded_ = 1

	return true
end

function ActivityJigsawItem:clearSelectEffect()
	if self.parent_.select_effect1 then
		self.parent_.select_effect1:Stop()

		self.parent_.select_effect1 = nil
	end

	if self.parent_.select_effect2 then
		self.parent_.select_effect2:Stop()

		self.parent_.select_effect2 = nil
	end
end

function ActivityJigsawItem:checkSwap()
	if xyd.models.backpack:getItemNumByID(self.parent_.buy_type) > 0 then
		return true
	else
		xyd.showToast(__("ACTIVITY_JIGSAW_NOT_ENOUGH"))

		return false
	end
end

function ActivityJigsawItem:swap()
	for i = 1, 2 do
		self["select_target" .. i] = self:getPieceByPicId(self:getPicIdByPosId(self.select_queue[i]))
		self["select_target" .. i].hasSwapOver_ = true

		self["select_target" .. i]:setEffect()

		self["select_effect" .. i] = nil
	end

	self:clearSelectEffect()

	local temp_x_1 = self.select_target1:getPosition().x
	local temp_x_2 = self.select_target2:getPosition().x
	local temp_y_1 = self.select_target1:getPosition().y
	local temp_y_2 = self.select_target2:getPosition().y
	self.swap_action = DG.Tweening.DOTween.Sequence()

	table.insert(self.parent_.sequenceList_, self.swap_action)
	self.swap_action:Insert(0, self.select_target2:getTrans():DOLocalMove(Vector3(temp_x_1, temp_y_1, 0), 0.5)):SetEase(DG.Tweening.Ease.OutBack)
	self.swap_action:Insert(0, self.select_target1:getTrans():DOLocalMove(Vector3(temp_x_2, temp_y_2, 0), 0.5)):SetEase(DG.Tweening.Ease.OutBack)
	self.swap_action:InsertCallback(0.5, function ()
		self.select_queue = {}
	end)

	local temp = self.pieces_[self.select_queue[1]]
	self.pieces_[self.select_queue[1]] = self.pieces_[self.select_queue[2]]
	self.pieces_[self.select_queue[2]] = temp

	self.select_target1:setPosId(self.select_queue[2])
	self.select_target2:setPosId(self.select_queue[1])

	local succ = self:testMatch()

	if succ then
		local selectPic = self.select_target1:getSprite()

		self.swap_action:AppendCallback(function ()
			self:playMatchEffect(selectPic)
		end)
	end

	self:clearSelect()

	return succ
end

function ActivityJigsawItem:clearSelectQueue()
	if #self.select_queue == 1 then
		local item = self:getPieceByPicId(self:getPicIdByPosId(self.select_queue[1]))

		item:setEffect()

		self.select_queue = {}
	end
end

function ActivityJigsawItem:showMatchAward()
	local awards = xyd.tables.activityJigsawPicTable:getAwards(self.item_id_)
	local items = {}

	for i = 1, #awards do
		local data = awards[i]

		table.insert(items, {
			item_id = data[1],
			item_num = data[2]
		})
	end

	xyd.WindowManager.get():openWindow("gamble_rewards_window", {
		wnd_type = 2,
		data = items
	})
	self.finishImg_.gameObject:SetActive(true)
end

function ActivityJigsawItem:playMatchEffect(sprite)
	self.matchEffect_ = xyd.Spine.new(self.piecesGroup_)

	self.matchEffect_:setInfo("act_jigsaw_finish", function ()
		self.matchEffect_:SetLocalPosition(0, 60, 0)
		self.matchEffect_:SetLocalScale(1, 1, 1)
		self.matchEffect_:setRenderTarget(sprite, 1)
		self.matchEffect_:play("texiao01", 1, 1, function ()
			self.matchEffect_:SetActive(false)
			self:showMatchAward()
		end)
	end)
end

function ActivityJigsawItem:clearSelect()
	self.select_target1 = nil
	self.select_target2 = nil
end

function ActivityJigsawItem:onRemove()
	if self.swap_action then
		self.swap_action:Kill(true)

		self.swap_action = nil
	end
end

function ActivityJigsawItem:destorySelf()
	self:onRemove()
	NGUITools.Destroy(self.go)
end

function ActivityJigsawItemPiece:ctor(parentGO)
	ActivityJigsawItemPiece.super.ctor(self, parentGO)
end

function ActivityJigsawItemPiece:initUI()
	ActivityJigsawItemPiece.super.initUI(self)
	self:getComponent()
end

function ActivityJigsawItemPiece:getComponent()
	self.scrImg_ = self.go:ComponentByName("img", typeof(UISprite))
end

function ActivityJigsawItemPiece:getPrefabPath()
	return "Prefabs/Components/jigsaw_piece"
end

function ActivityJigsawItemPiece:setPosId(pos_id)
	self.pos_id = pos_id
end

function ActivityJigsawItemPiece:setInfo(params)
	self.item_id = params.item_id
	self.pic_id = params.pic_id
	self.fa = params.fa
	local picName = xyd.tables.activityJigsawPicTable:getPicSrc(self.item_id) .. "_" .. self.pic_id

	xyd.setUISpriteAsync(self.scrImg_, nil, picName)

	UIEventListener.Get(self.scrImg_.gameObject).onClick = function ()
		self.fa:setSelect(self.pos_id)
	end
end

function ActivityJigsawItemPiece:setPosition(x, y)
	self.go:SetLocalPosition(x, y, 0)
end

function ActivityJigsawItemPiece:getPosition()
	return self.go.transform.localPosition
end

function ActivityJigsawItemPiece:getTrans()
	return self.go.transform
end

function ActivityJigsawItemPiece:getPosId()
	return self.pos_id
end

function ActivityJigsawItemPiece:getSprite()
	return self.scrImg_
end

function ActivityJigsawItemPiece:setEffect(effect)
	if not effect then
		if self.effect then
			self.effect:SetActive(false)
		end
	else
		self.effect = effect
	end
end

return ActivityJigsaw
