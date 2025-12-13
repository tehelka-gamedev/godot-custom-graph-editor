class_name CGEClipboard
extends RefCounted
## A clipboard for the Custom Graph Editor.
##
## This class represents a clipboard used to store nodes and links
## from the graph editor by serializing them.

## serialized nodes
var nodes: Array[Dictionary] = []
## serialized links
var links: Array[Dictionary] = []


## Empty the clipboard.
func clear() -> void:
    nodes.clear()
    links.clear()
   

## Add a node to the clipboard.
func add_node(node: CGEGraphNodeUI) -> void:
    nodes.append(node.serialize())

## Add a link to the clipboard.
func add_link(link: CGEGraphLinkUI) -> void:
    links.append(link.serialize())

## Check if the clipboard is empty.
func is_empty():
    return nodes.is_empty() and links.is_empty()
