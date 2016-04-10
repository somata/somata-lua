math.randomseed(os.time())

function randomString(length)
    if length == nil then length = 5 end
    local chars = {}
    for i = 1, length do
        table.insert(chars, string.char(math.random(97, 122)))
    end
    return table.concat(chars)
end

return {
    randomString = randomString
}
