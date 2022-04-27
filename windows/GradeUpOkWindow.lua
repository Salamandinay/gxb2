local BaseWindow = import(".BaseWindow")
local SkillIcon = import("app.components.SkillIcon")
local GradeUpOkWindow = class("GradeUpOkWindow", BaseWindow)

function GradeUpOkWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.closeTime = 5
	self.isPlayerEffect = true
	self.attrParams = params.attrParams
	self.skillIds = {}
	self.type = params.type

	if not params.skillIds then
		table.insert(self.skillIds, params.skillId)
	else
		self.skillIds = params.skillIds
	end

	self.attrChangeItems = {}
end

function GradeUpOkWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	self.content = winTrans:NodeByName("content").gameObject
	self.groupEffect = content:NodeByName("groupEffect").gameObject
	self.attrChange = content:NodeByName("attrChange").gameObject
	self.attrChangeGrid = self.attrChange:GetComponent(typeof(UIGrid))
	self.attrChangeItem = self.attrChange:NodeByName("attrChangeItem").gameObject
	self.labelTitle = content:ComponentByName("labelTitle", typeof(UILabel))
	self.tips = content:ComponentByName("tips", typeof(UILabel))
	self.groupUnlock = content:NodeByName("groupUnlock").gameObject
	self.labelUnlock = self.groupUnlock:ComponentByName("labelUnlock", typeof(UILabel))
	self.skillGroup = content:NodeByName("skillGroup").gameObject

	for i = 1, 3 do
		self["skillIcon" .. i] = self.skillGroup:NodeByName("skillIcon" .. i).gameObject
	end

	self.renderTarget = self.groupEffect:ComponentByName("renderTarget", typeof(UIWidget))
end

function GradeUpOkWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self.skillGroup:SetActive(false)
	self.groupUnlock:SetActive(false)
	self.labelTitle:SetActive(false)

	self.labelTitle.text = __("PARTNER_GRADEUP")

	if xyd.Global.lang == "de_de" then
		self.labelTitle.fontSize = 22

		self.labelTitle:SetLocalPosition(0, 115, 0)
	end

	self.tips.text = __("POTENTIALITY_CLICK_CLOSE")

	self:registerEvent()

	self.OkEffect1 = xyd.Spine.new(self.renderTarget.gameObject)
	self.OkEffect2 = xyd.Spine.new(self.renderTarget.gameObject)

	self.OkEffect1:setInfo("fx_ui_zhanjijinjie", function ()
		self.OkEffect2:setInfo("fx_ui_zj_jinjie", function ()
			self.OkEffect1:SetLocalPosition(0, 0, 1)
			self.OkEffect1:SetLocalScale(1, 1, 1)
			self.OkEffect2:SetLocalPosition(0, 0, 0)
			self.OkEffect2:SetLocalScale(1, 1, 1)

			local index = 0

			for key in pairs(self.attrParams) do
				index = index + 1
				local item = self.attrChangeItems[index]

				if item == nil then
					local node = NGUITools.AddChild(self.attrChange, self.attrChangeItem)
					item = {
						node = node,
						label1 = node:ComponentByName("label1", typeof(UILabel)),
						label2 = node:ComponentByName("label2", typeof(UILabel)),
						label3 = node:ComponentByName("label3", typeof(UILabel)),
						arrow = node:NodeByName("arrow").gameObject
					}

					item.node:SetActive(false)

					self.attrChangeItems[index] = item
				end

				for i = 1, #self.attrParams[key] do
					local text = self.attrParams[key][i]

					if i == 1 then
						text = __(string.upper(text))
					end

					item["label" .. i].text = text
				end
			end

			self.attrChangeGrid:Reposition()
			self:setTimeout(function ()
				self.isPlayerEffect = false
			end, self, 2000)

			if self.skillIds[1] then
				self:setTimeout(function ()
					self.groupUnlock:SetActive(true)

					self.labelUnlock.text = __("SKILL_UNLOCK")
					local sequence = self:getSequence()
					local w = self.labelUnlock:GetComponent(typeof(UIWidget))
					local getter, setter = xyd.getTweenAlphaGeterSeter(w)

					sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
					sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
					sequence:AppendCallback(function ()
						sequence:Kill(false)

						sequence = nil
					end)
				end, self, 2400)
				self.skillGroup:SetActive(true)
				self.content:Y(45)
				self:setSkillGroupPos()

				for i = 1, #self.skillIds do
					local skillIconCarrier = self["skillIcon" .. i]
					local skillId = self.skillIds[i]

					if skillId then
						local skillIcon = SkillIcon.new(skillIconCarrier)
						local labelSkillName = skillIconCarrier:ComponentByName("labelSkillName", typeof(UILabel))

						skillIcon:setInfo(skillId)

						labelSkillName.text = __(xyd.tables.skillTable:getName(skillId))

						self:waitForTime(2.6 + 0.5 * (i - 1), function ()
							local skillIconTrans = skillIconCarrier.transform
							local sequence = self:getSequence()

							skillIconCarrier:SetActive(true)
							sequence:Append(skillIconTrans:DOScale(1.2, 0.1))
							sequence:Append(skillIconTrans:DOScale(0.95, 0.1))
							sequence:Append(skillIconTrans:DOScale(1, 0.1))
							sequence:AppendCallback(function ()
								sequence:Kill(false)

								sequence = nil
							end)
						end)

						if not self.type then
							self:waitForTime(2 + 0.5 * (i - 1), function ()
								local labelSkillNameTrans = labelSkillName.gameObject.transform

								labelSkillName:SetActive(true)

								local w = labelSkillName:GetComponent(typeof(UIWidget))
								local getter, setter = xyd.getTweenAlphaGeterSeter(w)
								local sequence = self:getSequence()

								sequence:Append(labelSkillNameTrans:DOScale(0.6, 0))
								sequence:Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
								sequence:Append(labelSkillNameTrans:DOScale(1, 0.2))
								sequence:Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.2))
								sequence:AppendCallback(function ()
									sequence:Kill(false)

									sequence = nil
								end)
							end)
						end
					else
						skillIconCarrier:SetActive(false)
					end
				end
			end

			self:waitForTime(0.6, function ()
				self.labelTitle:SetActive(true)

				local w = self.labelTitle:GetComponent(typeof(UIWidget))
				local getter, setter = xyd.getTweenAlphaGeterSeter(w)
				local sequence = self:getSequence()
				local originY = self.labelTitle.gameObject.transform.localPosition.y

				sequence:Append(self.labelTitle.gameObject.transform:DOLocalMoveY(originY + 70, 0))
				sequence:Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0))
				sequence:Append(self.labelTitle.gameObject.transform:DOLocalMoveY(originY, 0.45))
				sequence:Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.45))
			end)
			self.OkEffect2:play("texiao01", 1)
			self:setTimeout(function ()
				self.OkEffect1:play("texiao03", 1)
				self:setTimeout(function ()
					self.OkEffect1.spAnim.timeScale = 0.8

					self.OkEffect1.spAnim:play("texiao02", 0)
				end, self, 700)
			end, self, 600)

			for i = 1, #self.attrChangeItems do
				local obj = self.attrChangeItems[i]

				self:setTimeout(function ()
					self:playLabelAnimation(obj)
				end, self, 200 * i + 1000)
			end

			xyd.SoundManager.get():playSound(xyd.SoundID.HERO_STAR_UP)
		end)
	end)
end

function GradeUpOkWindow:setSkillGroupPos()
	if #self.skillIds == 2 then
		self.skillIcon1:SetLocalPosition(-65, 0, 0)
		self.skillIcon2:SetLocalPosition(65, 0, 0)
	elseif #self.skillIds == 3 then
		self.skillIcon1:SetLocalPosition(-135, 0, 0)
		self.skillIcon2:SetLocalPosition(0, 0, 0)
		self.skillIcon3:SetLocalPosition(135, 0, 0)
	end
