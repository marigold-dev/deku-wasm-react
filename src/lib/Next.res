
module Head = {
  type props = { "children" : React.element }
  @obj external makeProps : (~children: React.element, unit) => props = ""
  @module("next/head") external make : props => React.element = "default"
}