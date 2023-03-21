local class = require "com.class"

---@class Network
---@overload fun():Network
local Network = class:derive("Network")

local json = require("com.json")
local https = require("https")
local ltn12 = require("ltn12")



--[[
    DEV NOTES:

    Keep in mind that HTTPS requests are only possible within LOVE 12.0. Building the
    DLLs for =<11.4 may be possible but stack overflow errors have occured during testing
    (indicated by the unhelpful "Failed to initialize filesystem" error).
    See more: https://love2d.org/wiki/lua-https
]]



--- Initializes the Network class.
---
--- This class is used for potential online functionality such as score submission,
--- version updates and advanced Discord integration.
function Network:new()
    self.USER_AGENT = "ZumaBlitzRemake"
end



---Sends a `GET` request to a specified URL.
---
---Return table fields:
---- `code`: The HTTPS code (or 0 if it fails).
---- `body`: The response body (or `nil` if it fails).
---@param url string The URL to send the `GET` request to.
---@param expectResJSON? boolean Expects a JSON response and serializes it.
---@return { code: number|0, body: string|nil }
function Network:get(url, expectResJSON)
    local code, body = https.request(url, {
        headers = {["User-Agent"] = self.USER_AGENT}
    })
    body = expectResJSON and json.encode(body) or body

    return {
        code = code,
        body = body
    }
end



---Sends a `GET` request to a specified URL on a separate thread.
---
---Return table fields (this table is the only argument in the `onFinish` function):
---- `code`: The HTTPS code (or 0 if it fails).
---- `body`: The response body (or `nil` if it fails).
---@param url string The URL to send the `GET` request to.
---@param expectResJSON? boolean Expects a JSON response and serializes it.
---@param onFinish function The function to be executed when the request finishes.
function Network:getThreaded(url, expectResJSON, onFinish)
    _ThreadManager:startJob("networkGet", {self = self, url = url, expectResJSON = expectResJSON}, onFinish)
end



---Sends a `POST` request with a serialized JSON as it's request body to a specified URL.
---
---Return table fields:
---- `code`: The HTTPS code (or 0 if it fails).
---- `body`: The response body (or `nil` if it fails).
---- `resHeaders`: Response headers (or `nil` if it fails).
---@param url string The URL to send the `POST` request to.
---@param tbl table The table to serialize to JSON.
---@param expectResJSON? boolean Expects a JSON response and serializes it.
---@return { code: number|0, body: string|nil, resHeaders: table|nil }
function Network:postSerialized(url, tbl, expectResJSON)
    local code, body, headers = https.request(url, {
        method = "post",
        headers = {
            ["User-Agent"] = self.USER_AGENT
        },
        data = json.encode(tbl),
    })
    body = expectResJSON and json.encode(body) or body
    return {
        code = code,
        body = body,
        resHeaders = headers
    }
end



return Network