end

function GradeUpOkWindow:playLabelAnimation(obj)
	local sequence1 = self:getSequence()
	local sequence2 = self:getSequence()
	local sequence3 = self:getSequence()
	local sequence4 = self:getSequence()

	obj.node:SetActive(true)

	local label1 = obj.label1
	local label2 = obj.label2
	local label3 = obj.label3
	local arrow = obj.arrow

	local function getterSetterGenerator(widget)
		local function getter()
			return widget.color
		end

		local function setter(color)
			widget.color = color
		end

		return getter, setter
	end

	local label1Getter, label1Setter = getterSetterGenerator(label1:GetComponent(typeof(UIWidget)))

	sequence1:Append(DG.Tweening.DOTween.ToAlpha(label1Getter, label1Setter, 0.1, 0))
	sequence1:Append(DG.Tweening.DOTween.ToAlpha(label1Getter, label1Setter, 1, 0))
	sequence1:AppendCallback(function ()
		sequence1:Kill(false)

		sequence1 = nil
	end)

	local label2Getter, label2Setter = getterSetterGenerator(label2:GetComponent(typeof(UIWidget)))

	sequence2:Append(DG.Tweening.DOTween.ToAlpha(label2Getter, label2Setter, 0.1, 0))
	sequence2:Append(DG.Tweening.DOTween.ToAlpha(label2Getter, label2Setter, 1, 0))
	sequence2:AppendCallback(function ()
		sequence2:Kill(false)

		sequence2 = nil
	end)

	local label3Getter, label3Setter = getterSetterGenerator(label3:GetComponent(typeof(UIWidget)))

	sequence3:Append(DG.Tweening.DOTween.ToAlpha(label3Getter, label3Setter, 0.1, 0))
	sequence3:Append(DG.Tweening.DOTween.ToAlpha(label3Getter, label3Setter, 1, 0))
	sequence3:AppendCallback(function ()
		sequence3:Kill(false)

		sequence3 = nil
	end)

	local arrowGetter, arrowSetter = getterSetterGenerator(arrow:GetComponent(typeof(UIWidget)))
	local originX = arrow.transform.localPosition.x

	sequence4:Insert(0, DG.Tweening.DOTween.ToAlpha(arrowGetter, arrowSetter, 0.5, 0))
	sequence4:Insert(0, arrow.transform:DOLocalMoveX(originX - 10, 0))
	sequence4:Insert(0, DG.Tweening.DOTween.ToAlpha(arrowGetter, arrowSetter, 1, 0.13))
	sequence4:Insert(0, arrow.transform:DOLocalMoveX(originX + 10, 0.13))
	sequence4:Insert(0.13, DG.Tweening.DOTween.ToAlpha(arrowGetter, arrowSetter, 1, 0.07))
	sequence4:Insert(0.13, arrow.transform:DOLocalMoveX(originX, 0.07))
	sequence4:AppendCallback(function ()
		sequence4:Kill(false)

		sequence4 = nil
	end)

	local effect = xyd.Spine.new(obj.node)

	effect:setInfo("fx_ui_zhanjijinjie", function ()
		effect:SetLocalPosition(0, 0, 0)
		effect:SetLocalScale(1, 1, 1)
		effect:setRenderTarget(arrow:GetComponent(typeof(UIWidget)), 1)
		effect.spAnim:play("texiao01", 1)
	end)
end

function GradeUpOkWindow:close()
	if self.isPlayerEffect then
		return
	end

	GradeUpOkWindow.super.close(self)
end

function GradeUpOkWindow:willClose()
	BaseWindow.willClose(self)

	local win = xyd.WindowManager.get():getWindow("partner_detail_window")

	if win then
		local partner = win:getCurPartner()
		local dialog = xyd.tables.partnerTable:getGradeupDialogInfo(partner:getTableID(), partner:getSkinID())

		win:playSound(dialog)
	end
end

function GradeUpOkWindow:registerEvent()
end

return GradeUpOkWindow
