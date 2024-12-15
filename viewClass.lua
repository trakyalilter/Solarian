local viewClass = {}
viewClass.View = {name="",pageNo=0}
function viewClass.View:create(o)
    o.parent = self
    return o
end

return viewClass