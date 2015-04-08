--[[
LuCI - Logger model

Copyright 2015 Andrian Yablonskyy <andrian.yablonskyy@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]--

local require = require

local io = require "io"
local string = require "string"
local debug = require "debug"

module("luci.model.log", package.seeall)

function _Msg(lvl, format, ...)
	io.stderr:write(string.format(lvl .. format .. "\n", ...))
end

function i(...)
	_Msg('INFO: ', ...)
end

function w(...)
	_Msg('WARNING: ', ...)
end

function e(...)
	_Msg('ERROR: ', ...)
end

function d(...)
	_Msg('DEBUG: ', ...)
end

function t(traceb, ...)
	-- AY: Skip current level
	local level = 2

	if ... then
		_Msg("TRACE: ", ...)
	end

	while true do
		local info = debug.getinfo(level, "Sl")
		if not info then break end
		if info.what == "C" then	 -- is a C function?
			_Msg("TRACE: ", "%d: %s", level, "C function")
		else	 -- a Lua function
			_Msg("TRACE: ", "%s:%d", info.short_src, info.currentline)
		end
		level = level + 1
	end

	if traceb ~= nil then
		_Msg("", debug.traceback())
	end
end

function dumpObj(t, exclusions)
	local out = ""

	dump = function(str)
		str = str or ""
		out = out .. str
	end

	dumpln = function(str)
		dump(str)
		dump("\n")
	end

	local nests = 0
	exclusions = exclusions or {}

	local indent = function()
		for i = 1, nests do
			dump("  ")
		end
	end
	
	local excluded = function(key)
		for _, v in pairs(exclusions) do
			if v == key then
				return true
			end
		end
		return false
	end

	local dumpV = function(k, v)
		
	end

	local recurse = function(t, recurse, exclusions)
		local isFirst = true
		for k, v in pairs(t) do
			if isFirst then
				indent()
				dumpln("|")
				isFirst = false
			end

			if not excluded(k) then
				indent()
				dump("|-> "..type(v)..", "..k..": ")

				if type(v) == "table" then
					nests = nests + 1
					dumpln();
					recurse(v, recurse, exclusions)
				elseif type(v) == "userdata" or type(v) == "function" then
					dumpln(type(v))
				elseif type(v) == "string" then
					dumpln("'"..v.."'")
				else
					dumpln(tostring(v))
				end
			end
		end
		nests = nests - 1
	end

	nests = 0
	dumpln("=================== OBJECT DUMP ===================")
	if type(t) == "table" then
		for k, v in pairs(t) do
			dump(type(v)..", "..k..": ")

			if type(v) == "table" then
				nests = nests + 1
				dumpln()
				recurse(v, recurse, exclusions)
			elseif type(v) == "userdata" or type(v) == "function" then
				dumpln(type(v))
			elseif type(v) == "string" then
				dumpln("'"..v.."'")
			else
				dumpln(tostring(v))
			end
			dumpln()
		end
	elseif type(t) == "userdata" or type(t) == "function" then
		dumpln(type(t))
	elseif type(t) == "string" then
		dumpln(type(t)..": '"..t.."'")
	else
		dumpln(tostring(t))
	end
	dumpln("======================= END =======================")

	return out
end

function toHtml(str)
	str = string.gsub(str, "\n", "<br/>")
	str = string.gsub(str, " ", "&nbsp;")
	return str
end