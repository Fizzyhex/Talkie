local function runTransformers(transformers: { (...any) -> ...any }, ...)
    if #transformers == 0 then
        return ...
    end

    local data = table.pack(...)

    for _, transformer in transformers do
        data = table.pack(transformer(unpack(...)))
    end

    return data
end

return runTransformers