local Trie = class("Trie")
local AC_DFA = class("AC_DFA", import(".BaseModel"))
local cjson = require("cjson")
local PartnerNameTrasTable = xyd.tables.partnerNameTrasTable

function Trie:ctor(params)
	self.edge = {}
	self.idx = params.idx or -1
	self.value = params.value or ""
end

function Trie:getEdges()
	return self.edge
end

function Trie:getEdge(u)
	return self.edge[u]
end

function Trie:addEdge(u, index)
	if index == nil then
		index = -1
	end

	self.edge[u] = Trie.new({
		idx = index,
		value = tostring(self.value) .. tostring(u)
	})
end

function Trie:getFail()
	return self.fail
end

function Trie:setFail(fail)
	self.fail = fail
end

function Trie:setIndex(index)
	self.idx = index
end

function Trie:getIdx()
	return self.idx
end

function Trie:isLeaf()
	return not next(self.edge)
end

function Trie:getValue()
	return self.value
end

function AC_DFA:ctor()
	AC_DFA.super.ctor(self)

	self.root = nil
	self.zh_tw_names_ = {}
	self.en_en_names_ = {}
	self.ja_jp_names_ = {}
	self.fr_fr_names_ = {}
	self.ko_kr_names_ = {}
	self.lang = {
		"zh_tw",
		"en_en",
		"fr_fr",
		"ja_jp",
		"ko_kr",
		"de_de"
	}
	self.langNames = {}

	for i = 1, #self.lang do
		local names = PartnerNameTrasTable:getLangNames(self.lang[i])
		self[self.lang[i] .. "_names_"] = names

		table.insert(self.langNames, names)
	end

	self:initACDFA(self:getAllName())
end

function AC_DFA:getAllName()
	local result = {}

	for i = 1, #self.lang do
		if xyd.Global.lang ~= self.lang[i] then
			result = xyd.tableConcat(result, self.langNames[i])
		end
	end

	return result
end

function AC_DFA:initACDFA(strs)
	self.root = Trie.new({
		value = "",
		level = 0
	})
	local error = -1

	for i = 1, #strs do
		if not strs[i] then
			error = i

			break
		end

		self:insertTrie(strs[i], i)
	end

	if error > -1 then
		local errorInfo = {
			error = "ACDFA partner Name is undefined, id: " .. tostring(error) .. " " .. tostring(xyd.Global.lang),
			player_id = xyd.Global.playerID,
			osType = xyd.Global.osType_
		}
		local encodeInfo = cjson.encode(errorInfo)

		xyd.db.errorLog:add(encodeInfo)

		return
	end

	self:initFail()
end

function AC_DFA:insertTrie(str, index)
	if not str then
		return
	end

	str = string.lower(str)
	local v = self.root

	for i = 1, #str do
		local x = string.sub(str, i, i)

		if not v:getEdge(x) then
			v:addEdge(x)
		end

		v = v:getEdge(x)

		if i == #str then
			v:setIndex(index)
		end
	end
end

function AC_DFA:initFail()
	local q = {}
	local edges = self.root:getEdges()

	for key, _ in pairs(edges) do
		self.root:getEdge(key):setFail(self.root)
		table.insert(q, self.root:getEdge(key))
	end

	while #q > 0 do
		local now = q[1]
		local edges = now:getEdges()
		q = xyd.splice(q, 1, 1)

		for key, edge in ipairs(edges) do
			local fail = now:getFail():getEdge(key)

			if fail then
				edge:setFail(fail)
			else
				edge:setFail(self.root)
			end

			table.insert(q, edge)
		end
	end
end

function AC_DFA:query(s)
	s = string.lower(s)
	local now = self.root
	local cnt = 0
	local result = {}

	for i = 1, #s do
		local tmpNow = now:getEdge(string.sub(s, i, i))
		local tmpPos = i

		while tmpNow do
			if tmpNow:isLeaf() then
				result[i] = {
					value = tmpNow:getValue(),
					index = tmpNow:getIdx()
				}
				cnt = cnt + 1
				tmpNow = tmpNow:getFail()

				if tmpNow == self.root then
					break
				end
			else
				local next = tmpNow:getEdge(string.sub(s, tmpPos + 1, tmpPos + 1))

				if next then
					tmpNow = next
					tmpPos = tmpPos + 1
				else
					tmpNow = tmpNow:getFail()

					if tmpNow == self.root then
						break
					end
				end
			end
		end
	end

	return result
end

function AC_DFA:preTraslation(str)
	local res = ""
	local keyArray = self:query(str)
	local i = 1

	while i <= #str do
		if keyArray[i] and self:isValid(str, i, keyArray[i].value) then
			local value = keyArray[i].value
			local index = keyArray[i].index % #self[xyd.Global.lang .. "_names_"]

			if index == 0 then
				index = #self[xyd.Global.lang .. "_names_"]
			end

			i = i + #value
			res = res .. tostring(self[xyd.Global.lang .. "_names_"][index])
		else
			res = tostring(res) .. string.sub(str, i, i)
			i = i + 1
		end
	end

	return res
end

function AC_DFA:isValid(str, index, value)
	return not self:isPreWord(str, index, value) and not self:isLaterWord(str, index, value)
end

function AC_DFA:isPreWord(str, index, value)
	if index > 1 and self:isWord(string.sub(str, index - 1, index - 1)) then
		return true
	end

	return false
end

function AC_DFA:isLaterWord(str, index, value)
	local v_length = #value

	if #str >= index + v_length and self:isWord(string.sub(str, index + v_length, index + v_length)) then
		return true
	end

	return false
end

function AC_DFA:isWord(s)
	if string.find(s, "[a-z]") or string.find(s, "[A-Z]") then
		return true
	end

	return false
end

return AC_DFA
