class_name CGEEnum
extends RefCounted
## Enumeration definitions for the custom graph editor.
##
## This file contains various enumerations used throughout the custom graph editor logic.

## Type of graph
enum GraphType {
    DIRECTED,       ## Directed graph (edges have a direction)
    UNDIRECTED      ## Undirected graph (edges have no direction). Not really supported yet.
}