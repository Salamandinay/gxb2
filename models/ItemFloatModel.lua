local ItemFloatModel = class("ItemFloatModel", import("app.models.BaseModel"))
local ItemFloat = import("app.components.ItemFloat")

function ItemFloatModel:ctor()
	ItemFloatModel.super.ctor(self)

	self.itemList_ = {}
	self.actions = {}
	self.parentGo = nil
	self.isPlaying_ = false
	self.actionCount_ = 0
	self.completeCount_ = 0
end

function ItemFloatModel:disposeAll()
	ItemFloatModel.super.disposeAll(self)

	if #self.actions > 0 then
		for i = 1, #self.actions do
			local action = self.actions[i]

			action:Pause()
			action:Kill()
		end

		self.actions = {}
	end

	XYDCo.StopWait("float_item_wait_new_action")
end

function ItemFloatModel:getTopObj()
	if self.parentGo then
		return self.parentGo
	end

	local topPanel = xyd.WindowManager.get():getTopPanel()

	if not topPanel then
		return
	end

	self.parentGo = topPanel:NodeByName("itemFloatNode").gameObject

	return self.parentGo
end

function ItemFloatModel:mergeItems(itemsData)
	local merge = {}
	local ifHide = {}
	local items = {}

	for i = 1, #itemsData do
		if itemsData[i].item_id ~= xyd.ItemID.VIP_EXP then
			merge[itemsData[i].item_id] = tonumber(itemsData[i].item_num) + (merge[itemsData[i].item_id] or 0)
			ifHide[itemsData[i].item_id] = itemsData[i].hideText or false
		end
	end

	for i, v in pairs(merge) do
		table.insert(items, {
			itemID = tonumber(i),
			num = v,
			hideText = ifHide[i]
		})
	end

	return items
end

function ItemFloatModel:pushNewItems(items, callback)
	self.callback = callback
	local merge = self:mergeItems(items)

	for i = 1, #items do
		table.insert(self.itemList_, merge[i])
	end

	if not self.isPlaying_ then
		if #items == 1 then
			xyd.SoundManager.get():playSound(xyd.SoundID.ITEM_FLOAT_1)
		elseif #items == 2 then
			xyd.SoundManager.get():playSound(xyd.SoundID.ITEM_FLOAT_2)
		elseif #items >= 3 then
			xyd.SoundManager.get():playSound(xyd.SoundID.ITEM_FLOAT_3)
		end

		self:playSingleAction()
	end
end

function ItemFloatModel:reset()
	self.callback = nil
	self.isPlaying_ = false
	self.actionCount_ = 0
	self.completeCount_ = 0
	self.actions = {}
	local parentGo = self:getTopObj()

	if not parentGo then
		return
	end

	parentGo:Y(0)
end

function ItemFloatModel:completeOne()
	self.completeCount_ = self.completeCount_ + 1

	if self.completeCount_ == self.actionCount_ then
		if self.callback then
			self.callback()
		end

		self:reset()
		self:playSingleAction()
	end
end

function ItemFloatModel:playSingleAction()
	if #self.itemList_ == 0 then
		return
	end

	local item = table.remove(self.itemList_, 1)
	local parentGo = self:getTopObj()

	if not parentGo then
		return
	end

	self.actionCount_ = self.actionCount_ + 1
	local singleItem = ItemFloat.new(parentGo)

	singleItem:setInfo(item)

	local action = self:getTimeLineLite()
	local w = singleItem:getGameObject():GetComponent(typeof(UIWidget))
	w.alpha = 0.5

	w:SetLocalScale(0.5, 0.5, 1)

	local offset0 = -(self.actionCount_ - 1) * 80
	local offset1 = 0
	local offset2 = offset1 + 60
	local offset3 = offset2 + 20
	local offset4 = offset3 + 40

	singleItem:SetLocalPosition(0, offset0, 0)
	action:Append(w.transform:DOLocalMove(Vector3(0, offset0 + offset1, 0), 0.1)):Join(w.transform:DOScale(Vector3(1, 1, 1), 0.1)):Join(xyd.getTweenAlpha(w, 1, 0.1)):Append(w.transform:DOLocalMove(Vector3(0, offset0 + offset2, 0), 0.2)):Append(w.transform:DOLocalMove(Vector3(0, offset0 + offset3, 0), 0.93)):Append(w.transform:DOLocalMove(Vector3(0, offset0 + offset4, 0), 0.2)):Join(xyd.getTweenAlpha(w, 0, 0.2)):AppendCallback(function ()
		NGUITools.Destroy(singleItem:getGameObject())
		self:completeOne()
	end)

	if self.actionCount_ > 1 then
		action:Insert(0, parentGo.transform:DOLocalMoveY(80 * (self.actionCount_ - 1), 0.2))
	end

	XYDCo.WaitForTime(0.2, function ()
		self:playSingleAction()
	end, "float_item_wait_new_action")

	self.isPlaying_ = true
end

function ItemFloatModel:getTimeLineLite()
	local action = nil

	local function completeCallback()
		for i = 1, #self.actions do
			if self.actions[i] == action then
				table.remove(self.actions, i)

				break
			end
		end
	end

	action = DG.Tweening.DOTween.Sequence():OnComplete(completeCallback)

	action:SetAutoKill(true)
	table.insert(self.actions, action)

	return action
end

return ItemFloatModel
